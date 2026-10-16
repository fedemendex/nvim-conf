-- A clickable floating debug toolbar, modelled on the one VS Code shows while a
-- debug session is active: grip, continue/pause, step over, step into, step
-- out, restart, stop.
--
-- Clicks are routed through global expr mappings on the mouse keys that are
-- installed only while the toolbar is visible. Each mapping asks getmousepos()
-- whether the pointer is over the toolbar: if so it runs the button and
-- swallows the key, otherwise it hands the key back unchanged. The float itself
-- is non-focusable, so clicking a button never moves the cursor out of the
-- source window, and <C-w>w never lands in it.

local M = {}

local config = {
    -- "nerd" uses the VS Code codicons shipped in Nerd Fonts; "text" sticks to
    -- plain Unicode for terminals without a patched font.
    icons = "nerd",
    -- Screen row of the top border. Row 0 is the tabline.
    row = 1,
}

local icon_sets = {
    nerd = {
        -- VS Code codicons, written as UTF-8 byte escapes because the glyphs
        -- live in the Private Use Area and do not survive every editor.
        grip = "\238\172\132",
        continue = "\238\171\143",
        pause = "\238\171\145",
        step_over = "\238\171\150",
        step_into = "\238\171\148",
        step_out = "\238\171\149",
        restart = "\238\171\146",
        stop = "\238\171\151",
    },
    text = {
        grip = "⠿",
        continue = "▶",
        pause = "‖",
        step_over = "↷",
        step_into = "↓",
        step_out = "↑",
        restart = "↻",
        stop = "■",
    },
}

local highlight_links = {
    DapToolbarGrip = "Comment",
    DapToolbarContinue = "Function",
    DapToolbarStep = "Function",
    DapToolbarRestart = "DiagnosticOk",
    DapToolbarStop = "DiagnosticError",
}

local namespace = vim.api.nvim_create_namespace("quiddam_debug_toolbar")
local mouse_keys = {
    "<LeftMouse>",
    "<2-LeftMouse>",
    "<3-LeftMouse>",
    "<4-LeftMouse>",
    "<LeftDrag>",
    "<LeftRelease>",
}
local mouse_modes = { "n", "i", "x", "s", "t" }

local state = {
    window = nil,
    buffer = nil,
    -- Byte ranges of the rendered line, one per clickable region.
    regions = {},
    -- Column the float was dragged to; nil keeps it centred.
    col = nil,
    row = nil,
    -- Offset between the pointer and the float's corner while dragging.
    drag = nil,
    -- Whether the last press landed on the toolbar, so its release is eaten.
    pressed = false,
}

local function dap()
    return require("dap")
end

local function is_stopped()
    local session = dap().session()
    return session ~= nil and session.stopped_thread_id ~= nil
end

local function buttons()
    local stopped = is_stopped()

    return {
        { id = "grip", hl = "DapToolbarGrip" },
        stopped
            and { id = "continue", hl = "DapToolbarContinue", action = dap().continue }
            or { id = "pause", hl = "DapToolbarContinue", action = dap().pause },
        { id = "step_over", hl = "DapToolbarStep", action = dap().step_over },
        { id = "step_into", hl = "DapToolbarStep", action = dap().step_into },
        { id = "step_out", hl = "DapToolbarStep", action = dap().step_out },
        { id = "restart", hl = "DapToolbarRestart", action = dap().restart },
        { id = "stop", hl = "DapToolbarStop", action = dap().terminate },
    }
end

local function is_open()
    return state.window ~= nil and vim.api.nvim_win_is_valid(state.window)
end

local function render()
    local icons = icon_sets[config.icons] or icon_sets.nerd
    local line = ""
    local regions = {}

    for index, button in ipairs(buttons()) do
        -- Pad each icon so the hit area is wider than the glyph.
        local start = #line
        local cell = (index == 1 and " " or "  ") .. icons[button.id] .. " "
        line = line .. cell
        table.insert(regions, {
            start = start,
            finish = #line,
            button = button,
            icon_start = start + #cell - #icons[button.id] - 1,
            icon_finish = #line - 1,
        })
    end

    vim.bo[state.buffer].modifiable = true
    vim.api.nvim_buf_set_lines(state.buffer, 0, -1, false, { line })
    vim.bo[state.buffer].modifiable = false

    vim.api.nvim_buf_clear_namespace(state.buffer, namespace, 0, -1)
    for _, region in ipairs(regions) do
        vim.api.nvim_buf_set_extmark(state.buffer, namespace, 0, region.icon_start, {
            end_col = region.icon_finish,
            hl_group = region.button.hl,
        })
    end

    state.regions = regions
    return vim.fn.strdisplaywidth(line)
end

