vim.api.nvim_create_autocmd('FileType', {
  once = true,
  group = vim.api.nvim_create_augroup('DropBarSetup', {}),
  callback = function()
    if vim.g.loaded_dropbar then
      return
    end
    require('dropbar').setup()
  end,
})
