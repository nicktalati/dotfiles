-- run python
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  callback = function()
    if vim.env.VIRTUAL_ENV then
      vim.api.nvim_buf_set_keymap(0, 'n', '<C-M>', ':w<CR>:!' .. vim.env.VIRTUAL_ENV .. '/bin/python %<CR>', {noremap = true})
    else
      vim.api.nvim_buf_set_keymap(0, 'n', '<C-M>', ':w<CR>:!python %<CR>', {noremap = true})
    end
  end,
})

-- run lean
vim.api.nvim_create_autocmd('FileType', {
  pattern = "*.lean",
  callback = function()
    vim.api.nvim_buf_set_keymap(0, 'n', '<C-M>', ':w<CR>:!lean %<CR>', {noremap = true})
  end,
})

-- run mojo as python?
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = "*.mojo",
  command = "set filetype=python",
})

-- detect sql
vim.api.nvim_create_autocmd({"BufEnter"}, {
  pattern = "*",
  callback = function()
    local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    if first_line and first_line:match("^-%[ RECORD 1 %]-------------------------") then
      vim.bo.filetype = 'sql_records'
    end
  end,
})
