local configs = require('dropbar.configs')
local utils = require('dropbar.utils')

---Add highlight to a string
---@param str string
---@param hlgroup string?
---@return string
local function hl(str, hlgroup)
  if not hlgroup or hlgroup:match('^%s*$') then
    return str
  end
  return string.format('%%#%s#%s%%*', hlgroup, str or '')
end

---Make a dropbar string clickable
---@param str string
---@param callback string
---@return string
local function make_clickable(str, callback)
  return string.format('%%@%s@%s%%X', callback, str)
end

---@alias dropbar_symbol_range_t lsp_range_t

---@class dropbar_symbol_t
---@field _ dropbar_symbol_t
---@field name string
---@field icon string
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
---@field on_click fun(this: dropbar_symbol_t, min_width: integer?, n_clicks: integer?, button: string?, modifiers: string?)|false? force disable on_click when false
---@field data table? any data associated with the symbol
---@field cache table caches string representation, length, etc. for the symbol
local dropbar_symbol_t = {}

function dropbar_symbol_t:__index(k)
  return self._[k] or dropbar_symbol_t[k]
end

function dropbar_symbol_t:__newindex(k, v)
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
---@param opts dropbar_symbol_t
---@return dropbar_symbol_t
function dropbar_symbol_t:merge(opts)
  return dropbar_symbol_t:new(
    setmetatable(
      vim.tbl_deep_extend('force', self._, opts),
      getmetatable(self._)
    )
  )
end

