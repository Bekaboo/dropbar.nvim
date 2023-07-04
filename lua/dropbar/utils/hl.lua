local M = {}

---Highlight text in buffer, clear previous highlight if any exists
---@param buf integer
---@param hlgroup string
---@param range dropbar_symbol_range_t?
function M.range_single(buf, hlgroup, range)
  local ns = vim.api.nvim_create_namespace(hlgroup)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if range then
    for linenr = range.start.line, range['end'].line do
      local start_col = linenr == range.start.line and range.start.character
        or 0
      local end_col = linenr == range['end'].line and range['end'].character
        or -1
      vim.api.nvim_buf_add_highlight(
        buf,
        ns,
        hlgroup,
        linenr,
        start_col,
        end_col
      )
    end
  end
end

---Highlight a line in buffer, clear previous highlight if any exists
---@param buf integer
---@param hlgroup string
---@param linenr integer? 1-indexed line number
function M.line_single(buf, hlgroup, linenr)
  M.range_single(buf, hlgroup, linenr and {
    start = {
      line = linenr - 1,
      character = 0,
    },
    ['end'] = {
      line = linenr - 1,
      character = -1,
    },
  })
end

---Merge highlight attributes, use values from the right most hl group
---if there are conflicts
---@vararg string highlight group names
---@return table merged highlight attributes
function M.merge(...)
  local hl_attr = vim.tbl_map(function(hl_name)
    return vim.api.nvim_get_hl(0, {
      name = hl_name,
      link = false,
    })
  end, { ... })
  return vim.tbl_extend('force', unpack(hl_attr))
end

return M
