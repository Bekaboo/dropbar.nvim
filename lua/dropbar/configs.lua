local utils = require('dropbar.utils')
local api = require('dropbar.api')
local M = {}

---@class dropbar_configs_t
M.opts = {
  icons = {
    enable = true,
    kinds = {
      ---Directory icon and highlighting getter, set to empty string to disable
      ---@param path string path to the directory
      ---@return string: icon for the directory
      ---@return string?: highlight group for the icon
      ---@type fun(path: string): string, string?|string?
      dir_icon = function(_)
        return M.opts.icons.kinds.symbols.Folder, 'DropBarIconKindFolder'
      end,
      ---File icon and highlighting getter, set to empty string to disable
      ---@param path string path to the file
      ---@return string: icon for the file
      ---@return string?: highlight group for the icon
      ---@type fun(path: string): string, string?|string?
      file_icon = function(path)
        local icon_kind_opts = M.opts.icons.kinds
        local file_icon = icon_kind_opts.symbols.File
        local file_icon_hl = 'DropBarIconKindFile'
        local devicons_ok, devicons = pcall(require, 'nvim-web-devicons')
        if not devicons_ok then
          return file_icon, file_icon_hl
        end

        -- Try to find icon using the filename, explicitly disable the
        -- default icon so that we can try to find the icon using the
        -- filetype if the filename does not have a corresponding icon
        local devicon, devicon_hl = devicons.get_icon(
          vim.fs.basename(path),
          vim.fn.fnamemodify(path, ':e'),
          { default = false }
        )

        -- No corresponding devicon found using the filename, try finding icon
        -- with filetype if the file is loaded as a buf in nvim
        if not devicon then
          ---@type integer?
          local buf = vim.iter(vim.api.nvim_list_bufs()):find(function(buf)
            return vim.api.nvim_buf_get_name(buf) == path
          end)
          if buf then
            local filetype =
              vim.api.nvim_get_option_value('filetype', { buf = buf })
            devicon, devicon_hl = devicons.get_icon_by_filetype(filetype)
          end
        end

        file_icon = devicon and devicon .. ' ' or file_icon
        file_icon_hl = devicon_hl

        return file_icon, file_icon_hl
      end,
      symbols = {
        Array = '󰅪 ',
        BlockMappingPair = '󰅩 ',
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
        Element = '󰅩 ',
        Enum = ' ',
        EnumMember = ' ',
        Event = ' ',
        Field = ' ',
        File = '󰈔 ',
        Folder = '󰉋 ',
        ForStatement = '󰑖 ',
        Function = '󰊕 ',
        GotoStatement = '󰁔 ',
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
        Return = '󰌑 ',
        Rule = '󰅩 ',
        RuleSet = '󰅩 ',
        Scope = '󰅩 ',
        Section = '󰅩 ',
        Snippet = '󰩫 ',
        Specifier = '󰦪 ',
        Statement = '󰅩 ',
        String = '󰉾 ',
        Struct = ' ',
        SwitchStatement = '󰺟 ',
        Table = '󰅩 ',
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
    ---@type fun(symbol: dropbar_symbol_t, min_width: integer?, n_clicks: integer?, button: string?, modifiers: string?)|false?
    on_click = function(symbol)
      -- Update current context highlights if the symbol
      -- is shown inside a menu
      if symbol.entry and symbol.entry.menu then
        symbol.entry.menu:update_current_context_hl(symbol.entry.idx)
      elseif symbol.bar then
        symbol.bar:update_current_context_hl(symbol.bar_idx)
      end

      -- Determine menu configs
      local prev_win = nil ---@type integer?
      local prev_buf = nil ---@type integer?
      local entries_source = nil ---@type dropbar_symbol_t[]?
      local init_cursor = nil ---@type integer[]?
      local win_configs = {}
      if symbol.bar then -- If symbol inside a dropbar
        prev_win = symbol.bar.win
        prev_buf = symbol.bar.buf
        entries_source = symbol.opts.siblings
        init_cursor = symbol.opts.sibling_idx
          and { symbol.opts.sibling_idx, 0 }
        if symbol.bar.in_pick_mode then
          ---@param tbl number[]
          local function tbl_sum(tbl)
            local sum = 0
            for _, v in ipairs(tbl) do
              sum = sum + v
            end
            return sum
          end
          win_configs.relative = 'win'
          win_configs.win = vim.api.nvim_get_current_win()
          win_configs.row = 0
          win_configs.col = symbol.bar.padding.left
            + tbl_sum(vim.tbl_map(
              function(component)
                return component:displaywidth()
                  + symbol.bar.separator:displaywidth()
              end,
              vim.tbl_filter(function(component)
                return component.bar_idx < symbol.bar_idx
              end, symbol.bar.components)
            ))
        end
      elseif symbol.entry and symbol.entry.menu then -- If inside a menu
        prev_win = symbol.entry.menu.win
        prev_buf = symbol.entry.menu.buf
        entries_source = symbol.opts.children
      end

      -- Toggle existing menu
      if symbol.menu then
        symbol.menu:toggle({
          prev_win = prev_win,
          prev_buf = prev_buf,
          win_configs = win_configs,
        })
        return
      end

      -- Create a new menu for the symbol
      if not entries_source or vim.tbl_isempty(entries_source) then
        return
      end

      local menu = require('dropbar.menu')
      local configs = require('dropbar.configs')
      symbol.menu = menu.dropbar_menu_t:new({
        prev_win = prev_win,
        prev_buf = prev_buf,
        cursor = init_cursor,
        win_configs = win_configs,
        ---@param sym dropbar_symbol_t
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
              sym:merge({
                name = '',
                icon = menu_indicator_icon,
                icon_hl = 'dropbarIconUIIndicator',
                on_click = menu_indicator_on_click,
              }),
              sym:merge({
                on_click = function()
                  local root_menu = symbol.menu and symbol.menu:root()
                  if root_menu then
                    root_menu:close(false)
                  end
                  sym:jump()
                end,
              }),
            },
          })
        end, entries_source),
      })
      symbol.menu:toggle()
    end,
    preview = {
      ---Reorient the preview window on previewing a new symbol
      ---@param win integer source window id, ignored
      ---@param range { start: { line: integer }, end: { line: integer } } 0-indexed
      reorient = function(win, range) end, -- luacheck: ignore 212
    },
    jump = {
      ---@param win integer source window id
      ---@param range { start: { line: integer }, end: { line: integer } } 0-indexed
      reorient = function(win, range) end, -- luacheck: ignore 212
    },
  },
  bar = {
    ---@type boolean|fun(buf: integer, win: integer, info: table?): boolean
    enable = function(buf, win, _)
      buf = vim._resolve_bufnr(buf)
      if
        not vim.api.nvim_buf_is_valid(buf)
        or not vim.api.nvim_win_is_valid(win)
      then
        return false
      end

      if
        not vim.api.nvim_buf_is_valid(buf)
        or not vim.api.nvim_win_is_valid(win)
        or vim.fn.win_gettype(win) ~= ''
        or vim.wo[win].winbar ~= ''
        or vim.bo[buf].ft == 'help'
      then
        return false
      end

      local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
      if stat and stat.size > 1024 * 1024 then
        return false
      end

      return vim.bo[buf].bt == 'terminal'
        or vim.bo[buf].ft == 'markdown'
        or pcall(vim.treesitter.get_parser, buf)
        or not vim.tbl_isempty(vim.lsp.get_clients({
          bufnr = buf,
          method = 'textDocument/documentSymbol',
        }))
    end,
    attach_events = {
      'TermOpen',
      'BufEnter',
      'BufWinEnter',
      'BufWritePost',
      'FileType',
      'LspAttach',
    },
    -- Wait for a short time before updating the winbar, if another update
    -- request is received within this time, the previous request will be
    -- cancelled, this improves the performance when the user is holding
    -- down a key (e.g. 'j') to scroll the window, default to 0 ms
    -- If you encounter performance issues when scrolling the window, try
    -- setting this option to a number slightly larger than
    -- 1000 / key_repeat_rate
    update_debounce = 32,
    update_events = {
      win = {
        'CursorMoved',
        'WinResized',
      },
      buf = {
        'BufModifiedSet',
        'FileChangedShellPost',
        'TextChanged',
        'ModeChanged',
      },
      global = {
        'DirChanged',
        'VimResized',
      },
    },
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
    -- Interval of periodic garbage collection, i.e. remove winbars attached to
    -- invalid buffers/windows, in ms
    gc = {
      interval = 60000,
    },
  },
  menu = {
    -- When on, preview the symbol under the cursor on CursorMoved
    preview = true,
    hover = true,
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
        if M.opts.menu.hover then
          utils.menu.update_hover_hl(mouse)
        end
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
        if not menu.prev_menu then
          return
        end
        return menu.prev_menu.scrollbar
            and menu.prev_menu.scrollbar.thumb
            and vim.api.nvim_win_get_config(menu.prev_menu.scrollbar.thumb).zindex
          or vim.api.nvim_win_get_config(menu.prev_win).zindex
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
          if not border then
            border = vim.go.winborder
          end

          if type(border) == 'string' then
            if border == '' or border == 'none' or border == 'shadow' then
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
        local menu_border = menu._win_configs.border or vim.go.winborder
        if
          type(menu_border) == 'string'
          and menu_border ~= 'shadow'
          and menu_border ~= 'none'
          and menu_border ~= ''
        then
          return menu._win_configs.height + 1
        elseif menu_border == 'none' or menu_border == '' then
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
        local menu_border = menu._win_configs.border or vim.go.winborder
        if
          type(menu_border) == 'string'
          and menu_border ~= 'shadow'
          and menu_border ~= 'none'
          and menu_border ~= ''
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
          menu = menu:root() --[[@as dropbar_menu_t]]
          if menu then
            menu:finish_preview(true)
            if M.opts.menu.hover then
              menu:update_hover_hl()
            end
          end
          return
        end
        if M.opts.menu.preview then
          menu:preview_symbol_at({ mouse.line, mouse.column - 1 }, true)
        end
        if M.opts.menu.hover then
          menu:update_hover_hl({ mouse.line, mouse.column - 1 })
        end
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
      max_depth = 16,
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
      preview = true,
      ---@type integer[]
      min_widths = {},
    },
    treesitter = {
      max_depth = 16,
      -- Vim regex used to extract a short name from the node text
      -- word with optional prefix and suffix: [#~!@\*&.]*[[:keyword:]]\+!\?
      -- word separators: \(->\)\+\|-\+\|\.\+\|:\+\|\s\+
      name_regex = [=[[#~!@\*&.]*[[:keyword:]]\+!\?]=]
        .. [=[\(\(\(->\)\+\|-\+\|\.\+\|:\+\|\s\+\)\?[#~!@\*&.]*[[:keyword:]]\+!\?\)*]=],
      -- The order matters! The first match is used as the type
      -- of the treesitter symbol and used to show the icon
      -- Types listed below must have corresponding icons
      -- in the `icons.kinds.symbols` table for the icon to be shown
      valid_types = {
        'block_mapping_pair',
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
        'element',
        'enum',
        'enum_member',
        'event',
        'for_statement',
        'function',
        'goto_statement',
        'if_statement',
        'interface',
        'keyword',
        'macro',
        'method',
        'namespace',
        'null',
        'number',
        'operator',
        'package',
        'pair',
        'property',
        'reference',
        'repeat',
        'return_statement',
        'rule',
        'rule_set',
        'scope',
        'section',
        'specifier',
        'struct',
        'switch_statement',
        'table',
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
      },
      ---@type integer[]
      min_widths = {},
    },
    lsp = {
      max_depth = 16,
      valid_symbols = {
        'File',
        'Module',
        'Namespace',
        'Package',
        'Class',
        'Method',
        'Property',
        'Field',
        'Constructor',
        'Enum',
        'Interface',
        'Function',
        'Variable',
        'Constant',
        'String',
        'Number',
        'Boolean',
        'Array',
        'Object',
        'Keyword',
        'Null',
        'EnumMember',
        'Struct',
        'Event',
        'Operator',
        'TypeParameter',
      },
      request = {
        -- Times to retry a request before giving up
        ttl_init = 60,
        interval = 1000, -- in ms
      },
      ---@type integer[]
      min_widths = {},
    },
    markdown = {
      max_depth = 6,
      parse = {
        -- Number of lines to update when cursor moves out of the parsed range
        look_ahead = 200,
      },
      ---@type integer[]
      min_widths = {},
    },
    terminal = {
      ---@type string|fun(buf: integer): string?
      icon = function(_)
        return M.opts.icons.kinds.symbols.Terminal
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

  -- Notify deprecated options
  if
    (vim.islist or vim.tbl_islist)(
      new_opts.general and new_opts.general.update_events
    )
  then
    vim.api.nvim_echo({
      { '[dropbar.nvim] ', 'Normal' },
      { 'opts.general.update_events', 'WarningMsg' },
      { ' is deprecated, please use:\n', 'Normal' },
      { '               opts.general.update_events.win', 'WarningMsg' },
      { ' for updating a winbar attached to a single window,\n', 'Normal' },
      { '               opts.general.update_events.buf ', 'WarningMsg' },
      { 'for updating all winbars attached to a buffer, or\n', 'Normal' },
      { '               opts.general.update_events.global ', 'WarningMsg' },
      { 'for updating all winbars in current nvim session ', 'Normal' },
      { 'instead', 'Normal' },
    }, true, {})
    new_opts.general.update_events = {
      win = new_opts.general.update_events,
    }
  end

  if ((new_opts.sources or {}).treesitter or {}).name_pattern then
    vim.api.nvim_echo({
      { '[dropbar.nvim] ', 'Normal' },
      { 'opts.sources.treesitter.name_pattern', 'WarningMsg' },
      { ' is deprecated.\n', 'Normal' },
      { '[dropbar.nvim] ', 'Normal' },
      { 'Please use ', 'Normal' },
      { 'opts.sources.treesitter.name_regex ', 'WarningMsg' },
      { 'instead to match ts node names with vim regex', 'Normal' },
    }, true, {})
    new_opts.sources.treesitter.name_pattern = nil
  end

  if (new_opts.general or {}).update_interval then
    vim.api.nvim_echo({
      { '[dropbar.nvim] ', 'Normal' },
      { 'opts.general.update_interval', 'WarningMsg' },
      { ' is deprecated, please use ', 'Normal' },
      { 'opts.bar.update_debounce', 'WarningMsg' },
      { ' instead', 'Normal' },
    }, true, {})
    new_opts.general.update_debounce = new_opts.general.update_interval
    new_opts.general.update_interval = nil
  end

  if new_opts.general then
    vim.api.nvim_echo({
      { '[dropbar.nvim] ', 'Normal' },
      { 'opts.general', 'WarningMsg' },
      { ' is deprecated, its config fields have been moved to ', 'Normal' },
      { 'opts.bar', 'WarningMsg' },
    }, true, {})
    new_opts.bar =
      vim.tbl_deep_extend('force', new_opts.bar or {}, new_opts.general)
    new_opts.general = nil ---@diagnostic disable-line: inject-field
  end

  if (((new_opts or {}).icons or {}).kinds or {}).use_devicons ~= nil then
    vim.api.nvim_echo({
      { '[dropbar.nvim] ', 'Normal' },
      { 'opts.icons.kinds.use_devicons', 'WarningMsg' },
      { ' is deprecated, please use ', 'Normal' },
      { 'opts.icons.kinds.file_icon', 'WarningMsg' },
      { ' and ', 'Normal' },
      { 'opts.icons.kinds.folder_icon', 'WarningMsg' },
      { ' to customize file or directory icons', 'Normal' },
    }, true, {})
    new_opts.icons.kinds.use_devicons = nil
  end

  if new_opts.icons and new_opts.icons.enable == false then
    local blank_icons = setmetatable({}, {
      __index = function()
        return ''
      end,
    })
    M.opts.icons.kinds.dir_icon = ''
    M.opts.icons.kinds.file_icon = ''
    M.opts.icons.kinds.symbols = blank_icons
    M.opts.icons.ui.bar = blank_icons
    M.opts.icons.ui.menu = blank_icons
  end

  M.opts = vim.tbl_deep_extend('force', M.opts, new_opts)
end

---Evaluate a dynamic option value (with type T|fun(...): T)
---@generic T
---@param opt? `T`|fun(...): `T`
---@return `T`?
function M.eval(opt, ...)
  if opt and vim.is_callable(opt) then
    return opt(...)
  end
  return opt
end

return M
