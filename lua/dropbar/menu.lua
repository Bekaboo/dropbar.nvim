local bar = require('dropbar.bar')
local configs = require('dropbar.configs')
local groupid = vim.api.nvim_create_augroup('DropBarMenu', {})

---Lookup table for dropbar menus
---@type table<integer, dropbar_menu_t>
_G.dropbar.menus = {}

---@class dropbar_menu_hl_info_t
---@field start integer
---@field end integer
---@field hlgroup string
---@field ns integer? namespace id, nil if using default namespace

---@class dropbar_menu_entry_t
---@field separator dropbar_symbol_t
---@field padding {left: integer, right: integer}
---@field components dropbar_symbol_t[]
---@field menu dropbar_menu_t? the menu the entry belongs to
---@field idx integer? the index of the entry in the menu
local dropbar_menu_entry_t = {}
dropbar_menu_entry_t.__index = dropbar_menu_entry_t

---Create a dropbar menu entry instance
---@param opts dropbar_menu_entry_t?
---@return dropbar_menu_entry_t
function dropbar_menu_entry_t:new(opts)
  local entry = setmetatable(
    vim.tbl_deep_extend('force', {
      separator = bar.dropbar_symbol_t:new({
        icon = configs.opts.icons.ui.menu.separator,
        icon_hl = 'DropBarIconUISeparatorMenu',
      }),
      padding = configs.opts.menu.entry.padding,
      components = {},
    }, opts),
    self
  )
  for idx, component in ipairs(entry.components) do
    component.entry = entry
    component.entry_idx = idx
  end
  return entry
end

---Concatenate inside a dropbar menu entry to get the final string
---and highlight information of the entry
---@return string str
---@return dropbar_menu_hl_info_t[] hl_info
function dropbar_menu_entry_t:cat()
  local components_with_sep = {} ---@type dropbar_symbol_t[]
  for component_idx, component in ipairs(self.components) do
    if component_idx > 1 then
      table.insert(components_with_sep, self.separator)
    end
    table.insert(components_with_sep, component)
  end
  local str = ''
  local hl_info = {}
  for _, component in ipairs(components_with_sep) do
    if component.icon_hl then
      table.insert(hl_info, {
        start = #str,
        ['end'] = #str + #component.icon,
        hlgroup = component.icon_hl,
      })
    end
    if component.name_hl then
      table.insert(hl_info, {
        start = #str + #component.icon + 1,
        ['end'] = #str + #component.icon + #component.name + 1,
        hlgroup = component.name_hl,
      })
    end
    str = str .. component:cat(true)
  end
  return string.rep(' ', self.padding.left) .. str .. string.rep(
    ' ',
    self.padding.right
  ),
    hl_info
end

---Get the display length of the dropbar menu entry
---@return integer
function dropbar_menu_entry_t:displaywidth()
  return vim.fn.strdisplaywidth((self:cat()))
end

---Get the byte length of the dropbar menu entry
---@return integer
function dropbar_menu_entry_t:bytewidth()
  return #(self:cat())
end

---Get the first clickable component in the dropbar menu entry
---@param offset integer? offset from the beginning of the entry, default 0
---@return dropbar_symbol_t?
function dropbar_menu_entry_t:first_clickable(offset)
  offset = offset or 0
  for _, component in ipairs(self.components) do
    offset = offset - component:bytewidth()
    if offset <= 0 and component.on_click then
      return component
    end
  end
end

---@class dropbar_menu_opts_t
---@field is_opened boolean?
---@field entries dropbar_menu_entry_t[]?
---@field win_configs table? window configuration
---@field cursor integer[]? initial cursor position
---@field prev_win integer? previous window

---@class dropbar_menu_t
---@field is_opened boolean?
---@field entries dropbar_menu_entry_t[]
---@field win_configs table window configuration, value can be a function
---@field _win_configs table evaluated window configuration
---@field cursor integer[]? initial cursor position
---@field prev_win integer? previous window, assigned when calling new() or automatically determined in open()
---@field sub_menu dropbar_menu_t? submenu, assigned when calling new() or automatically determined when a new menu opens
---@field parent_menu dropbar_menu_t? parent menu, assigned when calling new() or automatically determined in open()
---@field clicked_at integer[]? last position where the menu was clicked
local dropbar_menu_t = {}
dropbar_menu_t.__index = dropbar_menu_t

