vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function(args)
      vim.keymap.set("n", "<leader>r", ":w<CR>:!python %<CR>", { buffer = args.buf })
  end,
})
