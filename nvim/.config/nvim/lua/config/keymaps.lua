-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vim.keymap.set("n", "<leader>e", "<cmd>echo 'hi'<CR>")
-- vim.keymap.del('n', 's')
-- vim.api.nvim_set_keymap('n', 's', '<Nop>', { noremap = true, silent = true })

function handle_s_key()
  local next_key = vim.fn.getchar()
  local next_key_str = vim.fn.nr2char(next_key)
  local cmd_str = 'call feedkeys(\'s' .. next_key_str .. '\')'
  if next_key_str ~= "d" and next_key_str ~= "a" then
    return
  end
  vim.cmd(cmd_str)
end

-- Function to map keys in multiple modes
local function map_key(modes, lhs, rhs, opts, desc)
  desc = desc or ""
  opts = opts or { noremap = true, silent = true }
  opts["desc"] = desc
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

-- s hack
-- map_key({ "n" }, "s", ":lua handle_s_key()<CR>")
map_key({ "n" }, "s", ":lua handle_s_key()<CR>")

-- files
map_key({ "n", "v" }, "<Leader>F", "<Leader>fF", {noremap = false, silent = true})

---- navigation
map_key({ "n", "v", "o" }, "+", "$")
map_key({ "n", "v", "o" }, "_", "^")
map_key({ "v", "o" }, "L", "$")
map_key({ "v", "o" }, "H", "^")

-- refactor
-- I need to know how to ask for input from the use via a popup textbox like mini.surround "saf" action
-- map_key({ "n", "v" }, "<Leader>ce", "")

---- editing
-- duplicating
map_key({ "n" }, "<Leader>j", ":co.<CR>", nil, "duplicate line down")
map_key({ "v" }, "<Leader>j", "\"jy`]\"jp", nil, "duplicate selection down")
map_key({ "n" }, "<Leader>k", ":co-1<CR>", nil, "duplicate line up")
map_key({ "v" }, "<Leader>k", "\"ky`[\"kP", nil, "duplicate selection up")

---- yanking
-- registers
map_key({ "n", "v" }, "c", "\"cc")
map_key({ "n", "v" }, "C", "\"c")
map_key({ "n", "v" }, "d", "\"dd")
map_key({ "n", "v" }, "D", "\"d")
map_key({ "n", "v" }, "x", "\"xx")
map_key({ "n", "v" }, "X", "\"x")
map_key({ "v" }, "p", "P")
map_key({ "v" }, "P", "p")


------- dap
---vim.keymap.set('n', '<F5>', function() require('dap').continue() end)
---vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
---vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
---vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
---vim.keymap.set('n', '<Leader>B', function() require('dap').set_breakpoint() end)
---vim.keymap.set('n', '<Leader>lp', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
---vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.open() end)
---vim.keymap.set('n', '<Leader>dl', function() require('dap').run_last() end)
---vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
---  require('dap.ui.widgets').hover()
---end)
---vim.keymap.set({'n', 'v'}, '<Leader>dp', function()
---  require('dap.ui.widgets').preview()
---end)
---vim.keymap.set('n', '<Leader>df', function()
---  local widgets = require('dap.ui.widgets')
---  widgets.centered_float(widgets.frames)
---end)
---vim.keymap.set('n', '<Leader>ds', function()
---  local widgets = require('dap.ui.widgets')
---  widgets.centered_float(widgets.scopes)
---end)
---
