-- Debug script to see what happens when gr is pressed
-- This will help identify the source of the "A" issue

print("=== Debugging gr command ===")

-- Override nvim_feedkeys to log what's being sent
local original_feedkeys = vim.api.nvim_feedkeys
local feedkeys_count = 0
vim.api.nvim_feedkeys = function(keys, mode, escape_csi)
    feedkeys_count = feedkeys_count + 1
    print("nvim_feedkeys call #" .. feedkeys_count .. ":")
    print("  keys:", vim.inspect(keys))
    print("  mode:", mode)
    print("  escape_csi:", escape_csi)
    print("---")
    return original_feedkeys(keys, mode, escape_csi)
end

-- Check what LSP servers are currently attached
print("=== Current LSP servers ===")
local clients = vim.lsp.get_active_clients({ bufnr = 0 })
if #clients > 0 then
    print("Active LSP clients:", #clients)
    for i, client in ipairs(clients) do
        print("  Client", i, ":", client.name, "(id:", client.id, ")")
    end
else
    print("No LSP clients attached to current buffer")
end

-- Test the gr command
print("\n=== Testing gr command ===")
print("Press gr now and watch the nvim_feedkeys calls above...")

-- Set up a keymap to test gr
vim.keymap.set("n", "<leader>testgr", function()
    print("gr command triggered!")
    require("telescope.builtin").lsp_references()
end, { desc = "Test gr command" })

print("Press <leader>testgr to test the gr command")
print("This will help us see exactly what nvim_feedkeys calls are made") 