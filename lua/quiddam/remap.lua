-- Space is the leader key.
vim.g.mapleader = " "

vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

-- Both editors put every mapping in one searchable list, each with its own
-- picker: standalone Neovim opens Telescope, VS Code opens a quick pick built
-- from the same table Telescope reads.
--
-- VS Code's own keyboard-shortcuts editor is not the substitute it looks like.
-- The keys in question are Neovim mappings, and VS Code has never heard of
-- <leader>ts, so that editor would list an entirely different set. The list is
-- assembled here instead and handed over only to be displayed.
--
-- It is a reference, not a launcher: choosing an entry does nothing. Telescope
-- runs the mapping on select, but keys fed back into Neovim from a quick pick
-- would fire wherever the cursor had been left, and a good many of these
-- expect a selection or a particular buffer to act on.
local function keymap_items()
    local modes = {
        n = "Normal",
        x = "Visual",
        o = "Operator",
        i = "Insert",
        t = "Terminal",
    }

    local items = {}

    for mode, label in pairs(modes) do
        for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
            -- <Plug> mappings are plugin plumbing and are never typed.
            if not map.lhs:find("<Plug>", 1, true) then
                items[#items + 1] = {
                    -- nvim_get_keymap already reports special keys in <> form
                    -- -- "<C-W>h", never a raw byte -- so the only thing left
                    -- to spell out is the leader, which comes back as a
                    -- literal space. A space in an lhs is always the space
                    -- key, so every one of them can be named. Running
                    -- vim.fn.keytrans over this would be wrong: with nothing
                    -- raw left to translate it only escapes the notation that
                    -- is already there, turning "<C-W>h" into "<lt>C-W>h".
                    label = (map.lhs:gsub(" ", "<Space>")),
                    description = label,
                    detail = map.desc or map.rhs or "",
                }
            end
        end
    end

    table.sort(items, function(first, second)
        if first.description == second.description then
            return first.label < second.label
        end

        return first.description < second.description
    end)

    return items
end

if vim.g.vscode then
    vim.keymap.set("n", "<leader>?", function()
        local ok, vscode = pcall(require, "vscode")

        if not ok then
            vim.notify(
                "vim.g.vscode is set but the vscode module is unavailable",
                vim.log.levels.ERROR
            )

            return
        end

        vscode.eval_async(
            [[
                await vscode.window.showQuickPick(args.items, {
                    title: "Neovim mappings",
                    placeHolder: "Search all keyboard mappings",
                    matchOnDescription: true,
                    matchOnDetail: true,
                });
            ]],
            {
                args = {
                    items = keymap_items(),
                },
            }
        )
    end, {
        silent = true,
        desc = "Search all keyboard mappings",
    })
else
    vim.keymap.set("n", "<leader>?", "<cmd>Telescope keymaps<CR>", {
        desc = "Search all keyboard mappings",
    })
end

vim.keymap.set("n", "<C-a>", "ggVG", {
    desc = "Select entire file",
})

-- Easy select ---------------------------------------------------------------

vim.keymap.set("n", "<leader>w", "viw", {
    desc = "Select word under cursor",
})

vim.keymap.set("n", "<leader>W", "viW", {
    desc = "Select WORD under cursor",
})

-- Quit -----------------------------------------------------------------------

vim.keymap.set("n", "<leader>qq", function()
    -- Save ordinary modified file buffers first. If saving fails, this throws
    -- and quitting stops, so changes are not silently discarded.
    vim.cmd("wa")

    -- Terminate every ToggleTerm shell, including hidden terminals.
    local terminal = require("toggleterm.terminal")

    for _, term in ipairs(terminal.get_all(true)) do
        term:shutdown()
    end

    vim.cmd("qa")
end, {
    silent = true,
    desc = "Save all, close terminals, and quit Neovim",
})

-- LSP ------------------------------------------------------------------------

-- VS Code provides its own go-to-definition and formatting, so these are only
-- wired up when Neovim runs standalone. Mirrors the guard in
-- after/plugin/lsp.lua.
if not vim.g.vscode then
    vim.keymap.set(
        "n",
        "<leader><LeftMouse>",
        "<LeftMouse><cmd>lua vim.lsp.buf.definition()<CR>",
        {
            silent = true,
            desc = "Go to definition under mouse",
        }
    )

    vim.keymap.set("n", "<leader>f", function()
        vim.lsp.buf.format()
    end, {
        desc = "Format current file",
    })
end

-- Rename stays on <leader>rn in both editors. Standalone Neovim gets it from
-- after/plugin/lsp.lua, where it is buffer-local and appears only once a
-- language server attaches; that file is skipped wholesale under VS Code, so
-- the VS Code half is declared here instead. Hence no else branch.
if vim.g.vscode then
    vim.keymap.set("n", "<leader>rn", function()
        local ok, vscode = pcall(require, "vscode")

        if ok then
            vscode.action("editor.action.rename")
        end
    end, {
        silent = true,
        desc = "Rename symbol",
    })
