local M = {}

---Get dropbar
---If only `opts.win` is specified, return the dropbar attached the window;
---If only `opts.buf` is specified, return all dropbars attached the buffer;
---If both `opts.win` and `opts.buf` are specified, return the dropbar attached
---the window that contains the buffer;
---If neither `opts.win` nor `opts.buf` is specified, return the dropbar
---attached the current window
---@param opts {win: integer?, buf: integer?}
---@return dropbar_t|dropbar_t[]?
function M.get_dropbar(opts)
  opts = opts or {}
  if opts.buf then
    if opts.win then
      return rawget(_G.dropbar.bars, opts.buf)
        and rawget(_G.dropbar.bars[opts.buf], opts.win)
    end
    return rawget(_G.dropbar.bars, opts.buf)
  end
  opts.win = opts.win or vim.api.nvim_get_current_win()
  opts.buf = vim.api.nvim_win_get_buf(opts.win)
  return rawget(_G.dropbar.bars, opts.buf)
    and rawget(_G.dropbar.bars[opts.buf], opts.win)
end

---@type dropbar_t?
local last_hovered_dropbar = nil

---Update dropbar hover highlights given the mouse position
---@param mouse table
---@return nil
function M.update_hover_hl(mouse)
  local dropbar = M.get_dropbar({ win = mouse.winid })
  if not dropbar or mouse.winrow ~= 1 or mouse.line ~= 0 then
    if last_hovered_dropbar then
      last_hovered_dropbar:update_hover_hl()
      last_hovered_dropbar = nil
    end
    return
  end
  if last_hovered_dropbar and last_hovered_dropbar ~= dropbar then
    last_hovered_dropbar:update_hover_hl()
  end
  dropbar:update_hover_hl(math.max(0, mouse.wincol - 1))
  last_hovered_dropbar = dropbar
end

return M
