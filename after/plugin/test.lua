local function send_test_to_bottom_terminal(command)
    local editor_window = vim.api.nvim_get_current_win()

    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        local is_terminal_one =
            vim.bo[buffer].filetype == "toggleterm"
            and vim.b[buffer].toggle_number == 1

        if is_terminal_one then
            local channel = vim.b[buffer].terminal_job_id

            if not channel or channel <= 0 then
                break
            end

            -- Reveal Terminal 1 when it is hidden.
            if vim.fn.bufwinid(buffer) == -1 then
                vim.cmd("1ToggleTerm direction=horizontal")
            end

            -- Send the exact command without reparsing its quotes.
            vim.api.nvim_chan_send(channel, command .. "\n")

            -- ToggleTerm may change focus asynchronously, so restore it afterward.
            vim.schedule(function()
                if vim.api.nvim_win_is_valid(editor_window) then
                    vim.api.nvim_set_current_win(editor_window)
                end
            end)

            return
        end
    end

    vim.notify("ToggleTerm 1 is not running", vim.log.levels.ERROR)
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
