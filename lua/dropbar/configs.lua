local utils = require('dropbar.utils')
local api = require('dropbar.api')
local M = {}

---@class dropbar_configs_t
M.opts = {
  general = {
    ---@type boolean|fun(buf: integer, win: integer, info: table?): boolean
    enable = function(buf, win, _)
      return vim.fn.win_gettype(win) == ''
        and vim.wo[win].winbar == ''
        and vim.bo[buf].bt == ''
        and (
          vim.bo[buf].ft == 'markdown'
          or (
            buf
              and vim.api.nvim_buf_is_valid(buf)
              and (pcall(vim.treesitter.get_parser, buf))
              and true
            or false
          )
        )
    end,
    attach_events = {
      'BufWinEnter',
      'BufWritePost',
    },
    -- Wait for a short time before updating the winbar, if another update
    -- request is received within this time, the previous request will be
    -- cancelled, this improves the performance when the user is holding
    -- down a key (e.g. 'j') to scroll the window, default to 0 ms
    -- If you encounter performance issues when scrolling the window, try
    -- setting this option to a number slightly larger than
    -- 1000 / key_repeat_rate
    update_interval = 0,
    update_events = {
      win = {
        'CursorMoved',
        'CursorMovedI',
        'WinResized',
      },
      buf = {
        'BufModifiedSet',
        'FileChangedShellPost',
        'TextChanged',
        'TextChangedI',
      },
      global = {
        'DirChanged',
        'VimResized',
      },
    },
  },
  icons = {
    enable = true,
    kinds = {
      use_devicons = true,
      symbols = {
        Array = '󰅪 ',
        Boolean = ' ',
        BreakStatement = '󰙧 ',
        Call = '󰃷 ',
        CaseStatement = '󱃙 ',
        Class = ' ',
        Color = '󰏘 ',
        Constant = '󰏿 ',
        Constructor = ' ',
        ContinueStatement = '→ ',
        Copilot = ' ',
        Declaration = '󰙠 ',
        Delete = '󰩺 ',
        DoStatement = '󰑖 ',
        Enum = ' ',
        EnumMember = ' ',
        Event = ' ',
        Field = ' ',
        File = '󰈔 ',
        Folder = '󰉋 ',
        ForStatement = '󰑖 ',
        Function = '󰊕 ',
        H1Marker = '󰉫 ',
        H2Marker = '󰉬 ',
        H3Marker = '󰉭 ',
        H4Marker = '󰉮 ',
        H5Marker = '󰉯 ',
        H6Marker = '󰉰 ',
        Identifier = '󰀫 ',
        IfStatement = '󰇉 ',
        Interface = ' ',
        Keyword = '󰌋 ',
        List = '󰅪 ',
        Log = '󰦪 ',
        Lsp = ' ',
        Macro = '󰁌 ',
        MarkdownH1 = '󰉫 ',
        MarkdownH2 = '󰉬 ',
        MarkdownH3 = '󰉭 ',
        MarkdownH4 = '󰉮 ',
        MarkdownH5 = '󰉯 ',
        MarkdownH6 = '󰉰 ',
        Method = '󰆧 ',
        Module = '󰏗 ',
        Namespace = '󰅩 ',
        Null = '󰢤 ',
        Number = '󰎠 ',
        Object = '󰅩 ',
        Operator = '󰆕 ',
        Package = '󰆦 ',
        Pair = '󰅪 ',
        Property = ' ',
        Reference = '󰦾 ',
        Regex = ' ',
        Repeat = '󰑖 ',
        Scope = '󰅩 ',
        Snippet = '󰩫 ',
        Specifier = '󰦪 ',
        Statement = '󰅩 ',
        String = '󰉾 ',
        Struct = ' ',
        SwitchStatement = '󰺟 ',
        Terminal = ' ',
        Text = ' ',
        Type = ' ',
        TypeParameter = '󰆩 ',
        Unit = ' ',
        Value = '󰎠 ',
        Variable = '󰀫 ',
        WhileStatement = '󰑖 ',
      },
    },
    ui = {
      bar = {
        separator = ' ',
        extends = '…',
      },
      menu = {
        separator = ' ',
        indicator = ' ',
      },
    },
  },
  symbol = {
    preview = {
      ---Reorient the preview window on previewing a new symbol
      ---@param _ integer source window id, ignored
      ---@param range {start: {line: integer}, end: {line: integer}} 0-indexed
      reorient = function(_, range)
        local invisible = range['end'].line - vim.fn.line('w$') + 1
        if invisible > 0 then
          local view = vim.fn.winsaveview() --[[@as vim.fn.winrestview.dict]]
          view.topline = math.min(
            view.topline + invisible,
            math.max(1, range.start.line - vim.wo.scrolloff + 1)
          )
          vim.fn.winrestview(view)
        end
      end,
    },
    jump = {
      ---@param win integer source window id
      ---@param range {start: {line: integer}, end: {line: integer}} 0-indexed
      reorient = function(win, range)
        local view = vim.fn.winsaveview()
        local win_height = vim.api.nvim_win_get_height(win)
        local topline = range.start.line - math.floor(win_height / 4)
        if
          topline > view.topline
          and topline + win_height < vim.fn.line('$')
        then
          view.topline = topline
          vim.fn.winrestview(view)
        end
      end,
    },
  },
  bar = {
    hover = true,
    ---@type dropbar_source_t[]|fun(buf: integer, win: integer): dropbar_source_t[]
    sources = function(buf, _)
      local sources = require('dropbar.sources')
      if vim.bo[buf].ft == 'markdown' then
        return {
          sources.path,
          sources.markdown,
        }
      end
      if vim.bo[buf].buftype == 'terminal' then
        return {
          sources.terminal,
        }
      end
      return {
        sources.path,
        utils.source.fallback({
          sources.lsp,
          sources.treesitter,
        }),
      }
    end,
    padding = {
      left = 1,
      right = 1,
    },
    pick = {
      pivots = 'abcdefghijklmnopqrstuvwxyz',
    },
    truncate = true,
  },
  menu = {
    -- When on, preview the symbol under the cursor on CursorMoved
    preview = true,
    -- When on, automatically set the cursor to the closest previous/next
    -- clickable component in the direction of cursor movement on CursorMoved
    quick_navigation = true,
    entry = {
      padding = {
        left = 1,
        right = 1,
      },
    },
    -- Menu scrollbar options
    scrollbar = {
      enable = true,
      -- The background / gutter of the scrollbar
      -- When false, only the thumb is shown.
      background = true,
    },
    ---@type table<string, string|function|table<string, string|function>>
    keymaps = {
      ['q'] = '<C-w>q',
      ['<Esc>'] = '<C-w>q',
      ['<LeftMouse>'] = function()
        local menu = utils.menu.get_current()
        if not menu then
          return
        end
        local mouse = vim.fn.getmousepos()
        local clicked_menu = utils.menu.get({ win = mouse.winid })
        -- If clicked on a menu, invoke the corresponding click action,
        -- else close all menus and set the cursor to the clicked window
        if clicked_menu then
          clicked_menu:click_at({ mouse.line, mouse.column - 1 }, nil, 1, 'l')
          return
        end
        utils.menu.exec('close')
        utils.bar.exec('update_current_context_hl')
        if vim.api.nvim_win_is_valid(mouse.winid) then
          vim.api.nvim_set_current_win(mouse.winid)
        end
      end,
      ['<CR>'] = function()
        local menu = utils.menu.get_current()
        if not menu then
          return
        end
        local cursor = vim.api.nvim_win_get_cursor(menu.win)
        local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
        if component then
          menu:click_on(component, nil, 1, 'l')
        end
      end,
      ['<MouseMove>'] = function()
        local menu = utils.menu.get_current()
        if not menu then
          return
        end
        local mouse = vim.fn.getmousepos()
        utils.menu.update_hover_hl(mouse)
        if M.opts.menu.preview then
          utils.menu.update_preview(mouse)
        end
      end,
      ['i'] = function()
        local menu = utils.menu.get_current()
        if not menu then
          return
        end
        menu:fuzzy_find_open()
      end,
    },
    ---@alias dropbar_menu_win_config_opts_t any|fun(menu: dropbar_menu_t):any
    ---@type table<string, dropbar_menu_win_config_opts_t>
    ---@see vim.api.nvim_open_win
    win_configs = {
      border = 'none',
      style = 'minimal',
      row = function(menu)
        return menu.prev_menu
            and menu.prev_menu.clicked_at
            and menu.prev_menu.clicked_at[1] - vim.fn.line('w0')
          or 0
      end,
      ---@param menu dropbar_menu_t
      col = function(menu)
        if menu.prev_menu then
          return menu.prev_menu._win_configs.width
            + (
              menu.prev_menu.scrollbar
                and menu.prev_menu.scrollbar.background
                and 1
              or 0
            )
        end
        local mouse = vim.fn.getmousepos()
        local bar = utils.bar.get({ win = menu.prev_win })
        if not bar then
          return mouse.wincol
        end
        local _, range = bar:get_component_at(math.max(0, mouse.wincol - 1))
        return range and range.start or mouse.wincol
      end,
      relative = 'win',
      win = function(menu)
        return menu.prev_menu and menu.prev_menu.win
          or vim.fn.getmousepos().winid
      end,
      height = function(menu)
        return math.max(
          1,
          math.min(
            #menu.entries,
            vim.go.pumheight ~= 0 and vim.go.pumheight
              or math.ceil(vim.go.lines / 4)
          )
        )
      end,
      width = function(menu)
        local min_width = vim.go.pumwidth ~= 0 and vim.go.pumwidth or 8
        if vim.tbl_isempty(menu.entries) then
          return min_width
        end
        return math.max(
          min_width,
          math.max(unpack(vim.tbl_map(function(entry)
            return entry:displaywidth()
          end, menu.entries)))
        )
      end,
      zindex = function(menu)
        if menu.prev_menu then
          if menu.prev_menu.scrollbar and menu.prev_menu.scrollbar.thumb then
            return vim.api.nvim_win_get_config(menu.prev_menu.scrollbar.thumb).zindex
          end
          return vim.api.nvim_win_get_config(menu.prev_win).zindex
        end
      end,
    },
  },
  fzf = {
    win_configs = {
      relative = 'win',
      anchor = 'NW',
      height = 1,
      win = function(menu)
        return menu.win
      end,
      width = function(menu)
        local function border_width(border)
          if type(border) == 'string' then
            if border == 'none' or border == 'shadow' then
              return 0
            end
            return 2 -- left and right border
          end

          local left, right = 1, 1
          if
            (#border == 1 and border[1] == '')
            or (#border == 4 and border[4] == '')
            or (#border == 8 and border[8] == '')
          then
            left = 0
          end
          if
            (#border == 1 and border[1] == '')
            or (#border == 4 and border[4] == '')
            or (#border == 8 and border[4] == '')
          then
            right = 0
          end
          return left + right
        end
        local menu_width = menu._win_configs.width
          + border_width(menu._win_configs.border)
        local self_width = menu._win_configs.width
        local self_border = border_width(
          (
            M.opts.fzf.win_configs
            and M.eval(M.opts.fzf.win_configs.border, menu)
          )
            or (menu.fzf_win_configs and M.eval(
              menu.fzf_win_configs.border,
              menu
            ))
            or menu._win_configs.border
        )

        if self_width + self_border > menu_width then
          return self_width - self_border
        else
          return menu_width - self_border
        end
      end,
      row = function(menu)
        local menu_border = menu._win_configs.border
        if
          type(menu_border) == 'string'
          and menu_border ~= 'shadow'
          and menu_border ~= 'none'
        then
          return menu._win_configs.height + 1
        elseif menu_border == 'none' then
          return menu._win_configs.height
        end
        local len_menu_border = #menu_border
        if
          len_menu_border == 1 and menu_border[1] ~= ''
          or (len_menu_border == 2 or len_menu_border == 4) and menu_border[2] ~= ''
          or len_menu_border == 8 and menu_border[8] ~= ''
        then
          return menu._win_configs.height + 1
        else
          return menu._win_configs.height
        end
      end,
      col = function(menu)
        local menu_border = menu._win_configs.border
        if
          type(menu_border) == 'string'
          and menu_border ~= 'shadow'
          and menu_border ~= 'none'
        then
          return -1
        end
        if
          type(menu_border) == 'table' and menu_border[#menu_border] ~= ''
        then
          return -1
        end
        return 0
      end,
    },
    ---@type table<string, string | fun()>
    keymaps = {
      ['<LeftMouse>'] = function()
        ---@type dropbar_menu_t
        local menu = utils.menu.get_current()
        if not menu then
          return
        end
        local mouse = vim.fn.getmousepos()
        if not mouse then
          return
        end
        if mouse.winid ~= menu.win then
          local default_func = M.opts.menu.keymaps['<LeftMouse>']
          if type(default_func) == 'function' then
            default_func()
          end
          menu:fuzzy_find_close()
          return
        elseif mouse.winrow > vim.api.nvim_buf_line_count(menu.buf) then
          return
        end
        vim.api.nvim_win_set_cursor(menu.win, { mouse.line, mouse.column - 1 })
        menu:fuzzy_find_click_on_entry(function(entry)
          return entry:get_component_at(mouse.column - 1, true)
        end)
      end,
      ['<MouseMove>'] = function()
        ---@type dropbar_menu_t
        local menu = utils.menu.get_current()
        if not menu then
          return
        end
        local mouse = vim.fn.getmousepos()
        if not mouse then
          return
        end
        -- If mouse is not in the menu window or on the border, end preview
        -- and clear hover highlights
        if
          mouse.winid ~= menu.win
          or mouse.line <= 0
          or mouse.column <= 0
          or mouse.winrow > (#menu.entries + 1)
        then
          -- Find the root menu
          while menu and menu.prev_menu do
            menu = menu.prev_menu
          end
          if menu then
            menu:finish_preview(true)
            menu:update_hover_hl()
          end
          return
        end
        if M.opts.menu.preview then
          menu:preview_symbol_at({ mouse.line, mouse.column - 1 }, true)
        end
        menu:update_hover_hl({ mouse.line, mouse.column - 1 })
      end,
      ['<Up>'] = api.fuzzy_find_prev,
      ['<Down>'] = api.fuzzy_find_next,
      ['<C-k>'] = api.fuzzy_find_prev,
      ['<C-j>'] = api.fuzzy_find_next,
      ['<C-p>'] = api.fuzzy_find_prev,
      ['<C-n>'] = api.fuzzy_find_next,
      ['<CR>'] = api.fuzzy_find_click,
      ['<S-Enter>'] = function()
        api.fuzzy_find_click(-1)
      end,
    },
    prompt = '%#htmlTag# ',
    char_pattern = '[%w%p]',
    retain_inner_spaces = true,
    fuzzy_find_on_click = true,
  },
  sources = {
    path = {
      ---@type string|fun(buf: integer, win: integer): string
      relative_to = function(_, win)
        -- Workaround for Vim:E5002: Cannot find window number
        local ok, cwd = pcall(vim.fn.getcwd, win)
        return ok and cwd or vim.fn.getcwd()
      end,
      ---Can be used to filter out files or directories
      ---based on their name
      ---@type fun(name: string): boolean
      filter = function(_)
        return true
      end,
      ---Last symbol from path source when current buf is modified
      ---@param sym dropbar_symbol_t
      ---@return dropbar_symbol_t
      modified = function(sym)
        return sym
      end,
      ---@type boolean|fun(path: string): boolean?|nil
      preview = function(path)
        local stat = vim.uv.fs_stat(path)
        if not stat or stat.type ~= 'file' then
          return false
        end
        if stat.size > 524288 then
          vim.notify(
            string.format(
              '[dropbar.nvim] file "%s" too large to preview',
              path
            ),
            vim.log.levels.WARN
          )
          return false
        end
        return true
      end,
    },
    treesitter = {
      -- Lua pattern used to extract a short name from the node text
      name_pattern = '[#~%*%w%._%->!@:]+%s*'
        .. string.rep('[#~%*%w%._%->!@:]*', 3, '%s*'),
      -- The order matters! The first match is used as the type
      -- of the treesitter symbol and used to show the icon
      -- Types listed below must have corresponding icons
      -- in the `icons.kinds.symbols` table for the icon to be shown
      valid_types = {
        'array',
        'boolean',
        'break_statement',
        'call',
        'case_statement',
        'class',
        'constant',
        'constructor',
        'continue_statement',
        'delete',
        'do_statement',
        'enum',
        'enum_member',
        'event',
        'for_statement',
        'function',
        'h1_marker',
        'h2_marker',
        'h3_marker',
        'h4_marker',
        'h5_marker',
        'h6_marker',
        'if_statement',
        'interface',
        'keyword',
        'list',
        'macro',
        'method',
        'module',
        'namespace',
        'null',
        'number',
        'operator',
        'package',
        'pair',
        'property',
        'reference',
        'repeat',
        'scope',
        'specifier',
        'string',
        'struct',
        'switch_statement',
        'type',
        'type_parameter',
        'unit',
        'value',
        'variable',
        'while_statement',
        'declaration',
        'field',
        'identifier',
        'object',
        'statement',
        'text',
      },
    },
    lsp = {
      request = {
        -- Times to retry a request before giving up
        ttl_init = 60,
        interval = 1000, -- in ms
      },
    },
    markdown = {
      parse = {
        -- Number of lines to update when cursor moves out of the parsed range
        look_ahead = 200,
      },
    },
    terminal = {
      ---@type string|fun(buf: integer): string
      icon = function(buf)
        local icon = M.opts.icons.kinds.symbols.Terminal
        if M.opts.icons.kinds.use_devicons then
          icon = require('nvim-web-devicons').get_icon_by_filetype(
            vim.bo[buf].filetype
          ) or icon
        end
        return icon
      end,
      ---@type string|fun(buf: integer): string
      name = vim.api.nvim_buf_get_name,
      ---@type boolean
      ---Show the current terminal buffer in the menu
      show_current = true,
    },
  },
}

---Set dropbar options
---@param new_opts dropbar_configs_t?
function M.set(new_opts)
  new_opts = new_opts or {}

  local islist = vim.islist or vim.tbl_islist
  -- Notify deprecated options
  if new_opts.general and islist(new_opts.general.update_events) then
    vim.api.nvim_echo({
      { '[dropbar.nvim] ', 'Normal' },
      { 'opts.general.update_events', 'WarningMsg' },
      { ' is deprecated.\n', 'Normal' },
      { '[dropbar.nvim] ', 'Normal' },
      { 'Please use\n', 'Normal' },
      { '               opts.general.update_events.win ', 'WarningMsg' },
      { 'for updating a winbar attached to a single window,\n', 'Normal' },
      { '               opts.general.update_events.buf ', 'WarningMsg' },
      { 'for updating all winbars attached to a buffer, or\n', 'Normal' },
      { '               opts.general.update_events.global ', 'WarningMsg' },
      { 'for updating all winbars in current nvim session ', 'Normal' },
      { 'instead.\n', 'Normal' },
    }, true, {})
    new_opts.general.update_events = {
      win = new_opts.general.update_events,
    }
  end
  if new_opts.icons and new_opts.icons.enable == false then
    local blank_icons = setmetatable({}, {
      __index = function()
        return ' '
      end,
    })
    M.opts.icons.kinds.use_devicons = false
    M.opts.icons.kinds.symbols = blank_icons
    M.opts.icons.ui.bar = blank_icons
    M.opts.icons.ui.menu = blank_icons
  end
  M.opts = vim.tbl_deep_extend('force', M.opts, new_opts)
end

---Evaluate a dynamic option value (with type T|fun(...): T)
---@generic T
---@param opt T|fun(...): T
---@return T
function M.eval(opt, ...)
  if type(opt) == 'function' then
    return opt(...)
  end
  return opt
end

return M
