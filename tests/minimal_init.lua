vim.opt.rtp:prepend('.')

local data_path = vim.fn.stdpath('data') --[[@as string]]
local parent_path = vim.fn.fnamemodify('..', ':p')

---Add plugin with given name to nvim runtime path
---@param name string
local function add_to_rtp(name)
  local plugin_path = unpack(vim.fs.find(name, { path = data_path }))
    or unpack(vim.fs.find(name, { path = parent_path }))

  if plugin_path then
    vim.opt.rtp:prepend(plugin_path)
  else
    error(string.format('%s not found', name))
  end
end

add_to_rtp('plenary.nvim')
add_to_rtp('telescope-fzf-native.nvim')

vim.cmd.luafile('tests/utils.lua')
require('dropbar').setup()

vim.o.swapfile = false
