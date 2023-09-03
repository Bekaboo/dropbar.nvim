local initialized
local configs

local function init()
  initialized = true
  configs = require('dropbar.configs')
end

local function buf_info(buf)
  local icon = configs.opts.sources.terminal.icon
  if type(icon) == 'function' then
    icon = icon(buf)
  end
  local name = configs.opts.sources.terminal.name
  if type(name) == 'function' then
    name = name(buf)
  end
  return {
    icon = icon,
    name = name,
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
      return require('dropbar.menu').dropbar_menu_entry_t:new({
        components = {
          require('dropbar.bar').dropbar_symbol_t:new(entry),
        },
      })
    end)
    :totable()
end

local function get_symbols(buf, win)
  if not initialized then
    init()
  end

  local symbol = buf_info(buf)
  symbol.on_click = function(self)
    local entries = get_menu_entries(self)
    if #entries > 0 then
      self.menu = require('dropbar.menu').dropbar_menu_t:new({
        entries = entries,
        prev_win = self.bar.win,
      })
      self.menu:open({
        win_configs = {
          win = win,
          col = function(menu)
            if menu.prev_menu then
              return menu.prev_menu._win_configs.width
            end
            local mouse = vim.fn.getmousepos()
            local bar = require('dropbar.api').get_dropbar(
              vim.api.nvim_win_get_buf(menu.prev_win),
              menu.prev_win
            )
            if not bar then
              return 0
            end
            local _, range =
              bar:get_component_at(math.max(0, mouse.wincol - 1))
            return range and range.start or 0
          end,
        },
      })
    end
  end

  return {
    require('dropbar.bar').dropbar_symbol_t:new(symbol),
  }
end

return { get_symbols = get_symbols }
