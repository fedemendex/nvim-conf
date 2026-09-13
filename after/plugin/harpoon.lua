-- Harpoon draws its menu in a Neovim float, which vscode-neovim has nowhere to
-- render, and every jump goes through harpoon.ui.nav_file -- which calls
-- vim.fn.bufadd(filename) and so leaves a plain Neovim buffer named after the
-- file. vscode-neovim then fails with "E95: Buffer with this name already
-- exists" the next time VS Code opens that document, surfacing as "Error
-- syncing layout". It clears such collisions only for buffers it created
-- itself, recognised by their vscode_uri variable, so a buffer harpoon made is
-- invisible to that cleanup and the error escapes.
--
-- VS Code has no numbered file slots of its own, so the closest thing takes
-- their place: the open editors in the current group, reachable by index.
-- Pinning is what keeps a file in reach the way a harpoon mark does -- pinned
-- tabs sort to the front of the group, so they hold the low indices that
-- <leader>1 and <leader>2 land on.
if vim.g.vscode then
    local function action(command)
        return function()
            local ok, vscode = pcall(require, "vscode")

            if not ok then
                vim.notify(
                    "vim.g.vscode is set but the vscode module is unavailable",
                    vim.log.levels.ERROR
                )

                return
            end

            vscode.action(command)
        end
    end

    vim.keymap.set("n", "<leader>a", action("workbench.action.pinEditor"), {
        silent = true,
        desc = "Pin current editor",
    })

    vim.keymap.set("n", "<leader>m", action("workbench.action.showAllEditors"), {
        silent = true,
        desc = "Show all open editors",
    })

    -- VS Code registers workbench.action.openEditorAtIndex1 through
    -- ...Index9, one command per slot, so each index gets its own mapping.
    for index = 1, 9 do
        vim.keymap.set(
            "n",
            "<leader>" .. index,
            action("workbench.action.openEditorAtIndex" .. index),
            {
                silent = true,
                desc = "Open editor " .. index,
            }
        )
    end

    return
end

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

-- <leader>h jumps to the start of the line, so the menu lives on m for
-- "marks".
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
