local which_key = require("which-key")

which_key.setup({
    preset = "modern",
    delay = 300,
})

which_key.add({
    { "<leader>t", group = "Tests / terminal" },
    { "<leader>p", group = "Files / paste" },
    { "<leader>q", group = "Quit" },
})