local function place(width)
    local columns = vim.o.columns
    local col = state.col or math.floor((columns - width - 2) / 2)
    local row = state.row or config.row

    return {
        relative = "editor",
        row = math.max(0, math.min(row, vim.o.lines - 3)),
        col = math.max(0, math.min(col, columns - width - 2)),
        width = width,
        height = 1,
    }
end

local function refresh()
    if not is_open() then
        return
    end

    local width = render()
    vim.api.nvim_win_set_config(state.window, place(width))
end

local function region_at(pos)
    if pos.winid ~= state.window or pos.line ~= 1 or pos.column == 0 then
        return nil
    end

    -- getmousepos() columns are 1-based bytes; regions are 0-based.
    local byte = pos.column - 1
    for _, region in ipairs(state.regions) do
        if byte >= region.start and byte < region.finish then
            return region
        end
    end

    -- Past the last button but still inside the float.
    return {}
end

local function on_press(key)
    local pos = vim.fn.getmousepos()
    local region = is_open() and region_at(pos)

    if not region then
        state.pressed = false
        return require("quiddam.breakpoint_click").press(key)
    end

    state.pressed = true
    local button = region.button

    if button and button.id == "grip" then
        local window_pos = vim.api.nvim_win_get_position(state.window)
        state.drag = {
            row = pos.screenrow - 1 - window_pos[1],
            col = pos.screencol - 1 - window_pos[2],
        }
    elseif button and button.action then
        -- Expr mappings run under textlock, and dap may open windows.
        vim.schedule(function()
            if dap().session() then
                button.action()
            end
        end)
    end

    return ""
end

local function on_drag()
    if not state.drag then
        return "<LeftDrag>"
    end

    local pos = vim.fn.getmousepos()
    state.row = pos.screenrow - 1 - state.drag.row
    state.col = pos.screencol - 1 - state.drag.col
    vim.schedule(refresh)

    return ""
end

local function on_release()
    local swallow = state.pressed or state.drag ~= nil
    state.pressed = false
    state.drag = nil

    return swallow and "" or "<LeftRelease>"
end

local function map_mouse()
    for _, key in ipairs(mouse_keys) do
        local handler
        if key == "<LeftDrag>" then
            handler = on_drag
        elseif key == "<LeftRelease>" then
            handler = on_release
        else
            handler = function()
                return on_press(key)
            end
        end

        vim.keymap.set(mouse_modes, key, handler, {
            expr = true,
            replace_keycodes = true,
            desc = "Debug toolbar mouse handler",
        })
    end
end

local function unmap_mouse()
    for _, key in ipairs(mouse_keys) do
        for _, mode in ipairs(mouse_modes) do
            pcall(vim.keymap.del, mode, key)
        end
    end

    -- The toolbar's mappings shadowed the gutter double-click; bring it back.
    require("quiddam.breakpoint_click").setup()
end

function M.open()
    if is_open() then
        refresh()
        return
    end

    state.buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buffer].bufhidden = "wipe"

    local width = render()
    local win_config = place(width)
    win_config.style = "minimal"
    win_config.border = "rounded"
    win_config.focusable = false
    win_config.mouse = true
    win_config.zindex = 60
    win_config.noautocmd = true

    state.window = vim.api.nvim_open_win(state.buffer, false, win_config)
    vim.wo[state.window].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"

    map_mouse()
end

function M.close()
    if is_open() then
        vim.api.nvim_win_close(state.window, true)
    end

    state.window = nil
    state.buffer = nil
    state.drag = nil
    state.pressed = false
    unmap_mouse()
end

function M.toggle()
    if is_open() then
        M.close()
    else
        M.open()
    end
end

local function set_highlights()
    for group, target in pairs(highlight_links) do
        vim.api.nvim_set_hl(0, group, { link = target, default = true })
    end
end

function M.setup(opts)
    config = vim.tbl_extend("force", config, opts or {})

    set_highlights()

    local group = vim.api.nvim_create_augroup("quiddam_debug_toolbar", { clear = true })

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = set_highlights,
    })

    vim.api.nvim_create_autocmd("VimResized", {
        group = group,
        callback = refresh,
    })

    local listeners = dap().listeners
    local key = "quiddam_debug_toolbar"

    listeners.after.event_initialized[key] = function()
        vim.schedule(M.open)
    end

    for _, event in ipairs({ "event_terminated", "event_exited", "disconnect" }) do
        listeners.before[event][key] = function()
            vim.schedule(M.close)
        end
    end

    -- Swap continue and pause as the session stops and resumes.
    for _, event in ipairs({ "event_stopped", "event_continued" }) do
        listeners.after[event][key] = function()
            vim.schedule(refresh)
        end
    end

    for _, request in ipairs({ "continue", "next", "stepIn", "stepOut", "pause" }) do
        listeners.after[request][key] = function()
            vim.schedule(refresh)
        end
    end

    vim.api.nvim_create_user_command("DebugToolbar", M.toggle, {
        desc = "Toggle the clickable debug toolbar",
    })
end

return M
