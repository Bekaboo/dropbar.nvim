local bar = require('dropbar.bar')
local configs = require('dropbar.configs')
local groupid = vim.api.nvim_create_augroup('DropBarMenu', {})

---Lookup table for dropbar menus
---@type table<integer, dropbar_menu_t>
_G.dropbar.menus = {}

---@class dropbar_menu_hl_info_t
---@field start integer byte-indexed, 0-indexed, start inclusive
---@field end integer byte-indexed, 0-indexed, end exclusive
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
    }, opts or {}),
    self
  )
  -- vim.tbl_deep_extend drops metatables
  setmetatable(entry.separator, bar.dropbar_symbol_t)
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
  local str = string.rep(' ', self.padding.left)
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
        start = #str + #component.icon,
        ['end'] = #str + #component.icon + #component.name,
        hlgroup = component.name_hl,
      })
    end
    str = str .. component:cat(true)
  end
  return str .. string.rep(' ', self.padding.right), hl_info
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
---@return {start: integer, end: integer}? range of the clickable component in the menu, byte-indexed, 0-indexed, start-inclusive, end-exclusive
function dropbar_menu_entry_t:first_clickable(offset)
  offset = offset or 0
  local col_start = self.padding.left
  for _, component in ipairs(self.components) do
    local col_end = col_start + component:bytewidth()
    if offset < col_end and component.on_click then
      return component, { start = col_start, ['end'] = col_end }
    end
    col_start = col_end + self.separator:bytewidth()
  end
end

---Get the component at the given position in the dropbar menu
---@param col integer 1-indexed, byte-indexed
---@return dropbar_symbol_t?
---@return {start: integer, end: integer}? range of the component in the menu, byte-indexed, 0-indexed, start-inclusive, end-exclusive
function dropbar_menu_entry_t:get_component_at(col)
  local col_offset = self.padding.left
  for _, component in ipairs(self.components) do
    local component_len = component:bytewidth()
    if col > col_offset and col <= col_offset + component_len then
      return component,
        {
          start = col_offset,
          ['end'] = col_offset + component_len,
        }
    end
    col_offset = col_offset + component_len + self.separator:bytewidth()
  end
  return nil, nil
end

---Find the previous clickable component in the dropbar menu entry
---@param col integer byte-indexed, 0-indexed column position
---@return dropbar_symbol_t?
---@return {start: integer, end: integer}? range of the clickable component in the menu, byte-indexed, 0-indexed, start-inclusive, end-exclusive
function dropbar_menu_entry_t:prev_clickable(col)
  local col_start = self.padding.left
  local prev_component, range
  for _, component in ipairs(self.components) do
    local col_end = col_start + component:bytewidth()
    if col > col_end and component.on_click then
      prev_component = component
      range = { start = col_start, ['end'] = col_end }
    end
    col_start = col_end + self.separator:bytewidth()
  end
  return prev_component, range
end

---Find the next clickable component in the dropbar menu entry
---@param col integer byte-indexed, 0-indexed column position
---@return dropbar_symbol_t?
---@return {start: integer, end: integer}? range of the clickable component in the menu, byte-indexed, 0-indexed, start-inclusive, end-exclusive
function dropbar_menu_entry_t:next_clickable(col)
  local col_start = self.padding.left
  for _, component in ipairs(self.components) do
    local col_end = col_start + component:bytewidth()
    if col < col_start and component.on_click then
      return component, { start = col_start, ['end'] = col_end }
    end
    col_start = col_end + self.separator:bytewidth()
  end
end

---@class dropbar_menu_opts_t
---@field is_opened boolean?
---@field entries dropbar_menu_entry_t[]?
---@field win_configs table? window configuration
---@field cursor integer[]? initial cursor position
---@field prev_win integer? previous window

---@class dropbar_menu_t
---@field buf integer?
---@field win integer?
---@field is_opened boolean?
---@field entries dropbar_menu_entry_t[]
---@field win_configs table window configuration, value can be a function
---@field _win_configs table evaluated window configuration
---@field cursor integer[]? initial cursor position
---@field prev_win integer? previous window, assigned when calling new() or automatically determined in open()
---@field sub_menu dropbar_menu_t? submenu, assigned when calling new() or automatically determined when a new menu opens
---@field parent_menu dropbar_menu_t? parent menu, assigned when calling new() or automatically determined in open()
---@field clicked_at integer[]? last position where the menu was clicked
---@field prev_cursor integer[]? previous cursor position
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
    self
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
---@param win_configs table? window configurations to override
---@return nil
---@see vim.api.nvim_open_win
function dropbar_menu_t:eval_win_configs(win_configs)
  -- Evaluate function-valued window configurations
  self._win_configs = {}
  for k, config in
    pairs(vim.tbl_deep_extend('force', self.win_configs, win_configs or {}))
  do
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
---@return {start: integer, end: integer}? range of the component in the menu, byte-indexed, 0-indexed, start-inclusive, end-exclusive
function dropbar_menu_t:get_component_at(pos)
  if not self.entries or vim.tbl_isempty(self.entries) then
    return nil, nil
  end
  local row = pos[1]
  local col = pos[2]
  local entry = self.entries[row]
  if not entry or not entry.components then
    return nil, nil
  end
  return entry:get_component_at(col)
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
  local col = symbol.entry.padding.left + 1
  for idx, component in ipairs(symbol.entry.components) do
    if idx == symbol.entry_idx then
      break
    end
    col = col + component:bytewidth() + symbol.entry.separator:bytewidth()
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

