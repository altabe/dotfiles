-- Test to see if telescope sends multiple A commands
-- This will help debug the "AA" issue

print("=== Testing Telescope A Command ===")

-- Override nvim_feedkeys to log what's being sent
local original_feedkeys = vim.api.nvim_feedkeys
vim.api.nvim_feedkeys = function(keys, mode, escape_csi)
    print("nvim_feedkeys called with:")
    print("  keys:", vim.inspect(keys))
    print("  mode:", mode)
    print("  escape_csi:", escape_csi)
    print("---")
    return original_feedkeys(keys, mode, escape_csi)
end

-- Test telescope lsp_references
print("Testing telescope lsp_references...")
local telescope_ok, telescope_builtin = pcall(require, "telescope.builtin")
if telescope_ok then
    print("Calling telescope.builtin.lsp_references()")
    telescope_builtin.lsp_references()
else
    print("Telescope not available:", telescope_builtin)
end

print("=== Test complete ===")
print("Check the output above to see how many times nvim_feedkeys is called with 'A'") 