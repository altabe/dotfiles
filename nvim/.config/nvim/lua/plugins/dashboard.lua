return {
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  -- enabled = false,
  config = function()
    local db = require('dashboard')
    db.setup({
      theme = 'doom',
      config = {
        header = {
          vim.fn.getcwd(),
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          "",
        },
        center = {
          {
            icon = '📁 ',
            icon_hl = 'Title',
            desc = 'Find File                               ',
            desc_hl = 'String',
            key = 'f',
            key_hl = 'Number',
            key_format = ' %s',
            action = 'Telescope fd',
          },
          {
            icon = '🔎 ',
            desc = 'Grep         ',
            desc_hl = 'String',
            key = 'g',
            key_format = ' %s',
            action = 'Telescope live_grep'
          },
          {
            icon = '🛠️ ',
            desc = 'Configure',
            desc_hl = 'String',
            key = 'c',
            key_format = ' %s',
            action = 'Telescope fd seach_dirs=~/.config/nvim/'
          },
          {
            icon = '❌ ',
            desc = 'quit',
            desc_hl = 'String',
            key = 'q',
            key_format = ' %s',
            action = 'q'
          },
        },
        footer = {}  --your footer
      }
    })
  end,
  dependencies = { {'nvim-tree/nvim-web-devicons'}}
}
