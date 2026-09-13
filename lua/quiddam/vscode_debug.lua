-- Inspecting the embedded Neovim while VS Code appears frozen.
--
-- vscode-neovim starts Neovim with --embed over stdio, so there is no address
-- to connect to and no way to ask a wedged instance what it is doing. The
-- extension's own log is no substitute: it records the messages Neovim sent
-- out, not the state Neovim is sitting in, and that second half is the one
-- that matters when keystrokes stop landing.
--
-- Neovim keeps answering RPC from inside its input waits -- the hit-enter
-- prompt and the getcharstr() loops plugins block in both pump the event loop
-- -- so a second listening address stays reachable in exactly the situation
-- where the editor does not. Hence a socket, opened only under VS Code, and a
-- report that names the states input can be lost in.
if not vim.g.vscode then
    return
end

local directory = vim.fn.stdpath("state") .. "/vscode-sockets"

vim.fn.mkdir(directory, "p")

local socket = directory .. "/" .. vim.fn.getpid() .. ".sock"

-- A stale socket file left by a crashed instance would make serverstart fail,
-- and the pid it is named for is gone either way.
pcall(vim.fn.delete, socket)

local ok, err = pcall(vim.fn.serverstart, socket)

if not ok then
    vim.notify(
        "Could not open the debug socket: " .. tostring(err),
        vim.log.levels.WARN
    )
end

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        pcall(vim.fn.delete, socket)
    end,
})

-- Called over RPC by scripts/vscode-probe.sh. It returns a string rather than
-- printing, because a frozen instance can still compute an answer but cannot
-- be watched.
function _G.quiddam_vscode_probe()
    local lines = {}

    local function add(label, value)
        lines[#lines + 1] = string.format("%-18s %s", label .. ":", value)
    end

    -- nvim_get_mode().blocking is the flag that separates the two ways input
    -- goes missing. True means Neovim is inside a blocking read -- a plugin
    -- sitting in getcharstr(), which is what flash.nvim and multicursor do
    -- while they wait for their next key -- and every keystroke VS Code
    -- forwards is being eaten by that read.
    local mode = vim.api.nvim_get_mode()

    add("time", os.date("%Y-%m-%d %H:%M:%S"))
    add("mode", vim.inspect(mode.mode))
    add("blocking", tostring(mode.blocking))

    -- mode(1) spells out the sub-mode: "r", "rm" and "r?" are the hit-enter,
    -- more, and confirm prompts. Any of them is modal, and all typing goes to
    -- dismissing the prompt instead of into the buffer.
    add("mode(1)", vim.inspect(vim.fn.mode(1)))

    -- state() reports what Neovim is halted on; "m" is "halted for a message"
    -- and confirms a prompt is up.
    add("state", vim.inspect(vim.fn.state()))

    local window = vim.api.nvim_get_current_win()
    local buffer = vim.api.nvim_win_get_buf(window)
    local config = vim.api.nvim_win_get_config(window)

    -- A floating or hidden window is the other way typing disappears: the
    -- cursor is in a Neovim window VS Code never draws, so the keys land
    -- somewhere real but invisible.
    add("window", tostring(window))
    add("float", tostring(config.relative ~= ""))
    add("windows open", tostring(#vim.api.nvim_list_wins()))
    add("buffer", tostring(buffer))
    add("buffer name", vim.api.nvim_buf_get_name(buffer))
    add("buftype", vim.inspect(vim.bo[buffer].buftype))
    add("filetype", vim.inspect(vim.bo[buffer].filetype))

    -- vscode-neovim tags the buffers it owns with the document URI. A current
    -- buffer without one is a buffer VS Code has no editor for.
    add("vscode_uri", tostring(vim.b[buffer].vscode_uri))

    local messages = vim.fn.execute("messages")
    local recent = {}

    for line in messages:gmatch("[^\n]+") do
        recent[#recent + 1] = line
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "last messages:"

    for index = math.max(1, #recent - 14), #recent do
        lines[#lines + 1] = "  " .. recent[index]
    end

    return table.concat(lines, "\n")
end

-- Catching the freeze in the act ---------------------------------------------
--
-- The probe above only answers while someone is there to run it, and this
-- fault clears itself the moment anything moves the cursor -- including
-- clicking another editor to go and get a terminal. So the condition is
-- recorded as it happens instead.
--
-- What it watches for: vscode-neovim tags every buffer it holds an editor for
-- with vscode_uri. A buffer without one is real to Neovim and invisible to VS
-- Code -- the startup buffer is the standing example, and this instance still
-- has it. Land the cursor there and nothing is wrong by Neovim's reckoning:
-- normal mode, not blocking, keys arriving and being applied. They are simply
-- being applied to a buffer no editor is showing, which from the front looks
-- exactly like a dead editor.
local log_file = vim.fn.stdpath("state") .. "/vscode-freeze.log"

local function log(line)
    pcall(function()
        local handle = io.open(log_file, "a")

        if not handle then
            return
        end

        handle:write(os.date("%Y-%m-%d %H:%M:%S ") .. line .. "\n")
        handle:close()
    end)
end

local function is_rendered(window)
    if not vim.api.nvim_win_is_valid(window) then
        return false
    end

    return vim.b[vim.api.nvim_win_get_buf(window)].vscode_uri ~= nil
end

-- Starts true because that is the state at startup, before any file is open,
-- and logging the empty editor every session would bury the real events.
local was_unrendered = true

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
    callback = function()
        local window = vim.api.nvim_get_current_win()
        local unrendered = not is_rendered(window)

        -- Only transitions are worth a line; these fire constantly.
        if unrendered == was_unrendered then
            return
        end

        was_unrendered = unrendered

        if not unrendered then
            log(string.format("recovered -> win %d", window))

            return
        end

        local buffer = vim.api.nvim_win_get_buf(window)

        log(string.format(
            "STUCK in unrendered window: win=%d buf=%d buftype=%q "
            .. "filetype=%q mode=%q name=%q",
            window,
            buffer,
            vim.bo[buffer].buftype,
            vim.bo[buffer].filetype,
            vim.api.nvim_get_mode().mode,
            vim.api.nvim_buf_get_name(buffer)
        ))
    end,
})

-- The way out, and the test of the diagnosis in one key.
--
-- Neovim is not blocked in this state, so mappings still fire even though the
-- editor looks dead. If pressing this brings VS Code back, the cause was the
-- cursor sitting in a window VS Code does not draw, and nothing else.
local function focus_rendered_window()
    for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if is_rendered(window) then
            vim.api.nvim_set_current_win(window)

            return true
        end
    end

    return false
end

vim.api.nvim_create_user_command("VscodeUnstick", function()
    if focus_rendered_window() then
        log("unstuck by hand")
        vim.notify("Moved back to a window VS Code is showing")
    else
        vim.notify("No window maps to a VS Code editor", vim.log.levels.WARN)
    end
end, {
    desc = "Return the cursor to a window VS Code renders",
})

vim.keymap.set("n", "<leader>z", "<cmd>VscodeUnstick<CR>", {
    silent = true,
    desc = "Return the cursor to a window VS Code renders",
})
