<h1 align='center'>
  dropbar.nvim
</h1>

<p align='center'>
  <b>IDE-like breadcrumbs, out of the box</b>
</p>

<p align='center'>
  <img src=https://github.com/Bekaboo/dropbar.nvim/assets/76579810/28db72ab-d75c-46fe-8a9d-1f06b4440de9 width=500>
</p>

<p align='center'>
  A polished, IDE-like, highly-customizable winbar for Neovim <br>
  with drop-down menu support and multiple backends
</p>

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
  - [Options](#options)
    - [General](#general)
    - [Icons](#icons)
    - [Symbol](#symbol)
    - [Bar](#bar)
    - [Menu](#menu)
    - [Sources](#sources)
      - [Path](#path)
      - [Treesitter](#treesitter)
      - [LSP](#lsp)
      - [Markdown](#markdown)
      - [Terminal](#terminal)
  - [API](#api)
  - [Utility Functions](#utility-functions)
    - [Bar Utility Functions](#bar-utility-functions)
    - [Menu Utility Functions](#menu-utility-functions)
  - [Highlighting](#highlighting)
- [Developers](#developers)
  - [Architecture](#architecture)
  - [Classes](#classes)
    - [`dropbar_t`](#dropbar_t)
    - [`dropbar_symbol_t`](#dropbar_symbol_t)
    - [`dropbar_menu_t`](#dropbar_menu_t)
    - [`dropbar_menu_entry_t`](#dropbar_menu_entry_t)
    - [`dropbar_menu_hl_info_t`](#dropbar_menu_hl_info_t)
    - [`dropbar_source_t`](#dropbar_source_t)
  - [Making a New Source](#making-a-new-source)
    - [Making a Source With Drop-Down Menus](#making-a-source-with-drop-down-menus)
    - [Default `on_click()` Callback](#default-on_click-callback)
    - [Lazy-Loading Expensive Fields](#lazy-loading-expensive-fields)
- [Similar Projects](#similar-projects)

## Features

https://github.com/Bekaboo/dropbar.nvim/assets/76579810/e8c1ac26-0321-4762-9975-b20fc3098c5a

- [x] Opening drop-down menus or go to definition with a single mouse click

    ![mouse-click](https://github.com/Bekaboo/dropbar.nvim/assets/76579810/25282bf2-c90d-496b-9c37-0cbb6938ff5f)

- [x] Pick mode for quickly selecting a component in the winbar with shortcuts

    ![pick-mode](https://github.com/Bekaboo/dropbar.nvim/assets/76579810/6126ceb1-0ad9-468b-89b9-457ce4110999)

- [x] Automatically truncating long components

    ![auto-truncate](https://github.com/Bekaboo/dropbar.nvim/assets/76579810/c3b03e7f-d6f7-4c60-9c0d-da038529e1c7)

- [x] Multiple backends that support fall-backs

  `dropbar.nvim` comes with five builtin sources:

  - [x] [lsp](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/sources/lsp.lua): gets symbols from language servers using nvim's builtin LSP framework

  - [x] [markdown](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/sources/markdown.lua): a custom incremental parser that gets symbol information about markdown headings

  - [x] [path](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/sources/path.lua): gets current file path

  - [x] [treesitter](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/sources/treesitter.lua): gets symbols from treesitter parsers using nvim's builtin treesitter integration

  - [x] [terminal](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/sources/terminal.lua): easily switch terminal buffers using the dropdown menu

  To make a new source yourself, see [making a new source](#making-a-new-source).

  For source fall-backs support, see [bar options](#bar).

- [x] Zero config & Zero dependency

  `dropbar.nvim` does not require [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
  or any third-party UI libraries to work.
  As long as the language server or the treesitter parser is installed,
  it should work just fine.

  Optionally, you can install [telescope-fzf-native](https://github.com/nvim-telescope/telescope-fzf-native)
  to add fuzzy search support to dropbar menus.

- [x] Drop-down menu components and winbar symbols that response to
      mouse/cursor hovering:

    ![hover](https://github.com/Bekaboo/dropbar.nvim/assets/76579810/c944d61c-d39b-42e9-8b24-e3e33672b0d2)

    - This features requires `:h mousemoveevent` to be enabled.

- [x] Preview symbols in their source windows when hovering over them in the
  drop-down menu

    ![preview](https://github.com/Bekaboo/dropbar.nvim/assets/76579810/93f33b90-4f42-459c-861a-1e70114ba6f2)

- [x] Reorient the source window on previewing or after jumping to a symbol

- [x] Background color support<super>*</super> thanks [@theofabilous](https://github.com/theofabilous)

  ![background-color](https://github.com/Bekaboo/dropbar.nvim/assets/76579810/d7794098-9dcf-459e-9763-8b7d9414e035)

  - This is currently an experimental feature that is only available in branch
    [`feat-winbar-background-highlight`](https://github.com/Bekaboo/dropbar.nvim/tree/feat-winbar-background-highlight).
  - To achieve the same effect in branch [`master`](https://github.com/Bekaboo/dropbar.nvim/tree/master), see discussions in [#2](https://github.com/Bekaboo/dropbar.nvim/issues/2)

- [ ] Add preview for symbols shown in the winbar

- [ ] Preview symbols (files) from `path` source

- [ ] Add more actions other than `jump` and `preview`, e.g. `rename`,
  `delete`, `select`, etc.

- [ ] Support visual mode selection to select/delete multiple symbols

- [ ] Ability to hide/show the winbar on each window separately

## Requirements

- Neovim **Nightly** (>= 0.10.0-dev)
- Optional
  - [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons), if you want to see icons for different filetypes
  - [telescope-fzf-native](https://github.com/nvim-telescope/telescope-fzf-native), if you want fuzzy search support
  - Working language server installation for the lsp source to work
  - Working treesitter parser installation for the treesitter source to work

## Installation

- Using [lazy.nvim](https://github.com/folke/lazy.nvim)

  ```lua
  require('lazy').setup({
    {
      'Bekaboo/dropbar.nvim',
      -- optional, but required for fuzzy finder support
      dependencies = {
        'nvim-telescope/telescope-fzf-native'
      }
    }
  })
  ```

- Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

  ```lua
  require('packer').startup(function(use)
    use({
      'Bekaboo/dropbar.nvim',
      requires = {
        'nvim-telescope/telescope-fzf-native'
      }
    })
  end)
  ```

- Using native package manager

  ```sh
  mkdir -p ~/.local/share/nvim/site/pack/packages/
  git clone https://github.com/Bekaboo/dropbar.nvim ~/.local/share/nvim/site/pack/packages/start/dropbar.nvim
  ```

  Lazy-loading is unneeded as it is already done in [plugin/dropbar.lua](https://github.com/Bekaboo/dropbar.nvim/blob/master/plugin/dropbar.lua).

## Usage

- Basics
  - Moves the cursor around and see the winbar reflects your current context
- Mouse support
  - Click on a component in the winbar to open a drop-down menu of its
    siblings
  - Click on an entry in the drop-down menu to go to its location
  - Click on the indicator in the drop-down menu to open a sub-menu of its
    children
- Pick mode
  - Use `require('dropbar.api').pick()` to enter interactive pick mode or
    `require('dropbar.api').pick(<idx>)` to directly select a component at
    `idx`.
  - Inside interactive pick mode, press the corresponding pivot shown before
    each component to select it
- Fuzzy finder
  - Use dropbar_menu_t:fuzzy_find_open() to interactively
    filter, select and preview entries using fzf
  - `<i>`: enter fzf mode from the menu
  - `<Esc>`: exit fzf mode
  - `<Up>/<Down>`: move the cursor in fzf mode
  - `<CR>`: call the on_click callback of the symbol under the cursor
- Default keymaps in drop-down menu
  - `<LeftMouse>`: call the `on_click` callback of the symbol at the mouse
    click
  - `<CR>`: find the first clickable symbol in the current drop-down menu
    entry and call its `on_click` callback
  - To disable, remap or add new keymaps in the drop-down menu, see
    [menu options](#menu)

## Configuration

### Options

<details>
  <summary>
    A full list of all available options and their default values:
  </summary>

  ```lua
  ---@class dropbar_configs_t
  local opts = {
    general = {
      ---@type boolean|fun(buf: integer, win: integer): boolean
      enable = function(buf, win)
        return not vim.api.nvim_win_get_config(win).zindex
          and vim.bo[buf].buftype == ''
          and vim.api.nvim_buf_get_name(buf) ~= ''
          and not vim.wo[win].diff
      end,
      attach_events = {
        'OptionSet',
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
          'WinEnter',
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
          H1Marker = '󰉫 ', -- Used by markdown treesitter parser
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
          MarkdownH1 = '󰉫 ', -- Used by builtin markdown source
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
            local view = vim.fn.winsaveview()
            view.topline = view.topline + invisible
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
      ---@type dropbar_source_t[]|fun(buf: integer, win: integer): dropbar_source_t[]
      sources = function(buf, _)
        local sources = require('dropbar.sources')
	      local utils = require('dropbar.utils')
        if vim.bo[buf].ft == 'markdown' then
          return {
            sources.path,
            utils.source.fallback({
              sources.treesitter,
              sources.markdown,
              sources.lsp,
            }),
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
      ---@type table<string, string|function|table<string, string|function>>
      keymaps = {
        ['<LeftMouse>'] = function()
          local menu = utils.menu.get_current()
          if not menu then
            return
          end
          local mouse = vim.fn.getmousepos()
          if mouse.winid ~= menu.win then
            local prev_menu = utils.menu.get({ win = mouse.winid })
            if prev_menu and prev_menu.sub_menu then
              prev_menu.sub_menu:close()
            else
              utils.menu.exec('close')
              utils.bar.exec('update_current_context_hl')
            end
            if vim.api.nvim_win_is_valid(mouse.winid) then
              vim.api.nvim_set_current_win(mouse.winid)
            end
            return
          end
          menu:click_at({ mouse.line, mouse.column - 1 }, nil, 1, 'l')
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
          -- If mouse is not in the menu window or on the border, end preview
          -- and clear hover highlights
          if mouse.winid ~= menu.win or mouse.line <= 0 or mouse.column <= 0 then
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
          end
          local mouse = vim.fn.getmousepos()
          local bar = require('dropbar.api').get_dropbar(
            vim.api.nvim_win_get_buf(menu.prev_win),
            menu.prev_win
          )
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
      },
    },
    fzf = {
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
            menu:fuzzy_find_close(false)
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
            or mouse.winrow > #menu.entries
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
        ['<Esc>'] = function()
          ---@type dropbar_menu_t
          local menu = utils.menu.get_current()
          if not menu then
            return
          end
          menu:fuzzy_find_close(true)
        end,
        ['<Enter>'] = function()
          ---@type dropbar_menu_t
          local menu = utils.menu.get_current()
          if not menu then
            return
          end
          menu:fuzzy_find_click_on_entry(-1)
        end,
        ['<S-Enter>'] = function()
          ---@type dropbar_menu_t
          local menu = utils.menu.get_current()
          if not menu then
            return
          end
          menu:fuzzy_find_click_on_entry(nil)
        end,
        ['<Up>'] = function()
          ---@type dropbar_menu_t
          local menu = utils.menu.get_current()
          if not menu then
            return
          end
          if vim.api.nvim_buf_line_count(menu.buf) <= 1 then
            return
          end
          local cursor = vim.api.nvim_win_get_cursor(menu.win)
          cursor[1] = math.max(1, cursor[1] - 1)
          vim.api.nvim_win_set_cursor(menu.win, cursor)
          menu:update_hover_hl(cursor)
          if M.opts.menu.preview then
            menu:preview_symbol_at(cursor)
          end
        end,
        ['<Down>'] = function()
          ---@type dropbar_menu_t
          local menu = utils.menu.get_current()
          if not menu then
            return
          end
          local line_count = vim.api.nvim_buf_line_count(menu.buf)
          if line_count <= 1 then
            return
          end
          local cursor = vim.api.nvim_win_get_cursor(menu.win)
          cursor[1] = math.min(line_count, cursor[1] + 1)
          vim.api.nvim_win_set_cursor(menu.win, cursor)
          menu:update_hover_hl(cursor)
          if M.opts.menu.preview then
            menu:preview_symbol_at(cursor)
          end
        end,
      },
      -- Options passed to `:h nvim_open_win`. The fuzzy finder will use its
      -- parent window's config by default, but options set here will override those.
      win_configs = {},
      ---@type table
      hl = {
        ---@type string
        fg = vim.api.nvim_get_hl(0, { name = 'htmlTag', link = false }).fg,
        ---@type boolean
        underline = true,
      },
      ---@type string
      prompt = '%#htmlTag# ',
      ---@type string
      char_pattern = '[%w%p]',
      ---@type boolean
      retain_inner_spaces = true,
    },
    sources = {
      path = {
        ---@type string|fun(buf: integer): string
        relative_to = function(_)
          return vim.fn.getcwd()
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
      }
    },
  }
  ```

</details>

#### General

These options live under `opts.general` and are used to configure the
general behavior of the plugin:

- `opts.general.enable`: `boolean|fun(buf: integer, win: integer): boolean`
  - Controls whether to enable the plugin for the current buffer and window
  - If a function is provided, it will be called with the current bufnr and
  winid and should return a boolean
  - Default:
    ```lua
    function(buf, win)
      return not vim.api.nvim_win_get_config(win).zindex
      and vim.bo[buf].buftype == ''
      and vim.api.nvim_buf_get_name(buf) ~= ''
      and not vim.wo[win].diff
    end
    ```
- `opts.general.attach_events`: `string[]`
  - Controls when to evaluate the `enable()` function and attach the plugin
    to corresponding buffer or window
  - Default:
    ```lua
    {
      'OptionSet',
      'BufWinEnter',
      'BufWritePost',
    }
    ```
- `opts.general.update_interval`: `number`
  - Wait for a short time before updating the winbar, if another update
    request is received within this time, the previous request will be
    cancelled, this improves the performance when the user is holding
    down a key (e.g. `'j'`) to scroll the window
  - If you encounter performance issues when scrolling the window, try
    setting this option to a number slightly larger than
    `1000 / key_repeat_rate`
  - Default: `0`
- `opts.general.update_events.win`: `string[]`
  - List of events that should trigger an update on the dropbar attached to
    a single window
  - Default:
    ```lua
    {
      'CursorMoved',
      'CursorMovedI',
      'WinEnter',
      'WinResized',
    }
    ```
- `opts.general.update_events.buf`: `string[]`
  - List of events that should trigger an update on all dropbars attached to a
    buffer
  - Default:
    ```lua
    {
      'BufModifiedSet',
      'FileChangedShellPost',
      'TextChanged',
      'TextChangedI',
    }
    ```
- `opts.general.update_events.global`: `string[]`
  - List of events that should trigger an update of all dropbars in current
    nvim session
  - Default:
    ```lua
    {
      'DirChanged',
      'VimResized',
    }
    ```

#### Icons

These options live under `opts.icons` and are used to configure the icons
used by the plugin:

- `opts.icons.enable`: `boolean`
  - Whether to enable icons
  - Default: `true`
- `opts.icons.kinds.use_devicons`: `boolean`
  - Whether to use [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) to show icons for different filetypes
  - Default: `true`
- `opts.icons.kinds.symbols`: `table<string, string>`
  - Table mapping the different kinds of symbols to their corresponding icons
  - Default:
    ```lua
    {
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
      H1Marker = '󰉫 ', -- Used by markdown treesitter parser
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
      MarkdownH1 = '󰉫 ', -- Used by builtin markdown source
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
      Text = ' ',
      Type = ' ',
      TypeParameter = '󰆩 ',
      Unit = ' ',
      Value = '󰎠 ',
      Variable = '󰀫 ',
      WhileStatement = '󰑖 ',
    }
    ```
- `opts.icons.ui.bar`: `table<string, string>`
  - Controls the icons used in the winbar UI
  - Default:
    ```lua
    {
      separator = ' ',
      extends = '…',
    }
    ```
- `opts.icons.ui.menu`: `table<string, string>`
  - Controls the icons used in the menu UI
  - Default:
    ```lua
    {
      separator = ' ',
      indicator = ' ',
    }
    ```
#### Symbol

These options live under `opts.symbol` and are used to control the behavior of
the symbols:

- `opts.symbol.preview.reorient`: `fun(win: integer, range: {start: {line: integer, character: integer}, end: {line: integer, character: integer}})`
  - Function to reorient the source window when previewing symbol given
    the source window `win` and the range of the symbol `range`
  - Default:
    ```lua
    function(_, range)
      local invisible = range['end'].line - vim.fn.line('w$') + 1
      if invisible > 0 then
        local view = vim.fn.winsaveview()
        view.topline = view.topline + invisible
        vim.fn.winrestview(view)
      end
    end
    ```
- `opts.symbol.jump.reorient`: `fun(win: integer, range: {start: {line: integer, character: integer}, end: {line: integer, character: integer}})`
  - Function to reorient the source window after jumping to symbol given
    the source window `win` and the range of the symbol `range`
  - Default:
    ```lua
    function(win, range)
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
    end
    ```

#### Bar

These options live under `opts.bar` and are used to control the behavior of the
winbar:

- `opts.bar.hover`: `boolean`
  - Whether to highlight the symbol under the cursor
  - This feature requires `'mousemoveevent'` to be enabled
  - Default: `true`
- `opts.bar.sources`: `dropbar_source_t[]|fun(buf: integer, win: integer): dropbar_source_t[]`
  - List of sources to show in the winbar
  - If a function is provided, it will be called with the current bufnr and
    winid and should return a list of sources
  - Default:
    ```lua
    function(buf, _)
      local sources = require('dropbar.sources')
      local utils = require('dropbar.utils')
      if vim.bo[buf].ft == 'markdown' then
        return {
          sources.path,
          utils.source.fallback({
            sources.treesitter,
            sources.markdown,
            sources.lsp,
          }),
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
    end
    ```
  - For more information about sources, see [`dropbar_source_t`](#dropbar_source_t).
- `opts.bar.padding`: `{ left: number, right: number }`
  - Padding to use between the winbar and the window border
  - Default: `{ left = 1, right = 1 }`
- `opts.bar.pick.pivots`: `string`
  - Pivots to use in pick mode
  - Default: `'abcdefghijklmnopqrstuvwxyz'`
- `opts.bar.truncate`: `boolean`
  - Whether to truncate the winbar if it doesn't fit in the window
  - Default: `true`

#### Menu

These options live under `opts.menu` and are used to control the behavior of the
menu:

- `opts.menu.quick_navigation`: `boolean`
  - When on, automatically set the cursor to the closest previous/next
    clickable component in the direction of cursor movement on `CursorMoved`
  - Default: `true`
- `opts.menu.entry.padding`: `{ left: number, right: number }`
  - Padding to use between the menu entry and the menu border
  - Default: `{ left = 1, right = 1 }`
- `opts.menu.preview`: `boolean`
  - Whether to enable previewing for menu entries
  - Default: `true`
- `opts.menu.keymaps`: `table<string, function|string|table<string, function>|table<string, string>>`
  - Buffer-local keymaps in the menu
  - Use `<key> = <function|string>` to map a key in normal mode and visual mode
    in the menu buffer, or use `<key> = table<mode, function|string>` to map
    a key in specific modes.
  - Default:
    ```lua
    {
      ['<LeftMouse>'] = function()
        local menu = utils.menu.get_current()
        if not menu then
          return
        end
        local mouse = vim.fn.getmousepos()
        if mouse.winid ~= menu.win then
          local prev_menu = utils.menu.get({ win = mouse.winid })
          if prev_menu and prev_menu.sub_menu then
            prev_menu.sub_menu:close()
          else
            utils.menu.exec('close')
            utils.bar.exec('update_current_context_hl')
          end
          if vim.api.nvim_win_is_valid(mouse.winid) then
            vim.api.nvim_set_current_win(mouse.winid)
          end
          return
        end
        menu:click_at({ mouse.line, mouse.column - 1 }, nil, 1, 'l')
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
        -- If mouse is not in the menu window or on the border, end preview
        -- and clear hover highlights
        if mouse.winid ~= menu.win or mouse.line <= 0 or mouse.column <= 0 then
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
    }
    ```
- `opts.menu.win_configs`: `table<string, dropbar_menu_win_config_opts_t>`
  - Window configurations for the menu, see `:h nvim_open_win()`
  - Each config key in `opts.menu.win_configs` accepts either a plain value
    which will be passes directly to `nvim_open_win()`, or a function that
    takes the current menu (see [`dropbar_menu_t`](#dropbar_menu_t)) as an
    argument and returns a value to be passed to `nvim_open_win()`.
  - Default:
    ```lua
    {
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
        end
        local mouse = vim.fn.getmousepos()
        local bar = require('dropbar.api').get_dropbar(
          vim.api.nvim_win_get_buf(menu.prev_win),
          menu.prev_win
        )
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
    }
    ```

#### Fzf

These options live under opts.fzf and are used to control the behavior and
appearance of the fuzzy finder interface.

- opts.fzf.keymaps
  - The keymaps that will apply in insert mode, in the fzf prompt buffer
  - Same config as opts.menu.keymaps
  - Default:
    ```lua
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
          menu:fuzzy_find_close(false)
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
          or mouse.winrow > #menu.entries
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
      ['<Esc>'] = function()
        ---@type dropbar_menu_t
        local menu = utils.menu.get_current()
        if not menu then
          return
        end
        menu:fuzzy_find_close(true)
      end,
      ['<Enter>'] = function()
        ---@type dropbar_menu_t
        local menu = utils.menu.get_current()
        if not menu then
          return
        end
        menu:fuzzy_find_click_on_entry(-1)
      end,
      ['<S-Enter>'] = function()
        ---@type dropbar_menu_t
        local menu = utils.menu.get_current()
        if not menu then
          return
        end
        menu:fuzzy_find_click_on_entry(nil)
      end,
      ['<Up>'] = function()
        ---@type dropbar_menu_t
        local menu = utils.menu.get_current()
        if not menu then
          return
        end
        if vim.api.nvim_buf_line_count(menu.buf) <= 1 then
          return
        end
        local cursor = vim.api.nvim_win_get_cursor(menu.win)
        cursor[1] = math.max(1, cursor[1] - 1)
        vim.api.nvim_win_set_cursor(menu.win, cursor)
        menu:update_hover_hl(cursor)
        if M.opts.menu.preview then
          menu:preview_symbol_at(cursor)
        end
      end,
      ['<Down>'] = function()
        ---@type dropbar_menu_t
        local menu = utils.menu.get_current()
        if not menu then
          return
        end
        local line_count = vim.api.nvim_buf_line_count(menu.buf)
        if line_count <= 1 then
          return
        end
        local cursor = vim.api.nvim_win_get_cursor(menu.win)
        cursor[1] = math.min(line_count, cursor[1] + 1)
        vim.api.nvim_win_set_cursor(menu.win, cursor)
        menu:update_hover_hl(cursor)
        if M.opts.menu.preview then
          menu:preview_symbol_at(cursor)
        end
      end,
    }
    ```

- opts.fzf.win_configs
  - Options passed to `:h nvim_open_win`. The fuzzy finder will use its
    parent window's config by default, but options set here will override those.
  - Same config as opts.menu.win_configs
  - Default:
    ```lua
    win_configs = {}
    ```

- opts.fzf.hl
  - Highlight to use for the fuzzy finder.
  - Options passed directly to `:h nvim_set_hl`
  - Default:
    ```lua
    hl = {
      fg = vim.api.nvim_get_hl(0, { name = 'htmlTag', link = false }).fg,
      underline = true,
    }
    ```

- opts.fzf.prompt
  - Prompt string that will be displayed in the statuscolumn of the fzf input window.
  - Can include highlight groups
  - Default:
    ```lua
    prompt = '%#htmlTag# '
    ```

- opts.char_pattern
  - Default:
    ```lua
    char_pattern = '[%w%p]'
    ```

- opts.retain_inner_spaces
  - Default:
    ```lua
    retain_inner_spaces = true
    ```

#### Sources

These options live under `opts.sources` and are used to control the behavior of
each sources.

##### Path

- `opts.sources.path.relative_to`: `string|fun(buf: integer): string`
  - The path to use as the root of the relative path
  - If a function is provided, it will be called with the current buffer number
    as an argument and should return a string to use as the root of the relative
    path
  - Notice: currently does not support `..` relative paths
  - Default:
    ```lua
    function(_)
      return vim.fn.getcwd()
    end
    ```
- `opts.sources.path.filter`: `function(name: string): boolean`
  - A function that takes a file name and returns whether to include it in the
    results shown in the drop-down menu
  - Default:
    ```lua
    function(_)
      return true
    end
    ```
- `opts.sources.path.modified`: `function(sym: dropbar_symbol_t): dropbar_symbol_t`
  - A function that takes the last
    symbol<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> in the result got
    from the path source and returns an alternative
    symbol<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> to show if the
    current buffer is modified
  - Default:
    ```lua
    function(sym)
      return sym
    end
    ```
  - To set a different icon, name, or highlights when the buffer is modified,
    you can change the corresponding fields in the returned
    symbol<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub>
    ```lua
    function(sym)
      return sym:merge({
        name = sym.name .. '[+]',
        icon = ' ',
        name_hl = 'DiffAdded',
        icon_hl = 'DiffAdded',
        -- ...
      })
    end
    ```

##### Treesitter

- `opts.sources.treesitter.name_pattern`: `string`
  - Lua pattern used to extract a short name from the node text
  - Default: `'[#~%*%w%._%->!@:]+%s*' .. string.rep('[#~%*%w%._%->!@:]*', 3, '%s*')`
- `opts.sources.treesitter.valid_types:` `string[]`
  - A list of treesitter node types to include in the results
  - Default:
    ```lua
    {
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
    }
    ```

##### LSP

- `opts.sources.lsp.request.ttl_init`: `number`
  - Number of times to retry a request before giving up
  - Default: `60`
- `opts.sources.lsp.request.interval`: `number`
  - Number of milliseconds to wait between retries
  - Default: `1000`

##### Markdown

- `opts.sources.markdown.parse.look_ahead`: `number`
  - Number of lines to update when cursor moves out of the parsed range
  - Default: `200`

##### Terminal

Thanks [@willothy](https://github.com/willothy) for implementing this.

- `opts.sources.terminal.icon`: `string` or `fun(buf: integer): string`
  - Icon to show before terminal names
  - Default:
    ```lua
    icon = function(buf)
      local icon = M.opts.icons.kinds.symbols.Terminal
      if M.opts.icons.kinds.use_devicons then
        icon = require('nvim-web-devicons').get_icon_by_filetype(
          vim.bo[buf].filetype
        ) or icon
      end
      return icon
    end
    ```

- `opts.sources.terminal.name`: `string` or `fun(buf: integer): string`
  - Easy to integrate with other plugins (for example, [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)):
    ```lua
    name = function(buf)
      local name = vim.api.nvim_buf_get_name(buf)
      -- the second result val is the terminal object
      local term = select(2, require("toggleterm.terminal").indentify(name))
      if term then
        return term.display_name or term.name
      else
        return name
      end
    end
    ```
  - Default: `vim.api.nvim_buf_get_name`

- `opts.sources.terminal.show_current: boolean`
  - Show the current terminal buffer in the menu
  - Default: `true`

### API

`dropbar.nvim` exposes a few functions in `lua/dropbar/api.lua` that can be
used to interact with the winbar or the drop-down menu:

- ~~`get_dropbar(buf: integer?, win: integer): dropbar_t?`~~
  prefer [`utils.bar.get()`](#bar-utility-functions)
  - Get the dropbar associated with the given buffer and window
  - For more information about the `dropbar_t` type, see
    [`dropbar_t`](#dropbar_t)
- ~~`get_current_dropbar(): dropbar_t?`~~
  prefer [`utils.bar.get_current()`](#bar-utility-functions)
  - Get the dropbar associated with the current buffer and window
- ~~`get_dropbar_menu(win: integer): dropbar_menu_t?`~~
  prefer [`utils.menu.get()`](#menu-utility-functions)
  - Get the drop-down menu associated with the given window
  - For more information about the `dropbar_menu_t` type, see
    [`dropbar_menu_t`](#dropbar_menu_t)
- ~~`get_current_dropbr_menu(): dropbar_menu_t?`~~
  prefer [`utils.menu.get_current()`](#menu-utility-functions)
  - Get the drop-down menu associated with the current window
- `goto_context_start(count: integer?)`
  - Move the cursor to the start of the current context
  - If `count` is 0 or `nil`, go to the start of current context, or the start
    at previous context if cursor is already at the start of current context
  - If `count` is positive, goto the start of `count` previous context
- `select_next_context()`
  - Open the menu of current context to select the next context
- `pick(idx: integer?)`
  - Pick a component from current winbar
  - If `idx` is `nil`, enter interactive pick mode to select a component
  - If `idx` is a number, directly pick the component at that index if it exists
- `fuzzy_find_toggle(opts: table?)`
  - Toggle the fuzzy finder interface for the current dropbar menu
  - Options override the default / config options for the fuzzy finder
- `fuzzy_find_click(component: number | (fun(entry: dropbar_menu_entry_t):dropbar_sumbol_t)?)`
  - If `component` is a `number`, the `component`-nth symbol is selected,
    unless `0` or `-1` is supplied, in which case the *first* or *last*
    clickable component is selected, respectively.
  - If it is a `function`, it receives the `dropbar_menu_entry_t` as an argument
    and should return the `dropbar_symbol_t` that is to be clicked.
- `fuzzy_find_navigate(direction: "up" | "down")`
  - Select the previous/next entry in the menu while fuzzy finding

### Utility Functions

Here are some utility functions that can be handy when writing your customize
your config:

#### Bar Utility Functions

Defined in [`lua/dropbar/utils/bar.lua`](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/utils/bar.lua).

- `utils.bar.get(opts?): (dropbar_t?)|table<integer, dropbar_t>|table<integer, table<integer, dropbar_t>>`
  - Get the dropbar(s) associated with the given buffer and window
  - If only `opts.win` is specified, return the dropbar attached the window;
  - If only `opts.buf` is specified, return all dropbars attached the buffer;
  - If both `opts.win` and `opts.buf` are specified, return the dropbar
    attached the window that contains the buffer;
  - If neither `opts.win` nor `opts.buf` is specified, return all dropbars in
    the form of `table<buf, table<win, dropbar_t>>`
- `utils.bar.get_current(): dropbar_t?`
  - Get the dropbar associated with the current buffer and window

#### Menu Utility Functions

Defined in [`lua/dropbar/utils/menu.lua`](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/utils/menu.lua).

- `utils.menu.get(opts): (dropbar_menu_t?)|table<integer, dropbar_menu_t>`
  - Get dropbar menu
  - If `opts.win` is specified, return the dropbar menu attached the window;
  - If `opts.win` is not specified, return all opened dropbar menus
- `utils.menu.get_current(): dropbar_menu_t?`
  - Get current dropbar menu

### Highlighting

`dropbar.nvim` defines the following highlight groups that, override them in
your colorscheme to change the appearance of the drop-down menu, the names
should be self-explanatory:

<details>
  <summary>Highlight groups</summary>

  | Highlight group                  | Attributes                              |
  |----------------------------------|-----------------------------------------|
  | DropBarCurrentContext            | `{ link = 'Visual' }`                   |
  | DropBarHover                     | `{ link = 'Visual' }`                   |
  | DropBarIconCurrentContext        | `{ link = 'Visual' }`                   |
  | DropBarIconKindArray             | `{ link = 'Array' }`                    |
  | DropBarIconKindBoolean           | `{ link = 'Boolean' }`                  |
  | DropBarIconKindBreakStatement    | `{ link = 'Error' }`                    |
  | DropBarIconKindCall              | `{ link = 'Function' }`                 |
  | DropBarIconKindCaseStatement     | `{ link = 'Conditional' }`              |
  | DropBarIconKindClass             | `{ link = 'CmpItemKindClass' }`         |
  | DropBarIconKindConstant          | `{ link = 'Constant' }`                 |
  | DropBarIconKindConstructor       | `{ link = 'CmpItemKindConstructor' }`   |
  | DropBarIconKindContinueStatement | `{ link = 'Repeat' }`                   |
  | DropBarIconKindDeclaration       | `{ link = 'CmpItemKindSnippet' }`       |
  | DropBarIconKindDelete            | `{ link = 'Error' }`                    |
  | DropBarIconKindDoStatement       | `{ link = 'Repeat' }`                   |
  | DropBarIconKindElseStatement     | `{ link = 'Conditional' }`              |
  | DropBarIconKindEnum              | `{ link = 'CmpItemKindEnum' }`          |
  | DropBarIconKindEnumMember        | `{ link = 'CmpItemKindEnumMember' }`    |
  | DropBarIconKindEvent             | `{ link = 'CmpItemKindEvent' }`         |
  | DropBarIconKindField             | `{ link = 'CmpItemKindField' }`         |
  | DropBarIconKindFile              | `{ link = 'NormalFloat' }`              |
  | DropBarIconKindFolder            | `{ link = 'Directory' }`                |
  | DropBarIconKindForStatement      | `{ link = 'Repeat' }`                   |
  | DropBarIconKindFunction          | `{ link = 'Function' }`                 |
  | DropBarIconKindH1Marker          | `{ link = 'markdownH1' }`               |
  | DropBarIconKindH2Marker          | `{ link = 'markdownH2' }`               |
  | DropBarIconKindH3Marker          | `{ link = 'markdownH3' }`               |
  | DropBarIconKindH4Marker          | `{ link = 'markdownH4' }`               |
  | DropBarIconKindH5Marker          | `{ link = 'markdownH5' }`               |
  | DropBarIconKindH6Marker          | `{ link = 'markdownH6' }`               |
  | DropBarIconKindIdentifier        | `{ link = 'CmpItemKindVariable' }`      |
  | DropBarIconKindIfStatement       | `{ link = 'Conditional' }`              |
  | DropBarIconKindInterface         | `{ link = 'CmpItemKindInterface' }`     |
  | DropBarIconKindKeyword           | `{ link = 'Keyword' }`                  |
  | DropBarIconKindList              | `{ link = 'SpecialChar' }`              |
  | DropBarIconKindMacro             | `{ link = 'Macro' }`                    |
  | DropBarIconKindMarkdownH1        | `{ link = 'markdownH1' }`               |
  | DropBarIconKindMarkdownH2        | `{ link = 'markdownH2' }`               |
  | DropBarIconKindMarkdownH3        | `{ link = 'markdownH3' }`               |
  | DropBarIconKindMarkdownH4        | `{ link = 'markdownH4' }`               |
  | DropBarIconKindMarkdownH5        | `{ link = 'markdownH5' }`               |
  | DropBarIconKindMarkdownH6        | `{ link = 'markdownH6' }`               |
  | DropBarIconKindMethod            | `{ link = 'CmpItemKindMethod' }`        |
  | DropBarIconKindModule            | `{ link = 'CmpItemKindModule' }`        |
  | DropBarIconKindNamespace         | `{ link = 'NameSpace' }`                |
  | DropBarIconKindNull              | `{ link = 'Constant' }`                 |
  | DropBarIconKindNumber            | `{ link = 'Number' }`                   |
  | DropBarIconKindObject            | `{ link = 'Statement' }`                |
  | DropBarIconKindOperator          | `{ link = 'Operator' }`                 |
  | DropBarIconKindPackage           | `{ link = 'CmpItemKindModule' }`        |
  | DropBarIconKindPair              | `{ link = 'String' }`                   |
  | DropBarIconKindProperty          | `{ link = 'CmpItemKindProperty' }`      |
  | DropBarIconKindReference         | `{ link = 'CmpItemKindReference' }`     |
  | DropBarIconKindRepeat            | `{ link = 'Repeat' }`                   |
  | DropBarIconKindScope             | `{ link = 'NameSpace' }`                |
  | DropBarIconKindSpecifier         | `{ link = 'Specifier' }`                |
  | DropBarIconKindStatement         | `{ link = 'Statement' }`                |
  | DropBarIconKindString            | `{ link = 'String' }`                   |
  | DropBarIconKindStruct            | `{ link = 'CmpItemKindStruct' }`        |
  | DropBarIconKindSwitchStatement   | `{ link = 'Conditional' }`              |
  | DropBarIconKindTerminal          | `{ link = 'Number' }`                   |
  | DropBarIconKindType              | `{ link = 'CmpItemKindClass' }`         |
  | DropBarIconKindTypeParameter     | `{ link = 'CmpItemKindTypeParameter' }` |
  | DropBarIconKindUnit              | `{ link = 'CmpItemKindUnit' }`          |
  | DropBarIconKindValue             | `{ link = 'Number' }`                   |
  | DropBarIconKindVariable          | `{ link = 'CmpItemKindVariable' }`      |
  | DropBarIconKindWhileStatement    | `{ link = 'Repeat' }`                   |
  | DropBarIconUIIndicator           | `{ link = 'SpecialChar' }`              |
  | DropBarIconUIPickPivot           | `{ link = 'Error' }`                    |
  | DropBarIconUISeparator           | `{ link = 'SpecialChar' }`              |
  | DropBarIconUISeparatorMenu       | `{ link = 'DropBarIconUISeparator' }`   |
  | DropBarMenuCurrentContext        | `{ link = 'PmenuSel' }`                 |
  | DropBarMenuFloatBorder           | `{ link = 'FloatBorder' }`              |
  | DropBarMenuHoverEntry            | `{ link = 'Visual' }`                   |
  | DropBarMenuHoverIcon             | `{ reverse = true }`                    |
  | DropBarMenuHoverSymbol           | `{ bold = true }`                       |
  | DropBarMenuNormalFloat           | `{ link = 'NormalFloat' }`              |
  | DropBarMenuScrollBar             | `{ link = 'NormalFloat' }`              |
  | DropBarPreview                   | `{ link = 'Visual' }`                   |
  | DropBarKindArray                 | undefined                               |
  | DropBarKindBoolean               | undefined                               |
  | DropBarKindBreakStatement        | undefined                               |
  | DropBarKindCall                  | undefined                               |
  | DropBarKindCaseStatement         | undefined                               |
  | DropBarKindClass                 | undefined                               |
  | DropBarKindConstant              | undefined                               |
  | DropBarKindConstructor           | undefined                               |
  | DropBarKindContinueStatement     | undefined                               |
  | DropBarKindDeclaration           | undefined                               |
  | DropBarKindDelete                | undefined                               |
  | DropBarKindDoStatement           | undefined                               |
  | DropBarKindElseStatement         | undefined                               |
  | DropBarKindEnum                  | undefined                               |
  | DropBarKindEnumMember            | undefined                               |
  | DropBarKindEvent                 | undefined                               |
  | DropBarKindField                 | undefined                               |
  | DropBarKindFile                  | undefined                               |
  | DropBarKindFolder                | undefined                               |
  | DropBarKindForStatement          | undefined                               |
  | DropBarKindFunction              | undefined                               |
  | DropBarKindH1Marker              | undefined                               |
  | DropBarKindH2Marker              | undefined                               |
  | DropBarKindH3Marker              | undefined                               |
  | DropBarKindH4Marker              | undefined                               |
  | DropBarKindH5Marker              | undefined                               |
  | DropBarKindH6Marker              | undefined                               |
  | DropBarKindIdentifier            | undefined                               |
  | DropBarKindIfStatement           | undefined                               |
  | DropBarKindInterface             | undefined                               |
  | DropBarKindKeyword               | undefined                               |
  | DropBarKindList                  | undefined                               |
  | DropBarKindMacro                 | undefined                               |
  | DropBarKindMarkdownH1            | undefined                               |
  | DropBarKindMarkdownH2            | undefined                               |
  | DropBarKindMarkdownH3            | undefined                               |
  | DropBarKindMarkdownH4            | undefined                               |
  | DropBarKindMarkdownH5            | undefined                               |
  | DropBarKindMarkdownH6            | undefined                               |
  | DropBarKindMethod                | undefined                               |
  | DropBarKindModule                | undefined                               |
  | DropBarKindNamespace             | undefined                               |
  | DropBarKindNull                  | undefined                               |
  | DropBarKindNumber                | undefined                               |
  | DropBarKindObject                | undefined                               |
  | DropBarKindOperator              | undefined                               |
  | DropBarKindPackage               | undefined                               |
  | DropBarKindProperty              | undefined                               |
  | DropBarKindReference             | undefined                               |
  | DropBarKindRepeat                | undefined                               |
  | DropBarKindScope                 | undefined                               |
  | DropBarKindSpecifier             | undefined                               |
  | DropBarKindStatement             | undefined                               |
  | DropBarKindString                | undefined                               |
  | DropBarKindStruct                | undefined                               |
  | DropBarKindSwitchStatement       | undefined                               |
  | DropBarKindTerminal              | undefined                               |
  | DropBarKindType                  | undefined                               |
  | DropBarKindTypeParameter         | undefined                               |
  | DropBarKindUnit                  | undefined                               |
  | DropBarKindValue                 | undefined                               |
  | DropBarKindVariable              | undefined                               |
  | DropBarKindWhileStatement        | undefined                               |

</details>

## Developers

### Architecture

```
                                              ┌──────────────────┐
                                              │winbar at win 1000│ {k}th symbol clicked
                                              │ contaning buf 1  ├──────────────────────┐
                                              └───────┬─▲────────┘                      │
                                                      ▼ │                               │
                                          _G.dropbar.get_dropbar_str()                  │
                                                      │ ▲                               │
    ┌──────────────┐                           ┌──────▼─┴──────┐                        │
    │sources       │                           │_G.dropbar.bars│                        │
    │ ┌───┐        │                           └──────┬─▲──────┘                        │
    │ │lsp│        │                       ┌───────┬──▼─┴──┬───────┐                    │
    │ └───┘        │                     ┌─▼─┐   ┌─┴─┐   ┌─┴─┐    ...                   │
    │ ┌──────────┐ │                     │[1]│   │[2]│   │[3]│                          │
    │ │treesitter│ │                     └─┬─┘   └─┬─┘   └─┬─┘                          │
    │ └──────────┘ │                       │      ...     ...                           │
    │  ...         │                       └──┬─▲─────────────┬──────┐                  │
    └─────┬─▲──────┘                        ┌─▼─┴──┐       ┌──┴───┐ ...                 │
          │ │                               │[1000]│       │[1015]│                     │
          │ │                               └─┬─▲──┘       └──────┘                     │
          │ │                    __tostring() │ │ return string cache                   │
          │ │                             ┌───▼─┴───┐                    ┌──────────────▼──────────────┐
          │ │                             │dropbar_t├────────────────────▶_G.dropbar.on_click_callbacks│
          │ │    On update events         └───┬─▲───┘  register symbol   └──────────────┬──────────────┘
          │ │ get_symbols(1, 1000, <cursor>)  │ │    on_click() callbacks               │
          │ └─────────────────────────────────┘ │                       ┌──────────┬────▼─────┬─────────┐
          └─────────────────────────────────────┘                   ┌───▼────┐ ┌───┴────┐ ┌───┴────┐   ...
      each source returns dropbar_symbol_t[]                        │['buf1']│ │['buf2']│ │['buf3']│
     dropbar_t adds symbols as its components                       └───┬────┘ └───┬────┘ └───┬────┘
          dropbar_t flushes string cache                                │         ...        ...
                                                                        └────────┬───────────────┬─────────┐
                                                                           ┌─────▼─────┐   ┌─────┴─────┐  ...
                                                                           │['win1000']│   │['win1015']│
                                                                           └─────┬─────┘   └─────┬─────┘
                                                                                 │              ...
                                                                  ┌─────────┬────▼────┬─────────┐
                                                              ┌───┴───┐    ...   ┌────┴────┐   ...
                                                              │['fn1']│          │['fn{k}']│
                                                              └───────┘          └────┬────┘
                                                                                      ▼
                                                      invoke _G.dropbar.bars[1][1000].components[k]:on_click()
                                                                                      │
                                                                                      ▼
                                                                     open drop-down menu, goto symbol, etc
```

### Classes

:warning: **Notice**

The plugin is still in its early stage, so the names and fields of classes
might change in the future without notice.

#### `dropbar_t`

Declared and defined in [`lua/dropbar/bar.lua`](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/bar.lua).

---

`dropbar_t` is a class that represents a winbar.

It gets symbols<sub>[`dropbar_symbol_t[]`](#dropbar_symbol_t)</sub> from
sources<sub>[`dropbar_source_t`](#dropbar_source_t)</sub> and renders them to a
string. It is also responsible for registering `on_click` callbacks of each
symbol in the global table `_G.dropbar.on_click_callbacks` so that nvim knows
which function to call when a symbol is clicked.


`dropbar_t` has the following fields:

| Field                      | Type                                      | Description                                                                                                 |
| --------------             | ---------------------------------         | ---------------------------------------------------------------------------------------------               |
| `buf`                      | `integer`                                 | the buffer the dropbar is attached to                                                                       |
| `win`                      | `integer`                                 | the window the dropbar is attached to                                                                       |
| `sources`                  | [`dropbar_source_t[]`](#dropbar_source_t) | sources<sub>[`dropbar_source_t[]`](#dropbar_source_t)</sub> that provide symbols to the dropbar             |
| `separator`                | [`dropbar_symbol_t`](#dropbar_symbol_t)   | separator<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> between symbols                                 |
| `padding`                  | `{left: integer, right: integer}`         | padding to use between the winbar and the window border                                                     |
| `extends`                  | [`dropbar_symbol_t`](#dropbar_symbol_t)   | symbol<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> to use when a symbol is truncated                  |
| `components`               | [`dropbar_symbol_t[]`](#dropbar_symbol_t) | symbols<sub>[`dropbar_symbol_t[]`](#dropbar_symbol_t)</sub> to render                                       |
| `string_cache`             | `string`                                  | string cache of the dropbar                                                                                 |
| `in_pick_mode`             | `boolean?`                                | whether the dropbar is in pick mode                                                                         |
| `symbol_on_hover`          | [`dropbar_symbol_t`](#dropbar_symbol_t)   | The previous symbol<sub>[`dropbar_symbol_t[]`](#dropbar_symbol_t)</sub> under mouse hovering in the dropbar |
| `last_update_request_time` | `float?`                                  | timestamp of the last update request in ms, see `:h uv.now()`                                               |


`dropbar_t` has the following methods:

| Method                                                  | Description                                                                                                                                                                                               |
| ------------------------------------------------        | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dropbar_t:new(opts: dropbar_opts_t): dropbar_t`        | constructor of `dropbar_t`                                                                                                                                                                                |
| `dropbar_t:del()`                                       | destructor of `dropbar_t`                                                                                                                                                                                 |
| `dropbar_t:displaywidth(): integer`                     | returns the display width of the dropbar                                                                                                                                                                  |
| `dropbar_t:truncate()`                                  | truncates the dropbar if it exceeds the display width <br> \*side effect: changes dropbar components<sub>[`dropbar_symbol_t[]`](#dropbar_symbol_t)                                                        |
| `dropbar_t:cat(plain: boolean?): string`                | concatenates the dropbar components into a string with substrings for highlights and click support if `plain` is not set; else returns a plain string without substrings for highlights and click support |
| `dropbar_t:redraw()`                                    | redraws the dropbar                                                                                                                                                                                       |
| `dropbar_t:update()`                                    | update dropbar components<sub>[`dropbar_symbol_t[]`](#dropbar_symbol_t)</sub> and redraw the dropbar afterwards                                                                                           |
| `dropbar_t:pick_mode_wrap(fn: fun(...): T?, ...): T?`   | executes `fn` with parameters `...` in pick mode                                                                                                                                                          |
| `dropbar_t:pick(idx: integer?)`                         | pick a component from dropbar in interactive pick mode if `idx` is not given; else pick the `idx`th component directly                                                                                    |
| `dropbar_t:update_current_context_hl(bar_idx: integer)` | Update the current context highlight `hl-DropBarCurrentContext` and `hl-DropBarIconCurrentContext` assuming the `bar_idx` th symbol is clicked in the winbar                                              |
| `dropbar_t:update_hover_hl(col: integer?)`              | Highlight the symbol at `col` as if the mouse is hovering on it                                                                                                                                           |
| `dropbar_t:__tostring(): string`                        | meta method to convert `dropbar_t` to its string representation                                                                                                                                           |


#### `dropbar_symbol_t`

Declared and defined in [`lua/dropbar/bar.lua`](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/bar.lua).

---

`dropbar_symbol_t` is a class that represents a symbol in a dropbar. It is the
basic element of [`dropbar_t`](#dropbar_t) and [`dropbar_menu_entry_t`](#dropbar_menu_entry_t).


`dropbar_symbol_t` has the following fields:

| Field         | Type                                                                                                                | Description                                                                                                                                  |
| -----------   | ------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`        | `string`                                                                                                            | name of the symbol                                                                                                                           |
| `icon`        | `string`                                                                                                            | icon of the symbol                                                                                                                           |
| `name_hl`     | `string?`                                                                                                           | highlight of the name of the symbol                                                                                                          |
| `icon_hl`     | `string?`                                                                                                           | highlight of the icon of the symbol                                                                                                          |
| `win`         | `integer?`                                                                                                          | the source window the symbol is shown in                                                                                                     |
| `buf`         | `integer?`                                                                                                          | the source buffer the symbol is defined in                                                                                                   |
| `view`        | `table?`                                                                                                            | The original view of the source window, created by `winsaveview()`, used to restore the view after previewing the symbol                     |
| `bar`         | [`dropbar_t?`](#dropbar_t)                                                                                          | the dropbar<sub>[`dropbar_t`](#dropbar_t)</sub> the symbol belongs to, if the symbol is shown inside a winbar                                |
| `menu`        | [`dropbar_menu_t?`](#dropbar_menu_t)                                                                                | menu<sub>[`dropbar_menu_t`](#dropbar_menu_t)</sub> associated with the symbol, if the symbol is shown inside a winbar                        |
| `entry`       | [`dropbar_menu_entry_t?`](#dropbar_menu_entry_t)                                                                    | the dropbar menu entry<sub>[`dropbar_menu_entry_t`](#dropbar_menu_entry_t)</sub> the symbol belongs to, if the symbol is shown inside a menu |
| `children`    | `dropbar_symbol_t[]?`                                                                                               | children of the symbol (e.g. a children of a function symbol can be local variables inside the function)                                     |
| `siblings`    | `dropbar_symbol_t[]?`                                                                                               | siblings of the symbol (e.g. a sibling of a symbol that represents a level 4 markdown heading can be other headings with level 4)            |
| `bar_idx`     | `integer?`                                                                                                          | index of the symbol in the dropbar<sub>[`dropbar_t`](#dropbar_t)</sub>                                                                       |
| `entry_idx`   | `integer?`                                                                                                          | index of the symbol in the menu entry<sub>[`dropbar_menu_entry_t`](#dropbar_menu_entry_t)</sub>                                              |
| `sibling_idx` | `integer?`                                                                                                          | index of the symbol in the siblings                                                                                                          |
| `range`       | `{start: {line: integer, character: integer}, end: {line: integer, character: integer}}`                            | range of the symbol in the source window                                                                                                     |
| `on_click`    | `fun(this: dropbar_symbol_t, min_width: integer?, n_clicks: integer?, button: string?, modifiers: string?)\|false?` | callback to invoke when the symbol is clicked, force disable `on_click` when the value if set to `false`                                     |
| `data`        | `table?`                                                                                                            | any extra data associated with the symbol                                                                                                    |


`dropbar_symbol_t` has the following methods:

| Method                                                            | Description                                                                                                                                                                                   |
| ------------------------------------------------                  | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dropbar_symbol_t:new(opts: dropbar_symbol_t?): dropbar_symbol_t` | constructor of `dropbar_symbol_t`                                                                                                                                                             |
| `dropbar_symbol_t:del()`                                          | destructor of `dropbar_symbol_t`                                                                                                                                                              |
| `dropbar_symbol_t:merge(opts: dropbar_symbol_t)`                  | create a new `dropbar_symbol_t` by merging `opts` into the current `dropbar_symbol_t`                                                                                                         |
| `dropbar_symbol_t:cat(plain: boolean?): string`                   | concatenates the symbol into a string with substrings for highlights and click support if `plain` is not set; else returns a plain string without substrings for highlights and click support |
| `dropbar_symbol_t:displaywidth(): integer`                        | returns the display width of the symbol                                                                                                                                                       |
| `dropbar_symbol_t:bytewidth(): integer`                           | returns the byte width of the symbol                                                                                                                                                          |
| `dropbar_symbol_t:jump()`                                         | jump to the start of the range of the dropbar symbol                                                                                                                                          |
| `dropbar_symbol_t:preview()`                                      | preview the symbol in the source window                                                                                                                                                       |
| `dropbar_symbol_t:preview_restore_hl()`                           | clear the preview highlights in the source window                                                                                                                                             |
| `dropbar_symbol_t:preview_restore_view()`                         | restore the view in the source window after previewing the symbol                                                                                                                             |
| `dropbar_symbol_t:swap_field(field: string, new_val: any)`        | temporarily change the content of a dropbar symbol                                                                                                                                            |
| `dropbar_symbol_t:restore()`                                      | restore the original value of the fields of a dropbar symbol changed in `dropbar_symbol_t:swap_field()`                                                                                       |

#### `dropbar_menu_t`

Declared and defined in [`lua/dropbar/menu.lua`](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/menu.lua).

---

`dropbar_menu_t` is a class that represents a drop-down menu.

`dropbar_menu_t` has the following fields:

| Field              | Type                                              | Description                                                                            |
| ------             | ------                                            | ------                                                                                 |
| `buf`              | `integer`                                         | buffer number of the menu                                                              |
| `win`              | `integer`                                         | window id of the menu                                                                  |
| `is_opened`        | `boolean?`                                        | whether the menu is currently opened                                                   |
| `entries`          | [`dropbar_menu_entry_t[]`](#dropbar_menu_entry_t) | entries in the menu                                                                    |
| `win_configs`      | `table`                                           | window configuration, value can be a function, see [menu configuration options](#menu) |
| `_win_configs`     | `table?`                                          | evaluated window configuration                                                         |
| `cursor`           | `integer[]?`                                      | initial cursor position                                                                |
| `prev_win`         | `integer?`                                        | previous window, assigned when calling new() or automatically determined in open()     |
| `sub_menu`         | `dropbar_menu_t?`                                 | submenu, assigned when calling new() or automatically determined when a new menu opens |
| `prev_menu`        | `dropbar_menu_t?`                                 | previous menu, assigned when calling new() or automatically determined in open()       |
| `clicked_at`       | `integer[]?`                                      | last position where the menu was clicked, 1,0-indexed                                  |
| `prev_cursor`      | `integer[]?`                                      | previous cursor position in the menu                                                   |
| `symbol_previewed` | [`dropbar_symbol_t?`](#dropbar_symbol_t)          | symbol begin previewed in the menu                                                     |

`dropbar_menu_t` has the following methods:

| Method                                                                                                                            | Description                                                                                                                                                                 |
| ------                                                                                                                            | ------                                                                                                                                                                      |
| `dropbar_menu_t:new(opts: dropbar_menu_t?): dropbar_menu_t`                                                                       | constructor of `dropbar_menu_t`                                                                                                                                             |
| `dropbar_menu_t:del()`                                                                                                            | destructor of `dropbar_menu_t`                                                                                                                                              |
| `dropbar_menu_t:eval_win_configs()`                                                                                               | evaluate window configurations `dropbar_menu_t.win_configs` and store the result in `dropbar_menu_t._win_configs`                                                           |
| `dropbar_menu_t:get_component_at(pos: integer[], look_ahead: boolean?): dropbar_symbol_t?, { start: integer, end: integer }?`     | get the component<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> at position `pos` and its range it occupies in the entry it belongs to                                  |
| `dropbar_menu_t:click_at(pos: integer[], min_width: integer?, n_clicks: integer?, button: string?, modifiers: string?)`           | simulate a click at `pos` in the menu                                                                                                                                       |
| `dropbar_menu_t:click_on(symbol: dropbar_symbol_t, min_width: integer?, n_clicks: integer?, button: string?, modifiers: string?)` | simulate a click at the component `symbol`<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> of the menu                                                                    |
| `dropbar_menu_t:update_hover_hl(pos: integer[])`                                                                                  | update the hover highlights (`DropBarMenuHover*`) assuming the cursor/mouse is hovering at `pos` in the menu                                                                |
| `dropbar_menu_t:update_current_context_hl(linenr: integer?)`                                                                      | update the current context highlight (`hl-DropBarMenuCurrentContext`) assuming the cursor is at line `linenr` in the menu                                                   |
| `dropbar_menu_t:add_hl(hl_info: dropbar_menu_hl_info_t[][])`                                                                      | add highlights to the menu buffer                                                                                                                                           |
| `dropbar_menu_t:make_buf()`                                                                                                       | create the menu buffer from the entries<sub>[`dropbar_menu_entry_t`](#dropbar_menu_entry_t), must be called after `self:eval_win_configs()`                                 |
| `dropbar_menu_t:make_win()`                                                                                                       | open the menu window with `self._win_configs` and set menu options, must be called after `self:make_buf()`                                                                  |
| `dropbar_menu_t:override(opts: dropbar_menu_t?)`                                                                                  | override menu options                                                                                                                                                       |
| `dropbar_menu_t:preview_symbol_at(pos: integer[], look_ahead: boolean?)`                                                          | preview the component<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> at position `pos` in the menu                                                                       |
| `dropbar_menu_t:finish_preview(restore_view: boolean?)`                                                                           | finish previewing the symbol, always clear the preview highlights in the source buffer, restore the original view of the source window if `restore_view` is `true` or `nil` |
| `dropbar_menu_t:quick_navigation(new_cursor: integer[])`                                                                          | nagivate the cursor to the neartest clickable component on the current menu entry in the direction of cursor movement                                                       |
| `dropbar_menu_t:open(opts: dropbar_menu_t?)`                                                                                      | open the menu with options `opts`                                                                                                                                           |
| `dropbar_menu_t:close(restore_view: boolean?)`                                                                                    | close the menu                                                                                                                                                              |
| `dropbar_menu_t:toggle(opts: dropbar_menu_t?)`                                                                                    | toggle the menu                                                                                                                                                             |
| `dropbar_menu_t:fuzzy_find_restore_entries()`                                                                                     | restore menu buffer and entries in their original order before modification by fuzzy search
| `dropbar_menu_t:fuzzy_find_close()`                                                                                               | stop fuzzy finding and clean up allocated memory
| `dropbar_menu_t:fuzzy_find_click_on_entry(component: number or fun(dropbar_menu_entry_t):dropbar_symbol_t)`                       | click on the currently selected fuzzy menu entry, choosing the component to click according to component
| `dropbar_menu_t:fuzzy_find_open(opts: table?)`                                                                                    | open the fuzzy search menu, overriding fzf configuration with opts argument

#### `dropbar_menu_entry_t`

Declared and defined in [`lua/dropbar/menu.lua`](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/menu.lua).

---

`dropbar_menu_entry_t` is a class that represents an entry (row) in a
drop-down menu. A [`dropbar_menu_t`](#dropbar_menu_t) instance is made up of
multiple `dropbar_menu_entry_t` instances while a
[`dropbar_menu_entry_t`](#dropbar_menu_entry_t) instance can contain multiple
[`dropbar_symbol_t`](#dropbar_symbol_t) instances.

`dropbar_menu_entry_t` has the following fields:

| Field        | Type                                      | Description                                                                 |
| ------       | ------                                    | ------                                                                      |
| `separator`  | [`dropbar_symbol_t`](#dropbar_symbol_t)   | separator to use in the entry                                               |
| `padding`    | `{left: integer, right: integer}`         | padding to use between the menu entry and the menu border                   |
| `components` | [`dropbar_symbol_t[]`](#dropbar_symbol_t) | components<sub>[`dropbar_symbol_t[]`](#dropbar_symbol_t)</sub> in the entry |
| `menu`       | [`dropbar_menu_t?`](#dropbar_menu_t)      | the menu the entry belongs to                                               |
| `idx`        | `integer?`                                | the index of the entry in the menu                                          |

`dropbar_menu_entry_t` has the following methods:

| Method                                                                                                                            | Description                                                                                                                                                             |
| ------                                                                                                                            | ------                                                                                                                                                                  |
| `dropbar_menu_entry_t:new(opts: dropbar_menu_entry_t?): dropbar_menu_entry_t`                                                     | constructor of `dropbar_menu_entry_t`                                                                                                                                   |
| `dropbar_menu_entry_t:del()`                                                                                                      | destructor of `dropbar_menu_entry_t`                                                                                                                                    |
| `dropbar_menu_entry_t:cat(): string, dropbar_menu_hl_info_t`                                                                      | concatenate the components into a string, returns the string and highlight info<sub>[`dropbar_menu_hl_info_t`](#dropbar_menu_hl_info_t)                                 |
| `dropbar_menu_entry_t:displaywidth(): integer`                                                                                    | calculate the display width of the entry                                                                                                                                |
| `dropbar_menu_entry_t:bytewidth(): integer`                                                                                       | calculate the byte width of the entry                                                                                                                                   |
| `dropbar_menu_entry_t:first_clickable(offset: integer?): dropbar_symbol_t?, { start: integer, end: integer }?`                    | get the first clickable component<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> and its range in the dropbar menu entry starting from `offset`, which defaults to 0 |
| `dropbar_menu_entry_t:get_component_at(col: integer, look_ahead: boolean?): dropbar_symbol_t?, { start: integer, end: integer }?` | get the component<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> at column position `col` and the range it occupies in the menu entry                                |
| `dropbar_menu_entry_t:prev_clickable(col: integer): dropbar_symbol_t?, { start: integer, end: integer }?`                         | get the previous clickable component<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> and its range in the dropbar menu entry given current column position `col`      |
| `dropbar_menu_entry_t:next_clickable(col: integer): dropbar_symbol_t?, { start: integer, end: integer }?`                         | get the next clickable component<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> and its range in the dropbar menu entry given current column position `col`          |

#### `dropbar_menu_hl_info_t`

Declared and defined in [`lua/dropbar/menu.lua`](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/menu.lua).

---

`dropbar_menu_hl_info_t` is a class that represents a highlight range in a
single line of a drop-down menu.

`dropbar_menu_hl_info_t` has the following fields:

| Field     | Type       | Description                                                      |
| ------    | ------     | ------                                                           |
| `start`   | `integer`  | start column of the higlighted range                             |
| `end`     | `integer`  | end column of the higlighted range                               |
| `hlgroup` | `string`   | highlight group to use for the range                             |
| `ns`      | `integer?` | namespace to use for the range, `nil` if using default namespace |

#### `dropbar_source_t`

Declared in [`lua/dropbar/sources/init.lua`](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/sources/init.lua).

---

`dropbar_source_t` is a class that represents a source of a drop-down menu.

`dropbar_source_t` has the following field:

| Field         | Type                                                                          | Description                                                                                                                                          |
| ------        | ------                                                                        | ------                                                                                                                                               |
| `get_symbols` | `function(buf: integer, win: integer, cursor: integer[]): dropbar_symbol_t[]` | returns the symbols<sub>[`dropbar_symbol_t[]`](#dropbar_symbol_t)</sub> to show in the winbar given buffer number `buf` and cursor position `cursor` |

### Making a New Source

A [`dropbar_source_t`](#dropbar_source_t) instance is just a table with
`get_symbols` field set to a function that returns an array of
[`dropbar_symbol_t`](#dropbar_symbol_t) instances given the buffer number, the
window id, and the cursor position.

We have seen a simple example of a custom source in the [default config of
`opts.bar.sources`](#bar) where the second source is set to a combination
of lsp/treesitter/markdown sources using the `utils.source.fallback()` factory
function, which simply returns a table containing a `get_symbols()` function
where each source passed to `utils.source.fallback()` is queried and the first
non-empty result get from the sources is returned as the result of the combined
source.

Here is another example of a custom source that will always return two symbols
saying 'Hello' and 'dropbar' with highlights `'hl-Keyword'` and `'hl-Title'`
and a smiling face shown in `'hl-WarningMsg'` at the start of the first symbol;
clicking on the first symbol will show a notification message saying 'Have you
smiled today?', followed by the smiling face icon used in the in dropbar symbol:

```lua
local bar = require('dropbar.bar')
local custom_source = {
  get_symbols = function(_, _, _)
    return {
      bar.dropbar_symbol_t:new({
        icon = ' ',
        icon_hl = 'WarningMsg',
        name = 'Hello',
        name_hl = 'Keyword',
        on_click = function(self)
          vim.notify('Have you smiled today? ' .. self.icon)
        end,
      }),
      bar.dropbar_symbol_t:new({
        name = 'dropbar',
        name_hl = 'Title',
      }),
    }
  end,
}
```

Add this source to [`opts.bar.sources`](#bar) table to see it in action:

```lua
require('dropbar').setup({
  bar = {
    sources = {
      custom_source,
    },
  },
})
```

#### Making a Source With Drop-Down Menus

The following example shows how to make a source that returns two symbols with
the first symbol having a drop-down menu with a single entry saying 'World':

```lua
local bar = require('dropbar.bar')
local menu = require('dropbar.menu')
local custom_source = {
  get_symbols = function(_, _, _)
    return {
      bar.dropbar_symbol_t:new({
        icon = ' ',
        icon_hl = 'WarningMsg',
        name = 'Hello',
        name_hl = 'Keyword',
        on_click = function(self)
          self.menu = menu.dropbar_menu_t:new({
            entries = {
              menu.dropbar_menu_entry_t:new({
                components = {
                  bar.dropbar_symbol_t:new({
                    icon = ' ',
                    icon_hl = 'WarningMsg',
                    name = 'World',
                    name_hl = 'Keyword',
                    on_click = function(sym)
                      vim.notify('Have you smiled today? ' .. sym.icon)
                    end,
                  }),
                },
              }),
            },
          })
          self.menu:toggle()
        end,
      }),
      bar.dropbar_symbol_t:new({
        name = 'dropbar',
        icon = ' ',
        name_hl = 'Special',
        icon_hl = 'Error',
      }),
    }
  end,
}
```

#### Default `on_click()` Callback

[`dropbar_symbol_t:new()`](#dropbar_symbol_t) defines a default `on_click()`
callback if non is provided.

The default `on_click()` callback will look for these fields in the symbol
instance and create a drop-down menu accordingly on click, for more information
about these fields see [`dropbar_symbol_t`](#dropbar_symbol_t).

For creating the drop-down menu:

  - `dropbar_symbol_t.siblings`
  - `dropbar_symbol_t.sibling_idx`
  - `dropbar_symbol_t.children`

For jumping to the symbol or previewing it:

  - `dropbar_symbol_t.range`
  - `dropbar_symbol_t.win`
  - `dropbar_symbol_t.buf`

The following example shows a source that utilizes the default `on_click()`
callback:

```lua
local bar = require('dropbar.bar')
local custom_source = {
  get_symbols = function(buf, win, _)
    return {
      bar.dropbar_symbol_t:new({
        name = 'Section 1',
        name_hl = 'Keyword',
        siblings = {
          bar.dropbar_symbol_t:new({
            name = 'Section 2',
            name_hl = 'WarningMsg',
          }),
          bar.dropbar_symbol_t:new({
            name = 'Section 3',
            name_hl = 'Error',
          }),
          bar.dropbar_symbol_t:new({
            name = 'Section 4',
            name_hl = 'String',
            children = {
              bar.dropbar_symbol_t:new({
                buf = buf,
                win = win,
                name = 'Section 4.1',
                name_hl = 'String',
                -- Will jump to line 3, col 4 (0-indexed) when clicked in the
                -- menu
                range = {
                  start = { line = 3, character = 4 },
                  ['end'] = { line = 5, character = 6 },
                }
              }),
            },
          }),
        },
      }),
    }
  end,
}
```

To see this source in action add it to [`opts.bar.sources`](#bar) table:

```lua
require('dropbar').setup({
  bar = {
    sources = {
      custom_source,
    },
  },
})
```

#### Lazy-Loading Expensive Fields

If the symbol fields `siblings` or `children` are expensive to compute, you can
use meta-tables to lazy-load them, so that they are only computed when a menu
is opened:

```lua
local bar = require('dropbar.bar')
local custom_source = {
  get_symbols = function(_, _, _)
    return {
      bar.dropbar_symbol_t:new(setmetatable({
        name = 'Section 1',
        name_hl = 'Keyword',
      }, {
        __index = function(self, key)
          if key == 'siblings' then
            self[siblings] = -- [[ compute siblings ]]
            return self[siblings]
          end
          if key == 'children' then
            self[children] = -- [[ compute children ]]
            return self[children]
          end
          -- ...
        end,
      })),
    }
  end,
}
```

To see concrete examples of lazy-loading see
[`lua/dropbar/sources`](https://github.com/Bekaboo/dropbar.nvim/tree/master/lua/dropbar/sources).

## Similar Projects

- [nvim-navic](https://github.com/SmiteshP/nvim-navic)
