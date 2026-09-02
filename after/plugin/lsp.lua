-- Everything below is language-server, completion, and diagnostic setup, all of
-- which VS Code supplies itself. vscode-neovim sets vim.g.vscode, so under it
-- this file is skipped entirely.
if vim.g.vscode then
    return
end

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
            elseif luasnip.expand_or_locally_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
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
        local telescope = require("telescope.builtin")

        local function map(mode, keys, action, description)
            vim.keymap.set(mode, keys, action, {
                buffer = event.buf,
                silent = true,
                desc = description,
            })
        end

        -- Navigation
        map("n", "gd", vim.lsp.buf.definition, "LSP: Go to definition")
        map("n", "gD", vim.lsp.buf.declaration, "LSP: Go to declaration")
        map("n", "gi", vim.lsp.buf.implementation, "LSP: Go to implementation")
        map("n", "gr", telescope.lsp_references, "LSP: Find references")

        -- Information and project search
        map("n", "K", vim.lsp.buf.hover, "LSP: Show documentation")
        map(
            "n",
            "<leader>ds",
            telescope.lsp_document_symbols,
            "LSP: Find document symbols"
        )
        map(
            "n",
            "<leader>ws",
            telescope.lsp_dynamic_workspace_symbols,
            "LSP: Find workspace symbols"
        )

        -- Refactoring
        map(
            "n",
            "<leader>rn",
            vim.lsp.buf.rename,
            "LSP: Rename symbol"
        )

        map(
            { "n", "x" },
            "<leader>ca",
            vim.lsp.buf.code_action,
            "LSP: Show code actions"
        )

        map("n", "<leader>qf", function()
            vim.lsp.buf.code_action({
                context = {
                    only = { "quickfix" },
                },
                apply = true,
            })
        end, "LSP: Apply quick fix")

        map("n", "<leader>oi", function()
            vim.lsp.buf.code_action({
                context = {
                    only = { "source.organizeImports" },
                },
                apply = true,
            })
        end, "LSP: Organize imports")

        -- Formatting
        map("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
        end, "LSP: Format current file")

        -- Diagnostics
        map(
            "n",
            "<leader>d",
            vim.diagnostic.open_float,
            "LSP: Show diagnostic"
        )

        map("n", "[d", function()
            vim.diagnostic.jump({ count = -1 })
        end, "LSP: Previous diagnostic")

        map("n", "]d", function()
            vim.diagnostic.jump({ count = 1 })
        end, "LSP: Next diagnostic")
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
