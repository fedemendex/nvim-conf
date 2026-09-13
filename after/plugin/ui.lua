local windows = require("quiddam.windows")
local session = require("quiddam.session")

-- nvim-tree ---------------------------------------------------------------

local function tree_on_attach(bufnr)
    local api = require("nvim-tree.api")

    -- Preserve standard nvim-tree mappings.
    api.map.on_attach.default(bufnr)

    -- nvim-tree maps Space locally, blocking leader mappings.
    pcall(vim.keymap.del, "n", "<Space>", {
        buffer = bufnr,
    })

    -- It also maps <C-k> to its node-info popup, which would shadow the
    -- navigation chord and trap the cursor in the tree. Info stays on the
    -- tree's own "g?" help under <C-k>'s original name.
    pcall(vim.keymap.del, "n", "<C-k>", {
        buffer = bufnr,
    })

    -- Add the selected tree file to Harpoon.
    vim.keymap.set("n", "<leader>a", function()
        local node = api.tree.get_node_under_cursor()

        if node and node.type == "file" then
            require("harpoon.mark").add_file(node.absolute_path)
            vim.notify("Added to Harpoon: " .. node.name)
        else
            vim.notify("Select a file first")
        end
    end, {
        buffer = bufnr,
        silent = true,
        desc = "Add selected file to Harpoon",
    })
end

require("nvim-tree").setup({
    on_attach = tree_on_attach,

    view = {
        side = "left",
        width = 30,
    },

    renderer = {
        group_empty = true,
    },

    update_focused_file = {
        enable = true,
    },

    filters = {
        dotfiles = false,
        git_ignored = false,
    },
})

-- Opening a file the moment it is created ------------------------------------
--
-- nvim-tree's "a" creates the file and then leaves it sitting there: the
-- cursor stays in the tree and nothing opens. Naming a file is as good as
-- saying you want to write in it, so it is opened in the editor window and
-- focus follows it.
--
-- ":edit" in the window that is already there, rather than a split, is what
-- makes "gb" work afterwards. That mapping is ":edit #", and # is whatever the
-- window was showing before -- so replacing the buffer in place leaves the
-- previous file one keypress away. Opening a new split instead would leave two
-- windows and no alternate file to go back to.
--
-- VS Code has no nvim-tree, so none of this applies there.
if not vim.g.vscode then
    local tree_api = require("nvim-tree.api")

    tree_api.events.subscribe(
        tree_api.events.Event.FileCreated,
        function(file)
            local path = file.fname

            -- "a" makes a directory when the name ends in a separator, and
            -- nvim-tree reports that through FolderCreated rather than here.
            -- This only guards against editing one by accident.
            if vim.fn.isdirectory(path) == 1 then
                return
            end

            local name = vim.fn.fnameescape(path)

            -- The usual case: an editor window is already open beside the
            -- tree, so the new file replaces what it holds.
            if windows.focus_editor() then
                vim.cmd("edit " .. name)
            else
                -- Nothing but the tree is open, so the window it normally
                -- sits beside has to be built. 'splitright' puts it on the
                -- right, and the file is named here so the window is never
                -- momentarily holding the tree's own buffer.
                vim.cmd("vsplit " .. name)

                -- The split halved the tree; this returns it to the width
                -- configured above.
                pcall(tree_api.tree.resize)
            end

            windows.remember_editor()
        end
    )
end

-- VS Code has its own explorer, so the tree is never drawn there. Both
-- editors show and hide it from this key, each with its own machinery.
--
-- The single command that matches NvimTreeToggle in shape,
-- workbench.action.toggleSidebarVisibility, says nothing about *which* view
-- comes back, so after a project search it reopened the sidebar on Search
-- rather than on the file tree. Naming the view means naming the direction
-- too: workbench.view.explorer only ever reveals, closeSidebar only ever
-- hides.
--
-- Which of the two to run has to be tracked here, because VS Code exposes no
-- way to ask whether its sidebar is showing -- not through a command, and not
-- through the extension API that vscode.eval reaches. Both commands are
-- unconditional, so a tracked value that has drifted -- the sidebar closed
-- with Cmd+B or the mouse while this still thinks it is open -- costs one
-- keypress and corrects itself: that press hides nothing, the next one opens
-- the explorer.
--
-- It starts false against a sidebar VS Code usually opens showing the
-- explorer, which makes the first press of a session focus that explorer
-- rather than close it. That is the friendlier way round for the state to be
-- wrong, so it is left as is.
local explorer_visible = false

vim.keymap.set("n", "<leader>n", function()
    if vim.g.vscode then
        local ok, vscode = pcall(require, "vscode")

        if not ok then
            return
        end

        if explorer_visible then
            vscode.action("workbench.action.closeSidebar")
        else
            vscode.action("workbench.view.explorer")
        end

        explorer_visible = not explorer_visible

        return
    end

    vim.cmd("NvimTreeToggle")
end, {
    silent = true,
    desc = "Toggle file tree",
})

