# Neovim configuration

Personal Neovim configuration for Go, Rust, TypeScript/JavaScript, Python and Lua
development on macOS.

It includes:

- LSP support and completion through Mason, `nvim-lspconfig`, and `nvim-cmp`
- Treesitter syntax highlighting
- Telescope file and text search
- Harpoon file navigation
- A left-side file tree and bottom terminal
- Git integration
- Test commands
- Persistent undo and system-clipboard integration

The leader key is `Space`.

## Repository layout

Install the files with this structure:

```text
~/.config/nvim/
├── init.lua
├── lua/
│   └── quiddam/
│       ├── init.lua
│       ├── packer.lua
│       ├── remap.lua
│       └── set.lua
└── after/
    └── plugin/
        ├── colors.lua
        ├── fugitive.lua
        ├── harpoon.lua
        ├── lsp.lua
        ├── telescope.lua
        ├── test.lua
        ├── treesitter.lua
        ├── ui.lua
        └── undotree.lua
```

The uploaded `init(1).lua` is the root `~/.config/nvim/init.lua`. The uploaded
`init.lua` belongs at `~/.config/nvim/lua/quiddam/init.lua`.

To get help on the different keymaps hit `Space ?`

## Installation

### 1. Install system dependencies

Using Homebrew:

```bash
brew install neovim git ripgrep tree-sitter tree-sitter-cli
brew install --cask font-jetbrains-mono-nerd-font
```

The `tree-sitter` formula installs the library. `tree-sitter-cli` supplies the
`tree-sitter` command needed to compile parsers.

Telescope's native FZF extension is built with `make`. On macOS, install the
Command Line Tools if `make` is unavailable:

```bash
xcode-select --install
```

Select **JetBrainsMono Nerd Font Mono** in the terminal's font settings, then
restart the terminal. This is required for the file-tree icons to render
correctly.

Verify the important commands:

```bash
nvim --version
tree-sitter --version
rg --version
make --version
```

### 2. Clone the configuration

Back up an existing configuration first, then clone this repository:

```bash
mv ~/.config/nvim ~/.config/nvim.backup
git clone <repository-url> ~/.config/nvim
```

If there is no existing configuration, the `mv` command will simply be
unnecessary.

### 3. Install Packer

Packer manages the plugins declared in `lua/quiddam/packer.lua`:

```bash
git clone --depth 1 https://github.com/wbthomason/packer.nvim \
  ~/.local/share/nvim/site/pack/packer/start/packer.nvim
```

Packer is no longer maintained, but this configuration currently depends on
it. A future migration to `lazy.nvim` or Neovim's built-in package management
would be sensible.

### 4. Create the persistent-undo directory

```bash
mkdir -p ~/.vim/undodir
```

### 5. Install plugins and parsers

Open Neovim and run:

```vim
:PackerSync
```

Completely restart Neovim, then run:

```vim
:TSUpdate
```

Treesitter installs parsers for Lua, Vim, Go, Rust, JavaScript, TypeScript,
TSX, JSON, HTML, CSS, and YAML.

Mason automatically installs and enables:

- `gopls`
- `ts_ls`
- `rust_analyzer`
- `lua_ls`

Use `:Mason` to inspect their installation status and
`:checkhealth vim.lsp` to diagnose LSP problems.

### 6. Ensure nvim-tree replaces netrw

The root `init.lua` should disable netrw **before** loading the rest of the
configuration:

```lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("quiddam")
```

## Key mappings

Notation used below:

- `Space` is the leader key.
- `Ctrl-x` means hold Control and press `x`.
- `Shift-Tab` means hold Shift and press Tab.
- Mappings marked **LSP** exist only when a language server is attached.

### Files, search, and navigation

| Mode | Keys | Action |
|---|---|---|
| Normal | `Space o` | Find files with Telescope |
| Normal | `Space g i t` | Find Git-tracked files with Telescope |
| Normal | `Space g` | Prompt for text and grep the project |
| Normal | `Space n` | Toggle the file tree |
| Normal | `Space a` | Add the current file to Harpoon |
| Normal | `dd` | Removing files of Harpoon (execute on top of file name in Harpoon menu) |
| Normal | `Space h` | Toggle the Harpoon menu |
| Normal | `Space 1` … `Space 4` | Open Harpoon file 1 … 4 |
| Normal | `Space u` | Toggle the undo tree |
| Normal | `n` / `N` | Next/previous search result and centre it |
| Normal | `Ctrl-d` / `Ctrl-u` | Half-page down/up and centre the cursor |
| Normal | `Ctrl-k` / `Ctrl-j` | Next/previous quickfix entry |
| Normal | `Space k` / `Space j` | Next/previous location-list entry |
| Normal | `a` | Add files on nerd-tree window |
| Normal | `Ctrl-h|j|k|l` | Move to a different pane | 


### Editing and clipboard

