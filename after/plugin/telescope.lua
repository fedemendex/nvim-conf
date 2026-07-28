local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>o', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>git', builtin.git_files, { desc = 'Telescope find git files files' })
vim.keymap.set('n', '<leader>g', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)
