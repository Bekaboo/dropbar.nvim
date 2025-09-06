local configs = require('dropbar.configs')
local utils = require('dropbar.utils')

---Sanitize string by removing the newline character and all that follows
---Symbols with newline in their name can cause error when creating menu
---buffers when calling `vim.api.nvim_buf_set_lines` with lines containing
---their names
---@param str string?
---@return string?
local function str_sanitize(str)
  return str and vim.gsplit(str, '\n')()
end

---@alias dropbar_symbol_range_t lsp_range_t

---Symbol in dropbar, basic element of `dropbar_t` and
---`dropbar_menu_entry_t`
---@class dropbar_symbol_t
---@field _ dropbar_symbol_t
---@field name string name of the symbol
---@field icon string icon of the symbol
---@field name_hl string? highlight group of the name of the symbol
---@field icon_hl string? highlight group of the icon of the symbol
---@field win integer? source window the symbol is shown in
---@field buf integer? source buffer the symbol is defined in
---@field view table? original view of the source window
---@field bar dropbar_t? winbar the symbol belongs to, if the symbol is shown inside a winbar
---@field menu dropbar_menu_t? menu associated with the winbar symbol, if the symbol is shown inside a winbar
---@field entry dropbar_menu_entry_t? dropbar entry the symbol belongs to, if the symbol is shown inside a menu
---@field children dropbar_symbol_t[]? children of the symbol
---@field siblings dropbar_symbol_t[]? siblings of the symbol
---@field bar_idx integer? index of the symbol in the winbar
---@field entry_idx integer? index of the symbol in the menu entry
---@field sibling_idx integer? index of the symbol in its siblings
---@field range dropbar_symbol_range_t?
---@field on_click fun(this: dropbar_symbol_t, min_width: integer?, n_clicks: integer?, button: string?, modifiers: string?)|false|nil callback to invoke when the symbol is clicked, force disable mouse click support when set to `false`
---@field callback_idx integer? idx of the on_click callback in `_G.dropbar.callbacks[buf][win]`, use this to index callback function because `bar_idx` could change after truncate
---@field opts dropbar_symbol_opts_t? options passed to `dropbar_symbol_t:new()` when the symbols is created
---@field data table? any data associated with the symbol
---@field cache table caches string representation, length, etc. for the symbol
---@field min_width integer? minimum width when truncated
local dropbar_symbol_t = {}

function dropbar_symbol_t:__index(k)
  return self._[k] or dropbar_symbol_t[k]
end

function dropbar_symbol_t:__newindex(k, v)
  if type(v) == 'string' then
    v = str_sanitize(v)
  end
  if k == 'name' or k == 'icon' then
    self.cache.decorated_str = nil
    self.cache.plain_str = nil
    self.cache.displaywidth = nil
    self.cache.bytewidth = nil
  elseif k == 'name_hl' or k == 'icon_hl' then
    self.cache.decorated_str = nil
  end
  self._[k] = v
end

---Create a new dropbar symbol instance with merged options
---@param opts dropbar_symbol_opts_t
---@return dropbar_symbol_t
function dropbar_symbol_t:merge(opts)
  return dropbar_symbol_t:new(
    setmetatable(
      vim.tbl_deep_extend('force', self._, opts),
      getmetatable(self._)
    ) --[[@as dropbar_symbol_opts_t]]
  )
end

---@class dropbar_symbol_opts_t
---@field _ dropbar_symbol_t?
---@field name string?
---@field icon string?
---@field name_hl string?
---@field icon_hl string?
---@field win integer? the source window the symbol is shown in
---@field buf integer? the source buffer the symbol is defined in
---@field view table? original view of the source window
---@field bar dropbar_t? the winbar the symbol belongs to, if the symbol is shown inside a winbar
---@field menu dropbar_menu_t? menu associated with the winbar symbol, if the symbol is shown inside a winbar
---@field entry dropbar_menu_entry_t? the dropbar entry the symbol belongs to, if the symbol is shown inside a menu
---@field children dropbar_symbol_t[]? children of the symbol
---@field siblings dropbar_symbol_t[]? siblings of the symbol
---@field bar_idx integer? index of the symbol in the winbar
---@field entry_idx integer? index of the symbol in the menu entry
---@field sibling_idx integer? index of the symbol in its siblings
---@field range dropbar_symbol_range_t?
---@field on_click fun(this: dropbar_symbol_t, min_width: integer?, n_clicks: integer?, button: string?, modifiers: string?)|false|nil force disable on_click when false
---@field jump fun(reorient: boolean?)?
---@field data table? any data associated with the symbol
---@field cache table? caches string representation, length, etc. for the symbol

