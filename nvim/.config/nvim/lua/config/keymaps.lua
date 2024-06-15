-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vim.keymap.set("n", "<leader>e", "<cmd>echo 'hi'<CR>")

-- Function to map keys in multiple modes
local function map_key(modes, lhs, rhs, opts)
  opts = opts or { noremap = true, silent = true }
  for _, mode in ipairs(modes) do
    vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
  end
end

-- Handling splits
-- switch
map_key({ "n", "v" }, "<Leader>wh", ":wincmd h<CR>")
map_key({ "n", "v" }, "<Leader>wj", ":wincmd j<CR>")
map_key({ "n", "v" }, "<Leader>wk", ":wincmd k<CR>")
map_key({ "n", "v" }, "<Leader>wl", ":wincmd l<CR>")
-- close
map_key({ "n", "v" }, "<Leader>wq", ":wincmd q<CR>")
