# Minimal Neovim Configuration for Remote Development

This is a minimal Neovim configuration optimized for remote development performance. The lazy.nvim plugin manager is enabled with essential plugins including fuzzy file search for productivity.

## What's Disabled

- **Most plugins** - No nvim-tree, LSP, etc. are installed
- **Plugin-related keybindings** - All mappings that depend on disabled plugins are commented out
- **Plugin checker** - Disabled to prevent network calls on startup

## What's Enabled

- **lazy.nvim** - Plugin manager is available for future use
- **Catppuccin theme** - Beautiful color scheme for better visual experience
- **Telescope** - Powerful fuzzy finder for files, buffers, and more
- **TreeSitter** - Advanced code parsing and syntax highlighting
- **LSP** - Language Server Protocol for Python (go to definition, find references, etc.)
- **Autocompletion** - Intelligent code completion with nvim-cmp
- **Basic Neovim functionality** - All core features work normally
- **Window and tab management** - Split, resize, navigate windows and tabs
- **Text editing operations** - Duplicate, move, indent text
- **Basic navigation** - Enhanced line navigation (H/L keys)
- **Yank highlighting** - Visual feedback when copying text
- **Essential keybindings** - All mappings that don't depend on plugins

## Keybindings

### Fuzzy Search (Telescope)
- `<leader>sf` - Find files (including hidden files, respects gitignore)
- `<leader><leader>` - Find existing buffers
- `<leader>s.` - Search recent files
- `<leader>sh` - Search help tags
- `<leader>sk` - Search keymaps
- `<leader>ss` - Search telescope pickers
- `<leader>sw` - Search current word
- `<leader>sg` - Live grep
- `<leader>sd` - Search diagnostics
- `<leader>sr` - Resume last search
- `<leader>/` - Fuzzy search in current buffer
- `<leader>s/` - Live grep in open files
- `<leader>sn` - Search Neovim config files

### Code Navigation (TreeSitter + LSP)
- `gd` - Go to definition (works across modules and imports)
- `gr` - Find references
- `gI` - Go to implementation
- `gD` - Go to declaration
- `<leader>D` - Type definition
- `<leader>ds` - Document symbols
- `<leader>ws` - Workspace symbols
- `<leader>rn` - Rename symbol
- `<leader>ca` - Code actions
- `<leader>th` - Toggle inlay hints

### Autocompletion (nvim-cmp)
- `<C-n>/<C-p>` - Navigate completion menu
- `<C-y>/<CR>/<Tab>` - Accept completion
- `<C-b>/<C-f>` - Scroll documentation
- `<A-Space>` - Trigger completion
- `<C-l>/<C-h>` - Navigate snippets

### TreeSitter Text Objects
- `af/if` - Select outer/inner function
- `ac/ic` - Select outer/inner class
- `am/im` - Select outer/inner function (alternative)
- `as/is` - Select outer/inner scope
- `]m/[m` - Jump to next/previous function
- `]]/[[]` - Jump to next/previous class

### Window Management
- `<leader>sv` - Split window vertically
- `<leader>sh` - Split window horizontally  
- `<leader>se` - Make splits equal size
- `<leader>sx` - Close current split

### Tab Management
- `<leader>to` - Open new tab
- `<leader>tx` - Close current tab
- `<leader>tn` - Go to next tab
- `<leader>tp` - Go to previous tab
- `<leader>tf` - Open current buffer in new tab

### Navigation
- `L` - Go to end of line
- `H` - Go to beginning of line
- `<C-h>` - Move focus to left window
- `<C-l>` - Move focus to right window

### Editing
- `<leader>j` - Duplicate line down
- `<leader>k` - Duplicate line up
- `<A-j>` - Move line down
- `<A-k>` - Move line up
- `>` - Indent right
- `<` - Indent left

## Testing

To test this configuration:

1. Start Neovim: `nvim`
2. Check startup time: `:startuptime`
3. Verify telescope is loaded: `:lua print(pcall(require, 'telescope'))`
4. Test file search: `<leader>sf`
5. View installed plugins: `:Lazy`

## Adding More Plugins

To add additional plugins for local development:

1. Edit `.config/nvim/lua/config/lazy.lua`
2. Uncomment the full plugins import: `{ import = "plugins" }`
3. Or add individual plugins to the spec table

## Performance Benefits

This setup provides:
- **Fast startup** - Only essential plugins load (~43ms on modern systems)
- **Low memory usage** - Minimal plugin overhead
- **No network calls** - Plugin checker disabled
- **Stable performance** - No background plugin processes
- **Beautiful UI** - Catppuccin theme for better visual experience
- **Productive search** - Telescope for fast file and content finding
- **Easy to extend** - Plugin manager ready for future use
- **Optimized for remote** - Performance tweaks for remote development

## Performance Optimization

The configuration includes several optimizations:
- **Reduced updatetime** - Faster completion and diagnostics
- **Disabled swap/backup files** - Faster file operations
- **Optimized telescope layout** - Horizontal layout for better performance
- **Lazy redraw** - Don't redraw during macro execution
- **Hidden buffers** - Don't unload buffers when abandoned
- **Remote detection** - Automatically applies more aggressive optimizations when working remotely
- **Limited search depth** - Telescope searches limited to 10 levels deep for faster results
- **Reduced preview timeout** - Faster preview generation in telescope
- **Shell optimizations** - Optimized shell command execution
- **Disabled mouse/cursor features** - Reduces rendering overhead over remote connections

## File Structure

```
.config/nvim/
├── init.lua                    # Main entry point (essential plugins enabled)
├── lua/
│   └── config/
│       ├── options.lua         # Basic Neovim options
│       ├── keymaps.lua         # Keybindings (plugin ones commented)
│       └── lazy.lua           # Plugin manager (essential plugins)
└── plugins/                    # Plugin configurations (colorscheme + telescope loaded)
``` 