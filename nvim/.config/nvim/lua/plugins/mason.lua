return {
  { 
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  { 
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup()
      -- require("mason-lspconfig").setup({
      --   ensure_installed = { "basedpyright" }
      -- })
    end
  },
  { 
    "neovim/nvim-lspconfig",
    config = function()
      -- Setup LSP key mappings
      local on_attach = function(client, bufnr)
        local bufopts = { noremap = true, silent = true }
        
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', bufopts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', bufopts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', bufopts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', bufopts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', bufopts)
      end

      local lspconfig = require('lspconfig')
      lspconfig.basedpyright.setup{
        on_attach = on_attach,
      }
    end
  },
}

