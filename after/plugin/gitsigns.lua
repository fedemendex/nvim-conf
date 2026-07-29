local git_signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
    untracked = { text = "?" },
}

require("gitsigns").setup({
    signs = git_signs,
    signs_staged = git_signs,
    attach_to_untracked = true,


    on_attach = function(buffer)
        local gitsigns = require("gitsigns")

        local function map(mode, key, action, description)
            vim.keymap.set(mode, key, action, {
                buffer = buffer,
                silent = true,
                desc = description,
            })
        end

        -- Navigate changed sections.
        map("n", "]h", function()
            gitsigns.nav_hunk("next")
        end, "Next Git hunk")

        map("n", "[h", function()
            gitsigns.nav_hunk("prev")
        end, "Previous Git hunk")

        -- Inspect changes.
        map("n", "<leader>ghp", gitsigns.preview_hunk, "Preview Git hunk")

        map("n", "<leader>ghb", function()
            gitsigns.blame_line({ full = true })
        end, "Show Git blame for line")

        map("n", "<leader>ghd", gitsigns.diffthis, "Diff current file")

        -- Stage or discard individual changes.
        map("n", "<leader>ghs", gitsigns.stage_hunk, "Stage Git hunk")
        map("n", "<leader>ghr", gitsigns.reset_hunk, "Discard Git hunk")

        map("v", "<leader>ghs", function()
            gitsigns.stage_hunk({
                vim.fn.line("."),
                vim.fn.line("v"),
            })
        end, "Stage selected Git lines")

        map("v", "<leader>ghr", function()
            gitsigns.reset_hunk({
                vim.fn.line("."),
                vim.fn.line("v"),
            })
        end, "Discard selected Git lines")
    end,
})
