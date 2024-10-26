local bar = require('dropbar.bar')
local configs = require('dropbar.configs')

---@param buf integer buffer handler
---@return dropbar_symbol_opts_t
local function buf_info(buf)
  return {
    icon = configs.opts.icons.enable
      and configs.eval(configs.opts.sources.terminal.icon, buf),
    name = configs.eval(configs.opts.sources.terminal.name, buf),
    icon_hl = 'DropBarIconKindTerminal',
    name_hl = 'DropBarKindTerminal',
  }
end

---@param bar_buf integer buffer handler
---@return dropbar_symbol_t[]
local function get_symbols(bar_buf)
  local current = buf_info(bar_buf)
  current.siblings = vim
    .iter(vim.api.nvim_list_bufs())
    :filter(function(buf)
      return vim.bo[buf].buftype == 'terminal'
    end)
    :enumerate()
    :map(function(i, buf)
      local is_current = buf == bar_buf
      local entry = is_current and current or buf_info(buf)
      entry.jump = function()
        vim.api.nvim_win_set_buf(current.bar.win, buf)
      end
      entry.sibling_idx = i
      if is_current and not configs.opts.sources.terminal.show_current then
        return
      end
      return bar.dropbar_symbol_t:new(entry)
    end)
    :totable()

  current = bar.dropbar_symbol_t:new(current)

  return { current }
end

return { get_symbols = get_symbols }