end

-- Visual-mode editing --------------------------------------------------------

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", {
    silent = true,
    desc = "Move selected lines down",
})

vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", {
    silent = true,
    desc = "Move selected lines up",
})

vim.keymap.set("n", "<leader>b", "<C-v>", {
    desc = "Enter visual block mode",
})

-- Paste over a selection without replacing the copied text.
vim.keymap.set("x", "<leader>p", [["_dP]], {
    desc = "Paste without replacing clipboard",
})

-- Normal-mode improvements ---------------------------------------------------

vim.keymap.set("v", "<leader>tu", "U", { desc = "Convert selection to Uppercase" })
vim.keymap.set("v", "<leader>tp", "u", { desc = "Convert selection to Lowercase" })

vim.keymap.set("n", "gb", "<cmd>edit #<CR>", {
    silent = true,
    desc = "Go back to previous file",
})

vim.keymap.set("n", "Y", "yg$", {
    desc = "Yank from cursor to end of line",
})

vim.keymap.set("n", "J", "mzJ`z", {
    desc = "Join lines and preserve cursor position",
})

vim.keymap.set("n", "<C-d>", "<C-d>zz", {
    desc = "Scroll half-page down and centre cursor",
})

vim.keymap.set("n", "<C-u>", "<C-u>zz", {
    desc = "Scroll half-page up and centre cursor",
})

-- The leader row ------------------------------------------------------------

-- Scrolling moved off <C-j>/<C-k> and onto <leader>j/k: VS Code offers no
-- leader-key equivalent of window navigation, so the Ctrl chords are reserved
-- for movement and the same fingers work in both editors.
--
-- These are Normal, Visual, and operator-pending only. In Insert and Terminal
-- mode <leader> is a literal space, so mapping <leader>j there would swallow
-- every "j" typed after a space and stall every other space for timeoutlen.
-- Insert mode reaches them with <Esc> first; the <C-hjkl> navigation further
-- down does work in every mode.
vim.keymap.set({ "n", "x" }, "<leader>j", "<C-d>zz", {
    desc = "Scroll half-page down and centre cursor",
})

vim.keymap.set({ "n", "x" }, "<leader>k", "<C-u>zz", {
    desc = "Scroll half-page up and centre cursor",
})

-- The horizontal half of the same row goes to the ends of the line, which is
-- what Home and End do elsewhere. Operator-pending is included so that
-- d<leader>l and c<leader>h work like d$ and c^.
vim.keymap.set({ "n", "x", "o" }, "<leader>h", "^", {
    desc = "Go to first non-blank character",
})

vim.keymap.set({ "n", "x", "o" }, "<leader>l", "$", {
    desc = "Go to end of line",
})

-- Movement between Neovim splits and tmux panes ------------------------------

-- vim-tmux-navigator claims all four Ctrl chords from its own plugin file,
-- which loads after this one, so its default mappings are disabled and every
-- direction is declared here instead.
vim.g.tmux_navigator_no_mappings = 1

local navigations = {
    h = "TmuxNavigateLeft",
    j = "TmuxNavigateDown",
    k = "TmuxNavigateUp",
    l = "TmuxNavigateRight",
}

-- <C-hjkl> is the primary way to move in all four directions, matching the
-- chords VS Code is limited to. <C-w> keeps the familiar prefix working and
-- gains the same crossing into tmux panes.
for key, command in pairs(navigations) do
    local chord = "<C-" .. key .. ">"
    local rhs = "<cmd>" .. command .. "<CR>"

    local options = {
        silent = true,
        desc = "Navigate: " .. command,
    }

    vim.keymap.set("n", chord, rhs, options)
    vim.keymap.set("n", "<C-w>" .. key, rhs, options)

    -- Insert, Visual, and Terminal mode return to Normal mode first, so the
    -- chord never carries an insertion, a selection, or a shell across into
    -- the target split. <C-\><C-n> does that from all three.
    vim.keymap.set({ "i", "x", "t" }, chord, [[<C-\><C-n>]] .. rhs, options)
end

vim.keymap.set("n", "<C-\\>", "<cmd>TmuxNavigatePrevious<CR>", {
    silent = true,
    desc = "Navigate: TmuxNavigatePrevious",
})

vim.keymap.set("n", "n", "nzzzv", {
    desc = "Next search result and centre cursor",
})

vim.keymap.set("n", "N", "Nzzzv", {
    desc = "Previous search result and centre cursor",
})

vim.keymap.set("i", "<C-c>", "<Esc>", {
    desc = "Leave insert mode",
})

vim.keymap.set("n", "Q", "<nop>", {
    desc = "Disable Ex mode",
})

-- Clipboard ------------------------------------------------------------------

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], {
    desc = "Copy to system clipboard",
})

