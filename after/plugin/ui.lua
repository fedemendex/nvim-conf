local function on_attach(bufnr)
    local api = require("nvim-tree.api")

    -- Preserve nvim-tree's standard mappings
    api.map.on_attach.default(bufnr)

    vim.keymap.set("n", "<leader>a", function()
        local node = api.tree.get_node_under_cursor()

        if node and node.type == "file" then
            require("harpoon.mark").add_file(node.absolute_path)
            vim.notify("Added to Harpoon: " .. node.name)
        else
            vim.notify("Select a file first")
        end
    end, {
        buffer = bufnr,
        silent = true,
        desc = "Add selected file to Harpoon",
    })
end

require("nvim-tree").setup({
    on_attach = on_attach,

    view = {
        side = "left",
        width = 30,
    },

    renderer = {
        group_empty = true,
    },

    update_focused_file = {
        enable = true,
    },

    filters = {
        dotfiles = false,
    },
})

vim.keymap.set("n", "<leader>pv", "<cmd>NvimTreeToggle<CR>", {
    silent = true,
    desc = "Toggle file tree",
})

require("toggleterm").setup({
    size = function(term)
        if term.direction == "horizontal" then
            return math.max(10, math.floor(vim.o.lines * 0.25))
        end

        return 80
    end,

    direction = "horizontal",
    persist_size = false,
    start_in_insert = true,
    close_on_exit = true,
    shade_terminals = false,
})

vim.keymap.set("n", "<leader>ter", "<cmd>ToggleTerm<CR>", {
    silent = true,
    desc = "Toggle terminal",
})

vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "term://*toggleterm#*",
    callback = function(event)
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {
            buffer = event.buf,
            silent = true,
            desc = "Leave terminal input mode",
        })
    end,
})