---Create a dropbar symbol instance
---@param opts dropbar_symbol_opts_t? dropbar symbol structure
---@return dropbar_symbol_t
function dropbar_symbol_t:new(opts)
  if opts then
    for k, v in pairs(opts) do
      if type(v) == 'string' then
        opts[k] = str_sanitize(v)
      end
    end
  else
    opts = {}
  end
  return setmetatable({
    _ = setmetatable(
      vim.tbl_deep_extend('force', {
        name = '',
        icon = '',
        cache = {},
        opts = opts,
        on_click = opts and configs.opts.symbol.on_click,
      }, opts),
      getmetatable(opts)
    ),
  }, self)
end

---Delete a dropbar symbol instance
---@return nil
function dropbar_symbol_t:del()
  if self.menu then
    self.menu:del()
  end
end

---Concatenate inside a dropbar symbol to get the final string with highlights and click support
---@param plain boolean? whether to return a plain string without highlights and click support
---@return string
function dropbar_symbol_t:cat(plain)
  if self.cache.plain_str and plain then
    return self.cache.plain_str
  elseif self.cache.decorated_str and not plain then
    return self.cache.decorated_str
  end
  if plain then
    self.cache.plain_str = self.icon .. self.name
    return self.cache.plain_str
  end
  -- Escape `%` characters to prevent unintended statusline evaluation
  local icon_escaped = self.icon:gsub('%%', '%%%%')
  local name_escaped = self.name:gsub('%%', '%%%%')
  local icon_highlighted = utils.bar.hl(icon_escaped, self.icon_hl)
  local name_highlighted = utils.bar.hl(name_escaped, self.name_hl)
  if self.on_click and self.bar_idx then
    self.cache.decorated_str = utils.bar.make_clickable(
      icon_highlighted .. name_highlighted,
      string.format(
        'v:lua.dropbar.callbacks.buf%s.win%s.fn%s',
        self.bar.buf,
        self.bar.win,
        self.callback_idx
      )
    )
    return self.cache.decorated_str
  end
  self.cache.decorated_str = icon_highlighted .. name_highlighted
  return self.cache.decorated_str
end

---Get the display length of the dropbar symbol
---@return number
function dropbar_symbol_t:displaywidth()
  if self.cache.displaywidth then
    return self.cache.displaywidth
  end
  self.cache.displaywidth = vim.fn.strdisplaywidth(self:cat(true))
  return self.cache.displaywidth
end

---Get the byte length of the dropbar symbol
---@return number
function dropbar_symbol_t:bytewidth()
  if self.cache.bytewidth then
    return self.cache.bytewidth
  end
  self.cache.bytewidth = #self:cat(true)
  return self.cache.bytewidth
end

---Jump to the start of the symbol associated with the winbar symbol
---@param reorient boolean? whether to set view after jumping, default `true`
---@return nil
function dropbar_symbol_t:jump(reorient)
  if not self.range or not self.win then
    return
  end
  vim.cmd.normal({ "m'", bang = true })
  vim.api.nvim_win_set_cursor(self.win, {
    self.range.start.line + 1,
    self.range.start.character,
  })
  if reorient ~= false then
    vim.api.nvim_win_call(self.win, function()
      configs.opts.symbol.jump.reorient(self.win, self.range)
    end)
  end
end

---Preview the symbol in the source window
---@param orig_view table? use this view as original view
---@return nil
function dropbar_symbol_t:preview(orig_view)
  if not self.range or not self.win or not self.buf then
    return
  end
  self.view = orig_view or vim.api.nvim_win_call(self.win, vim.fn.winsaveview)
  utils.hl.range_single(self.buf, 'DropBarPreview', self.range)
  vim.api.nvim_win_set_cursor(self.win, {
    self.range.start.line + 1,
    self.range.start.character,
  })
  vim.api.nvim_win_call(self.win, function()
    configs.opts.symbol.preview.reorient(self.win, self.range)
  end)
end

