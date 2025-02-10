local M = {}

---Wrapper of nvim_get_hl(), but does not create a cleared highlight group
---if it doesn't exist
---NOTE: vim.api.nvim_get_hl() has a side effect, it will create a cleared
---highlight group if it doesn't exist, see
---https://github.com/neovim/neovim/issues/24583
---This affects regions highlighted by non-existing highlight groups in a
---winbar, which should falls back to the default 'WinBar' or 'WinBarNC'
---highlight groups but instead falls back to 'Normal' highlight group
---because of this side effect
---So we need to check if the highlight group exists before calling
---vim.api.nvim_get_hl()
---@param ns_id integer
---@param opts table{ name: string?, id: integer?, link: boolean? }
---@return table highlight attributes
function M.get_hl(ns_id, opts)
  if not opts.name then
    return vim.api.nvim_get_hl(ns_id, opts)
  end
  return vim.fn.hlexists(opts.name) == 1 and vim.api.nvim_get_hl(ns_id, opts)
    or {}
end

---Highlight text in buffer, clear previous highlight if any exists
---@param buf integer
---@param hlgroup string
---@param range dropbar_symbol_range_t?
function M.range_single(buf, hlgroup, range)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local ns = vim.api.nvim_create_namespace(hlgroup)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if range then
    vim.highlight.range(
      buf,
      ns,
      hlgroup,
      { range.start.line, range.start.character },
      { range['end'].line, range['end'].character },
      {}
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
---@vararg string highlight group names
---@return table merged highlight attributes
function M.merge(...)
  -- Eliminate nil values in vararg
  local hl_names = {}
  for _, hl_name in pairs({ ... }) do
    if hl_name then
      table.insert(hl_names, hl_name)
    end
  end
  local hl_attr = vim.tbl_map(function(hl_name)
    return M.get_hl(0, {
      name = hl_name,
      link = false,
    })
  end, hl_names)
  return vim.tbl_extend('force', unpack(hl_attr))
end

return M
