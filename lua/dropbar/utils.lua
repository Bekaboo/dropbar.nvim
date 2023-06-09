---@param win integer
---@generic T
---@param fn fun(...): T?
---@return T?
local function win_execute(win, fn, ...)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local cur_win = vim.api.nvim_get_current_win()
  vim.cmd('noautocmd silent keepjumps call win_gotoid(' .. win .. ')')
  local ret = { fn(...) }
  vim.cmd('noautocmd silent keepjumps call win_gotoid(' .. cur_win .. ')')
  return unpack(ret)
end

---Highlight text in buffer, clear previous highlight if any exists
---@param buf integer
---@param hlgroup string
---@param range dropbar_symbol_range_t?
local function hl_range_single(buf, hlgroup, range)
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
local function hl_line_single(buf, hlgroup, linenr)
  hl_range_single(buf, hlgroup, linenr and {
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

return {
  win_execute = win_execute,
  hl_range_single = hl_range_single,
  hl_line_single = hl_line_single,
}
