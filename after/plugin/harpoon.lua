require("harpoon").setup({
    global_settings = {
        tabline = true,
        tabline_prefix = " ",
        tabline_suffix = "  ",
    },
})

-- Required because Harpoon's global tabline setting wasn't activating it.
require("harpoon.tabline").setup({
    tabline_prefix = " ",
    tabline_suffix = "  ",
})

local mark = require("harpoon.mark")
local ui = require("harpoon.ui")
local windows = require("quiddam.windows")

vim.keymap.set("n", "<leader>a", mark.add_file, {
    desc = "Add current file to Harpoon",
})

-- <leader>h moves between splits, so the menu lives on m for "marks".
vim.keymap.set("n", "<leader>m", ui.toggle_quick_menu, {
    desc = "Toggle Harpoon menu",
})

for index = 1, 9 do
    vim.keymap.set("n", "<leader>" .. index, function()
        windows.focus_editor()
        ui.nav_file(index)
    end, {
        desc = "Open Harpoon file " .. index,
    })
end
