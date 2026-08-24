require("quiddam")

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("luasnip.loaders.from_lua").lazy_load({
    paths = vim.fn.stdpath("config") .. "/lua/quiddam/snippets",
})
