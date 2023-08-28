---Get the dropbar
---@param buf? integer
---@param win integer
---@return dropbar_t?
---@deprecated
local function get_dropbar(buf, win)
  buf = buf or vim.api.nvim_win_get_buf(win)
  if rawget(_G.dropbar.bars, buf) then
    return rawget(_G.dropbar.bars[buf], win)
  end
end

---Get current dropbar
---@return dropbar_t?
---@deprecated
local function get_current_dropbar()
  return get_dropbar(
    vim.api.nvim_get_current_buf(),
    vim.api.nvim_get_current_win()
  )
end

---Get dropbar menu
---@param win integer
---@return dropbar_menu_t?
---@deprecated
local function get_dropbar_menu(win)
  return _G.dropbar.menus[win]
end

---Get current dropbar menu
---@return dropbar_menu_t?
---@deprecated
local function get_current_dropbar_menu()
  return get_dropbar_menu(vim.api.nvim_get_current_win())
end

---Goto the start of context
---If `count` is 0, goto the start of current context, or the start at
---prev context if cursor is already at the start of current context;
---If `count` is positive, goto the start of `count` prev context
---@param count integer? default vim.v.count
local function goto_context_start(count)
  count = count or vim.v.count
  local bar = get_current_dropbar()
  if not bar or not bar.components or vim.tbl_isempty(bar.components) then
    return
  end
  local current_sym = bar.components[#bar.components]
  if not current_sym.range then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  if
    count == 0
    and current_sym.range.start.line == cursor[1] - 1
    and current_sym.range.start.character == cursor[2]
  then
    count = count + 1
  end
  while count > 0 do
    count = count - 1
    local prev_sym = bar.components[current_sym.bar_idx - 1]
    if not prev_sym or not prev_sym.range then
      break
    end
    current_sym = prev_sym
  end
  current_sym:jump()
end

---Open the menu of current context to select the next context
local function select_next_context()
  local bar = get_current_dropbar()
  if not bar or not bar.components or vim.tbl_isempty(bar.components) then
    return
  end
  bar:pick_mode_wrap(function()
    bar.components[#bar.components]:on_click()
  end)
end

---Pick a component from current dropbar
---@param idx integer?
local function pick(idx)
  local bar = get_current_dropbar()
  if bar then
    bar:pick(idx)
  end
end

return {
  get_dropbar = get_dropbar,
  get_current_dropbar = get_current_dropbar,
  get_dropbar_menu = get_dropbar_menu,
  get_current_dropbar_menu = get_current_dropbar_menu,
  goto_context_start = goto_context_start,
  select_next_context = select_next_context,
  pick = pick,
}
