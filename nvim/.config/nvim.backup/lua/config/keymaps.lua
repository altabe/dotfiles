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
-- splits
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
-- the following keys are not relevant since I mapped C-j and C-k to C-n and C-p respectively at the terminal level in kitty.conf
-- vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
-- vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

---- editing
-- duplicating
vim.keymap.set({ "n" }, "<Leader>j", ":co.<CR>", { desc = "duplicate line down" })
vim.keymap.set({ "v" }, "<Leader>j", '"jy`]"jp', { desc = "duplicate selection down" })
vim.keymap.set({ "n" }, "<Leader>k", ":co-1<CR>", { desc = "duplicate line up" })
vim.keymap.set({ "v" }, "<Leader>k", '"ky`["kP', { desc = "duplicate selection up" })
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
-- comments
-- vim.keymap.set({ "n" }, "gc", "gcc", {desc = "toggle comment", noremap=false})


---- yanking
-- registers
vim.keymap.set({ "n", "v" }, "c", '"cc')
vim.keymap.set({ "n", "v" }, "C", '"c')
vim.keymap.set({ "n", "v" }, "d", '"dd')
vim.keymap.set({ "n", "v" }, "D", '"d')
vim.keymap.set({ "n", "v" }, "x", '"xx')
vim.keymap.set({ "n", "v" }, "X", '"x')

---------- UI ----------
vim.keymap.set(
  'n',
  '<leader>ud',
  function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  end,
  { silent = true, noremap = true, desc = "[U]I Toggle [D]iagnostics"}
)

---------- Plugins ----------

-- fzf lua
vim.keymap.set({ "n", "v" }, "<leader>p", "<cmd>FzfLua files<cr>", { desc = "find files" })

-- nvim-tree
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer" })
-- vim.keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>", {desc = "Toggle file explorer on current file"})
-- vim.keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", {desc = "Collapse file explorer"})
-- vim.keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", {desc = "Refresh file explorer"})

---------- Kickstarter imports ----------

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
