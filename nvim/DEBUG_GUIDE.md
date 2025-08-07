# Debugging the "AA" Issue with gr Command

## The Problem
When pressing `gr` to find references, telescope opens with "AA" already typed in the search field, filtering out all results.

## Debugging Steps

### Step 1: Test Alternative Key Bindings
I've temporarily disabled the `gr` mapping and added alternatives:
- `<leader>rf` - Find references
- `<leader>rr` - Find references (alternative)

Try these and see if the "AA" issue persists.

### Step 2: Check for Key Mapping Conflicts
In Neovim, run:
```vim
:verbose map gr
```

This will show all mappings that start with "gr" and where they're defined.

### Step 3: Check for Terminal Issues
The "AA" might be coming from terminal input. Check:
```vim
:echo &term
:echo $TERM
```

### Step 4: Test Telescope Directly
Try running telescope manually:
```vim
:lua require('telescope.builtin').lsp_references()
```

### Step 5: Check for Autocommands
Look for any autocmds that might be sending input:
```vim
:autocmd
```

### Step 6: Check Input Mappings
Look for any input mappings that might cause "AA":
```vim
:verbose imap A
:verbose imap a
```

### Step 7: Test in Clean Neovim
Try the command in a clean Neovim instance:
```bash
nvim --clean
```

Then manually load your config and test.

### Step 8: Check for Plugin Conflicts
The issue might be caused by:
- Terminal multiplexer (tmux, screen)
- Terminal emulator settings
- Other plugins interfering with input

### Step 9: Monitor Input
To see what's actually being sent to telescope, you can temporarily modify the mapping to log input:

```lua
map("gr", function()
    print("gr pressed")
    vim.cmd("redraw!")
    require("telescope.builtin").lsp_references()
end, "[G]oto [R]eferences")
```

## Potential Solutions

### Solution 1: Use Different Key Binding
If the issue is specific to `gr`, use `<leader>rf` instead.

### Solution 2: Clear Input Buffer
Add input clearing before telescope:
```lua
map("gr", function()
    vim.cmd("redraw!")
    vim.fn.feedkeys("", "n") -- Clear input buffer
    require("telescope.builtin").lsp_references()
end, "[G]oto [R]eferences")
```

### Solution 3: Use Direct LSP Method
Bypass telescope entirely:
```lua
map("gr", function()
    vim.lsp.buf.references()
end, "[G]oto [R]eferences")
```

### Solution 4: Check Terminal Settings
If using tmux or a specific terminal, check for input forwarding issues.

## Next Steps
1. Test the alternative key bindings (`<leader>rf`, `<leader>rr`)
2. Run the debugging commands above
3. Report back what you find
4. We can then implement the appropriate fix 