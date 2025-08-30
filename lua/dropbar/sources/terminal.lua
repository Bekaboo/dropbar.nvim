local bar = require('dropbar.bar')
local configs = require('dropbar.configs')

---@param buf integer buffer handler
---@return dropbar_symbol_opts_t
local function buf_info(buf)
  return {
    icon = configs.eval(configs.opts.sources.terminal.icon, buf),
    name = configs.eval(configs.opts.sources.terminal.name, buf),
    icon_hl = 'DropBarIconKindTerminal',
    name_hl = 'DropBarKindTerminal',
  }
end

---@param buf integer buffer handler
---@return dropbar_symbol_t[]
local function get_symbols(buf)
  buf = vim._resolve_bufnr(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return {}
  end

  local current = buf_info(buf)
  current.siblings = vim
    .iter(vim.api.nvim_list_bufs())
    :filter(function(b)
      return vim.bo[b].buftype == 'terminal'
    end)
    :enumerate()
    :map(function(i, b)
      local is_current = b == buf
      local entry = is_current and current or buf_info(b)
      entry.jump = function()
        vim.api.nvim_win_set_buf(current.bar.win, b)
      end
      entry.sibling_idx = i
      if is_current and not configs.opts.sources.terminal.show_current then
        return
      end
      return bar.dropbar_symbol_t:new(entry)
    end)
    :totable()

  return { bar.dropbar_symbol_t:new(current) }
end

return { get_symbols = get_symbols }
