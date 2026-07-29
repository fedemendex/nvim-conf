require("lualine").setup({
    options = {
        icons_enabled = true,
        theme = "auto",
        component_separators = {
            left = "",
            right = "",
        },
        section_separators = {
            left = "",
            right = "",
        },
        globalstatus = false,
    },

    sections = {
        lualine_a = {
            "mode",
        },

        lualine_b = {
            "branch",
            "diff",
            "diagnostics",
        },

        lualine_c = {
            {
                "filename",
                path = 1,
            },
        },

        lualine_x = {
            "lsp_status",
            "encoding",
            "filetype",
        },

        lualine_y = {
            "progress",
        },

        lualine_z = {
            "location",
        },
    },

    extensions = {
        "nvim-tree",
        "toggleterm",
        "fugitive",
        "quickfix",
    },
})
