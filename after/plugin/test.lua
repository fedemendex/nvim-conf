local windows = require("quiddam.windows")

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

_G.run_vim_test_in_bottom_terminal = send_test_to_bottom_terminal

vim.cmd([[
function! VimTestBottomTerminal(command) abort
    call v:lua.run_vim_test_in_bottom_terminal(a:command)
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
