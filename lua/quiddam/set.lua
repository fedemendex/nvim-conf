vim.opt.guicursor = ""

-- make horizontal split open below
vim.opt.hidden = true
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

vim.g.mapleader = " "

-- Sessions restore the window layout only. Terminals and blank windows are
-- deliberately excluded so a restored layout matches what was being edited.
vim.opt.sessionoptions = {
    "buffers",
    "curdir",
    "folds",
    "help",
    "tabpages",
    "winsize",
    "winpos",
}

-- Highlight the entire line containing the cursor
vim.opt.cursorline = true
vim.opt.cursorcolumn = true

vim.api.nvim_set_hl(0, "CursorLine", {
    bg = "#302d49",
})
