require("nvim-tree").setup({
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