---Create a dropbar symbol instance
---@param opts dropbar_symbol_t? dropbar symbol structure
---@return dropbar_symbol_t
function dropbar_symbol_t:new(opts)
  return setmetatable({
    _ = setmetatable(
      vim.tbl_deep_extend('force', {
        name = '',
        icon = '',
        cache = {},
        on_click = opts
          ---@param this dropbar_symbol_t
          and function(this, _, _, _, _)
            -- Update current context highlights if the symbol
            -- is shown inside a menu
            if this.entry and this.entry.menu then
              this.entry.menu:update_current_context_hl(this.entry.idx)
            elseif this.bar then
              this.bar:update_current_context_hl(this.bar_idx)
            end

            -- Determine menu configs
            local prev_win = nil ---@type integer?
            local entries_source = nil ---@type dropbar_symbol_t[]?
            local init_cursor = nil ---@type integer[]?
            local win_configs = {}
            if this.bar then -- If symbol inside a winbar
              prev_win = this.bar.win
              entries_source = opts.siblings
              init_cursor = opts.sibling_idx and { opts.sibling_idx, 0 }
              ---@param tbl number[]
              local function _sum(tbl)
                local sum = 0
                for _, v in ipairs(tbl) do
                  sum = sum + v
                end
                return sum
              end
              if this.bar.in_pick_mode then
                win_configs.relative = 'win'
                win_configs.win = vim.api.nvim_get_current_win()
                win_configs.row = 0
                win_configs.col = this.bar.padding.left
                  + _sum(vim.tbl_map(
                    function(component)
                      return component:displaywidth()
                        + this.bar.separator:displaywidth()
                    end,
                    vim.tbl_filter(function(component)
                      return component.bar_idx < this.bar_idx
                    end, this.bar.components)
                  ))
              end
            elseif this.entry and this.entry.menu then -- If inside a menu
              prev_win = this.entry.menu.win
              entries_source = opts.children
            end

            -- Toggle existing menu
            if this.menu then
              this.menu:toggle({
                prev_win = prev_win,
                win_configs = win_configs,
              })
              return
            end

            -- Create a new menu for the symbol
            if not entries_source or vim.tbl_isempty(entries_source) then
              return
            end
            local menu = require('dropbar.menu')
            this.menu = menu.dropbar_menu_t:new({
              prev_win = prev_win,
              cursor = init_cursor,
              win_configs = win_configs,
              ---@param sym dropbar_symbol_t
              entries = vim.tbl_map(function(sym)
                local menu_indicator_icon =
                  configs.opts.icons.ui.menu.indicator
                local menu_indicator_on_click = nil
                if not sym.children or vim.tbl_isempty(sym.children) then
                  menu_indicator_icon = string.rep(
                    ' ',
                    vim.fn.strdisplaywidth(menu_indicator_icon)
                  )
                  menu_indicator_on_click = false
                end
                return menu.dropbar_menu_entry_t:new({
                  components = {
                    sym:merge({
                      name = '',
                      icon = menu_indicator_icon,
                      icon_hl = 'DropBarIconUIIndicator',
                      on_click = menu_indicator_on_click,
                    }),
                    sym:merge({
                      on_click = function()
                        local current_menu = this.menu
                        while current_menu and current_menu.prev_menu do
                          current_menu = current_menu.prev_menu
                        end
                        if current_menu then
                          current_menu:close(false)
                        end
                        sym:jump()
                      end,
                    }),
                  },
                })
              end, entries_source),
            })
            this.menu:toggle()
          end,
      }, opts or {}),
      getmetatable(opts or {})
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

---Concatenate inside a dropbar symbol to get the final string
---@param plain boolean?
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
  local icon_highlighted = hl(self.icon, self.icon_hl)
  local name_highlighted = hl(self.name, self.name_hl)
  if self.on_click and self.bar_idx then
    self.cache.decorated_str = make_clickable(
      icon_highlighted .. name_highlighted,
      string.format(
        'v:lua.dropbar.on_click_callbacks.buf%s.win%s.fn%s',
        self.bar.buf,
        self.bar.win,
        self.bar_idx
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
---@return nil
function dropbar_symbol_t:jump()
  if not self.range or not self.win then
    return
  end
  vim.api.nvim_win_set_cursor(self.win, {
    self.range.start.line + 1,
    self.range.start.character,
  })
  vim.api.nvim_win_call(self.win, function()
    configs.opts.symbol.jump.reorient(self.win, self.range)
  end)
end

---Preview the symbol in the source window
---@return nil
function dropbar_symbol_t:preview()
  if not self.range then
    return
  end
  if not self.win or not self.buf then
    return
  end
  self.view = vim.api.nvim_win_call(self.win, vim.fn.winsaveview)
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

---@class dropbar_opts_t
---@field buf integer?
---@field win integer?
---@field sources dropbar_source_t[]?
---@field separator dropbar_symbol_t?
---@field extends dropbar_symbol_t?
---@field padding {left: integer, right: integer}?

---@class dropbar_t
---@field buf integer
---@field win integer
---@field sources dropbar_source_t[]
---@field separator dropbar_symbol_t
---@field padding {left: integer, right: integer}
---@field extends dropbar_symbol_t
---@field components dropbar_symbol_t[]
---@field string_cache string
---@field in_pick_mode boolean?
---@field symbol_on_hover dropbar_symbol_t?
---@field last_update_request_time float? timestamp of the last update request in ms, see :h uv.hrtime()
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
  _G.dropbar.bars[self.buf][self.win] = nil
  _G.dropbar.on_click_callbacks[self.buf][self.win] = nil
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
---Side effect: change dropbar.components
---@return nil
function dropbar_t:truncate()
  local win_width = vim.api.nvim_win_get_width(self.win)
  local len = self:displaywidth()
  local delta = len - win_width
  for _, component in ipairs(self.components) do
    if delta <= 0 then
      break
    end
    local name_len = vim.fn.strdisplaywidth(component.name)
    local min_len =
      vim.fn.strdisplaywidth(component.name:sub(1, 1) .. self.extends.icon)
    if name_len > min_len then
      component.name = vim.fn.strcharpart(
        component.name,
        0,
        math.max(1, name_len - delta - 1)
      ) .. self.extends.icon
      delta = delta - name_len + vim.fn.strdisplaywidth(component.name)
    end
  end
end

---Concatenate dropbar into a string with separator and highlight
---@param plain boolean?
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
  return plain and result or hl(result, 'DropBar')
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
    vim.cmd('silent! redrawstatus')
  end
end

---Update dropbar components from sources and redraw dropbar, supposed to be
---called at CursorMoved, CurosrMovedI, TextChanged, and TextChangedI
---Not updating when executing a macro
---@return nil
function dropbar_t:update()
  local request_time = vim.uv.hrtime() / 1e6
  self.last_update_request_time = request_time
  vim.defer_fn(function()
    if
      not self.win
      or not self.buf
      or not vim.api.nvim_win_is_valid(self.win)
      or not vim.api.nvim_buf_is_valid(self.buf)
    then
      self:del()
      return
    end
    if
      -- Cancel current update if another update request is sent within
      -- the update interval
      (
        self.last_update_request_time
        -- Compare the last update request time and time when the current
        -- update request was made to make sure that there is a new update
        -- request after the current one if we are going to cancel the current
        -- one
        and self.last_update_request_time > request_time
        and vim.uv.hrtime() / 1e6 - self.last_update_request_time
          < configs.opts.general.update_interval
      )
      or vim.fn.reg_executing() ~= ''
      or self.in_pick_mode
    then
      return
    end
    local cursor = vim.api.nvim_win_get_cursor(self.win)
    for _, component in ipairs(self.components) do
      component:del()
    end
    self.components = {}
    _G.dropbar.on_click_callbacks['buf' .. self.buf]['win' .. self.win] = {}
    for _, source in ipairs(self.sources) do
      local symbols = source.get_symbols(self.buf, self.win, cursor)
      for _, symbol in ipairs(symbols) do
        symbol.bar_idx = #self.components + 1
        symbol.bar = self
        table.insert(self.components, symbol)
        -- Register on_click callback for each symbol
        if symbol.on_click then
          ---@param min_width integer 0 if no N specified
          ---@param n_clicks integer number of clicks
          ---@param button string mouse button used
          ---@param modifiers string modifiers used
          ---@return nil
          _G.dropbar.on_click_callbacks['buf' .. self.buf]['win' .. self.win]['fn' .. symbol.bar_idx] = function(
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
  end, configs.opts.general.update_interval)
end

---Execute a function in pick mode
---Side effect: change dropbar.in_pick_mode
---@generic T
---@param fn fun(...): T?
---@return T?
function dropbar_t:pick_mode_wrap(fn, ...)
  local pick_mode = self.in_pick_mode
  self.in_pick_mode = true
  local result = fn(...)
  self.in_pick_mode = pick_mode
  return result
end

---Pick a component from dropbar
---Side effect: change dropbar.in_pick_mode, dropbar.components
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
    -- If has only one component, pick it directly
    if #self.components == 1 then
      self.components[1]:on_click()
      return
    end
    -- Else Assign the chars on each component and wait for user input to pick
    local shortcuts = {}
    local pivots = {}
    for i = 1, #configs.opts.bar.pick.pivots do
      table.insert(pivots, configs.opts.bar.pick.pivots:sub(i, i))
    end
    local n_chars = math.ceil(math.log(#self.components, #pivots))
    for exp = 0, n_chars - 1 do
      for i = 1, #self.components do
        local new_char =
          pivots[math.floor((i - 1) / (#pivots) ^ exp) % #pivots + 1]
        shortcuts[i] = new_char .. (shortcuts[i] or '')
      end
    end
    -- Display the chars on each component
    for i, component in ipairs(self.components) do
      local shortcut = shortcuts[i]
      local icon_width = vim.fn.strdisplaywidth(component.icon)
      component:swap_field(
        'icon',
        shortcut .. string.rep(' ', icon_width - #shortcut)
      )
      component:swap_field('icon_hl', 'DropBarIconUIPickPivot')
    end
    self:redraw()
    -- Read the input from user
    local shortcut_read = ''
    for _ = 1, n_chars do
      shortcut_read = shortcut_read .. vim.fn.nr2char(vim.fn.getchar())
    end
    -- Restore the original content of each component
    for _, component in ipairs(self.components) do
      component:restore()
    end
    self:redraw()
    -- Execute the on_click callback of the component
    for i, shortcut in ipairs(shortcuts) do
      if shortcut == shortcut_read and self.components[i].on_click then
        self.components[i]:on_click()
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

---Highlight the symbol at bar_idx as current context
---@param bar_idx integer see dropbar_symbol_t.bar_idx
---@return nil
function dropbar_t:update_current_context_hl(bar_idx)
  local symbol = self.components[bar_idx]
  if not symbol then
    return
  end
  local hl_currentcontext_icon = '_DropBarIconCurrentContext'
  local hl_currentcontext_name = '_DropBarCurrentContext'
  vim.api.nvim_set_hl(
    0,
    hl_currentcontext_icon,
    utils.hl.merge(symbol.icon_hl or 'WinBar', 'DropBarCurrentContext')
  )
  vim.api.nvim_set_hl(
    0,
    hl_currentcontext_name,
    utils.hl.merge(symbol.name_hl or 'WinBar', 'DropBarCurrentContext')
  )
  symbol:swap_field('icon_hl', hl_currentcontext_icon)
  symbol:swap_field('name_hl', hl_currentcontext_name)
  self:redraw()
end

---Highlight the symbol at col as if the mouse is hovering on it
---@param col integer? displaywidth-indexed, 0-indexed mouse position, nil to clear the hover highlights
---@return nil
function dropbar_t:update_hover_hl(col)
  if not col then
    if self.symbol_on_hover then
      self.symbol_on_hover:restore()
      self.symbol_on_hover = nil
      self:redraw()
    end
    return
  end
  local symbol = self:get_component_at(col)
  if not symbol or symbol == self.symbol_on_hover then
    return
  end
  local hl_hover_icon = '_DropBarIconHover'
  local hl_hover_name = '_DropBarHover'
  vim.api.nvim_set_hl(
    0,
    hl_hover_icon,
    utils.hl.merge(symbol.icon_hl or 'WinBar', 'DropBarHover')
  )
  vim.api.nvim_set_hl(
    0,
    hl_hover_name,
    utils.hl.merge(symbol.name_hl or 'WinBar', 'DropBarHover')
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
---@return string
function dropbar_t:__tostring()
  if vim.tbl_isempty(self.components) then
    self:update()
  end
  return self.string_cache
end

return {
  dropbar_t = dropbar_t,
  dropbar_symbol_t = dropbar_symbol_t,
}
