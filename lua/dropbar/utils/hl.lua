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

---Convert `hl_info` to a normalized table of highlight attributes
---that can be used to create or merge highlight groups, following
---links if necessary, and optionally copy `hl_info` if it's a table
---@param hl_info string|table highlight group name or attribute table
---@param copy boolean? whether to copy `hl_info` if it's a table, default `false`
---@return table: normalized highlight attributes
function M.normalize(hl_info, copy)
  local hl_name = type(hl_info) == 'string' and hl_info or hl_info.link
  if hl_name then
    return vim.api.nvim_get_hl(0, {
      name = hl_name,
      link = false,
    })
  elseif copy then
    return vim.deepcopy(hl_info) ---@diagnostic disable-line: return-type-mismatch
  else
    return hl_info ---@diagnostic disable-line: return-type-mismatch
  end
end

---Get highlight attributes, ignoring those in `ignore`
---@param hl_info string|table highlight group name or attribute table
---@param ignore string[] highlight attributes to ignore
---@return table: highlight attributes
function M.without(hl_info, ignore)
  hl_info = M.normalize(hl_info, true) -- don't mutate hl_info
  for _, attr in ipairs(ignore) do
    hl_info[attr] = nil
  end
  return hl_info
end

---Merge highlight attributes, use values from the right most hl group
---if there are conflicts
---@vararg string|table highlight group names or attribute tables
---@return table merged highlight attributes
function M.merge(...)
  return vim.tbl_extend('force', unpack(vim.tbl_map(M.normalize, { ... })))
end

return M
