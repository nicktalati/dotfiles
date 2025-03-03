local lspconfig = require("lspconfig")
local util = require("lspconfig.util")

-- Common LSP on_attach function
local on_lsp_attach = function(client, bufnr)
  print("LSP started.")
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  local opts = {noremap=true, silent=true}
  local map = function(key, command)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', key, command, opts)
  end
  
  -- LSP keymaps
  map('gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>')
  map('gd', '<Cmd>lua vim.lsp.buf.definition()<CR>')
  map('K', '<Cmd>lua vim.lsp.buf.hover()<CR>')
  map('gi', '<Cmd>lua vim.lsp.buf.implementation()<CR>')
  map('<c-k>', '<Cmd> lua vim.lsp.buf.signature_help()<CR>')
  map('<leader>D', '<Cmd>lua vim.lsp.buf.type_definition()<CR>')
  map('gr', '<Cmd>lua vim.lsp.buf.references()<CR>')
  map('<leader>d', '<Cmd>lua vim.diagnostic.open_float()<CR>')
  map('[d', '<Cmd>lua vim.diagnostic.goto_prev()<CR>')
  map(']d', '<Cmd>lua vim.diagnostic.goto_next()<CR>')
  map('<leader>f', '<Cmd>lua vim.lsp.buf.formatting()<CR>')
  vim.api.nvim_buf_set_keymap(bufnr, 'i', '<c-k>', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
end

-- Configure LSP servers
-- Python LSP
lspconfig.pylsp.setup{
  on_attach = on_lsp_attach,
  cmd = {"pylsp", "-vvv", "--log-file", "/tmp/lsp.log"},
  settings = {
    pylsp = {
      plugins = {
        pylsp_mypy = {
          enabled = true,
          live_mode = true,
        },
      }
    },
  }
}

-- SQL LSP
lspconfig.sqlls.setup{
  on_attach = on_lsp_attach,
  cmd = {"sql-language-server", "up", "--method", "stdio"},
  filetypes = {"sql", "mysql"},
  root_dir = util.root_pattern(".sqllsrc.json")
}

-- TypeScript LSP
lspconfig.tsserver.setup{
  on_attach = on_lsp_attach,
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  init_options = {
    hostInfo = "neovim"
  }
}

-- Configure diagnostic display
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = true,
    signs = true,
    update_in_insert = true,
  }
)
