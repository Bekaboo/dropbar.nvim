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

---Options passed to `utils.menu.select` (`vim.ui.select` with some extensions).
---@class dropbar_select_opts_t
---Text to be displayed at the top of the menu
---@field prompt? string
---Function to format each item in the menu.
---Required if `items` is not a list of strings.
---The second return value is a list of virtual text chunks to be displayed below the item. If
---nothing is returned for the second value, no virtual text will be displayed.
---@field format_item? fun(item: any): string, string[][]?
---@field preview? fun(self: dropbar_symbol_t, item: any, idx: integer)
---@field preview_close? fun(self: dropbar_symbol_t, item: any, idx: integer)

---@param items string[]|table[] list of items to be selected
---@param opts dropbar_select_opts_t
function M.select(items, opts, on_choice)
  if not items then
    return
  end

  opts = opts or {}

  local bar = require('dropbar.bar')
  local menu = require('dropbar.menu')
  local configs = require('dropbar.configs')

  -- Determine maximum width of the icon, for entries ranges from 1 to 9
  -- they will be labeled and mapped with numbers, the rest will be labeled
  -- and mapped with Meta + letter chosen from `pivots`, for even more items,
  -- they will be labeled with number but no key mapped for them
  local num_items = #items
  local pivots = configs.opts.bar.pick.pivots
  local len_pivots = #pivots
  local num_bits = num_items == 1 and 1 or math.ceil(math.log10(num_items))
  local icon_width = num_bits <= 1 and 1 or math.max(num_bits, #'M-a')
  local icon_format = string.format('%%+%ds. ', icon_width)
  local entries = vim
    .iter(items)
    :enumerate()
    :map(function(idx, item)
      local text = item
      local virt_text

      -- Support custom formats for items like some
      -- other ui-select plugins do
      if opts.format_item then
        text, virt_text = opts.format_item(item)
        if type(virt_text) ~= 'table' then
          virt_text = nil
        end
      end

      return menu.dropbar_menu_entry_t:new({
        -- `virt_text` will only be shown if returned from `format_item`
        virt_text = virt_text,
        components = {
          bar.dropbar_symbol_t:new({
            icon = string.format(
              icon_format,
              (idx <= 9 or idx > 9 + len_pivots) and idx
                or 'M-' .. pivots:sub(idx - 9, idx - 9)
            ),
            icon_hl = 'DropBarIconUIIndicator',
            name = text,
            preview = function(self)
              if opts.preview then
                opts.preview(self, item, idx)
              end
            end,
            preview_restore_view = function(self)
              if opts.preview_close then
                opts.preview_close(self, item, idx)
              end
            end,
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

  local win = vim.api.nvim_get_current_win()
  local screenrow = vim.fn.screenpos(win, vim.fn.line('.'), 0).row
  local screenrows_left = vim.go.lines - screenrow
  local win_configs = {
    col = 0,
    relative = 'cursor',
    title = opts.prompt,
  }
  local fzf_win_configs = {}
  -- Change border settings if the default top border is empty
  -- to allow prompt to be displayed
  if opts.prompt then
    local border = configs.opts.menu.win_configs.border or vim.go.winborder
    local border_none_with_prompt = { '', ' ', '', '', '', '', '', '' }
    if border == '' or border == 'none' or border == 'shadow' then
      win_configs.border = border_none_with_prompt
      fzf_win_configs.border = 'none'
    elseif type(border) == 'table' then
      if #border == 1 and border[1] == '' then
        win_configs.border = border_none_with_prompt
        fzf_win_configs.border = 'none'
      elseif #border > 1 and border[2] == '' then
        win_configs.border = vim.deepcopy(border)
        if #win_configs.border == 4 then
          vim.list_extend(win_configs.border, win_configs.border)
        end
        win_configs.border[2] = ' '
        -- use the original headerless border for fzf
        fzf_win_configs.border = border
      end
    end
  end
  -- Place menu above or below the cursor depending on the available
  -- screen space
  if screenrow > screenrows_left then
    win_configs.row = 0
    win_configs.anchor = 'SW'
  else
    win_configs.row = 1
    win_configs.anchor = 'NW'
  end

  local smenu = menu.dropbar_menu_t:new({
    prev_win = win,
    entries = entries,
    win_configs = win_configs,
    fzf_win_configs = fzf_win_configs,
  })

  smenu:open()

  -- Set buffer-local keymaps
  if smenu.buf and vim.api.nvim_buf_is_valid(smenu.buf) then
    -- Press a number to go to the corresponding item
    for i = 1, math.min(9, num_items) do
      local i_str = tostring(i)
      vim.keymap.set('n', i_str, function()
        vim.cmd(i_str)
      end, { buffer = smenu.buf })
    end
    -- Press Meta + letter to go to the corresponding item
    for i = 1, math.min(len_pivots, num_items - 9) do
      vim.keymap.set('n', string.format('<M-%s>', pivots:sub(i, i)), function()
        vim.cmd(tostring(i + 9))
      end, { buffer = smenu.buf })
    end
  end
end

return M
