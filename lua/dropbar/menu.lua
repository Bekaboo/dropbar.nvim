local bar = require('dropbar.bar')
local utils = require('dropbar.utils')
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
---@field prev_menu dropbar_menu_t? previous menu, assigned when calling new() or automatically determined in open()
---@field clicked_at integer[]? last position where the menu was clicked, byte-indexed, 1,0-indexed
---@field prev_cursor integer[]? previous cursor position
---@field symbol_previewed dropbar_symbol_t? symbol being previewed
---@field fzf_state fzf_state_t? fuzzy-finding state, or nil if not currently fuzzy-finding
---@field data table? any data associated with the menu
local dropbar_menu_t = {}
dropbar_menu_t.__index = dropbar_menu_t

---Create a dropbar menu instance
---@param opts dropbar_menu_t?
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
    if vim.api.nvim_buf_is_valid(self.buf) then
      vim.api.nvim_buf_delete(self.buf, {})
    end
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
function dropbar_menu_t:eval_win_configs()
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

---Update DroPbarMenuHover* highlights according to pos
---@param pos integer[]? byte-indexed, 1,0-indexed cursor/mouse position
---@return nil
function dropbar_menu_t:update_hover_hl(pos)
  utils.hl.range_single(self.buf, 'DropBarMenuHoverSymbol', nil)
  utils.hl.range_single(self.buf, 'DropBarMenuHoverIcon', nil)
  utils.hl.range_single(self.buf, 'DropBarMenuHoverEntry', nil)
  if not pos then
    return
  end
  utils.hl.line_single(self.buf, 'DropBarMenuHoverEntry', pos[1])
  local component, range = self:get_component_at({ pos[1], pos[2] })
  if component and component.on_click and range then
    utils.hl.range_single(
      self.buf,
      component and component.name == '' and 'DropBarMenuHoverIcon'
        or 'DropBarMenuHoverSymbol',
      {
        start = {
          line = pos[1] - 1,
          character = range.start,
        },
        ['end'] = {
          line = pos[1] - 1,
          character = range['end'],
        },
      }
    )
  end
end

---Update highlights for current context according to pos
---@param linenr integer? 1-indexed line number
function dropbar_menu_t:update_current_context_hl(linenr)
  if self.buf then
    utils.hl.line_single(self.buf, 'DropBarMenuCurrentContext', linenr)
  end
end

---Add highlights to the menu buffer
---@param hl_info dropbar_menu_hl_info_t[][]
---@return nil
function dropbar_menu_t:add_hl(hl_info)
  if not self.buf then
    return
  end
  for linenr, hl_line_info in ipairs(hl_info) do
    for _, hl_symbol_info in ipairs(hl_line_info) do
      vim.api.nvim_buf_add_highlight(
        self.buf,
        hl_symbol_info.ns or -1,
        hl_symbol_info.hlgroup,
        linenr - 1, -- 0-indexed
        hl_symbol_info.start,
        hl_symbol_info['end']
      )
    end
  end
end

---Fill the menu buffer with entries in `self.entries` and add
---highlights to the buffer
function dropbar_menu_t:fill_buf()
  local lines = {} ---@type string[]
  local hl_info = {} ---@type dropbar_menu_hl_info_t[][]
  for _, entry in ipairs(self.entries) do
    local line, entry_hl_info = entry:cat()
    -- Pad lines with spaces to the width of the window
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
  self:add_hl(hl_info)
end

---Make a buffer for the menu and set buffer-local keymaps
---Must be called after self:eval_win_configs()
---Side effect: change self.buf, self.hl_info
---@return nil
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

      if configs.opts.menu.preview then
        self:preview_symbol_at(cursor, true)
      end

      if configs.opts.menu.quick_navigation then
        self:quick_navigation(cursor)
      else
        self.prev_cursor = cursor
      end

      -- Update hover highlights
      self:update_hover_hl(self.prev_cursor)
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

---Open the popup window with win configs and opts,
---must be called after self:make_buf()
---@return nil
function dropbar_menu_t:open_win()
  if self.is_opened then
    return
  end
  self.is_opened = true

  self.win = vim.api.nvim_open_win(self.buf, true, self._win_configs)
  vim.wo[self.win].scrolloff = 0
  vim.wo[self.win].sidescrolloff = 0
  vim.wo[self.win].winhl = table.concat({
    'NormalFloat:DropBarMenuNormalFloat',
    'FloatBorder:DropBarMenuFloatBorder',
  }, ',')
end

---Override menu options
---@param opts dropbar_menu_t?
---@return nil
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
---@param opts dropbar_menu_t?
---@return nil
function dropbar_menu_t:open(opts)
  if self.is_opened then
    return
  end
  self:override(opts)

  self.prev_menu = _G.dropbar.menus[self.prev_win]
  if self.prev_menu then
    -- if the prev menu has an existing sub-menu, close the sub-menu first
    if self.prev_menu.sub_menu then
      self.prev_menu.sub_menu:close()
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
end

