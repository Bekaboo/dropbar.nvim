if 1 ~= vim.fn.has('nvim-0.10.0') then
  vim.api.nvim_err_writeln('dropbar.nvim requires at least nvim-0.10.0')
  return
end

vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
  once = true,
  group = vim.api.nvim_create_augroup('DropBarSetup', {}),
  callback = function()
    require('dropbar').setup()
  end,
})
