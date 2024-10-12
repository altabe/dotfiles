vim.g.mapleader = " "

-- window management
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

vim.keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
vim.keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
vim.keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
vim.keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
vim.keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

---- navigation
-- line navigation
vim.keymap.set({ "n", "v", "o" }, "L", "$")
vim.keymap.set({ "n", "v", "o" }, "H", "^")
-- switch
vim.keymap.set({ "n", "v" }, "<Leader>wh", ":wincmd h<CR>")
vim.keymap.set({ "n", "v" }, "<Leader>wj", ":wincmd j<CR>")
vim.keymap.set({ "n", "v" }, "<Leader>wk", ":wincmd k<CR>")
vim.keymap.set({ "n", "v" }, "<Leader>wl", ":wincmd l<CR>")

---- editing
-- duplicating
vim.keymap.set({ "n" }, "<Leader>j", ":co.<CR>", { desc = "duplicate line down"})
vim.keymap.set({ "v" }, "<Leader>j", "\"jy`]\"jp", { desc = "duplicate selection down" })
vim.keymap.set({ "n" }, "<Leader>k", ":co-1<CR>", { desc = "duplicate line up" })
vim.keymap.set({ "v" }, "<Leader>k", "\"ky`[\"kP", { desc = "duplicate selection up" })
-- move
vim.keymap.set({ "n" }, "<A-j>", ":m+1<cr>")
vim.keymap.set({ "n" }, "<A-k>", ":m-2<cr>")
vim.keymap.set({ "i" }, "<A-j>", "<esc>:m +1<cr>==gi")
vim.keymap.set({ "i" }, "<A-k>", "<esc>:m -2<cr>==gi")
vim.keymap.set({ "v" }, "<A-j>", ":m '>+1<cr>gv=gv")
vim.keymap.set({ "v" }, "<A-k>", ":m '<-2<cr>gv=gv")
-- indent
vim.keymap.set({ "v" }, "<", "<gv")
vim.keymap.set({ "v" }, ">", ">gv")
vim.keymap.set({ "n" }, ">", ">>")
vim.keymap.set({ "n" }, "<", "<<")

---- yanking
-- registers
vim.keymap.set({ "n", "v" }, "c", "\"cc")
vim.keymap.set({ "n", "v" }, "C", "\"c")
vim.keymap.set({ "n", "v" }, "d", "\"dd")
vim.keymap.set({ "n", "v" }, "D", "\"d")
vim.keymap.set({ "n", "v" }, "x", "\"xx")
vim.keymap.set({ "n", "v" }, "X", "\"x")

---------- Plugins ----------

-- fzf lua
vim.keymap.set({"n", "v"}, "<leader>p", "<cmd>FzfLua files<cr>", { desc = "find files" })

-- nvim-tree
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeFindFileToggle<CR>", {desc = "Toggle file explorer"})
-- vim.keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>", {desc = "Toggle file explorer on current file"})
-- vim.keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", {desc = "Collapse file explorer"})
-- vim.keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", {desc = "Refresh file explorer"})
