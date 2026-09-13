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

-- Fixing and formatting on save ----------------------------------------------

-- Writing a file applies the fixes <leader>oi and <leader>qf apply by hand,
-- then formats. The case this is for: a new Go test file that calls
-- assert.Equal and t.Run before anything imports testify or testing. Those are
-- errors until the imports exist, and typing them out is work the language
-- server can do.
--
-- Both kinds are applied, in this order, because they answer different halves
-- of that. source.organizeImports is what actually adds a missing import --
-- gopls runs goimports for it, which resolves the package and writes the
-- import block. quickfix is the per-diagnostic kind <leader>qf uses, and it
-- covers what is left once the imports are in. Imports go first: adding lines
-- at the top of the file moves every range underneath, so a quickfix computed
-- beforehand would be computed against the wrong line.
local save_action_kinds = {
    "source.organizeImports",
    "quickfix",
}

local save_action_timeout = 3000

-- Set vim.b.disable_save_actions to keep a single buffer from being rewritten
-- on save. Formatting still happens; only the code actions are skipped.
local function save_actions_enabled(buffer)
    if vim.b[buffer].disable_save_actions then
        return false
    end

    return not vim.g.disable_save_actions
end

-- The end of the buffer, in the units the client counts characters in. The
-- range covers the whole file rather than the cursor, because a save is about
-- the file: an import missing forty lines down is the point of the exercise.
local function buffer_end(buffer, encoding)
    local line = math.max(0, vim.api.nvim_buf_line_count(buffer) - 1)
    local text = vim.api.nvim_buf_get_lines(buffer, line, line + 1, false)[1]
        or ""

    local character = #text

    if encoding == "utf-16" or encoding == "utf-32" then
        local ok, count = pcall(vim.str_utfindex, text, encoding)

        if ok then
            character = count
        end
    end

    return { line = line, character = character }
end

-- Servers decide which quickfixes apply by looking at the diagnostics handed
-- to them, so the buffer's own diagnostics are converted back into the shape
-- they arrived in.
local function lsp_diagnostics(buffer)
    local ok, converted = pcall(
        vim.lsp.diagnostic.from,
        vim.diagnostic.get(buffer)
    )

    return ok and converted or {}
end

-- A code action may arrive as an edit, as a command for the server to run, or
-- as neither -- a title and nothing else, to be filled in on request. The
-- third is why this resolves before deciding an action is empty.
local function apply_action(client, buffer, action)
    if not action.edit and not action.command then
        if not client:supports_method("codeAction/resolve") then
            return
        end

        local response = client:request_sync(
            "codeAction/resolve",
            action,
            save_action_timeout,
            buffer
        )

        if not response or response.err or not response.result then
            return
        end

        action = response.result
    end

    if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end

    if action.command then
        local command = type(action.command) == "table" and action.command
            or action

        pcall(function()
            client:exec_cmd(command, { bufnr = buffer })
        end)
    end
end

-- Which of several offered fixes to take is a question a save cannot ask, so
-- it only takes the ones where there is nothing to ask about.
--
-- Servers return one quickfix per diagnostic they can fix, so a file missing
-- two imports offers two actions and both should be applied -- refusing to act
-- on more than one action would defeat the point. What must not be guessed at
-- is two competing fixes for the *same* diagnostic: "did you mean Fatal or
-- Fatalf" has no right answer without being asked. Grouping by the diagnostic
-- each action addresses separates the two cases, and a group offering a choice
-- is left alone for <leader>qf to resolve by hand.
--
-- Source actions carry no diagnostics -- they act on the file as a whole --
-- and share the single empty group, which is correct for them: a server offers
-- one organizeImports, not a choice of several.
local function unambiguous(actions)
    local groups = {}
    local order = {}

    for _, action in ipairs(actions) do
        local key = ""

        for _, diagnostic in ipairs(action.diagnostics or {}) do
            key = key
                .. string.format(
                    "%d:%d:%s;",
                    diagnostic.range.start.line,
                    diagnostic.range.start.character,
                    diagnostic.message or ""
                )
        end

        if not groups[key] then
            groups[key] = {}
            order[#order + 1] = key
        end

        table.insert(groups[key], action)
    end

    local chosen = {}

    for _, key in ipairs(order) do
        if #groups[key] == 1 then
            chosen[#chosen + 1] = groups[key][1]
        end
    end

    return chosen
end

local function apply_save_actions(buffer)
    if not save_actions_enabled(buffer) then
        return
    end

    for _, kind in ipairs(save_action_kinds) do
        local clients = vim.lsp.get_clients({
            bufnr = buffer,
            method = "textDocument/codeAction",
        })

        for _, client in ipairs(clients) do
            local params = {
                textDocument = vim.lsp.util.make_text_document_params(buffer),
                range = {
                    start = { line = 0, character = 0 },
                    ["end"] = buffer_end(buffer, client.offset_encoding),
                },
                context = {
                    only = { kind },
                    diagnostics = lsp_diagnostics(buffer),
                    -- Automatic: this was not asked for by a keypress.
                    triggerKind = 2,
                },
            }

            local response = client:request_sync(
                "textDocument/codeAction",
                params,
                save_action_timeout,
                buffer
            )

            if response and not response.err and response.result then
                for _, action in ipairs(unambiguous(response.result)) do
                    apply_action(client, buffer, action)
                end
            end
        end

        -- Applying an edit changes the buffer, and the server is told about it
        -- by a callback that only runs once Neovim yields. Without this pause
        -- the next kind would be answered from the file as it was before the
        -- imports were added.
        vim.wait(50)
    end
end

vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function(args)
        apply_save_actions(args.buf)

        vim.lsp.buf.format({
            bufnr = args.buf,
            timeout_ms = save_action_timeout,
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