---Clear the preview highlights in the source window
---@return nil
function dropbar_symbol_t:preview_restore_hl()
  if self.buf then
    utils.hl.range_single(self.buf, 'DropBarPreview')
  end
end

---Restore the source window to its original view
---@return nil
function dropbar_symbol_t:preview_restore_view()
  if self.view and self.win then
    vim.api.nvim_win_call(self.win, function()
      vim.fn.winrestview(self.view)
    end)
  end
end

---Temporarily change the content of a dropbar symbol
---@param field string
---@param new_val any
---@return nil
function dropbar_symbol_t:swap_field(field, new_val)
  self.data = self.data or {}
  self.data.swap = self.data.swap or {}
  self.data.swapped = self.data.swapped or {}
  self.data.swap[field] = self.data.swap[field] or self[field]
  table.insert(self.data.swapped, field)
  self[field] = new_val
end

---Restore the content of a dropbar symbol
---@return nil
function dropbar_symbol_t:restore()
  if not self.data or not self.data.swap then
    return
  end
  for _, field in ipairs(self.data.swapped) do
    self[field] = self.data.swap[field]
  end
  self.data.swap = nil
  self.data.swapped = nil
end

---Opts to create a new `dropbar_t`
---@class dropbar_opts_t
---@field buf integer?
---@field win integer?
---@field sources (dropbar_source_t[]|fun(buf: integer, win: integer):dropbar_source_t[])?
---@field separator dropbar_symbol_t?
---@field extends dropbar_symbol_t?
---@field padding {left: integer, right: integer}?

---Represents a winbar.
---
---It gets symbols (`dropbar_symbol_t`) from sources (`dropbar_source_t`) and
---renders them to a string.
---
---It is also responsible for registering `on_click` callbacks of each symbol
---in the global table `_G.dropbar.callbacks` so that nvim knows which
---function to call when a symbol is clicked.
---@class dropbar_t
---@field buf integer buffer the dropbar is attached to
---@field win integer window the dropbar is attached to
---@field sources dropbar_source_t[] sourcess that provide symbols to the dropbar
---@field separator dropbar_symbol_t seprarator icon between symbols provided by sources
---@field padding {left: integer, right: integer} padding to use between the winbar and the window border
---@field extends dropbar_symbol_t symbol to use at the end of a symbol when it is truncated
---@field components dropbar_symbol_t[] symbols from sources
---@field string_cache string string cache of the dropbar
---@field in_pick_mode boolean? whether the dropbar is in pick mode
---@field symbol_on_hover dropbar_symbol_t? previous symbol under mouse hovering in the dropbar
---@field last_update_request_time number? timestamp of the last update request in ms, see :h uv.now()
local dropbar_t = {}
dropbar_t.__index = dropbar_t

---Create a dropbar instance
---@param opts dropbar_opts_t?
---@return dropbar_t
function dropbar_t:new(opts)
  local dropbar = setmetatable(
    vim.tbl_deep_extend('force', {
      buf = vim.api.nvim_get_current_buf(),
      win = vim.api.nvim_get_current_win(),
      components = {},
      string_cache = '',
      sources = {},
      separator = dropbar_symbol_t:new({
        icon = configs.opts.icons.ui.bar.separator,
        icon_hl = 'DropBarIconUISeparator',
      }),
      extends = dropbar_symbol_t:new({
        icon = configs.opts.icons.ui.bar.extends,
      }),
      padding = configs.opts.bar.padding,
    }, opts or {}),
    self
  )
  -- vim.tbl_deep_extend drops metatables
  setmetatable(dropbar.separator, dropbar_symbol_t)
  setmetatable(dropbar.extends, dropbar_symbol_t)
  return dropbar
end

---Delete a dropbar instance
---@return nil
function dropbar_t:del()
  local buf = self.buf
  local win = self.win

  local cb_buf_idx = 'buf' .. buf -- index to get buf callbacks in global table
  local cb_win_idx = 'win' .. win -- index to get win callbacks in global table

  local bars = _G.dropbar.bars
  local callbacks = _G.dropbar.callbacks

  bars[buf][win] = nil
  if vim.tbl_isempty(bars[buf]) then
    bars[buf] = nil
  end

  callbacks[cb_buf_idx][cb_win_idx] = nil
  if vim.tbl_isempty(callbacks[cb_buf_idx]) then
    callbacks[cb_buf_idx] = nil
  end

  for _, component in ipairs(self.components) do
    component:del()
  end