| Mode | Keys | Action |
|---|---|---|
| Normal | `Y` | Yank from the cursor to the end of the line |
| Normal | `J` | Join the next line while preserving cursor position |
| Visual | `J` / `K` | Move selected lines down/up and re-indent |
| Visual | `Space p` | Paste over the selection without replacing the yank register |
| Normal/Visual | `Space y` | Yank to the system clipboard |
| Normal | `Space Y` | Yank the line to the system clipboard |
| Normal/Visual | `Space d` | Delete into the black-hole register |
| Normal | `Space b` | Enter visual-block mode |
| Insert | `Ctrl-c` | Return to normal mode |
| Normal | `Q` | Disabled |
| Normal | `Space r` | Prepare whole-file replacement for the word under the cursor |
| Visual | `Space r` | Prepare replacement restricted to the visual selection |
| Normal | `Space x` | Make the current file executable |
| Normal | `Space Space` | Source/reload the current Lua file |
| Normal | `u` | Undo | 
| Normal | `Ctrl-r` | Redo | 

Ordinary yanks also use the macOS clipboard because
`clipboard=unnamedplus` is enabled.

### Go helpers

| Mode | Keys | Action |
|---|---|---|
| Normal | `Space e e` | Insert an `if err != nil { return err }` block |
| Normal | `Space e a` | Insert `assert.NoError(err, "")` and place the cursor in the message |

### Tests

| Mode | Keys | Action |
|---|---|---|
| Normal | `Space t n` | Run the nearest test |
| Normal | `Space t` | Run every test in the current file |
| Normal | `Space t a` | Run the entire test suite |
| Normal | `Space t t` | Run the last test again |

`vim-test` uses the project's own test runner. The corresponding tools must
already be available—for example `go`, `cargo`, `npm`, Vitest, or Jest.

### LSP

| Mode | Keys | Action |
|---|---|---|
| Normal | `g d` | Go to definition |
| Normal | `g D` | Go to declaration |
| Normal | `g i` | Go to implementation |
| Normal | `g r` | Find references with Telescope |
| Normal | `K` | Show hover documentation |
| Normal | `Space d s` | Find symbols in the current document |
| Normal | `Space w s` | Find symbols in the workspace |
| Normal | `Space r n` | Rename the symbol under the cursor |
| Normal | `Space c a` | Show code actions |
| Normal | `Space f` | Format the current buffer |
| Normal | `Space d` | Show diagnostics for the current position |
| Normal | `[ d` / `] d` | Previous/next diagnostic |
| Normal | `Space` + left click | Go to definition under the mouse pointer |

In an LSP-enabled buffer, the buffer-local `Space d` diagnostic mapping takes
precedence over the global black-hole-delete mapping.

Files are also formatted automatically immediately before saving.

### Completion

| Mode | Keys | Action |
|---|---|---|
| Insert/Snippet | `Tab` | Select the next completion or expand/jump through a snippet |
| Insert/Snippet | `Shift-Tab` | Select the previous completion or jump backward in a snippet |
| Insert | `Enter` | Confirm the explicitly selected completion |

### Git, terminal, and quitting

| Mode | Keys | Action |
|---|---|---|
| Normal | `Space g s` | Open Fugitive's Git status |
| Normal | `Space t e r` | Toggle the bottom terminal |
| Terminal | `Esc` | Leave terminal-input mode |
| Normal | `Space q q` | Quit all windows with `:qa` |

`Space q q` deliberately refuses to quit if a buffer has unsaved changes. Use
`:wqa` to save everything and quit, or `:qa!` to discard changes and quit.

The terminal opens horizontally at approximately one quarter of the Neovim
window height. From terminal normal mode, use `Ctrl-w k` to move into the
editor and `Ctrl-w j` to move back into the terminal; press `i` to resume
typing in it.

## Optional or currently incomplete mappings

These mappings are present in `remap.lua`, but their dependencies are not
declared in `packer.lua`:

| Keys | Dependency | Purpose |
|---|---|---|
| `Ctrl-f` | `tmux` and a `tmux-sessionizer` executable | Open a tmux workspace |
| `Space v w m` | `vim-with-me` | Start a Vim With Me session |
| `Space s v w m` | `vim-with-me` | Stop a Vim With Me session |

They will not work until those external tools/plugins are installed. Remove
the mappings if they are not wanted.

## Useful commands

| Command | Purpose |
|---|---|
| `:PackerSync` | Install/update plugins and remove plugins no longer declared |
| `:PackerUpdate` | Update installed plugins |
| `:TSUpdate` | Install/update Treesitter parsers |
| `:Mason` | Inspect and manage language servers |
| `:checkhealth` | Run general Neovim diagnostics |
| `:checkhealth vim.lsp` | Diagnose language-server configuration |
| `:lua vim.print(vim.lsp.get_clients({ bufnr = 0 }))` | Show LSP clients attached to the current buffer |
| `:qa` | Quit all windows if there are no unsaved changes |
| `:wqa` | Save all buffers and quit |
| `:qa!` | Discard unsaved changes and quit |

## Version-control notes

Commit the Lua source files and this README. Do not commit:

- `packer_compiled.lua`
- Neovim caches under `~/.cache/nvim`
- installed plugins under `~/.local/share/nvim`
- persistent undo files under `~/.vim/undodir`

Plugins are restored from `lua/quiddam/packer.lua` by running `:PackerSync`.
