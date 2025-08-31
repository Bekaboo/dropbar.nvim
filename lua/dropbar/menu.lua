local bar = require('dropbar.bar')
local utils = require('dropbar.utils')
local configs = require('dropbar.configs')
local groupid = vim.api.nvim_create_augroup('dropbar.menu', {})

---Lookup table for dropbar menus
---@type table<integer, dropbar_menu_t>
_G.dropbar.menus = {}

---Highlight range in a single line of a drop-down menu.
---@class dropbar_menu_hl_info_t
---@field start integer byte-indexed, 0-indexed, start inclusive
---@field end integer byte-indexed, 0-indexed, end exclusive
---@field hlgroup string
---@field ns integer? namespace id, nil if using default namespace

---Entry (row) in a drop-down menu.
---A `dropbar_menu_t` instance is made up of multiple `dropbar_menu_entry_t`
---instances while a `dropbar_menu_entry_t` instance can contain multiple
---`dropbar_symbol_t` instances.
---@class dropbar_menu_entry_t
---@field separator dropbar_symbol_t
---@field padding {left: integer, right: integer}
---@field components dropbar_symbol_t[]
---@field virt_text string[][]?
---@field menu dropbar_menu_t? the menu the entry belongs to
---@field idx integer? the index of the entry in the menu
local dropbar_menu_entry_t = {}
dropbar_menu_entry_t.__index = dropbar_menu_entry_t

---@class dropbar_menu_entry_opts_t
---@field separator dropbar_symbol_t?
---@field padding {left: integer, right: integer}?
---@field components dropbar_symbol_t[]?
---@field virt_text string[][]?
---@field menu dropbar_menu_t? the menu the entry belongs to
---@field idx integer? the index of the entry in the menu

---Create a dropbar menu entry instance
---@param opts dropbar_menu_entry_opts_t?
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
---@return number
function dropbar_menu_entry_t:displaywidth()
  return vim.fn.strdisplaywidth((self:cat()))
end

---Get the byte length of the dropbar menu entry
---@return number
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
---@param col integer 0-indexed, byte-indexed
---@param look_ahead boolean? whether to look ahead for the next component if the given position does not contain a component
---@return dropbar_symbol_t?
---@return {start: integer, end: integer}? range of the component in the menu, byte-indexed, 0-indexed, start-inclusive, end-exclusive
function dropbar_menu_entry_t:get_component_at(col, look_ahead)
  local col_offset = self.padding.left
  for _, component in ipairs(self.components) do
    local component_len = component:bytewidth()
    if
      (look_ahead or col >= col_offset) and col < col_offset + component_len
    then
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

---Represents a drop-down menu.
---@class dropbar_menu_t
---@field buf integer? buffer of the menu
---@field win integer? window of the menu
---@field is_opened boolean? whether the menu is currently opened
---@field entries dropbar_menu_entry_t[] entries (rows) in the menu
---@field win_configs table window configuration, value can be a function
---@field _win_configs table evaluated window configuration
---@field cursor integer[]? initial cursor position
---@field prev_win integer? previous window, assigned when calling new() or automatically determined in open()
---@field prev_buf integer? previous buffer, assigned when calling new() or automatically determined in open()
---@field sub_menu dropbar_menu_t? submenu, assigned when calling new() or automatically determined when a new menu opens
---@field prev_menu dropbar_menu_t? previous menu, assigned when calling new() or automatically determined in open()
---@field clicked_at integer[]? last position where the menu was clicked, byte-indexed, 1,0-indexed
---@field prev_cursor integer[]? previous cursor position
---@field symbol_previewed dropbar_symbol_t? symbol being previewed
---@field fzf_state fzf_state_t? fuzzy-finding state, or nil if not currently fuzzy-finding
---@field fzf_win_configs table window configuration, value can be a function
---@field scrollbar { thumb: integer, background: integer }? scrollbar window handlers
local dropbar_menu_t = {}
dropbar_menu_t.__index = dropbar_menu_t

