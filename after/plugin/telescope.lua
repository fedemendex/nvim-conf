local builtin = require("telescope.builtin")
local windows = require("quiddam.windows")

vim.keymap.set("n", "<leader>o", function()
    windows.focus_editor()
    builtin.find_files()
end, {
    desc = "Telescope find files",
})

vim.keymap.set("n", "<leader>git", function()
    windows.focus_editor()
    builtin.git_files()
end, {
    desc = "Telescope find Git files",
})

vim.keymap.set("n", "<leader>g", function()
    windows.focus_editor()

    builtin.grep_string({
        search = vim.fn.input("Grep > "),
    })
end)
