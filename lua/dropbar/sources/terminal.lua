local bar = require('dropbar.bar')
local menu = require('dropbar.menu')
local configs = require('dropbar.configs')
local utils = require('dropbar.utils')

---@param buf integer buffer handler
---@return dropbar_symbol_opts_t
local function buf_info(buf)
  return {
    icon = configs.eval(configs.opts.sources.terminal.icon, buf),
    name = configs.eval(configs.opts.sources.terminal.name, buf),
    icon_hl = 'DropBarIconKindTerminal',
  }
end

---@param sym dropbar_symbol_t
---@return dropbar_menu_entry_t[]
local function get_menu_entries(sym)
  return vim
    .iter(vim.api.nvim_list_bufs())
    :filter(function(buf)
      return vim.bo[buf].buftype == 'terminal'
        and (buf ~= sym.bar.buf or configs.opts.sources.terminal.show_current)
    end)
    :map(function(buf)
      local entry = buf_info(buf)
      entry.on_click = function()
        vim.api.nvim_win_set_buf(sym.bar.win, buf)
        sym.menu:close(true)
      end
      return menu.dropbar_menu_entry_t:new({
        components = {
          bar.dropbar_symbol_t:new(entry),
        },
      })
    end)
    :totable()
end

---@param buf integer buffer handler
---@param win integer window handler
---@return dropbar_symbol_t[]
local function get_symbols(buf, win)
  local symbol = buf_info(buf)
  ---@param self dropbar_symbol_t
  symbol.on_click = function(self)
    local entries = get_menu_entries(self)
    if #entries > 0 then
      self.menu = menu.dropbar_menu_t:new({
        entries = entries,
        prev_win = self.bar.win,
      })
      self.menu:open({
        win_configs = {
          win = win,
          col = function(this)
            if this.prev_menu then
              return this.prev_menu._win_configs.width
            end
            local mouse = vim.fn.getmousepos()
            local winbar = utils.bar.get({ win = this.prev_win })
            if not winbar then
              return 0
            end
            local _, range =
              winbar:get_component_at(math.max(0, mouse.wincol - 1))
            return range and range.start or 0
          end,
        },
      })
    end
  end

  return { bar.dropbar_symbol_t:new(symbol) }
end

return { get_symbols = get_symbols }
