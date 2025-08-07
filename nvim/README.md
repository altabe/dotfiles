# Minimal Neovim Configuration for Remote Development

This is a minimal Neovim configuration optimized for remote development performance. The lazy.nvim plugin manager is enabled but no plugins are installed to ensure fast startup and operation on remote machines.

## What's Disabled

- **All plugins** - No telescope, nvim-tree, LSP, etc. are installed
- **Plugin-related keybindings** - All mappings that depend on plugins are commented out
- **Plugin checker** - Disabled to prevent network calls on startup

## What's Enabled

- **lazy.nvim** - Plugin manager is available for future use
- **Basic Neovim functionality** - All core features work normally
- **Window and tab management** - Split, resize, navigate windows and tabs
- **Text editing operations** - Duplicate, move, indent text
- **Basic navigation** - Enhanced line navigation (H/L keys)
- **Yank highlighting** - Visual feedback when copying text
- **Essential keybindings** - All mappings that don't depend on plugins

## Keybindings

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
3. Verify lazy.nvim is loaded: `:lua print(package.loaded.lazy ~= nil)`
4. Check no plugins are installed: `:Lazy`

## Adding Plugins

To add plugins back for local development:

1. Edit `.config/nvim/lua/config/lazy.lua`
2. Uncomment the plugins import: `{ import = "plugins" }`
3. Or add individual plugins to the spec table

## Performance Benefits

This setup provides:
- **Fast startup** - No plugin loading or initialization
- **Low memory usage** - Only lazy.nvim itself is loaded
- **No network calls** - Plugin checker disabled
- **Stable performance** - No background plugin processes
- **Easy to extend** - Plugin manager ready for future use

## File Structure

```
.config/nvim/
├── init.lua                    # Main entry point (lazy.nvim enabled)
├── lua/
│   └── config/
│       ├── options.lua         # Basic Neovim options
│       ├── keymaps.lua         # Keybindings (plugin ones commented)
│       └── lazy.lua           # Plugin manager (enabled, no plugins)
└── plugins/                    # Plugin configurations (not loaded)
``` 