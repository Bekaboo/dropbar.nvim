local M = {}

---Add highlight to a string
---@param str string
---@param hlgroup string?
---@return string
function M.hl(str, hlgroup)
  if not hlgroup then
    return str
  end
  return string.format('%%#%s#%s%%*', hlgroup, str or '')
end

---Make a dropbar string clickable
---@param str string
---@param callback string
---@return string
function M.make_clickable(str, callback)
  return string.format('%%@%s@%s%%X', callback, str)
end

---Get dropbar
--- - If only `opts.win` is specified, return the dropbar attached the window;
--- - If only `opts.buf` is specified, return all dropbars attached the buffer;
--- - If both `opts.win` and `opts.buf` are specified, return the dropbar attached
---   the window that contains the buffer;
--- - If neither `opts.win` nor `opts.buf` is specified, return all dropbars
---   in the form of `table<buf, table<win, dropbar_t>>`
---@param opts {win: integer?, buf: integer?}?
---@return (dropbar_t?)|table<integer, dropbar_t>|table<integer, table<integer, dropbar_t>>
function M.get(opts)
  opts = opts or {}
  if opts.buf then
    if opts.win then
      return rawget(_G.dropbar.bars, opts.buf)
        and rawget(_G.dropbar.bars[opts.buf], opts.win)
    end
    return rawget(_G.dropbar.bars, opts.buf) or {}
  end
  if opts.win then
    if not vim.api.nvim_win_is_valid(opts.win) then
      return
    end
    local buf = vim.api.nvim_win_get_buf(opts.win)
    return rawget(_G.dropbar.bars, buf)
      and rawget(_G.dropbar.bars[buf], opts.win)
  end
  return _G.dropbar.bars
end

---Get current dropbar
---@return dropbar_t?
function M.get_current()
  return M.get({ win = vim.api.nvim_get_current_win() })
end

---Call method on dropbar(s) given the window id and/or buffer number the
---dropbar(s) attached to
--- - If only `opts.win` is specified, call the dropbar attached the window;
--- - If only `opts.buf` is specified, call all dropbars attached the buffer;
--- - If both `opts.win` and `opts.buf` are specified, call the dropbar attached
---   the window that contains the buffer;
--- - If neither `opts.win` nor `opts.buf` is specified, call all dropbars
--- - `opts.params` specifies params passed to the method
---@param method string
---@param opts {win: integer?, buf: integer?, params: table?}?
---@return any?: return values of the method
function M.exec(method, opts)
  opts = opts or {}
  opts.params = opts.params or {}
  local dropbars = M.get(opts)
  if not dropbars or vim.tbl_isempty(dropbars) then
    return
  end
  if opts.win then
    return dropbars[method](dropbars, unpack(opts.params))
  end
  if opts.buf then
    local results = {}
    for _, dropbar in pairs(dropbars) do
      table.insert(results, {
        dropbar[method](dropbar, unpack(opts.params)),
      })
    end
    return results
  end
  local results = {}
  for _, buf_dropbars in pairs(dropbars) do
    for _, dropbar in pairs(buf_dropbars) do
      table.insert(results, {
        dropbar[method](dropbar, unpack(opts.params)),
      })
    end
  end
  return results
end

---@type dropbar_t?
local last_hovered_dropbar = nil

---Update dropbar hover highlights given the mouse position
---@param mouse table
---@return nil
function M.update_hover_hl(mouse)
  local dropbar = M.get({ win = mouse.winid })
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

---Attach dropbar to window
---@param win integer?
---@param buf integer?
---@param info table? info from autocmd
function M.attach(buf, win, info)
  local configs = require('dropbar.configs')
  if configs.eval(configs.opts.bar.enable, buf, win, info) then
    vim.wo[win][0].winbar = '%{%v:lua.dropbar()%}'
  end
end

---Set min widths for dropbar symbols
---@param symbols dropbar_symbol_t[]
---@param min_widths integer[]
function M.set_min_widths(symbols, min_widths)
  for i, w in ipairs(min_widths) do
    if i > #symbols then
      break
    end
    symbols[#symbols - i + 1].min_width = w
  end
end

return M
