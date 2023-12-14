local M = {}

---Get dropbar menu
--- - If `opts.win` is specified, return the dropbar menu attached the window;
--- - If `opts.win` is not specified, return all opened dropbar menus
---@param opts {win: integer?}?
---@return (dropbar_menu_t?)|table<integer, dropbar_menu_t>
function M.get(opts)
  opts = opts or {}
  if opts.win then
    return _G.dropbar.menus[opts.win]
  end
  return _G.dropbar.menus
end

---Get current menu
---@return dropbar_menu_t?
function M.get_current()
  return M.get({ win = vim.api.nvim_get_current_win() })
end

---Call method on dropbar menu(s) given the window id
--- - If `opts.win` is specified, call the dropbar menu with the window id;
--- - If `opts.win` is not specified, call all opened dropbars
--- - `opts.params` specifies params passed to the method
---@param method string
---@param opts {win: integer?, params: table?}?
---@return any?: return values of the method
function M.exec(method, opts)
  opts = opts or {}
  opts.params = opts.params or {}
  local menus = M.get(opts)
  if not menus or vim.tbl_isempty(menus) then
    return
  end
  if opts.win then
    return menus[method](menus, unpack(opts.params))
  end
  local results = {}
  for _, menu in pairs(menus) do
    table.insert(results, {
      menu[method](menu, opts.params),
    })
  end
  return results
end

---@type dropbar_menu_t?
local last_hovered_menu = nil

---Update menu hover highlights given the mouse position
---@param mouse table
---@return nil
function M.update_hover_hl(mouse)
  local menu = M.get({ win = mouse.winid })
  if not menu or mouse.line <= 0 or mouse.column <= 0 then
    if last_hovered_menu then
      last_hovered_menu:update_hover_hl()
      last_hovered_menu = nil
    end
    return
  end
  if last_hovered_menu and last_hovered_menu ~= menu then
    last_hovered_menu:update_hover_hl()
  end
  menu:update_hover_hl({ mouse.line, mouse.column - 1 })
  last_hovered_menu = menu
end

---@type dropbar_menu_t?
local last_previewed_menu = nil

---Update menu preview given the mouse position
---@param mouse table
---@return nil
function M.update_preview(mouse)
  local menu = M.get({ win = mouse.winid })
  if not menu or mouse.line <= 0 or mouse.column <= 0 then
    if last_previewed_menu then
      last_previewed_menu:finish_preview()
      last_previewed_menu = nil
    end
    return
  end
  if last_previewed_menu and last_previewed_menu ~= menu then
    last_previewed_menu:finish_preview()
  end
  menu:preview_symbol_at({ mouse.line, mouse.column - 1 }, true)
  last_previewed_menu = menu
end

---@class dropbar_select_opts_t
---Text to be displayed at the top of the menu
---@field prompt? string
---Function to format each item in the menu.
---Required if `items` is not a list of strings.
---The second return value is a list of virtual text chunks to be displayed below the item. If
---nothing is returned for the second value, no virtual text will be displayed.
---@field format_item? fun(item: any): string, string[][]?

---@param items string[]|table[] list of items to be selected
---@param opts dropbar_select_opts_t
function M.select(items, opts, on_choice)
  if not items then
    return
  end

  opts = opts or {}

  local entries = vim
    .iter(items)
    :enumerate()
    :map(function(idx, item)
      local text = item
      local virt_text

      -- support custom formats for items like some
      -- other ui-select plugins do
      if opts.format_item then
        text, virt_text = opts.format_item(item)
      end

      return require('dropbar.menu').dropbar_menu_entry_t:new({
        -- virt_text will only be shown if returned from `format_item`
        virt_text = virt_text,
        components = {
          require('dropbar.bar').dropbar_symbol_t:new({
            icon = ' ',
            icon_hl = 'Special',
            name = text,
            on_click = function(self)
              self.entry.menu:close()
              if on_choice then
                on_choice(item, idx)
              end
            end,
          }),
        },
      })
    end)
    :totable()

  local border, title_pos
  if opts.prompt then
    border = require('dropbar.configs').opts.menu.win_configs.border
    title_pos = 'center'
  end

  local menu = require('dropbar.menu').dropbar_menu_t:new({
    entries = entries,
    prev_win = vim.api.nvim_get_current_win(),
    win_configs = {
      relative = 'cursor',
      title = opts.prompt,
      row = 1,
      col = 1,
      border = border,
      title_pos = title_pos,
    },
  })

  menu:open()

  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = menu.buf,
    callback = function()
      local cursor = { vim.api.nvim_win_get_cursor(menu.win)[1], 1 }
      vim.api.nvim_win_set_cursor(menu.win, cursor)
      menu:update_hover_hl(cursor)
    end,
    desc = 'Lock cursor to the first column of the menu',
  })
end

return M
