-- Comprehensive telescope debugging script
-- Run this in Neovim to debug the "AA" issue

print("=== Telescope Debugging ===")

-- Test 1: Check if telescope is loaded
local telescope_ok, telescope = pcall(require, "telescope")
if telescope_ok then
    print("✓ Telescope loaded successfully")
else
    print("✗ Telescope not loaded:", telescope)
    return
end

-- Test 2: Check telescope configuration
local config = telescope.get_config()
print("Telescope config:", vim.inspect(config))

-- Test 3: Check if there are any input mappings in telescope
local telescope_builtin_ok, telescope_builtin = pcall(require, "telescope.builtin")
if telescope_builtin_ok then
    print("✓ Telescope builtin available")
else
    print("✗ Telescope builtin not available:", telescope_builtin)
    return
end

-- Test 4: Check for any autocmds that might interfere
print("\n=== Checking for interfering autocmds ===")
local autocmds = vim.api.nvim_get_autocmds({})
for _, autocmd in ipairs(autocmds) do
    if autocmd.event == "BufEnter" or autocmd.event == "CursorHold" or 
       autocmd.event == "InsertEnter" or autocmd.event == "TextChanged" then
        print("Autocmd:", autocmd.event, autocmd.pattern)
    end
end

-- Test 5: Check for any input mappings that might cause "AA"
print("\n=== Checking input mappings ===")
local input_maps = vim.api.nvim_get_keymap("i")
for _, keymap in ipairs(input_maps) do
    if keymap.lhs:find("A") or keymap.lhs:find("a") then
        print("Input mapping:", keymap.lhs, "->", keymap.rhs)
    end
end

-- Test 6: Check terminal settings
print("\n=== Terminal settings ===")
print("Terminal type:", vim.env.TERM)
print("Terminal program:", vim.env.TERM_PROGRAM)
print("Terminal features:", vim.o.term)

-- Test 7: Check if there are any pending input
print("\n=== Checking for pending input ===")
local pending = vim.fn.getchar(0)
if pending > 0 then
    print("Pending input found:", pending, "(", string.char(pending), ")")
else
    print("No pending input")
end

print("\n=== Debug complete ===")
print("Try these tests:")
print("1. <leader>rf - Telescope lsp_references (with debug output)")
print("2. <leader>rr - Direct LSP references (bypasses telescope)")
print("3. <leader>rt - Telescope find_files (different function)")
print("4. :lua require('telescope.builtin').lsp_references() - Manual call") 