vim.keymap.set("n", "<leader>Y", [["+Y]], {
    desc = "Copy line to system clipboard",
})

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], {
    desc = "Delete without replacing clipboard",
})

-- Search and replace ---------------------------------------------------------

-- Both editors replace across the current file, each with its own machinery:
-- VS Code opens the find/replace widget, standalone Neovim opens a :%s command
-- line. Both are seeded with the word under the cursor, and the VS Code flags
-- are chosen to match the Neovim pattern exactly -- matchWholeWord for \< \>,
-- isCaseSensitive for the I flag, isRegex off because a bare word is literal.
-- Rename lives on <leader>rn in both, up in the LSP section.
if vim.g.vscode then
    vim.keymap.set("n", "<leader>r", function()
        local word = vim.fn.expand("<cword>")

        -- Nothing to seed the widget with, e.g. on a blank line.
        if word == "" then
            return
        end

        local ok, vscode = pcall(require, "vscode")

        if not ok then
            return
        end

        vscode.action("editor.actions.findWithArgs", {
            args = {
                searchString = word,
                replaceString = "",
                isRegex = false,
                isCaseSensitive = true,
                matchWholeWord = true,
                preserveCase = false,
                findInSelection = false,
            },
        })
    end, {
        silent = true,
        desc = "Replace word in current file",
    })
