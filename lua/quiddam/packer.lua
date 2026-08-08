-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require("packer").startup(function(use)
    use "wbthomason/packer.nvim"
    use {
        "nvim-telescope/telescope.nvim",
        branch = "master",
        requires = {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                run = "make",
            },
        },
    }

    use {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup({})

            -- Integrate with nvim-cmp
            local cmp = require("cmp")
            local cmp_autopairs =
                require("nvim-autopairs.completion.cmp")

            cmp.event:on(
                "confirm_done",
                cmp_autopairs.on_confirm_done()
            )
        end,
    }

    use {
        "rose-pine/neovim",
        as = "rose-pine",
        config = function()
            require("rose-pine").setup()
            vim.cmd("colorscheme rose-pine-dawn")
        end,
    }

    use {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
    }

    use {
        "ThePrimeagen/harpoon",
        branch = "master",
        requires = {
            "nvim-lua/plenary.nvim",
        },
    }

    use 'mbbill/undotree'
    use 'tpope/vim-fugitive'
    use "lewis6991/gitsigns.nvim"
    use "christoomey/vim-tmux-navigator"

    use {
        "nvim-lualine/lualine.nvim",
        requires = {
            "nvim-tree/nvim-web-devicons",
        },
    }

    -- Install and configure language servers
    use { "mason-org/mason-lspconfig.nvim",
        requires = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig",
        },
    }

    -- Autocompletion
    use {
        "hrsh7th/nvim-cmp",
        requires = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
    }

    use "vim-test/vim-test"

    use {
        "nvim-tree/nvim-tree.lua",
        requires = {
            "nvim-tree/nvim-web-devicons",
        },
    }

    use {
        "akinsho/toggleterm.nvim",
        tag = "*",
    }

    -- debugging plugins
    --

    use("mfussenegger/nvim-dap")

    use({
        "rcarriga/nvim-dap-ui",
        requires = {
            "mfussenegger/nvim-dap",
            "nvim-neotest/nvim-nio",
        },
    })

    use("leoluz/nvim-dap-go")
    use("mfussenegger/nvim-dap-python")

    use({
        "jay-babu/mason-nvim-dap.nvim",
        requires = {
            "williamboman/mason.nvim",
            "mfussenegger/nvim-dap",
        },
    })

    use({
        "mxsdev/nvim-dap-vscode-js",
        requires = {
            "mfussenegger/nvim-dap",
        },
    })

    use({
        "theHamsta/nvim-dap-virtual-text",
        requires = {
            "mfussenegger/nvim-dap",
            "nvim-treesitter/nvim-treesitter",
        },
    })
    -- Multi cursor stuff
    --
    use {
        "jake-stewart/multicursor.nvim",
        branch = "1.0",
        config = function()
            local mc = require("multicursor-nvim")
            mc.setup()

            vim.keymap.set({ "n", "x" }, "<M-Up>", function()
                mc.lineAddCursor(-1)
            end)

            vim.keymap.set({ "n", "x" }, "<M-Down>", function()
                mc.lineAddCursor(1)
            end)

            mc.addKeymapLayer(function(map)
                map("n", "<Esc>", mc.clearCursors)
            end)
        end,
    }
end)
