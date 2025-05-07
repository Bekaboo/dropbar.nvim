vim.o.swapfile = false

vim.opt.rtp:prepend('.')
vim.opt.rtp:prepend('../plenary.nvim')
vim.opt.rtp:prepend('../telescope-fzf-native.nvim')

dofile('tests/utils.lua')
require('dropbar').setup()