---Close the menu
---@param restore_view boolean? whether to restore the source win view, default true
---@return nil
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
    local prev_menu = _G.dropbar.menus[self.prev_win]
    if prev_menu then
      if prev_menu.cursor then
        prev_menu:update_current_context_hl(prev_menu.cursor[1])
      else
        prev_menu:update_current_context_hl(nil)
      end
    end
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
  -- Finish preview
  if configs.opts.menu.preview then
    self:finish_preview(restore_view)
  end
end

---Preview the symbol at the given position
---@param pos integer[] 1,0-indexed, byte-indexed position
---@param look_ahead boolean? whether to look ahead for a component
---@return nil
function dropbar_menu_t:preview_symbol_at(pos, look_ahead)
  if self.prev_cursor then
    local prev_component = self:get_component_at(self.prev_cursor, look_ahead)
    if prev_component then
      prev_component:preview_restore_view()
    end
  end
  local component = self:get_component_at(pos, look_ahead)
  if component then
    self.symbol_previewed = component
    component:preview()
  end
end

---Finish the preview in current menu
---@param restore_view boolean? whether to restore the source win view, default true
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
---@return nil
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
end

---Stop fuzzy finding and clean up allocated memory, optionally fixing the
---cursor position to counteract cursor movement caused by entering and leaving
---insert mode
---@param fix_cursor boolean?
---@version JIT
function dropbar_menu_t:stop_fuzzy_find(fix_cursor)
  -- todo: handle case when restoring cursor
  -- that only has one clickable component when
  -- fixing the cursor (quick navigation?)
  fix_cursor = fix_cursor == nil and true or fix_cursor
  if not self.fzf_state then
    return
  end
  if self.is_opened then
    self:fuzzy_find_restore_entries()
    vim.bo[self.buf].modifiable = false
  end
  local input_win = self.fzf_state.win
  self.fzf_state:gc()
  self.fzf_state = nil
  if vim.api.nvim_win_is_valid(input_win) then
    vim.cmd('silent! stopinsert')
    vim.api.nvim_win_close(input_win, false)
    if fix_cursor and self.is_opened then
      vim.schedule(function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local new_col = math.min(cursor[2] + 1, vim.fn.col('$') - 2)
        vim.api.nvim_win_set_cursor(0, { cursor[1], new_col })
      end)
    end
  end
  _G.dropbar.menus[input_win] = nil
end

---Click on the currently selected fuzzy find menu entry, choosing the component
---to click according to `component`.
---
---If `component` is a `number`, the `component`-nth symbol is selected, unless
---`0` or `-1` is supplied, in which case the *first* or *last* clickable component
---is selected, respectively. If it is a `function`, it receives the `dropbar_menu_entry_t`
---as an argument and should return the `dropbar_symbol_t` that is to be clicked.
---@param component? number|dropbar_symbol_t|fun(entry: dropbar_menu_entry_t):dropbar_symbol_t?
---@version JIT
function dropbar_menu_t:click_on_fuzzy_find_entry(component)
  if not self.fzf_state then
    return
  end
  if vim.api.nvim_buf_line_count(self.buf) < 1 then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(self.win)
  local menu_entry = self.entries[cursor[1]]
  if not menu_entry then
    return
  end
  cursor[1] = menu_entry.idx
  self:stop_fuzzy_find(false)
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
  end)
end

