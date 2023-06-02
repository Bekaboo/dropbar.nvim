local configs = require('dropbar.configs')

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

---@class dropbar_symbol_t
---@field name string
---@field icon string
---@field name_hl string?
---@field icon_hl string?
---@field bar dropbar_t? the winbar the symbol belongs to, if the symbol is shown inside a winbar
---@field menu dropbar_menu_t? menu associated with the winbar symbol, if the symbol is shown inside a winbar
---@field entry dropbar_menu_entry_t? the dropbar entry the symbol belongs to, if the symbol is shown inside a menu
---@field children dropbar_symbol_t[]? children of the symbol
---@field siblings dropbar_symbol_t[]? siblings of the symbol
---@field bar_idx integer? index of the symbol in the winbar
---@field entry_idx integer? index of the symbol in the menu entry
---@field sibling_idx integer? index of the symbol in its siblings
---@field on_click fun(this: dropbar_symbol_t, min_width: integer?, n_clicks: integer?, button: string?, modifiers: string?)|false? force disable on_click when false
---@field actions table<string, fun(this: dropbar_symbol_t)>? select, preview, jump, etc.
---@field data table? any data associated with the symbol
local dropbar_symbol_t = {}

function dropbar_symbol_t:__index(k)
  ---@diagnostic disable-next-line: undefined-field
  return self._[k] or dropbar_symbol_t[k]
end

function dropbar_symbol_t:__newindex(k, v)
  ---@diagnostic disable-next-line: undefined-field
  self._[k] = v
end