---Create a dropbar menu instance
---@param opts dropbar_menu_opts_t?
---@return dropbar_menu_t
function dropbar_menu_t:new(opts)
  local dropbar_menu = setmetatable(
    vim.tbl_deep_extend('force', {
      entries = {},
      win_configs = configs.opts.menu.win_configs,
    }, opts or {}),
    dropbar_menu_t
  )
  for idx, entry in ipairs(dropbar_menu.entries) do
    entry.menu = dropbar_menu
    entry.idx = idx
  end
  return dropbar_menu
end

---Delete a dropbar menu
---@return nil
function dropbar_menu_t:del()
  if self.sub_menu then
    self.sub_menu:del()
    self.sub_menu = nil
  end
  self:close()
  if self.buf then
    vim.api.nvim_buf_delete(self.buf, {})
    self.buf = nil
  end
  if self.win then
    _G.dropbar.menus[self.win] = nil
  end
end

---Evaluate window configurations
---Side effects: update self._win_configs
---@return nil
---@see vim.api.nvim_open_win
function dropbar_menu_t:eval_win_config()
  -- Evaluate function-valued window configurations
  self._win_configs = {}
  for k, config in pairs(self.win_configs) do
    if type(config) == 'function' then
      self._win_configs[k] = config(self)
    else
      self._win_configs[k] = config
    end
  end
end

---Get the component at the given position in the dropbar menu
---@param pos integer[] {row: integer, col: integer}, 1-indexed, byte-indexed
---@return dropbar_symbol_t?
function dropbar_menu_t:get_component_at(pos)
  if not self.entries or vim.tbl_isempty(self.entries) then
    return nil
  end
  local row = pos[1]
  local col = pos[2]
  local entry = self.entries[row]
  if not entry or not entry.components then
    return nil
  end
  local col_offset = entry.padding.left
  for _, component in ipairs(entry.components) do
    local component_len = component:bytewidth()
    if col <= col_offset + component_len then -- Look-ahead
      return component
    end
    col_offset = col_offset + component_len
  end
  return nil
end

---"Click" the component at the given position in the dropbar menu
---Side effects: update self.clicked_at
---@param pos integer[] {row: integer, col: integer}, 1-indexed
---@param min_width integer?
---@param n_clicks integer?
---@param button string?
---@param modifiers string?
function dropbar_menu_t:click_at(pos, min_width, n_clicks, button, modifiers)
  self.clicked_at = pos
  vim.api.nvim_win_set_cursor(self.win, pos)
  local component = self:get_component_at(pos)
  if component then
    if component.on_click then
      component:on_click(min_width, n_clicks, button, modifiers)
    end
  end
end

---"Click" the component in the dropbar menu
---Side effects: update self.clicked_at
---@param symbol dropbar_symbol_t
---@param min_width integer?
---@param n_clicks integer?
---@param button string?
---@param modifiers string?
function dropbar_menu_t:click_on(
  symbol,
  min_width,
  n_clicks,
  button,
  modifiers
)
  local row = symbol.entry.idx
  local col = 0
  for idx, component in ipairs(symbol.entry.components) do
    if idx == symbol.entry_idx then
      break
    end
    col = col + component:bytewidth()
  end
  self.clicked_at = { row, col }
  if symbol then
    if symbol.on_click then
      symbol:on_click(min_width, n_clicks, button, modifiers)
    end
  end
end

---Add highlight to a range in the menu buffer
---@param line integer 1-indexed
---@param hl_info dropbar_menu_hl_info_t
---@return nil
function dropbar_menu_t:hl_line_range(line, hl_info)
  if not self.buf then
    return
  end
  vim.api.nvim_buf_add_highlight(
    self.buf,
    hl_info.ns or -1,
    hl_info.hlgroup,
    line - 1, -- 0-indexed
    hl_info.start,
    hl_info['end']
  )
end