---@class dropbar_menu_opts_t
---@field buf integer?
---@field win integer?
---@field is_opened boolean?
---@field entries dropbar_menu_entry_t[]?
---@field win_configs table? window configuration, value can be a function
---@field _win_configs table? evaluated window configuration
---@field cursor integer[]? initial cursor position
---@field prev_win integer? previous window, assigned when calling new() or automatically determined in open()
---@field sub_menu dropbar_menu_t? submenu, assigned when calling new() or automatically determined when a new menu opens
---@field prev_menu dropbar_menu_t? previous menu, assigned when calling new() or automatically determined in open()
---@field clicked_at integer[]? last position where the menu was clicked, byte-indexed, 1,0-indexed
---@field prev_cursor integer[]? previous cursor position
---@field symbol_previewed dropbar_symbol_t? symbol being previewed

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
function dropbar_menu_t:del()
  if self.sub_menu then
    self.sub_menu:del()
    self.sub_menu = nil
  end
  self:close()
  if self.buf then
    if vim.api.nvim_buf_is_valid(self.buf) then
      vim.api.nvim_buf_delete(self.buf, {})
    end
    self.buf = nil
  end
  if self.win then
    _G.dropbar.menus[self.win] = nil
  end
end

---Retrieves the root menu (first menu opened from winbar)
---@return dropbar_menu_t?
function dropbar_menu_t:root()
  local current = self
  while current and current.prev_menu do
    current = current.prev_menu
  end
  return current
end

---Evaluate window configurations `dropbar_menu_t.win_configs` and store result
---in `dropbar_menu_t._win_configs`
---Side effects: update self._win_configs
---@see vim.api.nvim_open_win
function dropbar_menu_t:eval_win_configs()
  -- Evaluate function-valued window configurations
  self._win_configs = self:merge_win_configs(self.win_configs)

  -- See https://github.com/Bekaboo/dropbar.nvim/pull/90
  -- Ensure `win` field is nil if `relative` ~= 'win', else nvim will
  -- throw error
  -- Why `win` field is set if `relative` field is not 'win'?
  -- It's set because the global configs are used when creating windows, and
  -- overridden by the menu-local settings, but `vim.tbl_deep_extend` will not
  -- replace non-nil with nil so if the default win config uses
  -- `relative` = 'win' (which it does), win will be set even if the menu-local
  -- win config doesn't set it.
  if self._win_configs.relative ~= 'win' then
    self._win_configs.win = nil
  end
end

---Get the component at the given position in the dropbar menu
---@param pos integer[] 1,0-indexed, byte-indexed
---@param look_ahead boolean? whether to look ahead for the component at the given position
---@return dropbar_symbol_t?
---@return {start: integer, end: integer}? range of the component in the menu, byte-indexed, 0-indexed, start-inclusive, end-exclusive
function dropbar_menu_t:get_component_at(pos, look_ahead)
  if not self.entries or vim.tbl_isempty(self.entries) then
    return nil, nil
  end
  local entry = self.entries[pos[1]]
  if not entry or not entry.components then
    return nil, nil
  end
  return entry:get_component_at(pos[2], look_ahead)
end

---"Click" the component at the given position in the dropbar menu
---Side effects: update self.clicked_at
---@param pos integer[] 1,0-indexed, byte-indexed
---@param min_width integer?
---@param n_clicks integer?
---@param button string?
---@param modifiers string?
function dropbar_menu_t:click_at(pos, min_width, n_clicks, button, modifiers)
  if self.sub_menu then
    self.sub_menu:close()
  end
  self.clicked_at = pos
  vim.api.nvim_win_set_cursor(self.win, pos)
  local component = self:get_component_at(pos)
  if component and component.on_click then
    component:on_click(min_width, n_clicks, button, modifiers)
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
  if self.sub_menu then
    self.sub_menu:close()
  end
  local row = symbol.entry.idx
  local col = symbol.entry.padding.left
  for idx, component in ipairs(symbol.entry.components) do
    if idx == symbol.entry_idx then
      break
    end
    col = col + component:bytewidth() + symbol.entry.separator:bytewidth()
  end
  self.clicked_at = { row, col }
  if symbol and symbol.on_click then
    symbol:on_click(min_width, n_clicks, button, modifiers)
  end
end

