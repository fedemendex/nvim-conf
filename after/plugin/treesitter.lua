require("nvim-treesitter").setup()

require("nvim-treesitter").install({
	"lua",
	"vim",
	"vimdoc",

	"go",
	"gomod",
	"gosum",
	"gowork",

	"rust",

	"javascript",
	"typescript",
	"tsx",

	"json",
	"html",
	"css",
	"yaml",
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"lua",
		"vim",
		"vimdoc",
		"go",
		"gomod",
		"gowork",
		"rust",
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"json",
		"html",
		"css",
		"yaml",
	},
	callback = function()
		vim.treesitter.start()
	end,
})
