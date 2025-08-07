-- Minimal Neovim configuration for remote development
-- Plugin manager enabled with essential plugins for performance

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

-- Detect if we're in a remote environment
local is_remote = vim.env.SSH_CONNECTION ~= nil or vim.env.TMUX ~= nil

-- Performance optimizations for faster startup (especially for remote development)
vim.opt.updatetime = is_remote and 50 or 100 -- Even faster completion for remote
vim.opt.timeoutlen = is_remote and 200 or 300 -- Faster key sequences for remote
vim.opt.lazyredraw = true -- Don't redraw while executing macros
vim.opt.hidden = true -- Don't unload buffers when abandoned

-- Disable some features for faster startup
vim.opt.swapfile = false -- Don't create swap files
vim.opt.backup = false -- Don't create backup files
vim.opt.writebackup = false -- Don't create backup files before writing

-- Additional optimizations for remote development
vim.opt.shell = "zsh" -- Use zsh for better performance
vim.opt.shellcmdflag = "-c" -- Optimize shell command execution
vim.opt.shellquote = "" -- Reduce shell quoting overhead
vim.opt.shellxquote = "" -- Reduce shell quoting overhead

-- Disable features that can slow down remote development
vim.opt.mouse = "" -- Disable mouse (can be slow over remote)
vim.opt.cursorline = false -- Disable cursor line highlighting
vim.opt.cursorcolumn = false -- Disable cursor column highlighting
vim.opt.scrolloff = 0 -- Reduce scroll offset for faster rendering

-- Even more aggressive optimizations for remote environments
if is_remote then
  vim.opt.termguicolors = false -- Disable true color (can be slow over remote)
  vim.opt.lazyredraw = true -- Don't redraw during macro execution
  vim.opt.ttyfast = true -- Optimize for fast terminal connections
end

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
