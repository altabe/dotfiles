-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.relativenumber = true
opt.number = true

opt.scrolloff = 15

vim.g.autoformat = false

-- patch source: https://github.com/neovim/neovim/issues/28611#issuecomment-2147744670
function my_paste(reg)
    return function(lines)

        local content = vim.fn.getreg('"')
        return vim.split(content, '\n')
        
    end
end

if (os.getenv('SSH_TTY') == nil)
then
    opt.clipboard:append("unnamedplus")
else
    opt.clipboard:append("unnamedplus")
    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
        ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
      },
      paste = {
        ["+"] = my_paste("+"),
        ["*"] = my_paste("*"),
    },
}
end
-- patch end
