vim.opt.rtp:prepend('.')
vim.opt.rtp:prepend(
  unpack(vim.fs.find('plenary.nvim', { path = vim.fn.stdpath('data') }))
    or unpack(vim.fs.find('plenary.nvim', { path = vim.fs.normalize('..') }))
)
vim.cmd.luafile('tests/utils.lua')
require('dropbar').setup()
