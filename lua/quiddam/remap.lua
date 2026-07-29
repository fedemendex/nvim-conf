-- space is now the leader key
vim.g.mapleader = " "

vim.opt.mouse = "a"

-- quit
vim.keymap.set("n", "<leader>qq", "<cmd>qa<CR>", {
    silent = true,
    desc = "Quit Neovim",
})

vim.keymap.set(
    "n",
    "<leader><LeftMouse>",
    "<LeftMouse><cmd>lua vim.lsp.buf.definition()<CR>",
    {
        silent = true,
        desc = "Go to definition",
    }
)

-- highlight and move
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")


vim.keymap.set("n", "Y", "yg$")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<leader>vwm", function()
    require("vim-with-me").StartVimWithMe()
end)

vim.keymap.set("n", "<leader>svwm", function()
    require("vim-with-me").StopVimWithMe()
end)

-- Greatest remap ever (highlight and copy then paste on top of other highlighted stuff)
vim.keymap.set("x", "<leader>p", [["_dP]])

-- allow yanking into clipboard
vim.opt.clipboard = "unnamedplus"

-- Copy to the system clipboard
vim.keymap.set("n", "<leader>y", [["+y]])
vim.keymap.set("v", "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Multi line select
vim.keymap.set("n", "<leader>b", "<C-v>", {
    desc = "Visual block mode",
})


-- Delete without replacing the current register
vim.keymap.set("n", "<leader>d", [["_d]])
vim.keymap.set("v", "<leader>d", [["_d]])

vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")

vim.keymap.set(
    "n",
    "<C-f>",
    "<cmd>silent !tmux neww tmux-sessionizer<CR>"
)

vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format()
end)

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")

vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")


-- Replace word under cursor throughout the entire file
vim.keymap.set(
    "n",
    "<leader>r",
    [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]
)

-- Replace word under cursor only inside the visual selection
vim.keymap.set(
    "x",
    "<leader>r",
    [[:s/\%V\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]
)

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set(
    "n",
    "<leader>ee",
    "oif err != nil {<CR>}<Esc>Oreturn err<Esc>"
)

vim.keymap.set(
    "n",
    "<leader>ea",
    "oassert.NoError(err, \"\")<Esc>F\";a"
)

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

local window_mappings = {
    ["<C-h>"] = "h",
    ["<C-j>"] = "j",
    ["<C-k>"] = "k",
    ["<C-l>"] = "l",

    ["<C-Left>"] = "h",
    ["<C-Down>"] = "j",
    ["<C-Up>"] = "k",
    ["<C-Right>"] = "l",
}

for key, direction in pairs(window_mappings) do
    -- Normal mode
    vim.keymap.set(
        "n",
        key,
        "<C-w>" .. direction,
        {
            silent = true,
            desc = "Move to " .. direction .. " window",
        }
    )

    -- Terminal-input mode
    vim.keymap.set(
        "t",
        key,
        "<C-\\><C-n><C-w>" .. direction,
        {
            silent = true,
            desc = "Move to " .. direction .. " window",
        }
    )
end
