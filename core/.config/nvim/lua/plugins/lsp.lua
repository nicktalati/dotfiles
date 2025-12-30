return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  config = function() 
    vim.lsp.config["pylsp"] = {
      settings = {
        pylsp = {
          plugins = {
            pylsp_mypy = { enabled = true, live_mode = true },
          }
        }
      }
    }
    vim.lsp.enable("pylsp")
    vim.lsp.enable("sqlls")
    vim.lsp.enable("ts_ls")
    vim.lsp.enable("lua_ls")
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        local opts = { buffer = ev.buf }

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "grw", vim.diagnostic.open_float, opts)
      end
    })
  end
}
