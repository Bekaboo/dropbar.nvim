local M = {}

---@param sources dropbar_source_t[]
---@return dropbar_source_t
function M.fallback(sources)
  return {
    get_symbols = function(buf, win, cursor)
      for _, source in ipairs(sources) do
        local symbols = source.get_symbols(buf, win, cursor)
        if not vim.tbl_isempty(symbols) then
          return symbols
        end
      end
      return {}
    end,
  }
end

return M
