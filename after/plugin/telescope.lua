local builtin = require("telescope.builtin")
local windows = require("quiddam.windows")

-- Open a file by name ---------------------------------------------------------

-- Both editors fuzzy-match a name against the files in the project, each with
-- its own picker: VS Code opens Quick Open, the list Cmd+P puts up, and
-- standalone Neovim opens the Telescope file picker. Telescope draws into a
-- Neovim float, which vscode-neovim has nowhere to render, so under VS Code
-- the editor does the work.
--
-- quickOpen is the command Cmd+P has always run. Newer VS Code builds may bind
-- Cmd+P to workbench.action.quickOpenWithModes instead, which opens the same
-- file list with the search and chat modes attached; swap it in if those modes
-- are wanted.
if vim.g.vscode then
    vim.keymap.set("n", "<leader>o", function()
        local ok, vscode = pcall(require, "vscode")

        if not ok then
            vim.notify(
                "vim.g.vscode is set but the vscode module is unavailable",
                vim.log.levels.ERROR
            )

            return
        end

        vscode.action("workbench.action.quickOpen")
    end, {
        silent = true,
        desc = "Open file by name",
    })
else
    vim.keymap.set("n", "<leader>o", function()
        windows.focus_editor()
        builtin.find_files()
    end, {
        desc = "Open file by name",
    })
end

vim.keymap.set("n", "<leader>git", function()
    windows.focus_editor()
    builtin.git_files()
end, {
    desc = "Telescope find Git files",
})

-- Search across the project ----------------------------------------------------

-- Both editors search every file for a string, each with its own machinery:
-- VS Code opens the Search view, the panel Cmd+Shift+F puts up, and standalone
-- Neovim prompts for the string and lists the hits in Telescope.
--
-- findInFiles is called without arguments so the view behaves exactly as
-- Cmd+Shift+F does: it keeps the previous query and seeds from the selection
-- per VS Code's own search settings. Pass args.query to seed it from Neovim
-- instead, the way <leader>r seeds the replace widget.
if vim.g.vscode then
    vim.keymap.set("n", "<leader>g", function()
        local ok, vscode = pcall(require, "vscode")

        if not ok then
            vim.notify(
                "vim.g.vscode is set but the vscode module is unavailable",
                vim.log.levels.ERROR
            )

            return
        end

        vscode.action("workbench.action.findInFiles")
    end, {
        silent = true,
        desc = "Search across the project",
    })
else
    vim.keymap.set("n", "<leader>g", function()
        windows.focus_editor()

        builtin.grep_string({
            search = vim.fn.input("Grep > "),
        })
    end, {
        desc = "Search across the project",
    })
end