---Update DropBarMenuHover* highlights according to pos
---@param pos integer[]? byte-indexed, 1,0-indexed cursor/mouse position
function dropbar_menu_t:update_hover_hl(pos)
  if not self.buf then
    return
  end
  utils.hl.range_single(self.buf, 'DropBarMenuHoverSymbol', nil)
  utils.hl.range_single(self.buf, 'DropBarMenuHoverIcon', nil)
  utils.hl.range_single(self.buf, 'DropBarMenuHoverEntry', nil)
  if not pos then
    return
  end
  utils.hl.line_single(self.buf, 'DropBarMenuHoverEntry', pos[1])
  local component, range = self:get_component_at({ pos[1], pos[2] })
  local hlgroup = component and component.name == '' and 'DropBarMenuHoverIcon'
    or 'DropBarMenuHoverSymbol'
  if component and component.on_click and range then
    utils.hl.range_single(self.buf, hlgroup, {
      start = { line = pos[1] - 1, character = range.start },
      ['end'] = { line = pos[1] - 1, character = range['end'] },
    })
  end
end

---Update highlights for current context according to pos
---@param linenr integer? 1-indexed line number
function dropbar_menu_t:update_current_context_hl(linenr)
  if self.buf then
    utils.hl.line_single(self.buf, 'DropBarMenuCurrentContext', linenr)
  end
end

