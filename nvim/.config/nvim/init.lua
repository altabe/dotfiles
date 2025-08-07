-- Minimal Neovim configuration for remote development
-- Plugin manager enabled with essential plugins for performance

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

-- Performance optimizations for faster startup
vim.opt.updatetime = 100 -- Faster completion
vim.opt.timeoutlen = 300 -- Faster key sequence completion
vim.opt.lazyredraw = true -- Don't redraw while executing macros
vim.opt.hidden = true -- Don't unload buffers when abandoned

-- Disable some features for faster startup
vim.opt.swapfile = false -- Don't create swap files
vim.opt.backup = false -- Don't create backup files
vim.opt.writebackup = false -- Don't create backup files before writing

-- [[ Basic Autocommands ]]
-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Load configuration
require("config.options")
require("config.keymaps")
require("config.lazy") -- Plugin manager enabled with essential plugins

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
