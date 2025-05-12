---Sources providing symbol information for dropbars
---@class dropbar_source_t
---@field get_symbols fun(buf: integer, win: integer, cursor: integer[]): dropbar_symbol_t[] gets the symbols to show in the winbar given buffer number `buf`, window number `win`, and cursor position `cursor`

local notified = false

---For backword compatibility
---@param get_symbols fun(buf: integer, win: integer, cursor: integer[]): dropbar_symbol_t[]
---@return dropbar_symbol_t[]
---@nodoc
local function check_params(get_symbols, buf, win, cursor)
  if
    type(buf) ~= 'number'
    or type(win) ~= 'number'
    or type(cursor) ~= 'table'
  then
    if not notified then
      vim.api.nvim_echo({
        { '[dropbar.nvim] ', 'Normal' },
        { 'get_symbols() now accepts three parameters: ', 'Normal' },
        { '{buf}, ', 'Normal' },
        { '{win}, ', 'WarningMsg' },
        { '{cursor} ', 'Normal' },
        { 'instead of two parameters: ', 'Normal' },
        { '{buf}, ', 'Normal' },
        { '{cursor}', 'Normal' },
        { '.\n', 'Normal' },
      }, true, {})
      notified = true
    end
    return {}
  end
  return get_symbols(buf, win, cursor)
end

---@type table<string, dropbar_source_t>
return setmetatable({}, {
  __index = function(_, key)
    local source = require('dropbar.sources.' .. key)
    local _get_symbols = source.get_symbols
    source.get_symbols = function(buf, win, cursor)
      return check_params(_get_symbols, buf, win, cursor)
    end
    return source
  end,
})