---Used to add background highlight to a single line in the menu buffer
---Notice that all other highlight added using this function will be deleted
---@param line integer 1-indexed
---@param hlgroup string? default to 'DropBarMenuCurrentContext'
---@return nil
function dropbar_menu_t:hl_line_single(line, hlgroup)
  if not self.buf then
    return
  end
  hlgroup = hlgroup or 'DropBarMenuCurrentContext'
  -- Use namespace to delete highlights conveniently
  local ns = vim.api.nvim_create_namespace('DropBarMenu')
  vim.api.nvim_set_hl(ns, hlgroup, vim.api.nvim_get_hl(0, { name = hlgroup }))
  vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
  vim.api.nvim_buf_add_highlight(
    self.buf,
    ns,
    hlgroup,
    line - 1, -- 0-indexed
    0,
    -1
  )
end

---Make a buffer for the menu and set buffer-local keymaps
---Must be called after the popup window is created
---Side effect: change self.buf, self.hl_info
---@return nil
function dropbar_menu_t:make_buf()
  if self.buf then
    return
  end
  self.buf = vim.api.nvim_create_buf(false, true)
  local lines = {} ---@type string[]
  local hl_info = {} ---@type {start: integer, end: integer, hlgroup: string}[][]
  for _, entry in ipairs(self.entries) do
    local line, entry_hl_info = entry:cat()
    -- Pad the line with spaces to the width of the window
    -- This is to make sure hl-DropBarMenuCurrentContext colors
    -- the entire line
    table.insert(
      lines,
      line
        .. string.rep(
          ' ',
          self._win_configs.width - vim.fn.strdisplaywidth(line)
        )
    )
    table.insert(hl_info, entry_hl_info)
  end
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
  for entry_idx, entry_hl_info in ipairs(hl_info) do
    for _, hl in ipairs(entry_hl_info) do
      self:hl_line_range(entry_idx, hl)
    end
    if self.cursor and entry_idx == self.cursor[1] then
      self:hl_line_single(entry_idx)
    end
  end
  vim.bo[self.buf].ma = false
  vim.bo[self.buf].ft = 'dropbar_menu'

  -- Set buffer-local keymaps
  -- Default modes: normal and visual
  for key, mapping in pairs(configs.opts.menu.keymaps) do
    if type(mapping) == 'function' or type(mapping) == 'string' then
      vim.keymap.set({ 'x', 'n' }, key, mapping, { buffer = self.buf })
    elseif type(mapping) == 'table' then
      for mode, rhs in pairs(mapping) do
        vim.keymap.set(mode, key, rhs, { buffer = self.buf })
      end
    end
  end

  -- Set buffer-local autocmds
  vim.api.nvim_create_autocmd('WinClosed', {
    group = groupid,
    buffer = self.buf,
    callback = function()
      -- Trigger self:close() when the popup window is closed
      -- to ensure the cursor is set to the correct previous window
      self:close()
    end,
  })
end

---Open the menu
---Side effect: change self.win and self.buf
---@return nil
function dropbar_menu_t:open()
  if self.is_opened then
    return
  end
  self.is_opened = true

  self.prev_win = vim.api.nvim_get_current_win()
  local parent_menu = _G.dropbar.menus[self.prev_win]
  if parent_menu then
    parent_menu.sub_menu = self
    self.parent_menu = parent_menu
    self.prev_win = parent_menu.win
  end

  self:eval_win_config()
  self:make_buf()
  self.win = vim.api.nvim_open_win(self.buf, true, self._win_configs)
  vim.wo[self.win].scrolloff = 0
  vim.wo[self.win].sidescrolloff = 0
  _G.dropbar.menus[self.win] = self
  -- Initialize cursor position
  if self._win_configs.focusable ~= false and self.cursor then
    vim.api.nvim_win_set_cursor(self.win, self.cursor)
  end
end

---Close the menu
---@return nil
function dropbar_menu_t:close()
  if not self.is_opened then
    return
  end
  self.is_opened = false

  if self.sub_menu then
    self.sub_menu:close()
  end
  if self.win and vim.api.nvim_win_is_valid(self.prev_win) then
    vim.api.nvim_set_current_win(self.prev_win)
  end
  _G.dropbar.menus[self.win] = nil
  if vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end
  if self.win then
    self.win = nil
  end
end

---Toggle the menu
---@return nil
function dropbar_menu_t:toggle()
  if self.is_opened then
    self:close()
  else
    self:open()
  end
end

return {
  dropbar_menu_t = dropbar_menu_t,
  dropbar_menu_entry_t = dropbar_menu_entry_t,
}
