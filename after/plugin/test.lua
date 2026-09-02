local windows = require("quiddam.windows")

-- VS Code ---------------------------------------------------------------------

-- vscode-neovim has no Neovim windows to draw a terminal into, and shelling a
-- command out resolves paths against whatever directory the shell happens to
-- sit in. VS Code's own runner resolves package paths from the workspace root
-- and reports into the Test Results panel, so under VS Code the whole vim-test
-- and ToggleTerm path below is skipped and the editor does the work.
if vim.g.vscode then
    local function run(command)
        return function()
            local ok, vscode = pcall(require, "vscode")

            if not ok then
                vim.notify(
                    "vim.g.vscode is set but the vscode module is unavailable",
                    vim.log.levels.ERROR
                )

                return
            end

            vscode.action(command)
        end
    end

    -- These are the editor-agnostic Test Explorer commands, so they keep
    -- working for the Go, TypeScript, and Python projects alike. For the Go
    -- extension's "Running tool: ..." output tab instead, swap these for
    -- go.test.cursor / go.test.file / go.test.workspace / go.test.previous.
    local tests = {
        { "<leader>tn", "testing.runAtCursor", "Run nearest test" },
        { "<leader>tf", "testing.runCurrentFile", "Run current test file" },
        { "<leader>ta", "testing.runAll", "Run entire test suite" },
        { "<leader>tl", "testing.reRunLastRun", "Run last test again" },
    }

    for _, test in ipairs(tests) do
        vim.keymap.set("n", test[1], run(test[2]), {
            silent = true,
            desc = test[3],
        })
    end

    return
end

-- Standalone Neovim -----------------------------------------------------------

-- Terminal 1 is the bottom terminal shared with <leader>ter. It is no longer
-- opened at startup, so the test strategy creates it on demand.
local function bottom_terminal()
    local terminals = require("toggleterm.terminal")

    return terminals.get(1, true)
        or terminals.Terminal:new({
            id = 1,
            direction = "horizontal",
        })
end

local function send_test_to_bottom_terminal(command)
    -- Create the split from the editor, not from nvim-tree.
    windows.focus_editor()

    local editor_window = vim.api.nvim_get_current_win()
    local terminal = bottom_terminal()

    -- Reveal Terminal 1 when it is closed, starting its shell if needed.
    if not terminal:is_open() then
        terminal:open(nil, "horizontal")
    end

    local channel = terminal.job_id

    if not channel or channel <= 0 then
        vim.notify(
            "The bottom terminal has no running shell",
            vim.log.levels.ERROR
        )

        return
    end

    -- Send the exact command without reparsing its quotes.
    vim.api.nvim_chan_send(channel, command .. "\n")

    -- ToggleTerm may change focus asynchronously, so restore it afterward.
    vim.schedule(function()
        if vim.api.nvim_win_is_valid(editor_window) then
            vim.api.nvim_set_current_win(editor_window)
        end
    end)
end

_G.run_vim_test_command = send_test_to_bottom_terminal

vim.cmd([[
function! VimTestBottomTerminal(command) abort
    call v:lua.run_vim_test_command(a:command)
endfunction

let g:test#custom_strategies = {
    \ 'bottom_terminal': function('VimTestBottomTerminal')
    \ }

let g:test#strategy = 'bottom_terminal'
]])

vim.g["test#echo_command"] = 0

vim.keymap.set("n", "<leader>tn", "<cmd>TestNearest<CR>", {
    silent = true,
    desc = "Run nearest test",
})

vim.keymap.set("n", "<leader>tf", "<cmd>TestFile<CR>", {
    silent = true,
    desc = "Run current test file",
})

vim.keymap.set("n", "<leader>ta", "<cmd>TestSuite<CR>", {
    silent = true,
    desc = "Run entire test suite",
})

vim.keymap.set("n", "<leader>tl", "<cmd>TestLast<CR>", {
    silent = true,
    desc = "Run last test again",
})
