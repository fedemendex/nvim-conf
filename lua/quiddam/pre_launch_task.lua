-- Runs the `preLaunchTask` named in a launch.json configuration before the
-- debugger starts, the way VS Code does, so the build a configuration relies on
-- (typically `tsc` producing the `outFiles` it maps breakpoints through) does
-- not have to be run by hand.
--
-- A task label is looked up in .vscode/tasks.json first. Labels VS Code
-- detects on its own are understood as well: "tsc: build - <tsconfig>" and
-- "npm: <script>". Not supported: background tasks (`isBackground`, "tsc:
-- watch"), which VS Code waits on through problem matchers, and task types
-- other than shell, process and typescript. Those are reported and skipped, and
-- the launch continues.

local M = {}

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Debugger" })
end

local function read_tasks(root)
    local path = root .. "/.vscode/tasks.json"
    local handle = io.open(path, "r")

    if not handle then
        return {}
    end

    local contents = handle:read("*a")
    handle:close()

    local ok, data = pcall(vim.json.decode, contents, { skip_comments = true })

    if not ok or type(data) ~= "table" then
        notify("Could not parse " .. path .. ":\n" .. tostring(data), vim.log.levels.WARN)

        return {}
    end

    return data.tasks or {}
end

local function substitute(text, root)
    if type(text) == "table" then
        text = text.value
    end

    text = tostring(text)
    text = text:gsub("%${workspaceFolder}", root)
    text = text:gsub("%${cwd}", root)
    text = text:gsub("%${workspaceFolderBasename}", vim.fs.basename(root))

    return text
end

-- The project's own tsc when there is one, the way VS Code prefers it.
local function find_tsc(root)
    local local_bin = root .. "/node_modules/.bin/tsc"

    if vim.fn.executable(local_bin) == 1 then
        return { local_bin }
    end

    if vim.fn.executable("tsc") == 1 then
        return { "tsc" }
    end

    return { "npx", "--no-install", "tsc" }
end

local function tsc_command(root, tsconfig, watch)
    local command = find_tsc(root)

    vim.list_extend(command, { "-p", tsconfig })

    if watch then
        table.insert(command, "--watch")
    end

    return command
end

-- Turns a task definition into { command = {...}, cwd = ..., background = ... }
-- plus the labels it depends on.
local function describe(task, root)
    local cwd = root

    if task.options and task.options.cwd then
        cwd = substitute(task.options.cwd, root)
    end

    local description = {
        cwd = cwd,
        background = task.isBackground == true,
        depends_on = {},
    }

    local depends = task.dependsOn

    if type(depends) == "string" then
        depends = { depends }
    end

    for _, dependency in ipairs(depends or {}) do
        table.insert(
            description.depends_on,
            type(dependency) == "table" and dependency.task or dependency
        )
    end

    if task.type == "typescript" then
        description.command = tsc_command(
            root,
            substitute(task.tsconfig or "tsconfig.json", root),
            task.option == "watch"
        )
        description.background = task.option == "watch"
    elseif task.command then
        local parts = { substitute(task.command, root) }

        for _, argument in ipairs(task.args or {}) do
            table.insert(parts, substitute(argument, root))
        end

        if task.type == "process" then
            description.command = parts
        else
            -- Shell tasks may use pipes and globs, so the shell parses them.
            local quoted = { parts[1] }

            for index = 2, #parts do
                quoted[index] = vim.fn.shellescape(parts[index])
            end

            description.command = { vim.o.shell, "-c", table.concat(quoted, " ") }
        end
    end

    return description
end

local function detect(label, root)
    local mode, tsconfig = label:match("^tsc: (%a+) %- (.+)$")

    if mode == "build" or mode == "watch" then
        return {
            cwd = root,
            background = mode == "watch",
            depends_on = {},
            command = tsc_command(root, tsconfig, mode == "watch"),
        }
    end

    local script = label:match("^npm: (.+)$")

    if script then
        -- VS Code appends " - <folder>" for scripts in nested packages.
        script = script:gsub(" %- .*$", "")

        return {
            cwd = root,
            background = false,
            depends_on = {},
            command = { "npm", "run", script },
        }
    end
end

local function find(label, root)
    for _, task in ipairs(read_tasks(root)) do
        if task.label == label then
            return describe(task, root)
        end
    end

    return detect(label, root)
end

local function tail(text, count)
    local lines = vim.split(vim.trim(text), "\n", { plain = true })

    return table.concat(vim.list_slice(lines, math.max(1, #lines - count + 1)), "\n")
end

-- Runs `label` and the tasks it depends on, then calls on_done(true), or
-- on_done(false) after reporting why a task failed. `seen` guards against a
-- dependency cycle.
local function run_task(label, root, seen, on_done)
    if seen[label] then
        on_done(true)

        return
    end

    seen[label] = true

    local task = find(label, root)

    if not task then
        notify(
            "Task `" .. label .. "` was not found in .vscode/tasks.json,\n"
            .. "and is not one of the tasks that can be detected "
            .. "(`tsc: build - <tsconfig>`, `npm: <script>`).",
            vim.log.levels.ERROR
        )
        on_done(false)

        return
    end

    local pending = vim.deepcopy(task.depends_on)

    local function run_own_command()
        if not task.command then
            -- A task that only groups its dependencies.
            on_done(true)

            return
        end

        if task.background then
            notify(
                "`" .. label .. "` is a background task, which cannot be "
                .. "waited for here. Skipping it.",
                vim.log.levels.WARN
            )
            on_done(true)

            return
        end

        notify("Running task: " .. label)

        local ok, err = pcall(vim.system, task.command, {
            cwd = task.cwd,
            text = true,
        }, function(result)
            vim.schedule(function()
                if result.code == 0 then
                    on_done(true)

                    return
                end

                -- tsc reports its errors on stdout, most tools on stderr.
                notify(
                    "Task `" .. label .. "` failed with exit code "
                    .. result.code .. ", so the debugger was not started.\n\n"
                    .. tail((result.stdout or "") .. (result.stderr or ""), 15),
                    vim.log.levels.ERROR
                )
                on_done(false)
            end)
        end)

        if not ok then
            notify(
                "Could not start task `" .. label .. "`: " .. tostring(err),
                vim.log.levels.ERROR
            )
            on_done(false)
        end
    end

    local function next_dependency()
        local dependency = table.remove(pending, 1)

        if not dependency then
            run_own_command()

            return
        end

        run_task(dependency, root, seen, function(ok)
            if ok then
                next_dependency()
            else
                on_done(false)
            end
        end)
    end

    next_dependency()
end

---@param label string
---@param on_done fun(ok: boolean)
function M.run(label, on_done)
    run_task(label, vim.fn.getcwd(), {}, on_done)
end

return M
