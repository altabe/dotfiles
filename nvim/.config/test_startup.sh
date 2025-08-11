#!/bin/bash

# Script to test Neovim startup performance

echo "Testing Neovim startup performance..."
echo "====================================="

# Test basic startup time
echo "1. Clean startup time:"
time nvim --clean --headless -c "quit" 2>/dev/null

echo -e "\n2. Startup with plugins:"
time nvim --headless -c "lua print('Plugins loaded')" -c "quit" 2>/dev/null

echo -e "\n3. Telescope test:"
time nvim --headless -c "lua print('Telescope available:', pcall(require, 'telescope'))" -c "quit" 2>/dev/null

echo -e "\n4. System info:"
echo "Neovim version: $(nvim --version | head -1)"
echo "LuaJIT: $(nvim --version | grep LuaJIT)"
echo "Build type: $(nvim --version | grep 'Build type')"

echo -e "\n5. Performance tips for remote development:"
echo "- Use this minimal config for remote work"
echo "- Consider using 'nvim --clean' for ultra-fast startup"
echo "- Monitor startup time with: time nvim --headless -c 'quit'"
echo "- Check if ripgrep is available: which rg"
echo "- Ensure tmux session is stable and not reconnecting" 
