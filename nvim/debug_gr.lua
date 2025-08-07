-- Debug script for the "AA" issue with gr command
-- Run this in Neovim to debug the issue

print("=== Debugging gr command issue ===")

-- Check if telescope is available
local telescope_ok, telescope = pcall(require, "telescope.builtin")
if telescope_ok then
    print("✓ Telescope is available")
else
    print("✗ Telescope not available:", telescope)
    return
end

-- Check if LSP is attached to current buffer
local clients = vim.lsp.get_active_clients({ bufnr = 0 })
if #clients > 0 then
    print("✓ LSP clients attached:", #clients)
    for i, client in ipairs(clients) do
        print("  Client", i, ":", client.name)
    end
else
    print("✗ No LSP clients attached to current buffer")
end

-- Check current key mappings
print("\n=== Current key mappings ===")
local keymaps = vim.api.nvim_get_keymap("n")
for _, keymap in ipairs(keymaps) do
    if keymap.lhs == "gr" then
        print("Found gr mapping:", vim.inspect(keymap))
    end
end

-- Check for any autocmds that might interfere
print("\n=== Autocommands ===")
local autocmds = vim.api.nvim_get_autocmds({})
for _, autocmd in ipairs(autocmds) do
    if autocmd.event == "BufEnter" or autocmd.event == "CursorHold" then
        print("Autocmd:", autocmd.event, autocmd.pattern)
    end
end

-- Test telescope lsp_references directly
print("\n=== Testing telescope lsp_references ===")
local word = vim.fn.expand("<cword>")
print("Current word under cursor:", word)

-- Check if there are any input mappings that might cause "AA"
print("\n=== Input mappings ===")
local input_maps = vim.api.nvim_get_keymap("i")
for _, keymap in ipairs(input_maps) do
    if keymap.lhs:find("A") or keymap.lhs:find("a") then
        print("Input mapping:", keymap.lhs, "->", keymap.rhs)
    end
end

print("\n=== Debug complete ===")
print("Try running :lua require('telescope.builtin').lsp_references() manually")
print("This will help isolate if the issue is with the key mapping or telescope itself") 