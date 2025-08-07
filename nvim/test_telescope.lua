-- Test script to check telescope functions
-- Run this in Neovim to test different telescope functions

print("=== Testing Telescope Functions ===")

-- Test 1: Check if telescope is available
local telescope_ok, telescope_builtin = pcall(require, "telescope.builtin")
if not telescope_ok then
    print("✗ Telescope not available:", telescope_builtin)
    return
end

print("✓ Telescope available")

-- Test 2: List available functions
print("\nAvailable telescope functions:")
for name, _ in pairs(telescope_builtin) do
    if type(_) == "function" then
        print("  - " .. name)
    end
end

print("\n=== Test Commands ===")
print("Try these commands to test if the 'AA' issue affects all telescope functions:")
print("1. :lua require('telescope.builtin').find_files()")
print("2. :lua require('telescope.builtin').buffers()")
print("3. :lua require('telescope.builtin').help_tags()")
print("4. :lua require('telescope.builtin').lsp_references()")

print("\nIf only lsp_references shows 'AA', the issue is specific to that function.")
print("If all functions show 'AA', the issue is with telescope configuration.") 