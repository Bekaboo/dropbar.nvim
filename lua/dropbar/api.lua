local utils = require('dropbar.utils')
local M = {}

---@diagnostic disable
---Get the dropbar
---@param buf? integer
---@param win integer
---@return dropbar_t?
---@deprecated
function M.get_dropbar(buf, win)
  buf = buf or vim.api.nvim_win_get_buf(win)
  if rawget(_G.dropbar.bars, buf) then
    return rawget(_G.dropbar.bars[buf], win)
  end
end

---Get current dropbar
---@return dropbar_t?
---@deprecated
function M.get_current_dropbar()
  return M.get_dropbar(
    vim.api.nvim_get_current_buf(),
    vim.api.nvim_get_current_win()
  )
end

---Get dropbar menu
---@param win integer
---@return dropbar_menu_t?
---@deprecated
function M.get_dropbar_menu(win)
  return _G.dropbar.menus[win]
end

---Get current dropbar menu
---@return dropbar_menu_t?
---@deprecated
function M.get_current_dropbar_menu()
  return M.get_dropbar_menu(vim.api.nvim_get_current_win())
end
---@diagnostic enable

---Goto the start of context
---If `count` is 0, goto the start of current context, or the start at
---prev context if cursor is already at the start of current context;
---If `count` is positive, goto the start of `count` prev context
---@param count integer? default vim.v.count
---@return nil
function M.goto_context_start(count)
  count = count or vim.v.count
  local bar = utils.bar.get_current()
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
  current_sym:jump(false)
end

---Open the menu of current context to select the next context
---@return nil
function M.select_next_context()
  local bar = utils.bar.get_current()
  if not bar or not bar.components or vim.tbl_isempty(bar.components) then
    return
  end
  bar:pick_mode_wrap(function()
    bar.components[#bar.components]:on_click()
  end)
end

---Pick a component from current dropbar
---@param idx integer?
---@return nil
function M.pick(idx)
  local bar = utils.bar.get_current()
  if bar then
    bar:pick(idx)
  end
end

---Toggle fuzzy finding in current dropbar menu
---@param opts table? fuzzy find options, ignored if closing fuzzy find
---@return nil
function M.fuzzy_find_toggle(opts)
  local menu = utils.menu.get_current()
  if not menu then
    return
  end
  if menu.fzf_state then
    menu:fuzzy_find_close()
  else
    menu:fuzzy_find_open(opts)
  end
end

---Click on the currently selected fuzzy find menu entry, choosing the component
---to click according to `component`.
---
---If `component` is a `number`, the `component`-nth symbol is selected, unless
---`0` or `-1` is supplied, in which case the *first* or *last* clickable component
---is selected, respectively. If it is a `function`, it receives the `dropbar_menu_entry_t`
---as an argument and should return the `dropbar_symbol_t` that is to be clicked.
---@param component? integer|dropbar_symbol_t|fun(entry: dropbar_menu_entry_t):dropbar_symbol_t?
---@return nil
function M.fuzzy_find_click(component)
  local menu = utils.menu.get_current()
  if not menu or not menu.fzf_state then
    return
  end
  menu:fuzzy_find_click_on_entry(component)
end

---Navigate to the nth entry above/below in the menu while fuzzy finding
---@param direction 'up'|'down'|integer Direction to negative to:
--- - 'up':             navigate one entry upwards
--- - 'down':           navigate one entry downwards
--- - positive integer: navigate to the {direction}-th next entry
--- - negative integer: navigate to the {direction}-th previous entry
---@return nil
function M.fuzzy_find_navigate(direction)
  local menu = utils.menu.get_current()
  if not menu or not menu.fzf_state then
    return
  end
  menu:fuzzy_find_navigate(direction)
end

---Navigate to the previous entry in the menu while fuzzy finding
---@return nil
function M.fuzzy_find_prev()
  M.fuzzy_find_navigate(-1)
end

---Navigate to the next entry in the menu while fuzzy finding
---@return nil
function M.fuzzy_find_next()
  M.fuzzy_find_navigate(1)
end

return M
