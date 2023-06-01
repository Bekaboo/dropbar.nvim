vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
  once = true,
  group = vim.api.nvim_create_augroup('DropBarSetup', {}),
  callback = function()
    require('dropbar').setup()
  end,
})
