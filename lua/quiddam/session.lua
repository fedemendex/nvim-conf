-- Per-directory session persistence.
--
-- Leaving Neovim records the window layout for the current directory, and
-- starting Neovim in that directory again without file arguments restores it.

local M = {}

local directory = vim.fn.stdpath("state") .. "/sessions"

-- Captured while this module loads, which happens before Neovim opens the
-- windows for its arguments. nvim-tree rewrites the argument list when it
-- hijacks a directory, so by VimEnter `nvim .` no longer looks like a
-- directory and the list cannot be trusted.
local startup_arguments = vim.fn.argv()

local function session_file()
    local name = vim.fn.getcwd():gsub("[/\\:]", "%%")

    return directory .. "/" .. name .. ".vim"
end

local function tree_is_open()
    local ok, api = pcall(require, "nvim-tree.api")

    if not ok then
        return false
    end

    local visible, result = pcall(api.tree.is_visible)

    return visible and result or false
end

-- Terminals and plugin scratch windows restore badly, so they are closed
-- before the layout is written.
local function close_transient_windows()
    pcall(function()
        require("nvim-tree.api").tree.close()
    end)

    pcall(function()
        require("dapui").close()
    end)

    pcall(vim.cmd, "UndotreeHide")

    local ok, terminal = pcall(require, "toggleterm.terminal")

    if ok then
        for _, term in ipairs(terminal.get_all(true)) do
            pcall(function()
                term:close()
            end)
        end
    end
end

-- An empty Neovim must not replace a layout that is worth keeping.
local function has_file_buffers()
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        local listed = vim.bo[buffer].buflisted
        local ordinary = vim.bo[buffer].buftype == ""
        local named = vim.api.nvim_buf_get_name(buffer) ~= ""

        if listed and ordinary and named then
            return true
        end
    end

    return false
end

-- `nvim` and `nvim .` should both restore; `nvim main.go` should not.
function M.started_without_files()
    for _, argument in ipairs(startup_arguments) do
        if vim.fn.isdirectory(argument) == 0 then
            return false
        end
    end

    return true
end

function M.save()
    if not has_file_buffers() then
        return
    end

    local tree_open = tree_is_open()

    close_transient_windows()

    vim.fn.mkdir(directory, "p")

    local file = session_file()
    local ok, err = pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(file))

    if not ok then
        vim.notify(
            "Could not save the session: " .. tostring(err),
            vim.log.levels.WARN
        )
        return
    end

    -- Sessions cannot describe the tree, so reopening it is appended as code.
    if tree_open then
        vim.fn.writefile({
            "lua pcall(function() require('nvim-tree.api').tree.open() end)",
            "lua pcall(function() require('quiddam.windows').focus_editor() end)",
        }, file, "a")
    end
end

function M.restore()
    local file = session_file()

    if vim.fn.filereadable(file) == 0 then
        return false
    end

    -- `nvim .` makes nvim-tree hijack the directory before this runs. Both the
    -- tree and the directory buffer have to go first, or they survive
    -- alongside the restored layout and the windows never match.
    pcall(function()
        require("nvim-tree.api").tree.close()
    end)

    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buffer)

        if name ~= "" and vim.fn.isdirectory(name) == 1 then
            pcall(vim.api.nvim_buf_delete, buffer, { force = true })
        end
    end

    local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(file))

    if not ok then
        vim.notify(
            "Could not restore the session: " .. tostring(err),
            vim.log.levels.WARN
        )
        return false
    end

    return true
end

-- Answers "why did my layout not come back?".
vim.api.nvim_create_user_command("SessionInfo", function()
    local file = session_file()

    vim.notify(table.concat({
        "session file: " .. file,
        "exists:       " .. tostring(vim.fn.filereadable(file) == 1),
        "arguments:    " .. vim.inspect(startup_arguments),
        "restores:     " .. tostring(M.started_without_files()),
        "directory:    " .. vim.fn.getcwd(),
    }, "\n"))
end, {
    desc = "Show the session state for this directory",
})

return M
