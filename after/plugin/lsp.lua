-- language aware format
vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format({ async = true })
end)

-- formar whenever you save
--
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function(args)
        vim.lsp.buf.format({
            bufnr = args.buf,
            timeout_ms = 3000,
        })
    end,
})

local cmp = require("cmp")
local luasnip = require("luasnip")

-- Autocompletion
cmp.setup({
    completion = {
        completeopt = "menu,menuone,noinsert",
    },

    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },

    mapping = cmp.mapping.preset.insert({
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { "i", "s" }),

        ["<CR>"] = cmp.mapping.confirm({
            select = false,
        }),
    }),

    sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "path" },
    }, {
        {
            name = "buffer",
            keyword_length = 3,
        },
    }),
})

-- Advertise nvim-cmp's completion features to every LSP server.
vim.lsp.config("*", {
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
})

-- Some useful Go defaults.
vim.lsp.config("gopls", {
    settings = {
        gopls = {
            gofumpt = true,
            staticcheck = true,
            usePlaceholders = true,
        },
    },
})

-- Some useful Rust defaults.
vim.lsp.config("rust_analyzer", {
    settings = {
        ["rust-analyzer"] = {
            cargo = {
                allFeatures = true,
            },
            check = {
                command = "clippy",
            },
        },
    },
})

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },
            diagnostics = {
                globals = { "vim" },
            },
            workspace = {
                checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
                enable = false,
            },
        },
    },
})

-- Install and automatically enable these language servers.
require("mason").setup()

require("mason-lspconfig").setup({
    ensure_installed = {
        "gopls",
        "ts_ls",
        "rust_analyzer",
        "lua_ls", -- useful for editing your Neovim config
        "pyright",
    },
    automatic_enable = true,
})

-- Buffer-local mappings, created only when an LSP attaches.
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
        local opts = { buffer = event.buf }
        local telescope = require("telescope.builtin")

        -- Navigation
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "gr", telescope.lsp_references, opts)

        -- Information and project search
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>ds", telescope.lsp_document_symbols, opts)
        vim.keymap.set("n", "<leader>ws", telescope.lsp_dynamic_workspace_symbols, opts)

        -- Refactoring
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

        -- Formatting
        vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
        end, opts)

        -- Diagnostics
        vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "[d", function()
            vim.diagnostic.jump({ count = -1 })
        end, opts)
        vim.keymap.set("n", "]d", function()
            vim.diagnostic.jump({ count = 1 })
        end, opts)
    end,
})

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
    },
})
