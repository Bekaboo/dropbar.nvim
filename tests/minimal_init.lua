vim.o.swapfile = false

vim.opt.rtp:prepend('.')
vim.opt.rtp:prepend('deps/plenary.nvim')
vim.opt.rtp:prepend('deps/telescope-fzf-native.nvim')

dofile('tests/utils.lua')
require('dropbar').setup()
