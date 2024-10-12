vim.g.mapleader = " "

-- Function to map keys in multiple modes
local function map_key(modes, lhs, rhs, opts, desc)
  desc = desc or ""
  opts = opts or { noremap = true, silent = true }
  opts["desc"] = desc
  vim.keymap.set(modes, lhs, rhs, opts)
end

-- Handling splits
-- switch
map_key({ "n", "v" }, "<Leader>wh", ":wincmd h<CR>")
map_key({ "n", "v" }, "<Leader>wj", ":wincmd j<CR>")
map_key({ "n", "v" }, "<Leader>wk", ":wincmd k<CR>")
map_key({ "n", "v" }, "<Leader>wl", ":wincmd l<CR>")

-- window management
map_key("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
map_key("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
map_key("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
map_key("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

map_key("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
map_key("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
map_key("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
map_key("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
map_key("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

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

