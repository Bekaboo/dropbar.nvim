local bar = require('dropbar.bar')
local menu = require('dropbar.menu')
local configs = require('dropbar.configs')

---@alias dropbar_symbol_range_t lsp_range_t

---For unify the symbols from different sources
---@class dropbar_symbol_tree_t
---@field name string
---@field kind string
---@field children dropbar_symbol_tree_t[]?
---@field siblings dropbar_symbol_tree_t[]?
---@field idx integer? index of the symbol in its siblings
---@field range dropbar_symbol_range_t?
---@field data table? extra data

---Convert a dropbar tree symbol structure to a dropbar symbol
---@param symbol dropbar_symbol_tree_t
---@param opts dropbar_symbol_t? extra options to override or pass to dropbar_symbol_t:new()
---@return dropbar_symbol_t
local function to_dropbar_symbol(symbol, opts)
  return bar.dropbar_symbol_t:new(vim.tbl_deep_extend('force', {
    name = symbol.name,
    icon = configs.opts.icons.kinds.symbols[symbol.kind],
    icon_hl = 'DropBarIconKind' .. symbol.kind,
    symbol = symbol,
    ---@param this dropbar_symbol_t
    on_click = function(this, _, _, _, _)
      -- If currently inside a menu, highlight the current line
      if this.entry and this.entry.menu then
        this.entry.menu:hl_line_single(this.entry.idx)
      end
      -- Toggle menu on click, or create one if menu don't exist:
      -- 1. If symbol inside a dropbar, create a menu with entries containing
      --    the symbol's siblings
      -- 2. Else if symbol inside a menu, create menu with entries containing
      --    the symbol's children
      if this.menu then
        this.menu:toggle()
        return
      end
      if not this.symbol then
        return
      end

      local menu_prev_win = nil ---@type integer?
      local menu_entries_source = nil ---@type dropbar_symbol_tree_t[]?
      local menu_cursor_init = nil ---@type integer[]?
      if this.bar then -- If symbol inside a dropbar
        menu_prev_win = this.bar and this.bar.win
        menu_entries_source = this.symbol.siblings
        menu_cursor_init = this.symbol.idx and { this.symbol.idx, 0 }
      elseif this.entry and this.entry.menu then -- If symbol inside a menu
        menu_prev_win = this.entry.menu.win
        menu_entries_source = this.symbol.children
      end
      if not menu_entries_source or vim.tbl_isempty(menu_entries_source) then
        return
      end

      -- Called in dropbar pick mode, open the menu relative to the symbol
      -- position in the dropbar
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

      this.menu = menu.dropbar_menu_t:new({
        prev_win = menu_prev_win,
        cursor = menu_cursor_init,
        win_configs = menu_win_configs,

        ---@param sym dropbar_symbol_tree_t
        entries = vim.tbl_map(function(sym)
          local menu_indicator_icon = configs.opts.icons.ui.menu.indicator
          local menu_indicator_on_click = nil
          if not sym.children or vim.tbl_isempty(sym.children) then
            menu_indicator_icon =
              string.rep(' ', vim.fn.strdisplaywidth(menu_indicator_icon))
            menu_indicator_on_click = false
          end

          return menu.dropbar_menu_entry_t:new({
            components = {
              to_dropbar_symbol(sym, {
                name = '',
                icon = menu_indicator_icon,
                name_hl = 'DropBarMenuNormalFloat',
                icon_hl = 'DropBarIconUIIndicator',
                on_click = menu_indicator_on_click,
              }),
              to_dropbar_symbol(sym, {
                name_hl = 'DropBarMenuNormalFloat',
                ---Goto the location of the symbol on click
                ---@param dropbar_symbol dropbar_symbol_t
                on_click = function(dropbar_symbol, _, _, _, _)
                  dropbar_symbol:goto_start()
                end,
              }),
            },
          })
        end, menu_entries_source),
      })
      this.menu:toggle()
    end,
  }, opts or {}))
end

---@class dropbar_path_symbol_tree_t: dropbar_symbol_tree_t
---@field data {path: string}

