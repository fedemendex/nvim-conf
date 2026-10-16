-- Double-click a line number or sign column to toggle a breakpoint on that
-- line, the way clicking the gutter does in VS Code.
--
-- The first click of a double-click has already moved the cursor, and the
-- second arrives as <2-LeftMouse>. Double-clicking text is left alone so word
-- selection keeps working. The mapping is an expr mapping that hands the key
-- back unchanged unless the pointer is over the gutter, and the debug toolbar
-- calls press() for the clicks it does not claim, because it replaces this
-- mapping while it is on screen.

local M = {}

local key = "<2-LeftMouse>"

local function in_gutter(pos)
    if pos.winid == 0 or pos.line == 0 then
        return false
    end

    local info = vim.fn.getwininfo(pos.winid)[1]

    return info ~= nil and pos.wincol <= info.textoff
end

function M.press(pressed)
    if pressed ~= key or vim.fn.mode() ~= "n" then
        return pressed
    end

    local pos = vim.fn.getmousepos()

    if not in_gutter(pos) then
        return pressed
    end

    local buffer = vim.api.nvim_win_get_buf(pos.winid)

    -- Terminals, the dap-ui panes and the file tree have gutters too.
    if vim.bo[buffer].buftype ~= "" then
        return pressed
    end

    -- Expr mappings run under textlock.
    vim.schedule(function()
        if not vim.api.nvim_win_is_valid(pos.winid) then
            return
        end

        vim.api.nvim_win_call(pos.winid, function()
            vim.api.nvim_win_set_cursor(pos.winid, { pos.line, 0 })
            require("dap").toggle_breakpoint()
        end)
    end)

    return ""
end

function M.setup()
    vim.keymap.set("n", key, function()
        return M.press(key)
    end, {
        expr = true,
        replace_keycodes = true,
        desc = "Toggle a breakpoint when double-clicking the gutter",
    })
end

return M