---Used to add background highlight to a single range in the menu buffer
---Notice that all other highlight added using this function will be deleted
---@param line integer|false? 1-indexed
---@param range {start: integer, end: integer}? 0-indexed, byte-indexed, start inclusive, end exclusive
---@param hlgroup string? default to 'DropBarMenuHoverSymbol'
---@return nil
function dropbar_menu_t:hl_range_single(line, range, hlgroup)
  if not self.buf then
    return
  end
  hlgroup = hlgroup or 'DropBarMenuHoverSymbol'
  local ns = vim.api.nvim_create_namespace(hlgroup)
  vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
  if line and range then
    vim.api.nvim_set_hl(
      ns,
      hlgroup,
      vim.api.nvim_get_hl(0, { name = hlgroup })
    )
    vim.api.nvim_buf_add_highlight(
      self.buf,
      ns,
      hlgroup,
      line - 1,
      range.start,
      range['end']
    )
  end
end

---Used to add background highlight to a single line in the menu buffer
---Notice that all other highlight added using this function will be deleted
---@param line integer? 1-indexed
---@param hlgroup string? default to 'DropBarMenuCurrentContext'
---@return nil
function dropbar_menu_t:hl_line_single(line, hlgroup)
  if not self.buf then
    return
  end
  hlgroup = hlgroup or 'DropBarMenuCurrentContext'
  -- Use namespace to delete highlights conveniently
  local ns = vim.api.nvim_create_namespace(hlgroup)
  vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
  if line then
    vim.api.nvim_set_hl(
      ns,
      hlgroup,
      vim.api.nvim_get_hl(0, { name = hlgroup })
    )
    vim.api.nvim_buf_add_highlight(
      self.buf,
      ns,
      hlgroup,
      line - 1, -- 0-indexed
      0,
      -1
    )
  end
end

---Update DropBarMenuHover* highlights according to pos
---@param pos integer[]? byte-indexed, 1,0-indexed cursor/mouse position
---@return nil
function dropbar_menu_t:update_hover_hl(pos)
  self:hl_range_single(nil, nil)
  self:hl_range_single(nil, nil, 'DropBarMenuHoverIcon')
  self:hl_line_single(nil, 'DropBarMenuHoverEntry')
  if not pos then
    return
  end
  local component, range = self:get_component_at({ pos[1], pos[2] + 1 })
  self:hl_range_single(
    component and component.on_click and component.entry.idx,
    range,
    component and component.name == '' and 'DropBarMenuHoverIcon'
      or 'DropBarMenuHoverSymbol'
  )
  self:hl_line_single(pos[1], 'DropBarMenuHoverEntry')
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
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = groupid,
    buffer = self.buf,
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(self.win)
      local entry = self.entries and self.entries[cursor[1]]
      if not entry or not configs.opts.menu.quick_navigation then
        goto update_hover_hl
      end

      -- Code for quick navigation
      do
        local target_component, range
        if not self.prev_cursor then
          target_component, range =
            entry.components and entry.components[1], {
              start = entry.padding.left,
              ['end'] = entry.padding.left,
            }
        elseif self.prev_cursor[1] == cursor[1] then -- moved inside an entry
          if cursor[2] > self.prev_cursor[2] then -- moves right
            target_component, range = entry:next_clickable(self.prev_cursor[2])
          else -- moves left
            target_component, range = entry:prev_clickable(self.prev_cursor[2])
          end
        end
        if target_component and range then
          cursor = { cursor[1], range.start }
          vim.api.nvim_win_set_cursor(self.win, cursor)
        end
        self.prev_cursor = cursor
      end

      -- Update hover highlights
      ::update_hover_hl::
      self:update_hover_hl(cursor)
    end,
  })
  vim.api.nvim_create_autocmd('BufLeave', {
    group = groupid,
    buffer = self.buf,
    callback = function()
      self:update_hover_hl()
    end,
  })
end

---Open the menu
---Side effect: change self.win and self.buf
---@param win_configs table? window configurations to override
---@return nil
function dropbar_menu_t:open(win_configs)
  if self.is_opened then
    return
  end

  self.prev_win = vim.api.nvim_get_current_win()
  local parent_menu = _G.dropbar.menus[self.prev_win]
  if parent_menu then
    -- if the parent menu has an existing sub-menu, close the sub-menu first
    if parent_menu.sub_menu then
      parent_menu.sub_menu:close()
    end
    parent_menu.sub_menu = self
    self.parent_menu = parent_menu
    self.prev_win = parent_menu.win
  end

  self:eval_win_configs(win_configs)
  self:make_buf()
  self.win = vim.api.nvim_open_win(self.buf, true, self._win_configs)
  self.is_opened = true
  vim.wo[self.win].scrolloff = 0
  vim.wo[self.win].sidescrolloff = 0
  _G.dropbar.menus[self.win] = self
  -- Initialize cursor position
  if
    self._win_configs.focusable ~= false
    and not self.prev_cursor
    and self.cursor
  then
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
---@param win_configs table? window configurations to override
---@return nil
function dropbar_menu_t:toggle(win_configs)
  if self.is_opened then
    self:close()
  else
    self:open(win_configs)
  end
end

return {
  dropbar_menu_t = dropbar_menu_t,
  dropbar_menu_entry_t = dropbar_menu_entry_t,
}
