-- undotree draws its tree and diff in Neovim windows, which vscode-neovim has
-- nowhere to render, so the plugin is left alone under VS Code and the key
-- goes to the Timeline view instead.
--
-- Local History is what the Timeline holds for an ordinary file: a snapshot
-- taken at each save, which can be diffed against the current contents or
-- restored over them. That is undotree's job -- getting back to an earlier
-- state of this file -- so the same key does it in both editors. The two are
-- not equivalent, and the difference is worth knowing: undotree walks Neovim's
-- own undo history, so it reaches states that were never written to disk,
-- while Local History only has the saves.
--
-- VS Code registers "<view id>.focus" for every view, so timeline.focus both
-- reveals the Timeline and puts the cursor in it.
if vim.g.vscode then
    vim.keymap.set("n", "<leader>u", function()
        local ok, vscode = pcall(require, "vscode")

        if not ok then
            vim.notify(
                "vim.g.vscode is set but the vscode module is unavailable",
                vim.log.levels.ERROR
            )

            return
        end

        vscode.action("timeline.focus")
    end, {
        silent = true,
        desc = "Show file history",
    })

    return
end

vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, {
    desc = "Toggle the undo tree",
})
