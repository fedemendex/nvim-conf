require("quiddam")

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("luasnip.loaders.from_lua").lazy_load({
    paths = vim.fn.stdpath("config") .. "/lua/quiddam/snippets",
})


vim.api.nvim_set_hl(0, "YankHighlight", {
    bg = "#7aa2f7",
    fg = "#1a1b26",
})

local highlight_yank = vim.api.nvim_create_augroup(
    "highlight-yank",
    { clear = true }
)

vim.api.nvim_create_autocmd("TextYankPost", {
    group = highlight_yank,
    callback = function()
        if vim.v.event.operator ~= "y" then
            return
        end

        local on_yank = vim.hl and vim.hl.on_yank
            or vim.highlight.on_yank

        on_yank({
            higroup = "YankHighlight",
            timeout = 100,
        })
    end,
})
