local dap = require("dap")
local dapui = require("dapui")
---@diagnostic disable-next-line: undefined-field
local dap_listeners = dap.listeners

-- Variables alongside the relevant source lines.
require("nvim-dap-virtual-text").setup({
    commented = true,
    only_first_definition = true,
    all_references = false,
})

-- Debugging interface.
dapui.setup({
    layouts = {
        {
            elements = {
                { id = "scopes",      size = 0.40 },
                { id = "stacks",      size = 0.25 },
                { id = "watches",     size = 0.20 },
                { id = "breakpoints", size = 0.15 },
            },
            size = 40,
            position = "left",
        },
        {
            elements = {
                { id = "repl",    size = 0.50 },
                { id = "console", size = 0.50 },
            },
            size = 12,
            position = "bottom",
        },
    },
})

-- Breakpoint and stopped-line signs -------------------------------------------

-- nvim-dap draws breakpoints with the SignColumn highlight, which blends into
-- the gutter. Give them a dedicated red group, re-applied whenever a colorscheme
-- clears highlights.
local function set_breakpoint_highlights()
    vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400", bold = true })
    vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#e51400", bold = true })

    -- Amber band on the paused line, distinct from the blue-grey CursorLine.
    vim.api.nvim_set_hl(0, "DapStopped", { fg = "#ffc777", bold = true })
    vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#4b4122" })
end

set_breakpoint_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("quiddam_dap_signs", { clear = true }),
    callback = set_breakpoint_highlights,
})

vim.fn.sign_define("DapBreakpoint", {
    text = "B",
    texthl = "DapBreakpoint",
    numhl = "DapBreakpoint",
})

vim.fn.sign_define("DapBreakpointCondition", {
    text = "C",
    texthl = "DapBreakpointCondition",
    numhl = "DapBreakpointCondition",
})

vim.fn.sign_define("DapStopped", {
    text = "→",
    texthl = "DapStopped",
    linehl = "DapStoppedLine",
    numhl = "DapStopped",
})

-- Where execution stops ------------------------------------------------------

-- By default nvim-dap shows the stopped location in the current window, so
-- debugging a _test.go that stops in another file swaps the test out of its
-- pane. Instead, the window a session was launched from stays put: stops land
-- in a window already showing the file, else another file window, else a new
-- split beside the launch window.
local launch_window

local function remember_launch_window()
    if not dap.session() then
        launch_window = vim.api.nvim_get_current_win()
    end
end

local function is_file_window(win)
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.api.nvim_win_get_config(win).relative == ""
        and vim.bo[buf].buftype == ""
end

local function stop_window(bufnr)
    local current = vim.api.nvim_get_current_win()
    local windows = vim.tbl_filter(is_file_window, vim.api.nvim_tabpage_list_wins(0))

    if vim.api.nvim_win_get_buf(current) == bufnr then
        return current
    end

    for _, win in ipairs(windows) do
        if vim.api.nvim_win_get_buf(win) == bufnr then
            return win
        end
    end

    local previous = vim.fn.win_getid(vim.fn.winnr("#"))
    for _, win in ipairs({ current, previous, unpack(windows) }) do
        if win ~= launch_window and vim.tbl_contains(windows, win) then
            return win
        end
    end

    local anchor = launch_window
    if not (anchor and vim.api.nvim_win_is_valid(anchor)) then
        anchor = current
    end

    return vim.api.nvim_win_call(anchor, function()
        vim.cmd("vsplit")
        return vim.api.nvim_get_current_win()
    end)
end

dap.defaults.fallback.switchbuf = function(bufnr, line, column)
    local win = stop_window(bufnr)

    if vim.api.nvim_win_get_buf(win) ~= bufnr then
        vim.api.nvim_win_set_buf(win, bufnr)
    end

    pcall(vim.api.nvim_win_set_cursor, win, { line, math.max(column - 1, 0) })
    vim.api.nvim_set_current_win(win)
    vim.cmd("normal! zv")
