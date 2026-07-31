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
        " F5        Continue/start",
        " F9        Toggle breakpoint",
        " F10       Step over",
        " F11       Step into",
        " Shift-F11 Step out",
        " Shift-F5  Stop",
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

vim.keymap.set("n", "<F5>", dap.continue, {
    desc = "Debug: start or continue",
})

vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, {
    desc = "Debug: toggle breakpoint",
})

vim.keymap.set("n", "<F10>", dap.step_over, {
    desc = "Debug: step over",
})

vim.keymap.set("n", "<F11>", dap.step_into, {
    desc = "Debug: step into",
})

vim.keymap.set("n", "<S-F11>", dap.step_out, {
    desc = "Debug: step out",
})

vim.keymap.set("n", "<S-F5>", dap.terminate, {
    desc = "Debug: terminate",
})

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
    require("dap-go").debug_test()
end, {
    desc = "Debug nearest Go test",
})