---Fill the menu buffer with entries in `self.entries` and add
---highlights to the buffer
function dropbar_menu_t:fill_buf()
  local lines = {} ---@type string[]
  local hl_info = {} ---@type dropbar_menu_hl_info_t[][]
  local extmarks = {} ---@type table<integer, string[][]>
  for i, entry in ipairs(self.entries) do
    local line, entry_hl_info = entry:cat()
    -- Pad lines with spaces to the width of the window
    -- This is to make sure hl-DropBarMenuCurrentContext colors
    -- the entire line
    -- Also pad the last symbol's name so that cursor is always
    -- on at least one symbol when inside the menu
    local n = self._win_configs.width - entry:displaywidth()
    if n > 0 then
      local pad = string.rep(' ', n)
      local last_sym = entry.components[#entry.components]
      if last_sym then
        last_sym.name = last_sym.name .. pad
      end
      line = line .. pad
    end
    table.insert(lines, line)
    table.insert(hl_info, entry_hl_info)
    if entry.virt_text then
      table.insert(extmarks, i, entry.virt_text)
    end
  end

  -- Fill the buffer with lines, then add highlights
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
  for linenr, hl_line_info in ipairs(hl_info) do
    for _, hl_symbol_info in ipairs(hl_line_info) do
      vim.highlight.range(
        self.buf,
        hl_symbol_info.ns or vim.api.nvim_create_namespace('DropBar'),
        hl_symbol_info.hlgroup,
        { linenr - 1, hl_symbol_info.start },
        { linenr - 1, hl_symbol_info['end'] },
        {}
      )
    end
  end

  local extmark_ns = vim.api.nvim_create_namespace('DropBarExtmarks')
  vim.api.nvim_buf_clear_namespace(self.buf, extmark_ns, 0, -1)

  for i, virt_text in pairs(extmarks) do
    if type(i) == 'number' then
      vim.api.nvim_buf_set_extmark(
        self.buf,
        extmark_ns,
        i - 1, -- 0-indexed
        0,
        {
          virt_lines = { virt_text },
        }
      )
    end
  end
end

---Make a buffer for the menu and set buffer-local keymaps
---Must be called after `dropbar_menu_t:eval_win_configs()`
---Side effect: change `dropbar_menu_t.buf`, `dropbar_menu_t.hl_info`
function dropbar_menu_t:make_buf()
  if self.buf then
    return
  end
  self.buf = vim.api.nvim_create_buf(false, true)
  self:fill_buf()
  if self.cursor then
    self:update_current_context_hl(self.cursor[1])
  end
  vim.bo[self.buf].ma = false
  vim.bo[self.buf].ft = 'dropbar_menu'

  -- Set buffer-local keymaps
  -- Default modes: normal
  for key, mapping in pairs(configs.opts.menu.keymaps) do
    local mapping_type = type(mapping)
    if mapping_type == 'function' or mapping_type == 'string' then
      vim.keymap.set('n', key, mapping, { buffer = self.buf })
    elseif mapping_type == 'table' then
      for mode, rhs in pairs(mapping) do
        vim.keymap.set(mode, key, rhs, { buffer = self.buf })
      end
    end
  end

  -- Set buffer-local autocmds
  vim.api.nvim_create_autocmd('WinClosed', {
    nested = true,
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

      if configs.opts.menu.preview then
        self:preview_symbol_at(cursor, true)
      end

      if configs.opts.menu.quick_navigation and not self.fzf_state then
        self:quick_navigation(cursor)
      else
        self.prev_cursor = cursor
      end

      self:update_hover_hl(self.prev_cursor)
      self:update_scrollbar()
    end,
  })
  vim.api.nvim_create_autocmd('WinScrolled', {
    group = groupid,
    buffer = self.buf,
    callback = function()
      self:update_scrollbar()
    end,
  })
  vim.api.nvim_create_autocmd('BufLeave', {
    group = groupid,
    buffer = self.buf,
    callback = function()
      self:update_hover_hl()

      -- BufLeave event fires BEFORE actually switching buffers, so schedule a
      -- check to run after buffer switch is complete
      -- If we've switched to a non-menu buffer, close all menus starting from
      -- root, this ensures proper cleanup when leaving menu navigation
      vim.schedule(function()
        if vim.bo.ft ~= 'dropbar_menu' and vim.bo.ft ~= 'dropbar_menu_fzf' then
          self:root():close()
        end
      end)
    end,
  })
end

---Open the popup window with win configs and opts,
---must be called after self:make_buf()
function dropbar_menu_t:open_win()
  if self.is_opened then
    return
  end
  self.is_opened = true

  self.win = vim.api.nvim_open_win(self.buf, true, self._win_configs)
  vim.wo[self.win].scrolloff = 0
  vim.wo[self.win].sidescrolloff = 0
  vim.wo[self.win].wrap = false
  vim.wo[self.win].winfixbuf = true
  vim.wo[self.win].winhl = table.concat({
    'NormalFloat:DropBarMenuNormalFloat',
    'FloatBorder:DropBarMenuFloatBorder',
  }, ',')
end

---Update the scrollbar's position and height, create a new scrollbar if
---one does not exist
---Side effect: can change self.scrollbar
function dropbar_menu_t:update_scrollbar()
  if
    not self.win
    or not self.buf
    or not vim.api.nvim_win_is_valid(self.win)
    or not vim.api.nvim_buf_is_valid(self.buf)
    or not configs.opts.menu.scrollbar.enable
  then
    return
  end

  local buf_height = vim.api.nvim_buf_line_count(self.buf)
  local menu_win_configs = vim.api.nvim_win_get_config(self.win)
  if buf_height <= menu_win_configs.height then
    self:close_scrollbar()
    return
  end

  local thumb_height =
    math.max(1, math.floor(menu_win_configs.height ^ 2 / buf_height))
  local offset = vim.fn.line('w$') == buf_height
      and menu_win_configs.height - thumb_height
    or math.min(
      menu_win_configs.height - thumb_height,
      math.floor(menu_win_configs.height * vim.fn.line('w0') / buf_height)
    )

  if self.scrollbar and vim.api.nvim_win_is_valid(self.scrollbar.thumb) then
    local config = vim.api.nvim_win_get_config(self.scrollbar.thumb)
    config.row = offset
    config.height = thumb_height
    vim.api.nvim_win_set_config(self.scrollbar.thumb, config)
  else
    self:close_scrollbar()
    self.scrollbar = {}

    local win_configs = {
      row = 0,
      col = menu_win_configs.width
        - (configs.opts.menu.scrollbar.background and 0 or 1),
      width = 1,
      height = menu_win_configs.height,
      style = 'minimal',
      border = 'none',
      relative = 'win',
      win = self.win,
      focusable = false,
      noautocmd = true,
      zindex = menu_win_configs.zindex,
    }

    if configs.opts.menu.scrollbar.background then
      self.scrollbar.background = vim.api.nvim_open_win(
        vim.api.nvim_create_buf(false, true),
        false,
        win_configs
      )
      vim.wo[self.scrollbar.background].winhl = 'NormalFloat:DropBarMenuSbar'
    end

    win_configs.row = offset
    win_configs.height = thumb_height
    win_configs.zindex = menu_win_configs.zindex + 1
    self.scrollbar.thumb = vim.api.nvim_open_win(
      vim.api.nvim_create_buf(false, true),
      false,
      win_configs
    )
    vim.wo[self.scrollbar.thumb].winhl = 'NormalFloat:DropBarMenuThumb'
  end
end

---Close the scrollbar, if one exists
---Side effect: set self.scrollbar to nil
function dropbar_menu_t:close_scrollbar()
  if not self.scrollbar then
    return
  end
  if vim.api.nvim_win_is_valid(self.scrollbar.thumb) then
    vim.api.nvim_win_close(self.scrollbar.thumb, true)
  end
  if
    self.scrollbar.background
    and vim.api.nvim_win_is_valid(self.scrollbar.background)
  then
    vim.api.nvim_win_close(self.scrollbar.background, true)
  end
  self.scrollbar = nil
end

---Override menu options
---@param opts dropbar_menu_opts_t?
function dropbar_menu_t:override(opts)
  if not opts then
    return
  end
  for k, v in pairs(opts) do
    if type(v) == 'table' then
      if type(self[k]) == 'table' then
        self[k] = vim.tbl_extend('force', self[k], v)
      else
        self[k] = v
      end
    else
      self[k] = v
    end
  end
end

---Open the menu
---Side effect: change self.win and self.buf
---@param opts dropbar_menu_opts_t?
function dropbar_menu_t:open(opts)
  if self.is_opened then
    return
  end
  self:override(opts)

  self.prev_menu = _G.dropbar.menus[self.prev_win]
  local open_fzf = false
  if self.prev_menu then
    -- if the prev menu has an existing sub-menu, close the sub-menu first
    if self.prev_menu.sub_menu then
      self.prev_menu.sub_menu:close()
    end
    if self.prev_menu.fzf_state then
      self.prev_menu:fuzzy_find_close()
      if configs.opts.fzf.fuzzy_find_on_click then
        open_fzf = true
      end
    end
    self.prev_menu.sub_menu = self
  end

  self:eval_win_configs()
  self:make_buf()
  self:open_win()
  _G.dropbar.menus[self.win] = self
  -- Initialize cursor position
  if self._win_configs.focusable ~= false then
    if self.prev_cursor then
      vim.api.nvim_win_set_cursor(self.win, self.prev_cursor)
    elseif self.cursor then
      vim.api.nvim_win_set_cursor(self.win, self.cursor)
      vim.api.nvim_exec_autocmds('CursorMoved', { buffer = self.buf })
    end
  end
  if open_fzf then
    self:fuzzy_find_open()
  end
  self:update_scrollbar()
end

---Close the menu
---@param restore_view boolean? whether to restore the source win view, default `true`
function dropbar_menu_t:close(restore_view)
  if not self.is_opened then
    return
  end
  self.is_opened = false
  restore_view = restore_view == nil or restore_view
  -- Close sub-menus
  if self.sub_menu then
    self.sub_menu:close(restore_view)
  end
  -- Move cursor to the previous window
  if self.prev_win and vim.api.nvim_win_is_valid(self.prev_win) then
    vim.api.nvim_set_current_win(self.prev_win)
  end
  -- Close the menu window and dereference it in the lookup table
  if self.win then
    if vim.api.nvim_win_is_valid(self.win) then
      vim.api.nvim_win_close(self.win, true)
    end
    _G.dropbar.menus[self.win] = nil
    self.win = nil
  end
  if self.scrollbar then
    self:close_scrollbar()
  end
  -- Finish preview
  if configs.opts.menu.preview then
    self:finish_preview(restore_view)
  end
end

---Preview the symbol at the given position
---@param pos integer[] 1,0-indexed, byte-indexed position
---@param look_ahead boolean? whether to look ahead for a component
function dropbar_menu_t:preview_symbol_at(pos, look_ahead)
  if not pos then
    return
  end
  local component = self:get_component_at(pos, look_ahead)
  if not component then
    return
  end
  component:preview(self.symbol_previewed and self.symbol_previewed.view)
  self.symbol_previewed = component
end

---Finish previewing the symbol, preview highlights in the sourec buffer
---will always be cleared, the original view in the source window will
---be restored if `restore_view` is set to `true` (default)
---@param restore_view boolean? whether to restore the source win view, default `true`
function dropbar_menu_t:finish_preview(restore_view)
  restore_view = restore_view == nil or restore_view
  if self.symbol_previewed then
    self.symbol_previewed:preview_restore_hl()
    if restore_view then
      self.symbol_previewed:preview_restore_view()
    end
    self.symbol_previewed = nil
  end
end

---Set the cursor to the nearest clickable component in the direction of
---cursor movement
---@param new_cursor integer[] 1,0-indexed, byte-indexed position
function dropbar_menu_t:quick_navigation(new_cursor)
  local entry = self.entries and self.entries[new_cursor[1]]
  if not entry then
    return
  end
  local target_component, range
  if not self.prev_cursor then
    target_component, range =
      entry.components and entry.components[1], {
        start = entry.padding.left,
        ['end'] = entry.padding.left,
      }
  elseif self.prev_cursor[1] == new_cursor[1] then -- moved inside an entry
    if new_cursor[2] > self.prev_cursor[2] then -- moves right
      target_component, range = entry:next_clickable(self.prev_cursor[2])
    else -- moves left
      target_component, range = entry:prev_clickable(self.prev_cursor[2])
    end
  end
  if target_component and range then
    new_cursor = { new_cursor[1], range.start }
    vim.api.nvim_win_set_cursor(self.win, new_cursor)
  end
  self.prev_cursor = new_cursor
end

---Restore menu buffer and entries in their original order
---before modification by fuzzy finding
---@version JIT
function dropbar_menu_t:fuzzy_find_restore_entries()
  if not self.fzf_state then
    return
  end
  self.entries = {}
  -- the order of the entries is changed as the entries are
  -- sorted per their fzf score, but the idx field is preserved
  for _, entry in ipairs(self.fzf_state.menu_entries) do
    self.entries[entry.idx] = entry
  end
  self:fill_buf()
  if self.cursor then
    self:update_current_context_hl(self.cursor[1])
  end
end

---Stop fuzzy finding and clean up allocated memory
---@version JIT
function dropbar_menu_t:fuzzy_find_close()
  if not self.fzf_state then
    return
  end
  if self.is_opened then
    self:fuzzy_find_restore_entries()
    vim.bo[self.buf].modifiable = false
    if self.prev_cursor then
      vim.api.nvim_win_set_cursor(self.win, self.prev_cursor)
    end
  end
  local input_win = self.fzf_state.win
  self.fzf_state:gc()
  self.fzf_state = nil
  if vim.api.nvim_win_is_valid(input_win) then
    vim.cmd.stopinsert({ mods = { emsg_silent = true } })
    vim.api.nvim_win_close(input_win, false)
  end
  _G.dropbar.menus[input_win] = nil
  self:update_border()
end

---Click on the currently selected fuzzy find menu entry, choosing the component
---to click according to `component`.
---
---@param component? number|dropbar_symbol_t|fun(entry: dropbar_menu_entry_t):dropbar_symbol_t?
--- - If it is a `number`, the `component`-nth symbol is selected, unless `0`
--- or `-1` is supplied, in which case the *first* or *last* clickable
--- component is selected, respectively
--- - If it is a function, it receives the `dropbar_menu_entry_t` as an
--- argument and should return the `dropbar_symbol_t` that is to be clicked
---@version JIT
function dropbar_menu_t:fuzzy_find_click_on_entry(component)
  if self.sub_menu then
    self.sub_menu:close()
  end
  if not self.fzf_state or vim.api.nvim_buf_line_count(self.buf) < 1 then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(self.win)
  local menu_entry = self.entries[cursor[1]]
  if not menu_entry then
    return
  end
  cursor[1] = menu_entry.idx
  self:fuzzy_find_close()
  vim.api.nvim_win_set_cursor(self.win, cursor)
  vim.api.nvim_feedkeys('l', 'nt', false)
  component = component or 0
  vim.schedule(function()
    local target
    if type(component) == 'number' then
      if component == -1 then
        target = menu_entry.components[#menu_entry.components]
        while target and not target.on_click do
          target = menu_entry.components[target.entry_idx - 1]
        end
      elseif component == 0 then
        cursor = vim.api.nvim_win_get_cursor(self.win)
        target = menu_entry:first_clickable(cursor[2])
      else
        target = menu_entry.components[component]
      end
    elseif type(component) == 'function' then
      target = component(menu_entry)
    end
    if not target or not target.on_click then
      return
    end
    self:click_on(target, nil, 1, 'l')
    if configs.opts.fzf.fuzzy_find_on_click then
      if target.menu then
        target.menu:fuzzy_find_open()
      end
    end
  end)
end

---Navigate to the nth previous/next entry while fuzzy finding
---@param dir 'up'|'down'|integer Direction to negative to:
--- - 'up':             navigate one entry upwards
--- - 'down':           navigate one entry downwards
--- - positive integer: navigate to the {direction}-th next entry
--- - negative integer: navigate to the {direction}-th previous entry
function dropbar_menu_t:fuzzy_find_navigate(dir)
  if not self.fzf_state then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(self.win)
  local line_count = vim.api.nvim_buf_line_count(self.buf)
  if line_count <= 1 then
    return
  end
  dir = type(dir) == 'number' and dir or dir == 'up' and -1 or 1
  cursor[1] = math.max(1, math.min(line_count, cursor[1] + dir))
  vim.api.nvim_win_set_cursor(self.win, cursor)
  vim.api.nvim_exec_autocmds('CursorMoved', { buffer = self.buf })
end

function dropbar_menu_t:update_border()
  if self.win_configs.border then
    local border = self.win_configs.border
    if type(self.win_configs.border) == 'function' then
      border = self.win_configs.border(self)
    end
    local config = vim.api.nvim_win_get_config(self.win)
    config.border = border
    vim.api.nvim_win_set_config(self.win, config)
    self._win_configs.border = border
  end
end

---Merges win configs, with the last one taking precedence.
---@private
---@param ... nil | table | fun(self: dropbar_menu_t): table window configuration, value can be a function
---@return table
function dropbar_menu_t:merge_win_configs(...)
  local merged = {}
  for i = 1, select('#', ...) do
    local chunk = select(i, ...)
    if chunk then
      for k, v in pairs(chunk) do
        if type(v) == 'function' then
          merged[k] = v(self) or merged[k]
        else
          merged[k] = v
        end
      end
    end
  end
  return merged
end

---Enable fuzzy finding mode
---@param opts? table<string, any>
---@version JIT
function dropbar_menu_t:fuzzy_find_open(opts)
  opts = vim.tbl_deep_extend('force', configs.opts.fzf, opts or {})

  if not jit then
    vim.notify_once(
      '[dropbar.nvim] fuzzy finding requires LuaJIT',
      vim.log.levels.ERROR
    )
    return
  elseif not utils.fzf then
    vim.notify_once(
      '[dropbar.nvim] fzf-lib is not installed',
      vim.log.levels.ERROR
    )
    return
  end

  -- cache namespace
  local fzf_lib = utils.fzf.fzf_lib

  if self.fzf_state then
    self:fuzzy_find_close()
  end

  local ns_name = 'dropbar.fzf.win.' .. tostring(self.win)
  local augroup = vim.api.nvim_create_augroup(ns_name, { clear = true })
  local ns_id = vim.api.nvim_create_namespace(ns_name)

  vim.bo[self.buf].modifiable = true
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = 'dropbar_menu_fzf'
  vim.bo[buf].bufhidden = 'wipe'

  local win_configs = self:merge_win_configs(
    self.win_configs,
    self.fzf_win_configs,
    opts.win_configs
  )

  -- don't show title in the fzf window
  win_configs.title = nil
  win_configs.title_pos = nil

  local win = vim.api.nvim_open_win(buf, false, win_configs)
  vim.wo[win].stc = opts.prompt
  _G.dropbar.menus[win] = self
  self.fzf_state = utils.fzf.fzf_state_t:new(self, win, opts)

  self:update_border()

  local should_preview = configs.opts.menu.preview
  local function move_cursor(pos)
    vim.api.nvim_win_set_cursor(self.win, pos)
    self:update_hover_hl(pos)
    if should_preview then
      self:preview_symbol_at(pos)
    end
    self:update_scrollbar()
  end

  for key, rhs in pairs(opts.keymaps) do
    if rhs then
      vim.keymap.set('i', key, rhs, { buffer = buf })
    end
  end

  local prev_cursor = vim.api.nvim_win_get_cursor(self.win)

  vim.api.nvim_set_current_win(win)
  move_cursor({ 1, 1 })
  vim.cmd.startinsert({ mods = { emsg_silent = true } })

  local function on_update()
    if not self.fzf_state then
      return true
    end
    ---@type fzf_state_t
    local fzf_state = self.fzf_state
    local text = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    if not text or #text < 1 then
      vim.schedule(function()
        self:fuzzy_find_restore_entries()
        move_cursor({ 1, 1 })
      end)
      return
    end
    local pattern = fzf_lib.parse_pattern(text, 0, true)
    for _, fzf_entry in ipairs(fzf_state.entries) do
      fzf_entry.score =
        fzf_lib.get_score(fzf_entry.str, pattern, fzf_state.slab)
      fzf_entry.first = math.huge
      if fzf_entry.score > 1 then
        local positions =
          fzf_lib.get_pos(fzf_entry.str, pattern, fzf_state.slab)
        if positions and #positions > 0 then
          fzf_entry.first = positions[1]
          fzf_entry.pos = positions
        end
      end
    end
    fzf_lib.free_pattern(pattern)

    table.sort(fzf_state.entries, function(a, b)
      if a.score ~= b.score then
        return a.score > b.score
      elseif a.first ~= b.first then
        return a.first < b.first
      else
        return a.index < b.index
      end
    end)
    for i, fzf_entry in ipairs(fzf_state.entries) do
      if fzf_entry.score > 1 then
        self.entries[i] = fzf_state.menu_entries[fzf_entry.index]
      else
        self.entries[i] = nil
        fzf_entry.pos = nil
        fzf_entry.first = math.huge
      end
    end

    vim.schedule(function()
      vim.api.nvim_buf_clear_namespace(self.buf, ns_id, 0, -1)
      self:fill_buf()
      local cursor = self.cursor or self.prev_cursor
      if cursor and self.fzf_state.menu_entries[cursor[1]] then
        local hl_line = vim
          .iter(self.entries)
          :enumerate()
          :find(function(_, entry)
            return entry.idx == self.fzf_state.menu_entries[cursor[1]].idx
          end)
        if hl_line then
          self:update_current_context_hl(hl_line)
        end
      end
      for i, fzf_entry in ipairs(fzf_state.entries) do
        if fzf_entry.score >= 2 and fzf_entry.pos then
          for _, pos_idx in ipairs(fzf_entry.pos) do
            local pos = fzf_entry.locations[pos_idx]
            vim.api.nvim_buf_set_extmark(self.buf, ns_id, i - 1, pos - 1, {
              end_col = pos,
              hl_group = 'DropBarFzfMatch',
              priority = vim.highlight.priorities.user + 10,
            })
          end
          fzf_entry.pos = nil
        else
          break
        end
      end
      if #self.entries > 0 then
        move_cursor({ 1, 1 })
      else
        if self.symbol_previewed then
          self.symbol_previewed:preview_restore_hl()
          self.symbol_previewed:preview_restore_view()
          self.symbol_previewed = nil
          self:update_hover_hl()
        end
      end
    end)
  end

  vim.api.nvim_buf_attach(buf, false, { on_lines = on_update })

  -- make sure allocated memory is freed (done in fuzzy_find_stop())
  vim.api.nvim_create_autocmd({ 'BufUnload', 'BufWinLeave', 'WinLeave' }, {
    group = augroup,
    buffer = buf,
    once = true,
    callback = function()
      if prev_cursor and vim.api.nvim_win_is_valid(self.win) then
        vim.schedule(function()
          move_cursor(prev_cursor)
        end)
      end
      self:fuzzy_find_close()
    end,
  })

  -- exit fzf window when leaving insert mode
  vim.api.nvim_create_autocmd('InsertLeave', {
    group = augroup,
    buffer = buf,
    callback = function()
      self:fuzzy_find_close()
    end,
  })
end

---Toggle the menu
---@param opts dropbar_menu_opts_t? menu options passed to self:open()
function dropbar_menu_t:toggle(opts)
  if self.is_opened then
    self:close()
  else
    self:open(opts)
  end
end

return {
  dropbar_menu_t = dropbar_menu_t,
  dropbar_menu_entry_t = dropbar_menu_entry_t,
}
