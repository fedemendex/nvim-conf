local M = {}

local editor_window = nil

local function is_editor(window)
    if not window or not vim.api.nvim_win_is_valid(window) then
        return false
    end

    local buffer = vim.api.nvim_win_get_buf(window)

    return vim.bo[buffer].buftype == ""
        and vim.bo[buffer].filetype ~= "NvimTree"
end

function M.remember_editor(window)
    window = window or vim.api.nvim_get_current_win()

    if is_editor(window) then
        editor_window = window
    end
end

function M.focus_editor()
    if is_editor(editor_window) then
        vim.api.nvim_set_current_win(editor_window)
        return true
    end

    for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if is_editor(window) then
            editor_window = window
            vim.api.nvim_set_current_win(window)
            return true
        end
    end

    return false
end

return M
