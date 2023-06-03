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
  with drop-down menu support and mutiple backends
</p>

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
  - [Options](#options)
    - [General](#general)
    - [Icons](#icons)
    - [Bar](#bar)
    - [Menu](#menu)
    - [Sources](#sources)
      - [Path](#path)
      - [Treesitter](#treesitter)
      - [LSP](#lsp)
      - [Markdown](#markdown)
  - [API](#api)
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

  `dropbar.nvim` comes with four builtin sources:

  - [x] [lsp](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/sources/lsp.lua): gets symbols from language servers using nvim's builtin LSP framework

  - [x] [markdown](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/sources/markdown.lua): a custom incremental parser that gets symbol information about markdown headings

  - [x] [path](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/sources/path.lua): gets current file path

  - [x] [treesitter](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/sources/treesitter.lua): gets symbols from treesitter parsers using nvim's builtin treesitter integration

  To make a new source yourself, see [making a new source](#making-a-new-source).

  For source fall-backs support, see [bar options](#bar).

- [x] Zero config & Zero dependency

  `dropbar.nvim` does not require [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
  or any third-party UI libraries to work.
  As long as the language server or the treesitter parser is installed,
  it should work just fine.

- [ ] Show highlights in the drop-down menu according to current mouse/cursor
  position, see `:h mousemev` and `:h <MouseMove>`
- [ ] Preview symbol ranges in original window when hovering over them in the
  drop-down menu

## Requirements

- Neovim **Nightly** (>= 0.10.0-dev)
- Optional
  - [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons), if you want to see icons for different filetypes
  - Working language server installation for the lsp source to work
  - Working treesitter parser installation for the treesitter source to work

## Installation

- Using [lazy.nvim](https://github.com/folke/lazy.nvim)

  ```lua
  require('lazy').setup({
    { 'Bekaboo/dropbar.nvim' }
  })
  ```

- Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

  ```lua
  require('packer').startup(function(use)
    use('Bekaboo/dropbar.nvim')
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
      update_events = {
        'CursorMoved',
        'CursorMovedI',
        'DirChanged',
        'FileChangedShellPost',
        'TextChanged',
        'TextChangedI',
        'VimResized',
        'WinResized',
        'WinScrolled',
      },
    },
    icons = {
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
    bar = {
      ---@type dropbar_source_t[]|fun(buf: integer, win: integer): dropbar_source_t[]
      sources = function(_, _)
        local sources = require('dropbar.sources')
        return {
          sources.path,
          {
            get_symbols = function(buf, cursor)
              if vim.bo[buf].ft == 'markdown' then
                return sources.markdown.get_symbols(buf, cursor)
              end
              for _, source in ipairs({
                sources.lsp,
                sources.treesitter,
              }) do
                local symbols = source.get_symbols(buf, cursor)
                if not vim.tbl_isempty(symbols) then
                  return symbols
                end
              end
              return {}
            end,
          },
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
      entry = {
        padding = {
          left = 1,
          right = 1,
        },
      },
      ---@type table<string, string|function|table<string, string|function>>
      keymaps = {
        ['<LeftMouse>'] = function()
          local api = require('dropbar.api')
          local menu = api.get_current_dropbar_menu()
          if not menu then
            return
          end
          local mouse = vim.fn.getmousepos()
          if mouse.winid ~= menu.win then
            local parent_menu = api.get_dropbar_menu(mouse.winid)
            if parent_menu and parent_menu.sub_menu then
              parent_menu.sub_menu:close()
            end
            if vim.api.nvim_win_is_valid(mouse.winid) then
              vim.api.nvim_set_current_win(mouse.winid)
            end
            return
          end
          menu:click_at({ mouse.line, mouse.column }, nil, 1, 'l')
        end,
        ['<CR>'] = function()
          local menu = require('dropbar.api').get_current_dropbar_menu()
          if not menu then
            return
          end
          local cursor = vim.api.nvim_win_get_cursor(menu.win)
          local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
          if component then
            menu:click_on(component, nil, 1, 'l')
          end
        end,
      },
      ---@alias dropbar_menu_win_config_opts_t any|fun(menu: dropbar_menu_t):any
      ---@type table<string, dropbar_menu_win_config_opts_t>
      ---@see vim.api.nvim_open_win
      win_configs = {
        border = 'none',
        style = 'minimal',
        row = function(menu)
          return menu.parent_menu
              and menu.parent_menu.clicked_at
              and menu.parent_menu.clicked_at[1] - vim.fn.line('w0')
            or 1
        end,
        col = function(menu)
          return menu.parent_menu and menu.parent_menu._win_configs.width or 0
        end,
        relative = function(menu)
          return menu.parent_menu and 'win' or 'mouse'
        end,
        win = function(menu)
          return menu.parent_menu and menu.parent_menu.win
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
      },
      treesitter = {
        -- Lua pattern used to extract a short name from the node text
        -- Be aware that the match result must not be nil!
        name_pattern = string.rep('[#~%w%._%->!]*', 4, '%s*'),
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
- `opts.general.update_events`: `string[]`
  - List of events that should trigger an update of the dropbar
  - Default:
    ```lua
    {
      'CursorMoved',
      'CursorMovedI',
      'DirChanged',
      'FileChangedShellPost',
      'TextChanged',
      'TextChangedI',
      'VimResized',
      'WinResized',
      'WinScrolled',
    }
    ```

#### Icons

These options live under `opts.icons` and are used to configure the icons
used by the plugin:

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

#### Bar

These options live under `opts.bar` and are used to control the behavior of the
winbar:

- `opts.bar.sources`: `dropbar_source_t[]|fun(buf: integer, win: integer): dropbar_source_t[]`
  - List of sources to show in the winbar
  - If a function is provided, it will be called with the current bufnr and
    winid and should return a list of sources
  - Default:
    ```lua
    function(_, _)
      local sources = require('dropbar.sources')
      return {
        sources.path,
        {
          get_symbols = function(buf, cursor)
            if vim.bo[buf].ft == 'markdown' then
              return sources.markdown.get_symbols(buf, cursor)
            end
            for _, source in ipairs({
              sources.lsp,
              sources.treesitter,
            }) do
              local symbols = source.get_symbols(buf, cursor)
              if not vim.tbl_isempty(symbols) then
                return symbols
              end
            end
            return {}
          end,
        },
      }
    end
    ```
  - Notice that in the default config we register the second source as an
    aggregation of LSP, treesitter, and markdown sources, so that we dynamically
    choose the best source for the current buffer or window.
    For more information about sources, see [`dropbar_source_t`](#dropbar_source_t).
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

- `opts.menu.entry.padding`: `{ left: number, right: number }`
  - Padding to use between the menu entry and the menu border
  - Default: `{ left = 1, right = 1 }`
- `opts.menu.keymaps`: `table<string, function|string|table<string, function>|table<string, string>>`
  - Buffer-local keymaps in the menu
  - Use `<key> = <function|string>` to map a key in normal mode and visual mode
    in the menu buffer, or use `<key> = table<mode, function|string>` to map
    a key in specific modes.
  - Default:
    ```lua
    {
      ['<LeftMouse>'] = function()
        local api = require('dropbar.api')
        local menu = api.get_current_dropbar_menu()
        if not menu then
          return
        end
        local mouse = vim.fn.getmousepos()
        if mouse.winid ~= menu.win then
          local parent_menu = api.get_dropbar_menu(mouse.winid)
          if parent_menu and parent_menu.sub_menu then
            parent_menu.sub_menu:close()
          end
          if vim.api.nvim_win_is_valid(mouse.winid) then
            vim.api.nvim_set_current_win(mouse.winid)
          end
          return
        end
        menu:click_at({ mouse.line, mouse.column }, nil, 1, 'l')
      end,
      ['<CR>'] = function()
        local menu = require('dropbar.api').get_current_dropbar_menu()
        if not menu then
          return
        end
        local cursor = vim.api.nvim_win_get_cursor(menu.win)
        local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
        if component then
          menu:click_on(component, nil, 1, 'l')
        end
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
        return menu.parent_menu
            and menu.parent_menu.clicked_at
            and menu.parent_menu.clicked_at[1] - vim.fn.line('w0')
          or 1
      end,
      col = function(menu)
        return menu.parent_menu and menu.parent_menu._win_configs.width or 0
      end,
      relative = function(menu)
        return menu.parent_menu and 'win' or 'mouse'
      end,
      win = function(menu)
        return menu.parent_menu and menu.parent_menu.win
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

##### Treesitter

- `opts.sources.treesitter.name_pattern`: `string`
  - Lua pattern used to extract a short name from the node text
  - Be aware! The matching result must not be nil
  - Default: `string.rep('[#~%w%._%->!]*', 4, '%s*')`
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

### API

`dropbar.nvim` exposes a few functions in `lua/dropbar/api.lua` that can be
used to interact with the winbar or the drop-down menu:

- `get_dropbar(buf: integer, win: integer): dropbar_t?`
  - Get the dropbar associated with the given buffer and window
  - For more information about the `dropbar_t` type, see
    [`dropbar_t`](#dropbar_t)
- `get_current_dropbar(): dropbar_t?`
  - Get the dropbar associated with the current buffer and window
- `get_dropbar_menu(win: integer): dropbar_menu_t?`
  - Get the drop-down menu associated with the given window
  - For more information about the `dropbar_menu_t` type, see
    [`dropbar_menu_t`](#dropbar_menu_t)
- `get_current_dropbr_menu(): dropbar_menu_t?`
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

### Highlighting

`dropbar.nvim` defines the following highlight groups that, override them in
your colorscheme to change the appearance of the drop-down menu, the names
should be self-explanatory:

<details>
  <summary>Highlight groups</summary>

  | Highlight group                  | Attributes                              |
  |----------------------------------|-----------------------------------------|
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
  | DropBarIconKindProperty          | `{ link = 'CmpItemKindProperty' }`      |
  | DropBarIconKindReference         | `{ link = 'CmpItemKindReference' }`     |
  | DropBarIconKindRepeat            | `{ link = 'Repeat' }`                   |
  | DropBarIconKindScope             | `{ link = 'NameSpace' }`                |
  | DropBarIconKindSpecifier         | `{ link = 'Specifier' }`                |
  | DropBarIconKindStatement         | `{ link = 'Statement' }`                |
  | DropBarIconKindString            | `{ link = 'String' }`                   |
  | DropBarIconKindStruct            | `{ link = 'CmpItemKindStruct' }`        |
  | DropBarIconKindSwitchStatement   | `{ link = 'Conditional' }`              |
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
  | DropBarMenuNormalFloat           | `{ link = 'WinBar' }`                   |

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
┌──────────────┐                     ┌──────▼─┴──────┐                        │
│sources       │                     │_G.dropbar.bars│                        │
│ ┌───┐        │                     └──────┬─▲──────┘                        │
│ │lsp│        │                 ┌───────┬──▼─┴──┬───────┐                    │
│ └───┘        │               ┌─▼─┐   ┌─┴─┐   ┌─┴─┐    ...                   │
│ ┌──────────┐ │               │[1]│   │[2]│   │[3]│                          │
│ │treesitter│ │               └─┬─┘   └─┬─┘   └─┬─┘                          │
│ └──────────┘ │                 │      ...     ...                           │
│  ...         │                 └──┬─▲─────────────┬──────┐                  │
└─────┬─▲──────┘                  ┌─▼─┴──┐       ┌──┴───┐ ...                 │
      │ │                         │[1000]│       │[1015]│                     │
      │ │                         └─┬─▲──┘       └──────┘                     │
      │ │              __tostring() │ │ return string cache                   │
      │ │                       ┌───▼─┴───┐                    ┌──────────────▼──────────────┐
      │ │                       │dropbar_t├────────────────────▶_G.dropbar.on_click_callbacks│
      │ │    On update events   └───┬─▲───┘  register symbol   └──────────────┬──────────────┘
      │ │ get_symbols(1, <cursor>)  │ │    on_click() callbacks               │
      │ └───────────────────────────┘ │                       ┌──────────┬────▼─────┬─────────┐
      └───────────────────────────────┘                   ┌───▼────┐ ┌───┴────┐ ┌───┴────┐   ...
  each source returns dropbar_symbol_t[]                  │['buf1']│ │['buf2']│ │['buf3']│
 dropbar_t adds symbols as its components                 └───┬────┘ └───┬────┘ └───┬────┘
      dropbar_t flushes string cache                          │         ...        ...
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

| Field          | Type                                      | Description                                                                                     |
| -------------- | ---------------------------------         | ---------------------------------------------------------------------------------------------   |
| `buf`          | `integer`                                 | the buffer the dropbar is attached to                                                           |
| `win`          | `integer`                                 | the window the dropbar is attached to                                                           |
| `sources`      | [`dropbar_source_t[]`](#dropbar_source_t) | sources<sub>[`dropbar_source_t[]`](#dropbar_source_t)</sub> that provide symbols to the dropbar |
| `separator`    | [`dropbar_symbol_t`](#dropbar_symbol_t)   | separator<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> between symbols                     |
| `padding`      | `{left: integer, right: integer}`         | padding to use between the winbar and the window border                                         |
| `extends`      | [`dropbar_symbol_t`](#dropbar_symbol_t)   | symbol<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> to use when a symbol is truncated      |
| `components`   | [`dropbar_symbol_t[]`](#dropbar_symbol_t) | symbols<sub>[`dropbar_symbol_t[]`](#dropbar_symbol_t)</sub> to render                           |
| `string_cache` | `string`                                  | string cache of the dropbar                                                                     |
| `in_pick_mode` | `boolean?`                                | whether the dropbar is in pick mode                                                             |


`dropbar_t` has the following methods:

| Method                                           | Description                                                                                                                                                                                               |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dropbar_t:new(opts: dropbar_opts_t): dropbar_t` | constructor of `dropbar_t`                                                                                                                                                                                |
| `dropbar_t:del()`                                | destructor of `dropbar_t`                                                                                                                                                                                 |
| `dropbar_t:displaywidth(): integer`              | returns the display width of the dropbar                                                                                                                                                                  |
| `dropbar_t:truncate()`                           | truncates the dropbar if it exceeds the display width <br> *side effect: changes dropbar components<sub>[`dropbar_symbol_t[]`](#dropbar_symbol_t)                                                         |
| `dropbar_t:cat(plain: boolean?): string`         | concatenates the dropbar components into a string with substrings for highlights and click support if `plain` is not set; else returns a plain string without substrings for highlights and click support |
| `dropbar_t:redraw()`                             | redraws the dropbar                                                                                                                                                                                       |
| `dropbar_t:update()`                             | update dropbar components<sub>[`dropbar_symbol_t[]`](#dropbar_symbol_t)</sub> and redraw the dropbar afterwards                                                                                           |
| `dropbar_t:pick_mode_wrap(fn: fun(): T?): T?`    | executes `fn` in pick mode                                                                                                                                                                                |
| `dropbar_t:pick(idx: integer?)`                  | pick a component from dropbar in interactive pick mode if `idx` is not given; else pick the `idx`th component directly                                                                                    |
| `dropbar_t:__tostring(): string`                 | meta method to convert `dropbar_t` to its string representation                                                                                                                                           |


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
| `bar`         | [`dropbar_t?`](#dropbar_t)                                                                                          | the dropbar<sub>[`dropbar_t`](#dropbar_t)</sub> the symbol belongs to, if the symbol is shown inside a winbar                                |
| `menu`        | [`dropbar_menu_t?`](#dropbar_menu_t)                                                                                | menu<sub>[`dropbar_menu_t`](#dropbar_menu_t)</sub> associated with the symbol, if the symbol is shown inside a winbar                        |
| `entry`       | [`dropbar_menu_entry_t?`](#dropbar_menu_entry_t)                                                                    | the dropbar menu entry<sub>[`dropbar_menu_entry_t`](#dropbar_menu_entry_t)</sub> the symbol belongs to, if the symbol is shown inside a menu |
| `children`    | `dropbar_symbol_t[]?`                                                                                               | children of the symbol (e.g. a children of a function symbol can be local variables inside the function)                                     |
| `siblings`    | `dropbar_symbol_t[]?`                                                                                               | siblings of the symbol (e.g. a sibling of a symbol that represents a level 4 markdown heading can be other headings with level 4)            |
| `bar_idx`     | `integer?`                                                                                                          | index of the symbol in the dropbar<sub>[`dropbar_t`](#dropbar_t)</sub>                                                                       |
| `entry_idx`   | `integer?`                                                                                                          | index of the symbol in the menu entry<sub>[`dropbar_menu_entry_t`](#dropbar_menu_entry_t)</sub>                                              |
| `sibling_idx` | `integer?`                                                                                                          | index of the symbol in the siblings                                                                                                          |
| `on_click`    | `fun(this: dropbar_symbol_t, min_width: integer?, n_clicks: integer?, button: string?, modifiers: string?)\|false?` | callback to invoke when the symbol is clicked, force disable `on_click` when the value if set to `false`                                     |
| `actions`     | `table<string, fun(this: dropbar_symbol_t)>?`                                                                       | select, preview, jump, etc; pick one to invoke when clicking or hitting Enter on the corresponding symbol                                    |
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
| `dropbar_symbol_t:goto_range_start()`                             | moves the cursor to the start of the range of the dropbar symbol                                                                                                                              |
| `dropbar_symbol_t:swap_field(field: string, new_val: any)`        | temporarily change the content of a dropbar symbol <br> *does not support replacing nil values                                                                                                |
| `dropbar_symbol_t:restore()`                                      | restore the content of a dropbar symbol after `dropbar_symbol_t:swap_field()` is called <br> *does not support restoring nil values                                                           |

#### `dropbar_menu_t`

Declared and defined in [`lua/dropbar/menu.lua`](https://github.com/Bekaboo/dropbar.nvim/blob/master/lua/dropbar/menu.lua).

---

`dropbar_menu_t` is a class that represents a drop-down menu.

`dropbar_menu_t` has the following fields:

| Field          | Type                                              | Description                                                                            |
| ------         | ------                                            | ------                                                                                 |
| `buf`          | `integer`                                         | buffer number of the menu                                                              |
| `win`          | `integer`                                         | window id of the menu                                                                  |
| `is_opened`    | `boolean?`                                        | whether the menu is currently opened                                                   |
| `entries`      | [`dropbar_menu_entry_t[]`](#dropbar_menu_entry_t) | entries in the menu                                                                    |
| `win_configs`  | `table`                                           | window configuration, value can be a function, see [menu configuration options](#menu) |
| `_win_configs` | `table?`                                          | evaluated window configuration                                                         |
| `cursor`       | `integer[]?`                                      | initial cursor position                                                                |
| `prev_win`     | `integer?`                                        | previous window, assigned when calling new() or automatically determined in open()     |
| `sub_menu`     | `dropbar_menu_t?`                                 | submenu, assigned when calling new() or automatically determined when a new menu opens |
| `parent_menu`  | `dropbar_menu_t?`                                 | parent menu, assigned when calling new() or automatically determined in open()         |
| `clicked_at`   | `integer[]?`                                      | last position where the menu was clicked                                               |

`dropbar_menu_t` has the following methods:

| Method                                                                                                                            | Description                                                                                                                                                                      |
| ------                                                                                                                            | ------                                                                                                                                                                           |
| `dropbar_menu_t:new(opts: dropbar_menu_opts_t?): dropbar_menu_t`                                                                  | constructor of `dropbar_menu_t`                                                                                                                                                  |
| `dropbar_menu_t:del()`                                                                                                            | destructor of `dropbar_menu_t`                                                                                                                                                   |
| `dropbar_menu_t:eval_win_config()`                                                                                                | evaluate window configuration and store the result in `_win_configs`                                                                                                             |
| `dropbar_menu_t:get_component_at(pos: integer[]): dropbar_symbol_t`                                                               | get the component<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> at position `pos`                                                                                            |
| `dropbar_menu_t:click_at(pos: integer[], min_width: integer?, n_clicks: integer?, button: string?, modifiers: string?)`           | simulate a click at `pos` in the menu                                                                                                                                            |
| `dropbar_menu_t:click_on(symbol: dropbar_symbol_t, min_width: integer?, n_clicks: integer?, button: string?, modifiers: string?)` | simulate a click at the component `symbol`<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> of the menu                                                                         |
| `dropbar_menu_t:hl_line_range(line: integer, hl_info: dropbar_menu_hl_info_t)`                                                    | add highlight to a range in the menu buffer according to the line number and the highlight info<sub>[`dropbar_menu_hl_info_t`](#dropbar_menu_hl_info_t)                          |
| `dropbar_menu_t:hl_line_single(line: integer, hlgroup: string?)`                                                                  | add highlight to a single line in the menu buffer; `hlgroups` defaults to `'DropBarMenuCurrentContext'`<br> *all other highlights added by this functions before will be cleared |
| `dropbar_menu_t:make_buf()`                                                                                                       | create the menu buffer from the entries<sub>[`dropbar_menu_entry_t`](#dropbar_menu_entry_t)                                                                                      |
| `dropbar_menu_t:open()`                                                                                                           | open the menu                                                                                                                                                                    |
| `dropbar_menu_t:close()`                                                                                                          | close the menu                                                                                                                                                                   |
| `dropbar_menu_t:toggle()`                                                                                                         | toggle the menu                                                                                                                                                                  |

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

| Method                                                                        | Description                                                                                                                                               |
| ------                                                                        | ------                                                                                                                                                    |
| `dropbar_menu_entry_t:new(opts: dropbar_menu_entry_t?): dropbar_menu_entry_t` | constructor of `dropbar_menu_entry_t`                                                                                                                     |
| `dropbar_menu_entry_t:del()`                                                  | destructor of `dropbar_menu_entry_t`                                                                                                                      |
| `dropbar_menu_entry_t:cat(): string, dropbar_menu_hl_info_t`                  | concatenate the components into a string, returns the string and highlight info<sub>[`dropbar_menu_hl_info_t`](#dropbar_menu_hl_info_t)                   |
| `dropbar_menu_entry_t:displaywidth(): integer`                                | calculate the display width of the entry                                                                                                                  |
| `dropbar_menu_entry_t:bytewidth(): integer`                                   | calculate the byte width of the entry                                                                                                                     |
| `dropbar_menu_entry_t:first_clickable(offset: integer?): dropbar_symbol_t?`   | get the first clickable component<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> in the dropbar menu entry starting from `offset`, which defaults to 0 |

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

| Field         | Type                                                            | Description                                                                                                                                          |
| ------        | ------                                                          | ------                                                                                                                                               |
| `get_symbols` | `function(buf: integer, cursor: integer[]): dropbar_symbol_t[]` | returns the symbols<sub>[`dropbar_symbol_t[]`](#dropbar_symbol_t)</sub> to show in the winbar given buffer number `buf` and cursor position `cursor` |

### Making a New Source

A [`dropbar_source_t`](#dropbar_source_t) instance is just a table with
`get_symbols` field set to a function that returns an array of
[`dropbar_symbol_t`](#dropbar_symbol_t) instances given a buffer number and a
cursor position.

We have seen a simple example of a custom source in the [default config of
`opts.bar.sources`](#bar) where the second source is set to a table with its
field `get_symbols` set to a function that gets symbols from either the
markdown, LSP, or treesitter sources to achieve fall-back behavior.

Here is another example of a custom source that will always return two symbols
saying 'Hello' and 'dropbar' with highlights `'hl-Keyword'` and `'hl-Title'`
and a smiling face shown in `'hl-WarningMsg'` the start of the first symbol;
clicking on the first symbol will show a notification message saying 'Have you
smiled today?', followed by the smiling face icon used in the in dropbar symbol:

```lua
local bar = require('dropbar.bar')
local custom_source = {
  get_symbols = function(_, _)
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
  get_symbols = function(_, _)
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

| Field          | Type                          | Description                                                                                                                                                                      |
| ------         | ------                        | ------                                                                                                                                                                           |
| `siblings`     | `dropbar_symbol_t[]`          | array of symbols to show in the first drop-down menu<sub>[`dropbar_menu_t`](#dropbar_menu_t)</sub> (the menu opened by clicking the symbol in the winbar)                        |
| `sibling_idx`  | `integer?`                    | index of the symbol in `siblings` array, used to determine the initial position of the cursor in the first drop-down menu                                                        |
| `children`     | `dropbar_symbol_t[]`          | array of symbols to show in the sub-menus<sub>[`dropbar_menu_t`](#dropbar_menu_t)</sub> of the corresponding symbol (the menus opened by clicking a symbol inside another menu)  |
| `actions.jump` | `fun(this: dropbar_symbol_t)` | jump to the start of the symbol, it will be called when clicking on the corresponding symbol<sub>[`dropbar_symbol_t`](#dropbar_symbol_t)</sub> (not the indicator) inside a menu |

The following example shows a source that utilizes the default `on_click()`
callback:

```lua
local bar = require('dropbar.bar')
local custom_source = {
  get_symbols = function(_, _)
    return {
      bar.dropbar_symbol_t:new({
        name = 'Lev 1',
        name_hl = 'Keyword',
        siblings = {
          bar.dropbar_symbol_t:new({
            name = 'Lev 1.1',
            name_hl = 'WarningMsg',
          }),
          bar.dropbar_symbol_t:new({
            name = 'Lev 1.2',
            name_hl = 'Error',
          }),
          bar.dropbar_symbol_t:new({
            name = 'Lev 1.3',
            name_hl = 'String',
            children = {
              bar.dropbar_symbol_t:new({
                name = 'Lev 1.3.1',
                name_hl = 'String',
                actions = {
                  jump = function(_)
                    vim.notify('Jumping to Lev 1.3.1')
                  end
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
  get_symbols = function(_, _)
    return {
      bar.dropbar_symbol_t:new(setmetatable({
        name = 'Lev 1',
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