end

---Get the display length of the dropbar
---@return integer
function dropbar_t:displaywidth()
  return vim.fn.strdisplaywidth(self:cat(true))
end

---Truncate the dropbar to fit the window width
---Side effect: change `dropbar_t.components`
---@return nil
function dropbar_t:truncate()
  if not self.win or not vim.api.nvim_win_is_valid(self.win) then
    self:del()
    return
  end
  local win_width = vim.api.nvim_win_get_width(self.win)
  local len = self:displaywidth()
  local delta = len - win_width
  for _, component in ipairs(self.components) do
    if delta <= 0 then
      break
    end
    local name_len = vim.fn.strdisplaywidth(component.name)
    local min_len = vim.fn.strdisplaywidth(
      vim.fn.strcharpart(component.name, 0, component.min_width or 1)
        .. self.extends.icon
    )
    if name_len > min_len then
      component.name = vim.fn.strcharpart(
        component.name,
        0,
        math.max(component.min_width or 1, name_len - delta - 1)
      ) .. self.extends.icon
      delta = delta - name_len + vim.fn.strdisplaywidth(component.name)
    end
  end

  -- Return if dropbar already fits in the window
  -- or there's only one or less symbol in dropbar (cannot truncate)
  if delta <= 0 or #self.components <= 1 then
    return
  end

  -- Consider replacing symbols at the start of the winbar with an extends sign
  local sym_extends = dropbar_symbol_t:new({
    icon = configs.opts.icons.ui.bar.extends,
    icon_hl = 'WinBarIconUIExtends',
    on_click = false,
    bar = self,
  })
  local extends_width = sym_extends:displaywidth()
  local sep_width = self.separator:displaywidth()
  local sym_first = self.components[1]
  local wdiff = extends_width - sym_first:displaywidth()
  -- Extends width larger than the first symbol, removing the
  -- first symbol will not help
  if wdiff >= 0 then
    return
  end
  -- Replace the first symbol with the extends sign and update delta
  self.components[1] = sym_extends
  delta = delta + wdiff
  sym_first:del()
  -- Keep removing symbols from the start, notice that self.components[1] is
  -- the extends symbol
  while delta > 0 and #self.components > 1 do
    local sym_remove = self.components[2]
    table.remove(self.components, 2)
    delta = delta - sym_remove:displaywidth() - sep_width
    sym_remove:del()
  end
  -- Update bar_idx of each symbol
  for i, component in ipairs(self.components) do
    component.bar_idx = i
  end
end

---Concatenate dropbar into a string with separator, highlight, and click support
---@param plain boolean? whether to return a plain string without substrings for highlights and click support
---@return string
function dropbar_t:cat(plain)
  if vim.tbl_isempty(self.components) then
    return ''
  end
  local result = nil
  for _, component in ipairs(self.components) do
    result = result
        and result .. self.separator:cat(plain) .. component:cat(plain)
      or component:cat(plain)
  end
  local padding_left = string.rep(' ', self.padding.left)
  local padding_right = string.rep(' ', self.padding.right)
  result = result and padding_left .. result .. padding_right or ''
  -- Must add highlights to padding when `plain` is false, else nvim will
  -- automatically truncate it
  return plain and result or utils.bar.hl(result, '')
end

---Reevaluate dropbar string from components and redraw dropbar
---@return nil
function dropbar_t:redraw()
  if configs.opts.bar.truncate then
    self:truncate()
  end
  local new_str = self:cat()
  if new_str ~= self.string_cache then
    self.string_cache = new_str
    vim.cmd.redrawstatus({
      bang = true,
      mods = { emsg_silent = true },
    })
  end
end