-- Toggleterm --------------------------------------------------------------

require("toggleterm").setup({
    size = function(term)
        if term.direction == "horizontal" then
            return math.max(10, math.floor(vim.o.lines * 0.25))
        end

        return 80
    end,

    direction = "horizontal",
    persist_size = false,
    persist_mode = false,
    start_in_insert = false,
    close_on_exit = true,
    shade_terminals = false,

    on_open = function()
        vim.wo.winfixheight = true
    end,
})

if vim.g.vscode then
    -- The panel is shared: Test Results takes it over after <leader>tn, and
    -- workbench.action.terminal.focus does not reliably pull it back to the
    -- terminal from there. Terminal.show() is addressed at one terminal
    -- rather than at the panel, so it reveals that terminal whatever view the
    -- panel is parked on, and creating one when none exists matches the way
    -- the ToggleTerm branch below builds the terminal on demand.
    --
    -- preserveFocus is false so focus moves into the terminal, as
    -- 1ToggleTerm does.
    --
    -- The module is required inside the mapping and through pcall, as
    -- <leader>n above does. Requiring it at file scope instead would throw
    -- during startup if it were ever missing, taking the rest of this file --
    -- and undotree.lua after it -- down with it.
    vim.keymap.set("n", "<leader>ter", function()
        local ok, vscode = pcall(require, "vscode")

        if not ok then
            vim.notify(
                "vim.g.vscode is set but the vscode module is unavailable",
                vim.log.levels.ERROR
            )

            return
        end

        vscode.eval_async([[
            const terminal = vscode.window.activeTerminal
                || vscode.window.terminals[0]
                || vscode.window.createTerminal();

            terminal.show(false);
        ]])
    end, {
        silent = true,
        desc = "Focus VS Code terminal",
    })
else
    vim.keymap.set("n", "<leader>ter", function()
        -- Create the terminal from the editor rather than nvim-tree.
        windows.focus_editor()

        vim.cmd("1ToggleTerm direction=horizontal")
    end, {
        silent = true,
        desc = "Toggle bottom terminal",
    })
end

local terminal_group = vim.api.nvim_create_augroup(
    "ToggleTermMappings",
    { clear = true }
)

vim.api.nvim_create_autocmd("TermOpen", {
    group = terminal_group,
    pattern = "term://*toggleterm#*",

    callback = function(event)
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {
            buffer = event.buf,
            silent = true,
            desc = "Leave terminal-input mode",
        })
    end,
})

-- Startup layout ----------------------------------------------------------

-- VS Code owns the window layout, the file tree, and which editors are open,
-- so none of this runs under vscode-neovim. Restoring a session there also
-- broke it outright: 'buffers' is in sessionoptions, so sourcing the session
-- created a buffer already named after a file, and vscode-neovim then failed
-- with "E95: Buffer with this name already exists" when it tried to name its
-- own buffer for the same document. Saving is skipped for the same reason --
-- a VS Code layout is meaningless to standalone Neovim, and writing one would
-- overwrite the session this directory saved from the terminal.
if not vim.g.vscode then
    local startup_group = vim.api.nvim_create_augroup(
        "OpenWorkspaceLayout",
        { clear = true }
    )

    vim.api.nvim_create_autocmd("VimEnter", {
        group = startup_group,
        once = true,

        callback = function()
            vim.schedule(function()
                -- Restoring only makes sense when no files were given to open.
                if session.started_without_files() and session.restore() then
                    windows.focus_editor()
                    windows.remember_editor()

                    return
                end

                local editor_window = vim.api.nvim_get_current_win()

                -- Remember the window where files should be opened.
                windows.remember_editor(editor_window)

                -- Open the tree on the left.
                vim.cmd("NvimTreeOpen")

                if vim.api.nvim_win_is_valid(editor_window) then
                    vim.api.nvim_set_current_win(editor_window)
                end

                -- Start with nvim-tree focused.
                vim.schedule(function()
                    vim.cmd("NvimTreeFocus")
                end)
            end)
        end,
    })

    -- Record the layout so the next start in this directory can rebuild it.
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = startup_group,

        callback = function()
            session.save()
        end,
    })
end

-- Make the focused window visually obvious.
local function set_window_focus()
    local active_window = vim.api.nvim_get_current_win()

    for _, window in ipairs(vim.api.nvim_list_wins()) do
        if window == active_window then
            vim.wo[window].winhighlight =
            "Normal:Normal,NormalNC:Normal"
        else
            vim.wo[window].winhighlight =
            "Normal:InactiveWindow,NormalNC:InactiveWindow"
        end
    end
end

-- Adjust this background to match your colour scheme.
vim.api.nvim_set_hl(0, "InactiveWindow", {
    bg = "#191827",
})

vim.api.nvim_create_autocmd({
    "WinEnter",
    "WinLeave",
    "BufWinEnter",
    "TermOpen",
}, {
    callback = function()
        vim.schedule(set_window_focus)
    end,
})

vim.schedule(set_window_focus)
