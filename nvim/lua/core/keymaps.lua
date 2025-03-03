vim.g.mapleader = " "

-- normal
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<leader>t", ":!")
vim.keymap.set('n', '<c-u>', '<c-u>zz', {noremap = true})
vim.keymap.set('n', '<c-d>', '<c-d>zz', {noremap = true})
vim.keymap.set('n', '<leader>fq', ':q!<cr>', {noremap = true})

-- insert
vim.keymap.set('i', 'kj', '<ESC>', {noremap = true})
vim.keymap.set('i', '<c-n>', '<c-x><c-o>', {noremap = true})

-- telescope kms in plugins/telescope.lua
