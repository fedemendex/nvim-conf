-- Run tests in a reusable terminal split.
vim.g["test#strategy"] = "neovim_sticky"

vim.keymap.set("n", "<leader>tn", "<cmd>TestNearest<CR>", {
	silent = true,
	desc = "Run nearest test",
})

vim.keymap.set("n", "<leader>t", "<cmd>TestFile<CR>", {
	silent = true,
	desc = "Run current test file",
})

vim.keymap.set("n", "<leader>ta", "<cmd>TestSuite<CR>", {
	silent = true,
	desc = "Run entire test suite",
})

vim.keymap.set("n", "<leader>tt", "<cmd>TestLast<CR>", {
	silent = true,
	desc = "Run last test again",
})