---Enable fuzzy finding mode
---@param opts? table<string, any>
---@version JIT
function dropbar_menu_t:fuzzy_find(opts)
  opts = vim.tbl_extend('keep', opts or {}, {
    retain_inner_spaces = true,
    char_pattern = '[%w%p]',
    hl = {
      fg = vim.api.nvim_get_hl(0, { name = 'htmlTag', link = false }).fg,
      underline = true,
    },
    prompt = '%#htmlTag# ',
  })

  if not jit then
    vim.notify('Fuzzy finding requires LuaJIT', vim.log.levels.ERROR)
    return
  elseif not utils.fzf then
    vim.notify('fzf-lib is not installed', vim.log.levels.ERROR)
    return
  elseif not utils.fzf.load() then
    vim.notify('Error loading fzf-lib', vim.log.levels.ERROR)
    return
  end

  -- cache namespaces and types
  local fzf_lib = utils.fzf.lib
  local fzf_native = utils.fzf.native
  local fzf_entry_array_t = utils.fzf.fzf_entry_array_t
  local copy_entry = utils.fzf.copy_entry
  local ffi = require('ffi')

  if self.fzf_state then
    self:stop_fuzzy_find(false)
  end

  local ns_name = 'DropBarFzf' .. tostring(self.win)
  local augroup = vim.api.nvim_create_augroup(ns_name, { clear = true })
  local ns_id = vim.api.nvim_create_namespace(ns_name)

  vim.api.nvim_set_hl(0, 'DropBarFzfMatch', opts.hl)

  vim.bo[self.buf].modifiable = true
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(
    buf,
    false,
    vim.tbl_extend('force', self._win_configs, {
      row = self._win_configs.row + self._win_configs.height,
      col = self._win_configs.col - 1,
      height = 1,
      border = 'single',
    }, opts.win_configs or {})
  )
  vim.wo[win].stc = opts.prompt
  _G.dropbar.menus[win] = self

  local should_preview = configs.opts.menu.preview
  local function move_cursor(pos)
    vim.api.nvim_win_set_cursor(self.win, pos)
    self:update_hover_hl(pos)
    if should_preview then
      self:preview_symbol_at(pos)
    end
  end

  local num_entries = #self.entries

  -- This is used as a sorting proxy. Instead of sorting the entries directly,
  -- we sort the proxy array and then use the indices to collect the entries.
  -- The proxy's element count is twice that of the entries because
  -- a merge sorting algorithm is used, requiring 2 arrays
  local proxy_buff = ffi.new('int32_t[?]', num_entries * 2)

  self.fzf_state = utils.fzf.fzf_state_t:new(self, win, opts)

  local keymaps = vim.tbl_extend('force', {
    ['<LeftMouse>'] = function()
      local mouse = vim.fn.getmousepos()
      if mouse.winid ~= self.win then
        local default_func = configs.opts.menu.keymaps['<LeftMouse>']
        if type(default_func) == 'function' then
          default_func()
        end
        self:stop_fuzzy_find(false)
        return
      elseif mouse.winrow > vim.api.nvim_buf_line_count(self.buf) then
        return
      end
      vim.api.nvim_win_set_cursor(self.win, { mouse.line, mouse.column - 1 })
      self:click_on_fuzzy_find_entry(function(entry)
        return entry:get_component_at(mouse.column - 1, true)
      end)
    end,
    ['<Esc>'] = function()
      self:stop_fuzzy_find(true)
    end,
    ['<Enter>'] = function()
      self:click_on_fuzzy_find_entry(-1)
    end,
    ['<S-Enter>'] = function()
      self:click_on_fuzzy_find_entry(nil)
    end,
    ['<Up>'] = function()
      if vim.api.nvim_buf_line_count(self.buf) <= 1 then
        return
      end
      local cursor = vim.api.nvim_win_get_cursor(self.win)
      cursor[1] = math.max(1, cursor[1] - 1)
      move_cursor(cursor)
    end,
    ['<Down>'] = function()
      local line_count = vim.api.nvim_buf_line_count(self.buf)
      if line_count <= 1 then
        return
      end
      local cursor = vim.api.nvim_win_get_cursor(self.win)
      cursor[1] = math.min(line_count, cursor[1] + 1)
      move_cursor(cursor)
    end,
  }, opts.keymaps or {})

  for key, func in pairs(keymaps) do
    vim.keymap.set('i', key, func, { buffer = buf })
  end

  vim.api.nvim_set_current_win(win)
  vim.schedule(function()
    move_cursor({ 1, 1 })
    vim.cmd('silent! startinsert')
  end)

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
    for i = 0, num_entries - 1 do
      local entry = fzf_state.entries[i]
      entry.score = fzf_lib.get_score(entry.str, pattern, fzf_state.slab)
      entry.first_position = 0
      if entry.pos ~= nil then
        fzf_native.fzf_free_positions(entry.pos)
        entry.pos = nil
      end
      if entry.score > 1 then
        local positions =
          fzf_native.fzf_get_positions(entry.str, pattern, fzf_state.slab)
        if positions and positions.size > 0 then
          entry.first_position = positions.data[0] + 1
          entry.pos = positions
        end
      end
    end
    fzf_lib.free_pattern(pattern)

    local proxy_ptr =
      utils.fzf.sort_entries(fzf_state.entries, num_entries, proxy_buff)
    local new_entries = fzf_entry_array_t(num_entries)
    local old_entries_ptr = fzf_state.entries + 0
    for i = 0, num_entries - 1 do
      local fzf_entry = old_entries_ptr[proxy_ptr[i]]
      copy_entry(new_entries[i], fzf_entry)
      if fzf_entry.score > 1 then
        self.entries[i + 1] = fzf_state.menu_entries[fzf_entry.index]
      else
        self.entries[i + 1] = nil
        if fzf_entry.pos ~= nil then
          fzf_native.fzf_free_positions(fzf_entry.pos)
          fzf_entry.pos = nil
          fzf_entry.first_position = 0
        end
      end
    end
    fzf_state.entries = new_entries

    vim.schedule(function()
      vim.api.nvim_buf_clear_namespace(self.buf, ns_id, 0, -1)
      self:fill_buf()
      for i = 0, num_entries - 1 do
        local entry = fzf_state.entries[i]
        -- if score >= 2 then positions is either valid or nil and freed
        if entry.score >= 2 then
          local locations = entry.locations
          local data = entry.pos.data
          for pos_idx = 0, tonumber(entry.pos.size) - 1 do
            local pos = locations[data[pos_idx]]
            vim.api.nvim_buf_set_extmark(self.buf, ns_id, i, pos, {
              end_col = pos + 1,
              hl_group = 'DropBarFzfMatch',
              priority = vim.highlight.priorities.user + 10,
            })
          end
          fzf_native.fzf_free_positions(entry.pos)
          entry.pos = nil
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
    callback = function()
      self:stop_fuzzy_find(false)
    end,
    once = true,
  })
end

---Toggle the menu
---@param opts dropbar_menu_t? menu options passed to self:open()
---@return nil
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