end

-- Clickable VS Code-style controls, shown while a session is active.
require("quiddam.debug_toolbar").setup()

-- Install/configure external adapters.
require("mason-nvim-dap").setup({
    ensure_installed = {
        "delve",
        "python",
        "js",
    },
    handlers = {},
})

-- Go -------------------------------------------------------------------------

require("dap-go").setup()

-- Python ---------------------------------------------------------------------

local debugpy_python =
    vim.fn.stdpath("data")
    .. "/mason/packages/debugpy/venv/bin/python"

require("dap-python").setup(debugpy_python)

-- JavaScript and TypeScript --------------------------------------------------

-- JavaScript and TypeScript --------------------------------------------------

local function cancel_debug(message)
    vim.notify(message, vim.log.levels.ERROR, {
        title = "Debugger",
    })

    error("Debug launch cancelled", 0)
end

local function require_command(command, install_hint)
    if vim.fn.executable(command) == 0 then
        cancel_debug(
            "`"
            .. command
            .. "` was not found.\n"
            .. install_hint
        )
    end
end

local function port_is_listening(port)
    if vim.fn.executable("lsof") == 0 then
        return true
    end

    vim.fn.system({
        "lsof",
        "-nP",
        "-iTCP:" .. port,
        "-sTCP:LISTEN",
    })

    return vim.v.shell_error == 0
end

require("dap-vscode-js").setup({
    debugger_cmd = { "js-debug-adapter" },
    adapters = {
        "pwa-node",
        "pwa-chrome",
    },
})

local js_languages = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
}

for _, language in ipairs(js_languages) do
    dap.configurations[language] = {
        {
            name = "Launch current file with Node",
            type = "pwa-node",
            request = "launch",

            program = function()
                require_command(
                    "node",
                    "Install Node.js or make sure it is available in PATH."
                )

                return vim.api.nvim_buf_get_name(0)
            end,

            cwd = "${workspaceFolder}",
            sourceMaps = true,

            skipFiles = {
                "<node_internals>/**",
                "${workspaceFolder}/node_modules/**",
            },
        },

        {
            name = "Attach to running Node process",
            type = "pwa-node",
            request = "attach",

            processId = function()
                require_command(
                    "node",
                    "Install Node.js or make sure it is available in PATH."
                )

                local processes = vim.fn.systemlist({
                    "pgrep",
                    "-fl",
                    "node",
                })

                if vim.v.shell_error ~= 0 or #processes == 0 then
                    cancel_debug(
                        "No running Node process was found.\n"
                        .. "Start the application first, for example:\n"
                        .. "npm run dev"
                    )
                end

                return require("dap.utils").pick_process()
            end,

            cwd = "${workspaceFolder}",
            sourceMaps = true,
        },

        {
            name = "Launch browser application with Vite",
            type = "pwa-chrome",
            request = "launch",

            url = function()
                local port = "5173"

                if not port_is_listening(port) then
                    cancel_debug(
                        "Nothing is listening on localhost:"
                        .. port
                        .. ".\nStart Vite first, usually with:\n"
                        .. "npm run dev"
                    )
                end

                return "http://localhost:" .. port
            end,

            webRoot = "${workspaceFolder}",
            sourceMaps = true,
        },
    }
end

-- Debugging reminder ---------------------------------------------------------

local help_window
local help_buffer

local function close_debug_help()
    if help_window and vim.api.nvim_win_is_valid(help_window) then
        vim.api.nvim_win_close(help_window, true)
    end

    help_window = nil
    help_buffer = nil
end

