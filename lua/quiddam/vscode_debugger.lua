-- The debugger chords under VS Code.
--
-- nvim-dap has no windows to draw into here, so the same keys drive VS Code's
-- own debugger instead, and launch.json, the breakpoint gutter and the debug
-- toolbar are VS Code's. Breakpoints are toggled at the cursor, which
-- vscode-neovim keeps in step with the editor; clicking the gutter works
-- natively and needs nothing from this file.

local function run(code)
    return function()
        local ok, vscode = pcall(require, "vscode")

        if not ok then
            vim.notify(
                "vim.g.vscode is set but the vscode module is unavailable",
                vim.log.levels.ERROR
            )

            return
        end

        vscode.eval_async(code)
    end
end

local function command(id)
    return run("await vscode.commands.executeCommand('" .. id .. "');")
end

local controls = {
    {
        chord = "<leader>dc",
        fkey = "<F5>",
        -- F5 starts when idle and continues when paused, as in VS Code.
        action = run([[
            await vscode.commands.executeCommand(
                vscode.debug.activeDebugSession
                    ? 'workbench.action.debug.continue'
                    : 'workbench.action.debug.start'
            );
        ]]),
        desc = "Debug: start or continue",
    },
    {
        chord = "<leader>db",
        fkey = "<F9>",
        action = command("editor.debug.action.toggleBreakpoint"),
        desc = "Debug: toggle breakpoint",
    },
    {
        chord = "<leader>dn",
        fkey = "<F10>",
        action = command("workbench.action.debug.stepOver"),
        desc = "Debug: step over",
    },
    {
        chord = "<leader>di",
        fkey = "<F11>",
        action = command("workbench.action.debug.stepInto"),
        desc = "Debug: step into",
    },
    {
        chord = "<leader>do",
        fkey = "<S-F11>",
        action = command("workbench.action.debug.stepOut"),
        desc = "Debug: step out",
    },
    {
        chord = "<leader>dq",
        fkey = "<S-F5>",
        action = command("workbench.action.debug.stop"),
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

vim.keymap.set(
    { "n", "x" },
    "<leader>de",
    command("editor.debug.action.showDebugHover"),
    { desc = "Debug: inspect value" }
)

vim.keymap.set(
    "n",
    "<leader>du",
    command("workbench.view.debug"),
    { desc = "Debug: toggle interface" }
)

vim.keymap.set(
    "n",
    "<leader>dr",
    command("workbench.debug.action.toggleRepl"),
    { desc = "Debug: open REPL" }
)

-- Provided by the Go extension.
vim.keymap.set(
    "n",
    "<leader>dt",
    command("go.debug.cursor"),
    { desc = "Debug nearest Go test" }
)
