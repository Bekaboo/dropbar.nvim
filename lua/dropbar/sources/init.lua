---@class dropbar_source_t
---@field get_symbols fun(buf: integer, cursor: integer[]): dropbar_symbol_t[]

---@type table<string, dropbar_source_t>
return setmetatable({}, {
  __index = function(self, key)
    local ok, source = pcall(require, 'dropbar.sources.' .. key)
    if ok then
      self[key] = source
      return source
    end
    return nil
  end,
})
