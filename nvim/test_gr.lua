-- Simple test for gr command
-- This will help us see if the issue is with the key mapping or telescope

-- Test 1: Direct telescope call
print("Test 1: Direct telescope call")
local ok, result = pcall(function()
    require("telescope.builtin").lsp_references()
end)
print("Direct call result:", ok, result)

-- Test 2: Check if there are any conflicting mappings
print("\nTest 2: Check for conflicting mappings")
local mappings = vim.api.nvim_get_keymap("n")
local gr_mappings = {}
for _, mapping in ipairs(mappings) do
    if mapping.lhs:find("gr") then
        table.insert(gr_mappings, mapping)
    end
end
print("Found gr mappings:", #gr_mappings)
for i, mapping in ipairs(gr_mappings) do
    print("  ", i, ":", mapping.lhs, "->", mapping.rhs)
end

-- Test 3: Check if there are any terminal or input issues
print("\nTest 3: Check terminal settings")
print("Terminal type:", vim.env.TERM)
print("Terminal program:", vim.env.TERM_PROGRAM)

-- Test 4: Check if there are any autocmds that might send input
print("\nTest 4: Check for input-related autocmds")
local autocmds = vim.api.nvim_get_autocmds({})
for _, autocmd in ipairs(autocmds) do
    if autocmd.event == "BufEnter" or autocmd.event == "CursorHold" or autocmd.event == "InsertEnter" then
        print("Autocmd:", autocmd.event, autocmd.pattern)
    end
end 