---Create a dropbar symbol instance
---@param opts dropbar_symbol_t?
---@return dropbar_symbol_t
function dropbar_symbol_t:new(opts)
  return setmetatable({
    _ = setmetatable(
      vim.tbl_deep_extend('force', {
        name = '',
        icon = '',
        on_click = opts
          and function(this, _, _, _, _)
            if this.entry and this.entry.menu then
              this.entry.menu:hl_line_single(this.entry.idx)
            end
            -- Toggle menu on click, or create one if menu don't exist:
            -- 1. If symbol inside a winbar, create a menu with entries
            --    containing the symbol's siblings
            -- 2. Else if symbol inside a menu, create menu with entries
            --    containing the symbol's children
            if this.menu then
              this.menu:toggle()
              return
            end

            local menu_prev_win = nil ---@type integer?
            local menu_entries_source = nil ---@type dropbar_symbol_t[]?
            local menu_cursor_init = nil ---@type integer[]?
            if this.bar then -- If symbol inside a winbar
              menu_prev_win = this.bar and this.bar.win
              menu_entries_source = opts.siblings
              menu_cursor_init = opts.sibling_idx and { opts.sibling_idx, 0 }
            elseif this.entry and this.entry.menu then -- If inside a menu
              menu_prev_win = this.entry.menu.win
              menu_entries_source = opts.children
            end
            if
              not menu_entries_source or vim.tbl_isempty(menu_entries_source)
            then
              return
            end

            -- Called in pick mode, open the menu relative to the symbol
            -- position in the winbar
            local menu_win_configs = nil
            if this.bar and this.bar.in_pick_mode then
              local col = 0
              for i, component in ipairs(this.bar.components) do
                if i < this.bar_idx then
                  col = col
                    + component:displaywidth()
                    + this.bar.separator:displaywidth()
                end
              end
              menu_win_configs = {
                relative = 'win',
                row = 0,
                col = col,
              }
            end

            local menu = require('dropbar.menu')
            this.menu = menu.dropbar_menu_t:new({
              prev_win = menu_prev_win,
              cursor = menu_cursor_init,
              win_configs = menu_win_configs,
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
                    dropbar_symbol_t:new(vim.tbl_deep_extend('force', sym, {
                      name = '',
                      icon = menu_indicator_icon,
                      name_hl = 'DropBarMenuNormalFloat',
                      icon_hl = 'DropBarIconUIIndicator',
                      on_click = menu_indicator_on_click,
                    })),
                    dropbar_symbol_t:new(vim.tbl_deep_extend('force', sym, {
                      name_hl = 'DropBarMenuNormalFloat',
                      on_click = sym.actions and sym.actions.jump,
                    })),
                  },
                })
              end, menu_entries_source),
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
  if plain then
    return self.icon .. self.name
  end
  local icon_highlighted = hl(self.icon, self.icon_hl)
  local name_highlighted = hl(self.name, self.name_hl)
  if self.on_click and self.bar_idx then
    return make_clickable(
      icon_highlighted .. name_highlighted,
      string.format(
        'v:lua.dropbar.on_click_callbacks.buf%s.win%s.fn%s',
        self.bar.buf,
        self.bar.win,
        self.bar_idx
      )
    )
  end
  return icon_highlighted .. name_highlighted
end

---Get the display length of the dropbar symbol
---@return number
function dropbar_symbol_t:displaywidth()
  return vim.fn.strdisplaywidth(self:cat(true))
end

---Get the byte length of the dropbar symbol
---@return number
function dropbar_symbol_t:bytewidth()
  return #self:cat(true)
end

---Goto the start location of the symbol associated with the dropbar symbol
---@return nil
function dropbar_symbol_t:goto_range_start()
  if not self.data or not self.data.range then
    return
  end
  local dest_pos = self.data.range.start
  if not self.entry then -- symbol is not shown inside a menu
    vim.api.nvim_win_set_cursor(self.bar.win, {
      dest_pos.line + 1,
      dest_pos.character,
    })
    return
  end
  -- symbol is shown inside a menu
  local current_menu = self.entry.menu
  while current_menu and current_menu.parent_menu do
    current_menu = current_menu.parent_menu
  end
  if current_menu then
    vim.api.nvim_win_set_cursor(current_menu.prev_win, {
      dest_pos.line + 1,
      dest_pos.character,
    })
    current_menu:close()
  end
end

---Temporarily change the content of a dropbar symbol
---Does not support replacing nil values
---@param field string
---@param new_val any
function dropbar_symbol_t:swap_field(field, new_val)
  self.data = self.data or {}
  self.data.swap = self.data.swap or {}
  self.data.swap[field] = self.data.swap[field] or self[field]
  self[field] = new_val
end

---Restore the content of a dropbar symbol
---Does not support restoring nil values
function dropbar_symbol_t:restore()
  if not self.data or not self.data.swap then
    return
  end
  for field, val in pairs(self.data.swap) do
    self[field] = val
  end
  self.data.swap = nil
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
  -- Must add highlights to padding, else nvim will automatically truncate it
  local padding_hl = not plain and 'DropBar' or nil
  local padding_left = hl(string.rep(' ', self.padding.left), padding_hl)
  local padding_right = hl(string.rep(' ', self.padding.right), padding_hl)
  return result and padding_left .. result .. padding_right or ''
end

---Reevaluate dropbar string from components and redraw dropbar
---@return nil
function dropbar_t:redraw()
  if configs.opts.bar.truncate then
    self:truncate()
  end
  self.string_cache = self:cat()
  vim.cmd('silent! redrawstatus')
end

---Update dropbar components from sources and redraw dropbar, supposed to be
---called at CursorMoved, CurosrMovedI, TextChanged, and TextChangedI
---Not updating when executing a macro
---@return nil
function dropbar_t:update()
  if not self.win or not vim.api.nvim_win_is_valid(self.win) then
    self:del()
    return
  end
  if vim.fn.reg_executing() ~= '' or self.in_pick_mode then
    return self.string_cache
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  for _, component in ipairs(self.components) do
    component:del()
  end
  self.components = {}
  _G.dropbar.on_click_callbacks['buf' .. self.buf]['win' .. self.win] = {}
  for _, source in ipairs(self.sources) do
    local symbols = source.get_symbols(self.buf, cursor)
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
end

---Execute a function in pick mode
---Side effect: change dropbar.in_pick_mode
---@generic T
---@param fn fun(): T?
---@return T?
function dropbar_t:pick_mode_wrap(fn)
  local pick_mode = self.in_pick_mode
  self.in_pick_mode = true
  local result = fn()
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
