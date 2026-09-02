-- Loaded first: it records the startup arguments before anything can alter
-- them. See lua/quiddam/session.lua.
require("quiddam.session")

require("quiddam.remap")
require("quiddam.packer")
require("quiddam.set")

local highlight_yank = vim.api.nvim_create_augroup(
    "highlight-yank",
    { clear = true }
)

vim.api.nvim_create_autocmd("TextYankPost", {
    group = highlight_yank,
    desc = "Briefly highlight yanked text",
    callback = function()
        if vim.v.event.operator == "y" then
            local on_yank = vim.hl and vim.hl.on_yank
                or vim.highlight.on_yank

            on_yank({
                higroup = "Visual",
                timeout = 250,
            })
        end
    end,
})
