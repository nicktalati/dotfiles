-- lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  -- treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("plugins.treesitter")
    end
  },
  
  -- python indentation
  {
    "Vimjas/vim-python-pep8-indent"
  },
  
  -- telescope
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.6',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require("plugins.telescope")
    end
  },
  
  -- theme
  {
    "EdenEast/nightfox.nvim",
    config = function() 
      vim.cmd("colorscheme carbonfox")
    end
  },
  
  -- LSP
  {
    'neovim/nvim-lspconfig',
    config = function()
      require("plugins.lsp")
    end
  },
}

require("lazy").setup(plugins)