---Helper function to update dropbar (without debounce)
---Notice:
--- - Dropbar instance can be deleted if its source window or buffer is invalid
--- - Not updated when winbar is in pick mode or nvim is executing a macro
function dropbar_t:_update()
  if
    not self.win
    or not self.buf
    or not vim.api.nvim_win_is_valid(self.win)
    or not vim.api.nvim_buf_is_valid(self.buf)
  then
    self:del()
    return
  end

  -- Cancel current update if is inside pick mode or is executing a macro
  if self.in_pick_mode or vim.fn.reg_executing() ~= '' then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(self.win)
  for _, component in ipairs(self.components) do
    component:del()
  end

  self.components = {}
  _G.dropbar.callbacks['buf' .. self.buf]['win' .. self.win] = {}
  for _, source in ipairs(self.sources) do
    local symbols = source.get_symbols(self.buf, self.win, cursor)
    for _, symbol in ipairs(symbols) do
      symbol.bar_idx = #self.components + 1
      symbol.callback_idx = symbol.bar_idx
      symbol.bar = self
      table.insert(self.components, symbol)
      -- Register on_click callback for each symbol
      if symbol.on_click then
        ---@param min_width integer 0 if no N specified
        ---@param n_clicks integer number of clicks
        ---@param button string mouse button used
        ---@param modifiers string modifiers used
        ---@return nil
        _G.dropbar.callbacks['buf' .. self.buf]['win' .. self.win]['fn' .. symbol.callback_idx] = function(
          min_width,
          n_clicks,
          button,
          modifiers
        )
          symbol:on_click(min_width, n_clicks, button, modifiers)
        end
      end
    end
  end

  self:redraw()
end

---Update dropbar components from sources and redraw dropbar with debounce,
---supposed to be called on events `CursorMoved`, `CursorMovedI`,
---`TextChanged`, and `TextChangedI`
---@return nil
function dropbar_t:update()
  local first_request = not self.last_update_request_time
  local request_time = vim.uv.now()
  self.last_update_request_time = request_time

  -- Update immediately for the first update request to make UI snappier
  if first_request then
    self:_update()
    return
  end

  vim.defer_fn(function()
    if self.last_update_request_time ~= request_time then
      return
    end
    self:_update()
  end, configs.opts.bar.update_debounce)
end

---Execute a function in pick mode
---Side effect: change `dropbar_t.in_pick_mode`
---@param fn fun(...): ...?
---@return ...?
function dropbar_t:pick_mode_wrap(fn, ...)
  local pick_mode = self.in_pick_mode
  self.in_pick_mode = true
  local results = { fn(...) }
  self.in_pick_mode = pick_mode
  return unpack(results)
end

