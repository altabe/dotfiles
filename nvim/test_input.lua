-- Test to see if "AA" appears without telescope
-- This will help determine if the issue is telescope-specific or terminal-wide

print("=== Testing Input Buffer ===")

-- Test 1: Check for pending input
local pending = vim.fn.getchar(0)
if pending > 0 then
    print("Pending input found:", pending, "(", string.char(pending), ")")
else
    print("No pending input")
end

-- Test 2: Simulate telescope-like behavior without telescope
print("\n=== Testing mode switching ===")
print("This will simulate what telescope does when switching to insert mode")

-- Test 3: Check if "AA" appears when we switch to insert mode
vim.keymap.set("n", "<leader>test", function()
    print("Switching to insert mode...")
    vim.cmd("startinsert")
    print("Now in insert mode. Check if 'AA' appears.")
end, { desc = "Test insert mode switching" })

print("\n=== Instructions ===")
print("1. Press <leader>test to switch to insert mode")
print("2. If 'AA' appears, the issue is terminal-wide")
print("3. If no 'AA' appears, the issue is telescope-specific")

print("\n=== Alternative Test ===")
print("Try pressing Option+A in normal mode, then immediately press 'i'")
print("If 'AA' appears after pressing 'i', that confirms the terminal buffering theory") 