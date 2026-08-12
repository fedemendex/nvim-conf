require("tokyonight").setup({
    style = "moon",

    -- Built-in inactive-window dimming.
    dim_inactive = true,

    on_highlights = function(hl, c)
        -- Harpoon uses Neovim's standard tabline groups.
        hl.TabLine = {
            fg = c.fg_dark,
            bg = c.bg_dark,
        }

        hl.TabLineSel = {
            fg = c.orange,
            bg = c.bg_highlight,
            bold = true,
        }

        hl.TabLineFill = {
            bg = c.bg_dark,
        }

        -- Make the current line substantially easier to find.
        hl.CursorLine = {
            bg = c.bg_highlight,
        }

        -- More obvious line number on the active line.
        hl.CursorLineNr = {
            fg = c.orange,
            bold = true,
        }

        -- Stronger visual selection.
        hl.Visual = {
            bg = c.bg_search,
        }

        -- Clearer divider between windows.
        hl.WinSeparator = {
            fg = c.blue,
            bold = true,
        }
    end,
})

vim.cmd.colorscheme("tokyonight-moon")

vim.opt.cursorline = true