---Pick a component from dropbar
---Side effect: change `dropbar_t.in_pick_mode`, `dropbar_t.components`
---@param idx integer? index of the component to pick
---@return nil
function dropbar_t:pick(idx)
  self:pick_mode_wrap(function()
    if #self.components == 0 then
      return
    end
    if idx then
      if self.components[idx] then
        self.components[idx]:on_click()
      end
      return
    end

    ---Clickable symbols
    ---@type dropbar_symbol_t[]
    local clickables = vim.tbl_filter(function(component)
      return component.on_click
    end, self.components)
    local n_clickables = #clickables

    -- If has only one component, pick it directly
    if n_clickables == 1 then
      clickables[1]:on_click()
      return
    end

    -- Else assign the chars on each component and wait for user input to pick
    local shortcuts = {}
    local pivots = {}
    for i = 1, #configs.opts.bar.pick.pivots do
      table.insert(pivots, configs.opts.bar.pick.pivots:sub(i, i))
    end
    local n_pivots = #pivots
    local n_chars = math.ceil(math.log(n_clickables, n_pivots))
    for exp = 0, n_chars - 1 do
      for i = 1, n_clickables do
        local new_char =
          pivots[math.floor((i - 1) / n_pivots ^ exp) % n_pivots + 1]
        shortcuts[i] = new_char .. (shortcuts[i] or '')
      end
    end
    -- Display the chars on each component
    for i, component in ipairs(clickables) do
      local shortcut = shortcuts[i]
      local icon_width = vim.fn.strdisplaywidth(component.icon)
      component:swap_field(
        'icon',
        -- Add at least 1 space after winbar shortcut pivots, see
        -- https://github.com/Bekaboo/dropbar.nvim/pull/218
        shortcut .. string.rep(' ', math.max(1, icon_width - #shortcut))
      )
      component:swap_field('icon_hl', 'DropBarIconUIPickPivot')
    end
    self:redraw()
    -- Read the input from user
    local shortcut_read = ''
    for _ = 1, n_chars do
      shortcut_read = shortcut_read
        .. vim.fn.nr2char(vim.fn.getchar() --[[@as integer]])
    end
    -- Restore the original content of each component
    for _, component in ipairs(clickables) do
      component:restore()
    end
    self:redraw()
    -- Execute the on_click callback of the component
    for i, shortcut in ipairs(shortcuts) do
      local sym = clickables[i]
      if shortcut == shortcut_read and sym.on_click then
        sym:on_click()
        break
      end
    end
  end)
end

---Get the component at the given position in the winbar
---@param col integer 0-indexed, byte-indexed
---@param look_ahead boolean? whether to look ahead for the next component if the given position does not contain a component
---@return dropbar_symbol_t?
---@return {start: integer, end: integer}? range of the component in the menu, byte-indexed, 0-indexed, start-inclusive, end-exclusive
function dropbar_t:get_component_at(col, look_ahead)
  local col_offset = self.padding.left
  for _, component in ipairs(self.components) do
    -- Use display width instead of byte width here because
    -- vim.fn.getmousepos().wincol is the display width of the mouse position
    -- and also the menu window needs to be opened with relative to the
    -- display position of the winbar symbol to be aligned with the symbol
    -- on the screen
    local component_len = component:displaywidth()
    if
      (look_ahead or col >= col_offset) and col < col_offset + component_len
    then
      return component,
        {
          start = col_offset,
          ['end'] = col_offset + component_len,
        }
    end
    col_offset = col_offset + component_len + self.separator:displaywidth()
  end
  return nil, nil
end

---Highlight the symbol at `bar_idx` as current context
---@param bar_idx integer see `dropbar_symbol_t.bar_idx`
---@return nil
function dropbar_t:update_current_context_hl(bar_idx)
  local symbol = self.components[bar_idx]
  if not symbol then
    return
  end
  local hl_currentcontext_icon = '_DropBarIconCurrentContext'
  local hl_currentcontext_name = '_DropBarCurrentContext'
  symbol:restore()
  vim.api.nvim_set_hl(
    0,
    hl_currentcontext_icon,
    utils.hl.merge('WinBarNC', symbol.icon_hl, 'DropBarCurrentContextIcon')
  )
  vim.api.nvim_set_hl(
    0,
    hl_currentcontext_name,
    utils.hl.merge('WinBarNC', symbol.name_hl, 'DropBarCurrentContextName')
  )
  symbol:swap_field('icon_hl', hl_currentcontext_icon)
  symbol:swap_field('name_hl', hl_currentcontext_name)
  self:redraw()
end

---Highlight the symbol at col as if the mouse is hovering on it
---@param col integer? displaywidth-indexed, 0-indexed mouse position, nil to clear the hover highlights
---@return nil
function dropbar_t:update_hover_hl(col)
  local symbol = col and self:get_component_at(col)
  if not symbol then
    if self.symbol_on_hover then
      self.symbol_on_hover:restore()
      self.symbol_on_hover = nil
      self:redraw()
    end
    return
  end
  if not symbol.on_click or symbol == self.symbol_on_hover then
    return
  end
  local hl_hover_icon = '_DropBarIconHover'
  local hl_hover_name = '_DropBarHover'
  local hl_winbar = vim.api.nvim_get_current_win() == self.win and 'WinBar'
    or 'WinbarNC'
  vim.api.nvim_set_hl(
    0,
    hl_hover_icon,
    utils.hl.merge(hl_winbar, symbol.icon_hl, 'DropBarHover')
  )
  vim.api.nvim_set_hl(
    0,
    hl_hover_name,
    utils.hl.merge(hl_winbar, symbol.name_hl, 'DropBarHover')
  )
  symbol:swap_field('icon_hl', hl_hover_icon)
  symbol:swap_field('name_hl', hl_hover_name)
  if self.symbol_on_hover then
    self.symbol_on_hover:restore()
  end
  self.symbol_on_hover = symbol
  self:redraw()
end

---Get the string representation of the dropbar
---@deprecated
---@return string
function dropbar_t.__tostring()
  vim.notify_once(
    '[dropbar.nvim] tostring(dropbar_t) is deprecated, use dropbar_t() instead',
    vim.log.levels.WARN
  )
  return ''
end

---Get the string representation of the dropbar
---@return string
function dropbar_t:__call()
  if vim.tbl_isempty(self.components) then
    self:update()
  end
  return self.string_cache
end

return {
  dropbar_t = dropbar_t,
  dropbar_symbol_t = dropbar_symbol_t,
}