---Convert a dropbar tree symbol structure from source 'path' to a dropbar symbol
---@param symbol dropbar_path_symbol_tree_t
---@param opts dropbar_symbol_t? extra options to override or pass to dropbar_symbol_t:new()
---@return dropbar_symbol_t
local function to_dropbar_symbol_from_path(symbol, opts)
  local icon = configs.opts.icons.kinds.symbols.Folder
  local icon_hl = 'DropBarIconKindFolder'
  local stat = vim.loop.fs_stat(symbol.data.path)
  if configs.opts.icons.kinds.use_devicons then
    local devicons_ok, devicons = pcall(require, 'nvim-web-devicons')
    if devicons_ok and stat and stat.type ~= 'directory' then
      local devicon, devicon_hl = devicons.get_icon(
        vim.fs.basename(symbol.data.path),
        vim.fn.fnamemodify(symbol.data.path, ':e'),
        { default = true }
      )
      icon = devicon and devicon .. ' ' or icon
      icon_hl = devicon_hl
    end
  end
  return bar.dropbar_symbol_t:new(vim.tbl_deep_extend('force', {
    name = symbol.name,
    icon = icon,
    icon_hl = icon_hl,
    symbol = symbol,
    ---@param this dropbar_symbol_t
    on_click = function(this, _, _, _, _)
      -- If currently inside a menu, highlight the current line
      if this.entry and this.entry.menu then
        this.entry.menu:hl_line_single(this.entry.idx)
      end
      -- Toggle menu on click, or create one if menu don't exist:
      -- 1. If symbol inside a dropbar, create a menu with entries containing
      --    the symbol's siblings
      -- 2. Else if symbol inside a menu, create menu with entries containing
      --    the symbol's children
      if this.menu then
        this.menu:toggle()
        return
      end
      if not this.symbol then
        return
      end

      local menu_prev_win = nil ---@type integer?
      local menu_entries_source = nil ---@type dropbar_symbol_tree_t[]?
      local menu_cursor_init = nil ---@type integer[]?
      if this.bar then -- If symbol inside a dropbar
        menu_prev_win = this.bar and this.bar.win
        menu_entries_source = this.symbol.siblings
        menu_cursor_init = this.symbol.idx and { this.symbol.idx, 0 }
      elseif this.entry and this.entry.menu then -- If symbol inside a menu
        menu_prev_win = this.entry.menu.win
        menu_entries_source = this.symbol.children
      end
      if not menu_entries_source or vim.tbl_isempty(menu_entries_source) then
        return
      end

      -- Called in dropbar pick mode, open the menu relative to the symbol
      -- position in the dropbar
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

      this.menu = menu.dropbar_menu_t:new({
        prev_win = menu_prev_win,
        cursor = menu_cursor_init,
        win_configs = menu_win_configs,

        ---@param sym dropbar_path_symbol_tree_t
        entries = vim.tbl_map(function(sym)
          local menu_indicator_icon = configs.opts.icons.ui.menu.indicator
          local menu_indicator_icon_hl = 'DropBarIconUIIndicator'
          local menu_indicator_on_click = nil
          local menu_entry_text_on_click = nil
          if not sym.children or vim.tbl_isempty(sym.children) then
            ---@param self dropbar_symbol_t
            menu_entry_text_on_click = function(self)
              if self.entry then -- Inside a menu entry
                local current_menu = self.entry.menu
                while current_menu and current_menu.parent_menu do
                  current_menu = current_menu.parent_menu
                end
                if current_menu then
                  current_menu:close()
                end
                vim.cmd.edit(self.symbol.data.path)
              end
            end
            menu_indicator_on_click = false
            menu_indicator_icon =
              string.rep(' ', vim.fn.strdisplaywidth(menu_indicator_icon))
          end

          return menu.dropbar_menu_entry_t:new({
            components = {
              to_dropbar_symbol_from_path(sym, {
                name = '',
                icon = menu_indicator_icon,
                name_hl = 'DropBarMenuNormalFloat',
                icon_hl = menu_indicator_icon_hl,
                on_click = menu_indicator_on_click,
              }),
              to_dropbar_symbol_from_path(sym, {
                name_hl = 'DropBarMenuNormalFloat',
                on_click = menu_entry_text_on_click,
              }),
            },
          })
        end, menu_entries_source),
      })
      this.menu:toggle()
    end,
  }, opts or {}))
end

return {
  to_dropbar_symbol = to_dropbar_symbol,
  to_dropbar_symbol_from_path = to_dropbar_symbol_from_path,
}