local function open_debug_help()
    close_debug_help()

    local lines = {
        " DEBUGGING",
        "",
        " Space dc  Continue/start",
        " Space db  Toggle breakpoint",
        " Space dn  Step over",
        " Space di  Step into",
        " Space do  Step out",
        " Space dq  Stop",
        " Space de  Inspect value",
        " Space dh  Toggle this help",
    }

    help_buffer = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_lines(
        help_buffer,
        0,
        -1,
        false,
        lines
    )

    vim.bo[help_buffer].modifiable = false
    vim.bo[help_buffer].bufhidden = "wipe"

    local width = 32
    local height = #lines

    help_window = vim.api.nvim_open_win(help_buffer, false, {
        relative = "editor",
        width = width,
        height = height,
        row = 1,
        col = math.max(0, vim.o.columns - width - 3),
        style = "minimal",
        border = "rounded",
        focusable = false,
        zindex = 50,
    })
end

local function toggle_debug_help()
    if help_window and vim.api.nvim_win_is_valid(help_window) then
        close_debug_help()
    else
        open_debug_help()
    end
end

-- Open/close interface with the debug session -------------------------------

dap_listeners.before.attach.debug_ui = function()
    dapui.open()
    vim.schedule(open_debug_help)
end

dap_listeners.before.launch.debug_ui = function()
    dapui.open()
    vim.schedule(open_debug_help)
end

dap_listeners.before.event_terminated.debug_ui = function()
    dapui.close()
    close_debug_help()
end

dap_listeners.before.event_exited.debug_ui = function()
    dapui.close()
    close_debug_help()
end

dap_listeners.after.event_exited.debug_error_message =
    function(_, body)
        if body and body.exitCode and body.exitCode ~= 0 then
            vim.schedule(function()
                vim.notify(
                    "The debugged process exited with code "
                    .. body.exitCode
                    .. ".\n"
                    .. "Check that the application, Vite/Node runtime, "
                    .. "and required project dependencies are available.\n"
                    .. "Run :DapShowLog for technical details.",
                    vim.log.levels.ERROR,
                    {
                        title = "Debugger stopped",
                    }
                )
            end)
        end
    end

-- Familiar debugger controls ------------------------------------------------

-- Keyboards without a function row cannot reach F5-F11 without a layer, so the
-- <leader>d chords are the primary bindings and the F-keys remain as aliases.
local controls = {
    {
        chord = "<leader>dc",
        fkey = "<F5>",
        action = function()
            remember_launch_window()
            dap.continue()
        end,
        desc = "Debug: start or continue",
    },
    {
        chord = "<leader>db",
        fkey = "<F9>",
        action = dap.toggle_breakpoint,
        desc = "Debug: toggle breakpoint",
    },
    {
        chord = "<leader>dn",
        fkey = "<F10>",
        action = dap.step_over,
        desc = "Debug: step over",
    },
    {
        chord = "<leader>di",
        fkey = "<F11>",
        action = dap.step_into,
        desc = "Debug: step into",
    },
    {
        chord = "<leader>do",
        fkey = "<S-F11>",
        action = dap.step_out,
        desc = "Debug: step out",
    },
    {
        chord = "<leader>dq",
        fkey = "<S-F5>",
        action = dap.terminate,
        desc = "Debug: terminate",
    },
}

for _, control in ipairs(controls) do
    vim.keymap.set("n", control.chord, control.action, {
        desc = control.desc,
    })

    vim.keymap.set("n", control.fkey, control.action, {
        desc = control.desc,
    })
end

vim.keymap.set({ "n", "x" }, "<leader>de", function()
    dapui.eval()
end, {
    desc = "Debug: inspect value",
})

vim.keymap.set("n", "<leader>dh", toggle_debug_help, {
    desc = "Debug: toggle controls reminder",
})

vim.keymap.set("n", "<leader>du", dapui.toggle, {
    desc = "Debug: toggle interface",
})

vim.keymap.set("n", "<leader>dr", dap.repl.open, {
    desc = "Debug: open REPL",
})

vim.keymap.set("n", "<leader>dt", function()
    remember_launch_window()
    require("dap-go").debug_test()
end, {
    desc = "Debug nearest Go test",
})
