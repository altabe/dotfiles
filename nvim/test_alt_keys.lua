-- Test script to check Alt key handling
-- This will help identify if Alt keys are causing the "AA" issue

print("=== Testing Alt Key Handling ===")

-- Test 1: Check if Alt keys are being interpreted correctly
print("Testing Alt key interpretation...")

-- Test 2: Check terminal settings
print("\nTerminal settings:")
print("TERM:", vim.env.TERM)
print("TERM_PROGRAM:", vim.env.TERM_PROGRAM)
print("KITTY_WINDOW_ID:", vim.env.KITTY_WINDOW_ID)

-- Test 3: Check if there are any pending key sequences
print("\nChecking for pending key sequences...")
local pending = vim.fn.getchar(0)
if pending > 0 then
    print("Pending input found:", pending, "(", string.char(pending), ")")
else
    print("No pending input")
end

-- Test 4: Check if Alt keys are being sent as escape sequences
print("\nAlt key test:")
print("Press Alt+A and see what happens...")
print("If you see 'AA' appear, it means Alt+A is being sent as 'A' twice")

print("\n=== Instructions ===")
print("1. Press Alt+A in normal mode")
print("2. If you see 'AA' appear, that's the source of the telescope issue")
print("3. This suggests your terminal is sending Alt+A as 'AA' instead of a proper escape sequence")

print("\n=== Potential Solutions ===")
print("If Alt+A sends 'AA':")
print("- Check your kitty.conf for Alt key mappings")
print("- Look for 'map alt+a' or similar configurations")
print("- The issue is terminal-level, not Neovim-level") 