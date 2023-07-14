---@class dropbar_source_t
---@field get_symbols fun(buf: integer, win: integer, cursor: integer[], opts: table<string, any>?): dropbar_symbol_t[]

local notified = false

---For backword compatibility
---@param get_symbols fun(buf: integer, win: integer, cursor: integer[], opts: table<string, any>?): dropbar_symbol_t[]
---@return dropbar_symbol_t[]
local function check_params(get_symbols, buf, win, cursor, opts)
  if
    type(buf) ~= 'number'
    or type(win) ~= 'number'
    or type(cursor) ~= 'table'
    or opts ~= nil and type(opts) ~= 'table'
  then
    if not notified then
      vim.api.nvim_echo({
        { '[dropbar.nvim] ', 'Normal' },
        { 'get_symbols() now accepts three to four parameters: ', 'Normal' },
        { '{buf}, ', 'Normal' },
        { '{win}, ', 'WarningMsg' },
        { '{cursor}, ', 'Normal' },
        { '{opts}? ', 'MoreMsg' },
        { 'instead of two parameters: ', 'Normal' },
        { '{buf}, ', 'Normal' },
        { '{cursor}', 'Normal' },
        { '.\n', 'Normal' },
      }, true, {})
      notified = true
    end
    return {}
  end
  return get_symbols(buf, win, cursor, opts)
end

---@type table<string, dropbar_source_t>
return setmetatable({}, {
  __index = function(self, key)
    local source = require('dropbar.sources.' .. key)
    local _get_symbols = source.get_symbols
    source.get_symbols = function(buf, win, cursor, opts)
      return check_params(_get_symbols, buf, win, cursor, opts)
    end
    self[key] = source
    return source
  end,
})
