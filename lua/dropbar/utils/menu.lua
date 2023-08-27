local M = {}

---Get dropbar menu
--- - If `opts.win` is specified, return the dropbar menu attached the window;
--- - If `opts.win` is not specified, return all opened dropbar menus
---@param opts {win: integer?}?
---@return (dropbar_menu_t?)|table<integer, dropbar_menu_t>
function M.get(opts)
  opts = opts or {}
  if opts.win then
    return _G.dropbar.menus[opts.win]
  end
  return _G.dropbar.menus
end

---Get current menu
---@return dropbar_menu_t?
function M.get_current()
  return M.get({ win = vim.api.nvim_get_current_win() })
end

---Call method on dropbar menu(s) given the window id
--- - If `opts.win` is specified, call the dropbar menu with the window id;
--- - If `opts.win` is not specified, call all opened dropbars
--- - `opts.params` specifies params passed to the method
---@param method string
---@param opts {win: integer?, params: table?}?
---@return any?: return values of the method
function M.exec(method, opts)
  opts = opts or {}
  opts.params = opts.params or {}
  local menus = M.get(opts)
  if not menus or vim.tbl_isempty(menus) then
    return
  end
  if opts.win then
    return menus[method](menus, unpack(opts.params))
  end
  local results = {}
  for _, menu in pairs(menus) do
    table.insert(results, {
      menu[method](menu, opts.params),
    })
  end
  return results
end

return M
