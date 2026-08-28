-- Treesitter-backed structural selection.
--
-- nvim-treesitter's `main` branch dropped its incremental-selection module and
-- provides no `an`/`in` text objects, so the expand/shrink behaviour is built
-- directly on vim.treesitter here.

local M = {}

-- Ranges previously selected in a buffer, so shrinking can retrace them.
local history = {}

local function is_visual()
    local mode = vim.fn.mode()

    return mode == "v" or mode == "V" or mode == "\22"
end

-- Treesitter ranges are 0-indexed with an exclusive end column.
local function visual_range()
    local anchor = vim.fn.getpos("v")
    local cursor = vim.fn.getpos(".")

    local srow, scol = anchor[2] - 1, anchor[3] - 1
    local erow, ecol = cursor[2] - 1, cursor[3] - 1

    if srow > erow or (srow == erow and scol > ecol) then
        srow, scol, erow, ecol = erow, ecol, srow, scol
    end

    return srow, scol, erow, ecol + 1
end

-- A node ending at column 0 really ends on the previous line. Two different
-- nodes can therefore describe the same visible selection, so ranges are
-- normalised before being compared or selected.
local function normalize(srow, scol, erow, ecol)
    if ecol == 0 and erow > srow then
        erow = erow - 1

        local line = vim.api.nvim_buf_get_lines(0, erow, erow + 1, false)[1]
        ecol = #(line or "")
    end

    return srow, scol, erow, ecol
end

local function select_range(range)
    local srow, scol, erow, ecol = normalize(unpack(range))

    if is_visual() then
        vim.cmd("normal! \27")
    end

    vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
    vim.cmd("normal! v")
    vim.api.nvim_win_set_cursor(0, { erow + 1, math.max(ecol - 1, 0) })
end

local function root_node()
    local buffer = vim.api.nvim_get_current_buf()
    local ok, parser = pcall(vim.treesitter.get_parser, buffer)

    if not ok or not parser then
        return nil
    end

    local tree = parser:parse()[1]

    return tree and tree:root() or nil
end

-- True when the node covers strictly more text than the given range, once its
-- range is normalised to what would actually be highlighted.
local function is_larger(node, srow, scol, erow, ecol)
    local nsrow, nscol, nerow, necol = normalize(node:range())

    if nsrow < srow or nerow > erow then
        return true
    end

    if nsrow == srow and nscol < scol then
        return true
    end

    return nerow == erow and necol > ecol
end

function M.expand()
    local root = root_node()

    if not root then
        vim.notify(
            "No Treesitter parser for this buffer",
            vim.log.levels.WARN
        )
        return
    end

    local buffer = vim.api.nvim_get_current_buf()
    local srow, scol, erow, ecol

    if is_visual() then
        srow, scol, erow, ecol = visual_range()
    else
        -- Starting fresh, so any earlier selections are irrelevant.
        history[buffer] = {}

        local cursor = vim.api.nvim_win_get_cursor(0)
        srow, scol = cursor[1] - 1, cursor[2]
        erow, ecol = srow, scol + 1
    end

    local node = root:named_descendant_for_range(srow, scol, erow, ecol)

    -- Climb until the node adds something to the current selection.
    while node and not is_larger(node, srow, scol, erow, ecol) do
        node = node:parent()
    end

    if not node then
        vim.notify("Already at the outermost node", vim.log.levels.INFO)
        return
    end

    history[buffer] = history[buffer] or {}
    table.insert(history[buffer], { srow, scol, erow, ecol })

    select_range({ node:range() })
end

function M.shrink()
    local buffer = vim.api.nvim_get_current_buf()
    local previous = history[buffer] and table.remove(history[buffer])

    if not previous then
        vim.notify("Nothing left to shrink to", vim.log.levels.INFO)
        return
    end

    select_range(previous)
end

vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(event)
        history[event.buf] = nil
    end,
})

return M
