vim.keymap.set("n", "<leader>gs", function()
    if vim.g.vscode then
        local ok, vscode = pcall(require, "vscode")

        if ok then
            vscode.action("workbench.view.scm")
        end

        return
    end

    vim.cmd.Git()
end, {
    silent = true,
    desc = "Open Git status",
})