else
    vim.keymap.set(
        "n",
        "<leader>r",
        [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
        {
            desc = "Replace word under cursor in file",
        }
    )
end

-- Visual mode stays a substitute in both editors: it rewrites text inside the
-- selection, which neither the widget nor a rename scopes to.

vim.keymap.set(
    "x",
    "<leader>r",
    [[:s/\%V\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    {
        desc = "Replace word inside selection",
    }
)

-- Quickfix and location lists ------------------------------------------------

vim.keymap.set("n", "<leader>cn", "<cmd>cnext<CR>zz", {
    silent = true,
    desc = "Next quickfix result",
})

vim.keymap.set("n", "<leader>cp", "<cmd>cprev<CR>zz", {
    silent = true,
    desc = "Previous quickfix result",
})

-- Bracket pairs, matching ]d/[d for diagnostics and ]h/[h for Git hunks.
vim.keymap.set("n", "]l", "<cmd>lnext<CR>zz", {
    silent = true,
    desc = "Next location-list result",
})

vim.keymap.set("n", "[l", "<cmd>lprev<CR>zz", {
    silent = true,
    desc = "Previous location-list result",
})

-- Go helpers -----------------------------------------------------------------

vim.keymap.set(
    "n",
    "<leader>ee",
    "oif err != nil {<CR>}<Esc>Oreturn err<Esc>",
    {
        desc = "Insert Go return-error block",
    }
)

vim.keymap.set(
    "n",
    "<leader>ea",
    "oassert.NoError(err, \"\")<Esc>F\";a",
    {
        desc = "Insert Go NoError assertion",
    }
)

vim.keymap.set("i", "/**", "/**<CR><CR>*/<Up>", {
    noremap = true,
    desc = "Expand block comment",
})

-- External tools -------------------------------------------------------------

vim.keymap.set(
    "n",
    "<C-f>",
    "<cmd>silent !tmux neww tmux-sessionizer<CR>",
    {
        silent = true,
        desc = "Open tmux sessionizer",
    }
)

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", {
    silent = true,
    desc = "Make current file executable",
})

vim.keymap.set("n", "<leader>vwm", function()
    require("vim-with-me").StartVimWithMe()
end, {
    desc = "Start Vim With Me",
})

vim.keymap.set("n", "<leader>svwm", function()
    require("vim-with-me").StopVimWithMe()
end, {
    desc = "Stop Vim With Me",
})

-- Reload configuration -------------------------------------------------------

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


-- Structural selection -------------------------------------------------------

-- <Tab> is <C-i> in Normal mode, which would otherwise move forward in the
-- jump list. nvim-tree and Telescope map <Tab> in their own buffers, so those
-- windows keep their usual behaviour.
vim.keymap.set({ "n", "x" }, "<Tab>", function()
    require("quiddam.structural").expand()
end, {
    silent = true,
    desc = "Expand structural selection",
})

vim.keymap.set("x", "<S-Tab>", function()
    require("quiddam.structural").shrink()
end, {
    silent = true,
    desc = "Shrink structural selection",
})

-- opens the companion test on the right, creating it immediately if necessary
local function companion_test_path(source)
    local directory = vim.fn.fnamemodify(source, ":h")
    local filename = vim.fn.fnamemodify(source, ":t")
    local extension = vim.fn.fnamemodify(source, ":e")
    local stem = vim.fn.fnamemodify(filename, ":r")

    local candidates

    if extension == "go" then
        candidates = {
            directory .. "/" .. stem .. "_test.go",
        }
    elseif extension == "js"
        or extension == "jsx"
        or extension == "ts"
        or extension == "tsx"
    then
        candidates = {
            directory .. "/" .. stem .. ".test." .. extension,
            directory .. "/" .. stem .. ".spec." .. extension,
        }
    elseif extension == "py" then
        candidates = {
            directory .. "/test_" .. stem .. ".py",
            directory .. "/" .. stem .. "_test.py",
        }
    else
        return nil
    end

    -- Prefer an existing test file, including .spec files.
    for _, path in ipairs(candidates) do
        if vim.fn.filereadable(path) == 1 then
            return path
        end
    end

    -- Otherwise create the first/default convention.
    return candidates[1]
end

-- Under VS Code both halves of the job -- creating the file and putting it
-- beside the current one -- go through VS Code's own API, and nothing here
-- touches a Neovim buffer.
--
-- That last part is the point. Opening the test with :vsplit left a plain
-- Neovim buffer named after the file, and vscode-neovim then failed with
-- "E95: Buffer with this name already exists" when it created its own buffer
-- for the same document, surfacing as "Error syncing layout". The extension
-- clears such collisions only for buffers it made itself, which it recognises
-- by their vscode_uri variable; a buffer this configuration opened has none,
-- so the error escapes. It is the same failure that keeps session restore out
-- of VS Code in after/plugin/ui.lua.
--
-- workspace.fs rather than vim.fn.writefile so the explorer and any file
-- watchers see the new file at once, and so the write goes wherever the
-- workspace actually lives. That last part is also why the target URI is
-- rebuilt from the current document's own URI when there is one, instead of
-- always being vscode.Uri.file: over Remote SSH or in a dev container the
-- documents are vscode-remote:// and a file:// URI would name a path on the
-- wrong machine. ViewColumn.Beside is what "rightbelow vsplit" means here: the
-- editor group to the right, created if there is not one yet. Without it the
-- file merely takes over the active group as another tab. preview = false
-- pins the tab, so the next file opened does not recycle it -- a split stays
-- put, and this should too.
local function open_companion_test_in_vscode(test_path)
    local ok, vscode = pcall(require, "vscode")

    if not ok then
        vim.notify(
            "vim.g.vscode is set but the vscode module is unavailable",
            vim.log.levels.ERROR
        )

        return
    end

    vscode.eval_async(
        [[
            const base = args.base ? vscode.Uri.parse(args.base) : null;

            // The companion test sits in the same directory as its source, so
            // the source's scheme and authority are the right ones to keep.
            const uri = base
                ? base.with({ path: args.path, query: "", fragment: "" })
                : vscode.Uri.file(args.path);

            let created = false;

            try {
                await vscode.workspace.fs.stat(uri);
            } catch {
                await vscode.workspace.fs.writeFile(uri, new Uint8Array());
                created = true;
            }

            await vscode.window.showTextDocument(uri, {
                viewColumn: vscode.ViewColumn.Beside,
                preview: false,
            });

            return created;
        ]],
        {
            args = {
                path = test_path,

                -- vscode-neovim records the document's URI on the buffer it
                -- owns. Absent for a buffer VS Code does not back, in which
                -- case the JS falls back to a local file URI.
                base = vim.b.vscode_uri,
            },

            callback = function(err, created)
                if err then
                    vim.notify(tostring(err), vim.log.levels.ERROR)
                elseif created then
                    vim.notify(
                        "Created " .. vim.fn.fnamemodify(test_path, ":t")
                    )
                end
            end,
        }
    )
end

local function open_companion_test()
    local source = vim.api.nvim_buf_get_name(0)

    if source == "" then
        vim.notify("Current buffer has no filename", vim.log.levels.WARN)
        return
    end

    local test_path = companion_test_path(source)

    if not test_path then
        vim.notify(
            "No test-file convention for this file type",
            vim.log.levels.WARN
        )
        return
    end

    if vim.g.vscode then
        open_companion_test_in_vscode(test_path)
        return
    end

    if vim.fn.filereadable(test_path) == 0 then
        vim.fn.writefile({}, test_path)
        vim.notify(
            "Created " .. vim.fn.fnamemodify(test_path, ":t")
        )
    end

    vim.cmd(
        "rightbelow vsplit " .. vim.fn.fnameescape(test_path)
    )
end

vim.keymap.set("n", "<leader>ts", open_companion_test, {
    desc = "Open or create companion test",
})
