local M = {}

---Highlight text in buffer, clear previous highlight if any exists
---@param buf integer
---@param hlgroup string
---@param range dropbar_symbol_range_t?
---@param priority integer?
function M.range_single(buf, hlgroup, range, priority)
  local ns = vim.api.nvim_create_namespace(hlgroup)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if range then
    local end_col = range['end'].character
    if end_col == -1 then
      end_col = 1
        + #vim.api.nvim_buf_get_lines(
          buf,
          range['end'].line,
          range['end'].line + 1,
          false
        )[1]
    end
    vim.highlight.range(
      buf,
      ns,
      hlgroup,
      { range.start.line, range.start.character },
      { range['end'].line, end_col },
      {
        priority = priority or vim.highlight.priorities.user + 1,
        inclusive = false,
      }
    )
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
---@vararg string|table highlight group names or attribute tables
---@return table merged highlight attributes
function M.merge(...)
  local hl_attr = vim.tbl_map(function(hl_info)
    if type(hl_info) == 'string' then
      return vim.api.nvim_get_hl(0, {
        name = hl_info,
        link = false,
      })
    end
    return hl_info
  end, { ... })
  return vim.tbl_extend('force', unpack(hl_attr))
end

return M
