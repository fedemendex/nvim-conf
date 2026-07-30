-- Space is the leader key.
vim.g.mapleader = " "

vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

vim.keymap.set("n", "<leader>?", "<cmd>Telescope keymaps<CR>", {
    desc = "Search all keyboard mappings",
})

vim.keymap.set("n", "<C-a>", "ggVG", {
    desc = "Select entire file",
})

-- Easy select ---------------------------------------------------------------

vim.keymap.set("n", "<leader>w", "viw", {
    desc = "Select word under cursor",
})

vim.keymap.set("n", "<leader>W", "viW", {
    desc = "Select WORD under cursor",
})

-- Quit -----------------------------------------------------------------------

vim.keymap.set("n", "<leader>qq", function()
    -- Save ordinary modified file buffers first. If saving fails, this throws
    -- and quitting stops, so changes are not silently discarded.
    vim.cmd("wa")

    -- Terminate every ToggleTerm shell, including hidden terminals.
    local terminal = require("toggleterm.terminal")

    for _, term in ipairs(terminal.get_all(true)) do
        term:shutdown()
    end

    vim.cmd("qa")
end, {
    silent = true,
    desc = "Save all, close terminals, and quit Neovim",
})

-- LSP ------------------------------------------------------------------------

vim.keymap.set(
    "n",
    "<leader><LeftMouse>",
    "<LeftMouse><cmd>lua vim.lsp.buf.definition()<CR>",
    {
        silent = true,
        desc = "Go to definition under mouse",
    }
)

vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format()
end, {
    desc = "Format current file",
})

-- Visual-mode editing --------------------------------------------------------

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", {
    silent = true,
    desc = "Move selected lines down",
})

vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", {
    silent = true,
    desc = "Move selected lines up",
})

vim.keymap.set("n", "<leader>b", "<C-v>", {
    desc = "Enter visual block mode",
})

-- Paste over a selection without replacing the copied text.
vim.keymap.set("x", "<leader>p", [["_dP]], {
    desc = "Paste without replacing clipboard",
})

-- Normal-mode improvements ---------------------------------------------------

vim.keymap.set("n", "Y", "yg$", {
    desc = "Yank from cursor to end of line",
})

vim.keymap.set("n", "J", "mzJ`z", {
    desc = "Join lines and preserve cursor position",
})

vim.keymap.set("n", "<C-d>", "<C-d>zz", {
    desc = "Scroll half-page down and centre cursor",
})

vim.keymap.set("n", "<C-u>", "<C-u>zz", {
    desc = "Scroll half-page up and centre cursor",
})

vim.keymap.set("n", "n", "nzzzv", {
    desc = "Next search result and centre cursor",
})

vim.keymap.set("n", "N", "Nzzzv", {
    desc = "Previous search result and centre cursor",
})

vim.keymap.set("i", "<C-c>", "<Esc>", {
    desc = "Leave insert mode",
})

vim.keymap.set("n", "Q", "<nop>", {
    desc = "Disable Ex mode",
})

-- Clipboard ------------------------------------------------------------------

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], {
    desc = "Copy to system clipboard",
})

vim.keymap.set("n", "<leader>Y", [["+Y]], {
    desc = "Copy line to system clipboard",
})

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], {
    desc = "Delete without replacing clipboard",
})

-- Search and replace ---------------------------------------------------------

vim.keymap.set(
    "n",
    "<leader>r",
    [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    {
        desc = "Replace word under cursor in file",
    }
)

vim.keymap.set(
    "x",
    "<leader>r",
    [[:s/\%V\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    {
        desc = "Replace word inside selection",
    }
)

-- Quickfix and location lists ------------------------------------------------

vim.keymap.set("n", "<leader>cn", "<cmd>cnext<CR>zz", {
    silent = true,
    desc = "Next quickfix result",
})

vim.keymap.set("n", "<leader>cp", "<cmd>cprev<CR>zz", {
    silent = true,
    desc = "Previous quickfix result",
})

vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", {
    silent = true,
    desc = "Next location-list result",
})

vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", {
    silent = true,
    desc = "Previous location-list result",
})

-- Go helpers -----------------------------------------------------------------

vim.keymap.set(
    "n",
    "<leader>ee",
    "oif err != nil {<CR>}<Esc>Oreturn err<Esc>",
    {
        desc = "Insert Go return-error block",
    }
)

vim.keymap.set(
    "n",
    "<leader>ea",
    "oassert.NoError(err, \"\")<Esc>F\";a",
    {
        desc = "Insert Go NoError assertion",
    }
)

-- External tools -------------------------------------------------------------

vim.keymap.set(
    "n",
    "<C-f>",
    "<cmd>silent !tmux neww tmux-sessionizer<CR>",
    {
        silent = true,
        desc = "Open tmux sessionizer",
    }
)

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", {
    silent = true,
    desc = "Make current file executable",
})

vim.keymap.set("n", "<leader>vwm", function()
    require("vim-with-me").StartVimWithMe()
end, {
    desc = "Start Vim With Me",
})

vim.keymap.set("n", "<leader>svwm", function()
    require("vim-with-me").StopVimWithMe()
end, {
    desc = "Stop Vim With Me",
})

-- Reload configuration -------------------------------------------------------

vim.keymap.set("n", "<leader><leader>", function()
    if vim.bo.filetype ~= "lua" or not vim.bo.modifiable then
        vim.notify(
            "This mapping only reloads editable Lua files",
            vim.log.levels.WARN
        )
        return
    end

    vim.cmd.source(vim.api.nvim_buf_get_name(0))
end, {
    desc = "Reload current Lua file",
})


-- Haram vim remaps (visual select)
vim.keymap.set("n", "<S-Up>", "van", {
    remap = true,
    desc = "Start structural selection",
})

vim.keymap.set("x", "<S-Up>", "an", {
    remap = true,
    desc = "Expand structural selection",
})

vim.keymap.set("x", "<S-Down>", "in", {
    remap = true,
    desc = "Shrink structural selection",
})
