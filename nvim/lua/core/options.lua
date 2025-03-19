-- undo dir
local undodir = vim.fn.expand('~/.config/nvim/undo')
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, 'p')
end

-- osc 52
vim.opt.clipboard = "unnamedplus"
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

vim.o.undofile = true
vim.o.undodir = vim.fn.expand('~/.config/nvim/undo')
vim.o.undolevels = 10000
vim.o.hlsearch = false
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.completeopt = 'menu'

-- window
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.scrolloff = 8
vim.wo.wrap = false

-- tab
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- python sux
vim.g.python_recommended_style = 0
