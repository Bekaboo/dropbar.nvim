vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile', 'BufWritePost' }, {
  once = true,
  group = vim.api.nvim_create_augroup('DropBarSetup', {}),
  callback = function()
    if vim.g.loaded_dropbar then
      return
    end
    require('dropbar').setup()
  end,
})
