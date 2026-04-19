return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      filetypes = {
        ["*"] = true,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          -- Tab is handled in nvim-cmp config to avoid conflicts
          accept = false,
          accept_word = "<M-Right>",
          accept_line = "<M-Down>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
          trigger = "<C-\\>",
        },
      },
      panel = {
        enabled = false,
      },
    })
  end,
}
