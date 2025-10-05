<h1 align='center'>
  dropbar.nvim
</h1>

<p align='center'>
  <b>IDE-like breadcrumbs, out of the box</b>
</p>

<p align='center'>
  <img src=https://github.com/Bekaboo/dropbar.nvim/assets/76579810/28db72ab-d75c-46fe-8a9d-1f06b4440de9 width=500>
</p>

<div align="center">
  <a href="./doc/dropbar.txt">
    <img src="https://github.com/bekaboo/dropbar.nvim/actions/workflows/tests.yml/badge.svg" alt="docs">
  </a>
  <a href="https://luarocks.org/modules/bekaboo/dropbar.nvim">
    <img src="https://img.shields.io/luarocks/v/bekaboo/dropbar.nvim?logo=lua&color=blue" alt="luarocks">
  </a>
</div>

## Introduction

A polished, IDE-like, highly-customizable winbar for Neovim with drop-down
menus and multiple backends.

For more information see [`:h dropbar`](doc/dropbar.txt).

## Features

https://github.com/Bekaboo/dropbar.nvim/assets/76579810/e8c1ac26-0321-4762-9975-b20fc3098c5a

- Opening drop-down menus or go to definition with a single mouse click
    ![mouse-click](https://github.com/Bekaboo/dropbar.nvim/assets/76579810/25282bf2-c90d-496b-9c37-0cbb6938ff5f)
- Pick mode for quickly selecting a component in the winbar with shortcuts
    ![pick-mode](https://github.com/Bekaboo/dropbar.nvim/assets/76579810/6126ceb1-0ad9-468b-89b9-457ce4110999)
- Automatically truncating long components
    ![auto-truncate](https://github.com/Bekaboo/dropbar.nvim/assets/76579810/c3b03e7f-d6f7-4c60-9c0d-da038529e1c7)
  - Better truncation when winbar is still too long after shortening
        all components
- Multiple backends that support fall-backs
  `dropbar.nvim` comes with five builtin sources:
  - [lsp](lua/dropbar/sources/lsp.lua): gets symbols from language servers using nvim's builtin LSP framework
  - [markdown](lua/dropbar/sources/markdown.lua): a custom incremental parser that gets symbol information about markdown headings
  - [path](lua/dropbar/sources/path.lua): gets current file path
  - [treesitter](lua/dropbar/sources/treesitter.lua): gets symbols from treesitter parsers using nvim's builtin treesitter integration
  - [terminal](lua/dropbar/sources/terminal.lua): easily switch terminal buffers using the dropdown menu
  To make a new source yourself, see [making a new source](#making-a-new-source).
  For source fall-backs support, see [bar options](#bar).
- Zero config & Zero dependency
  `dropbar.nvim` does not require [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
  or any third-party UI libraries to work.
  As long as the language server or the treesitter parser is installed,
  it should work just fine.
  Optionally, you can install [telescope-fzf-native](https://github.com/nvim-telescope/telescope-fzf-native.nvim)
  to add fuzzy search support to dropbar menus.
- Drop-down menu components and winbar symbols that response to
      mouse/cursor hovering:
    ![hover](https://github.com/Bekaboo/dropbar.nvim/assets/76579810/c944d61c-d39b-42e9-8b24-e3e33672b0d2)
    - This features requires `:h mousemoveevent` to be enabled.
- Preview symbols in their source windows when hovering over them in the
  drop-down menu
    ![preview](https://github.com/Bekaboo/dropbar.nvim/assets/76579810/93f33b90-4f42-459c-861a-1e70114ba6f2)
- Reorient the source window on previewing or after jumping to a symbol
- Add scrollbar to the menu when the symbol list is too long
  ![scrollbar](https://github.com/Bekaboo/dropbar.nvim/assets/76579810/ace94d9a-e850-4a6b-9ab3-51a290e5af32)

## Requirements

- Neovim >= 0.11.0
- Optional
  - [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons), if you want to see icons for different filetypes
  - [telescope-fzf-native](https://github.com/nvim-telescope/telescope-fzf-native.nvim), if you want fuzzy search support
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
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make'
      },
      config = function()
        local dropbar_api = require('dropbar.api')
        vim.keymap.set('n', '<Leader>;', dropbar_api.pick, { desc = 'Pick symbols in winbar' })
        vim.keymap.set('n', '[;', dropbar_api.goto_context_start, { desc = 'Go to start of current context' })
        vim.keymap.set('n', '];', dropbar_api.select_next_context, { desc = 'Select next context' })
      end
    }
  })
  ```

- Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

  ```lua
  require('packer').startup(function(use)
    use({
      'Bekaboo/dropbar.nvim',
      requires = {
        'nvim-telescope/telescope-fzf-native.nvim',
        run = 'make'
      },
      config = function ()
        local dropbar_api = require('dropbar.api')
        vim.keymap.set('n', '<Leader>;', dropbar_api.pick, { desc = 'Pick symbols in winbar' })
        vim.keymap.set('n', '[;', dropbar_api.goto_context_start, { desc = 'Go to start of current context' })
        vim.keymap.set('n', '];', dropbar_api.select_next_context, { desc = 'Select next context' })
      end
    })
  end)
  ```

- Using native package manager

  ```sh
  mkdir -p ~/.local/share/nvim/site/pack/packages/
  git clone https://github.com/Bekaboo/dropbar.nvim ~/.local/share/nvim/site/pack/packages/start/dropbar.nvim
  ```

  Lazy-loading is unneeded as it is already done in [plugin/dropbar.lua](plugin/dropbar.lua).

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
  - Use `dropbar_menu_t:fuzzy_find_open()` to interactively
    filter, select and preview entries using fzf
  - `<Esc>`: exit fzf mode
  - `<Up>/<Down>`: move the cursor in fzf mode
  - `<CR>`: call the on_click callback of the symbol under the cursor
- Default keymaps in drop-down menu
  - `<LeftMouse>`: call the `on_click` callback of the symbol at the mouse
    click
  - `<CR>`: find the first clickable symbol in the current drop-down menu
    entry and call its `on_click` callback
  - `i`: enter fzf mode from the menu
  - `q` / `<Esc>`: close current menu
  - To disable, remap or add new keymaps in the drop-down menu, see
    [menu options](#menu)

### Usage with `vim.ui.select`

Dropbar can be used as a drop-in replacement for Neovim's builtin `vim.ui.select` menu.

To enable this functionality, simply replace `vim.ui.select` with `dropbar.utils.menu.select`:

```lua
vim.ui.select = require('dropbar.utils.menu').select
```

## Configuration

### Options

For all available options and their default values, see [lua/dropbar/configs.lua](lua/dropbar/configs.lua).

Below are the detailed explanation of the options.

#### Bar

These options live under `opts.bar` and are used to control the behavior of the
winbar:

- `opts.bar.enable`: `boolean|fun(buf: integer?, win: integer?, info: table?): boolean`
  - Controls whether to attach dropbar to the current buffer and window
  - If a function is provided, it will be called with the current bufnr and
  winid and should return a boolean
  - Default:
    ```lua
    function(buf, win, _)
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

      return vim.bo[buf].ft == 'markdown'
        or pcall(vim.treesitter.get_parser, buf)
        or not vim.tbl_isempty(vim.lsp.get_clients({
          bufnr = buf,
          method = 'textDocument/documentSymbol',
        }))
    end,
    ```
- `opts.bar.attach_events`: `string[]`
  - Controls when to evaluate the `enable()` function and attach the plugin
    to corresponding buffer or window
  - Default:
    ```lua
    {
      'TermOpen',
      'BufEnter',
      'BufWinEnter',
      'BufWritePost',
      'FileType',
      'LspAttach',
    }
    ```
- `opts.bar.update_debounce`: `number`
  - Wait for a short time before updating the winbar, if another update
    request is received within this time, the previous request will be
    cancelled, this improves the performance when the user is holding
    down a key (e.g. `'j'`) to scroll the window
  - If you encounter performance issues when scrolling the window, try
    setting this option to a number slightly larger than
    `1000 / key_repeat_rate`
  - Default: `32`
- `opts.bar.update_events.win`: `string[]`
  - List of events that should trigger an update on the dropbar attached to
    a single window
  - Default:
    ```lua
    {
      'CursorMoved',
      'WinEnter',
      'WinResized',
    }
    ```
- `opts.bar.update_events.buf`: `string[]`
  - List of events that should trigger an update on all dropbars attached to a
    buffer
  - Default:
    ```lua
    {
      'BufModifiedSet',
      'FileChangedShellPost',
      'TextChanged',
      'ModeChanged',
    }
    ```
- `opts.bar.update_events.global`: `string[]`
  - List of events that should trigger an update of all dropbars in current
    nvim session
  - Default:
    ```lua
    {
      'DirChanged',
      'VimResized',
    }
    ```
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
    end
    ```
  - For more information about sources, see `dropbar_source_t`.
- `opts.bar.padding`: `{ left: number, right: number }`
  - Padding to use between the winbar and the window border
  - Default: `{ left = 1, right = 1 }`
- `opts.bar.pick.pivots`: `string`
  - Pivots to use in pick mode
  - Default: `'abcdefghijklmnopqrstuvwxyz'`
- `opts.bar.truncate`: `boolean`
  - Whether to truncate the winbar if it doesn't fit in the window
  - Default: `true`
- `opts.bar.gc.interval`: `number`
    - Interval of periodic garbage collection, i.e. remove winbars attached to
      invalid buffers/windows, in ms

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
- `opts.menu.hover`: `boolean`
  - Whether to highlight the symbol under the cursor
  - This feature requires `'mousemoveevent'` to be enabled
  - Default: `true`
- `opts.menu.keymaps`: `table<string, function|string|table<string, function>|table<string, string>>`
  - Buffer-local keymaps in the menu
  - Use `<key> = <function|string>` to map a key in normal mode in the menu
    buffer, or use `<key> = table<mode, function|string>` to map
    a key in specific modes.
  - Default:
    ```lua
    {
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
    ```

- `opts.menu.scrollbar`: `table<string, boolean>`
  - Scrollbar configuration for the menu.
  - Default:
    ```lua
    {
      enable = true,
      -- if false, only the scrollbar thumb will be shown
      background = true
    }
    ```

- `opts.menu.win_configs`: `table<string, dropbar_menu_win_config_opts_t>`
  - Window configurations for the menu, see `:h nvim_open_win()`
  - Each config key in `opts.menu.win_configs` accepts either a plain value
    which will be passes directly to `nvim_open_win()`, or a function that
    takes the current menu (see `dropbar_menu_t`) as an
    argument and returns a value to be passed to `nvim_open_win()`.
  - Default:
    ```lua
    {
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
            + (menu.prev_menu.scrollbar and 1 or 0)
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
      zindex = function(menu)
        if not menu.prev_menu then
          return
        end
        return menu.prev_menu.scrollbar
            and menu.prev_menu.scrollbar.thumb
            and vim.api.nvim_win_get_config(menu.prev_menu.scrollbar.thumb).zindex
          or vim.api.nvim_win_get_config(menu.prev_win).zindex
      end,
    }
    ```

#### Fzf

These options live under `opts.fzf` and are used to control the behavior and
appearance of the fuzzy finder interface.

- `opts.fzf.keymaps`
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
    }
    ```

- `opts.fzf.win_configs`
  - Options passed to `:h nvim_open_win`. The fuzzy finder will use its
    parent window's config by default, but options set here will override those.
  - Same config as opts.menu.win_configs
  - Default:
    ```lua
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
        local menu_border = menu._win_configs.border or vim.go.border
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
        local menu_border = menu._win_configs.border or vim.go.border
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
    ```

- `opts.fzf.prompt`
  - Prompt string that will be displayed in the statuscolumn of the fzf input window.
  - Can include highlight groups
  - Default:
    ```lua
    prompt = '%#htmlTag# '
    ```

- `opts.fzf.char_pattern`
  - Default:
    ```lua
    char_pattern = '[%w%p]'
    ```

- `opts.fzf.retain_inner_spaces`
  - Default:
    ```lua
    retain_inner_spaces = true
    ```

- `opts.fzf.fuzzy_find_on_click`
  - When opening an entry with a submenu via the fuzzy finder,
    open the submenu in fuzzy finder mode.
  - Default:
    ```lua
    fuzzy_find_on_click = true
    ```

#### Icons

These options live under `opts.icons` and are used to configure the icons
used by the plugin:

- `opts.icons.enable`: `boolean`
  - Whether to enable icons
  - Default: `true`
- `opts.icons.kinds.dir_icon`: `fun(path: string): string, string?|string?`
  - Directory icon and highlighting getter, set to empty string to disable
  - Default:
    ```lua
    function(_)
      return M.opts.icons.kinds.symbols.Folder, 'DropBarIconKindFolder'
    end
    ```
- `opts.icons.kinds.file_icon`: `fun(path: string): string, string?|string?`
  - File icon and highlighting getter, set to empty string to disable
  - Default:
    ```lua
    function(path)
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
    end
    ```
- `opts.icons.kinds.symbols`: `table<string, string>`
  - Table mapping the different kinds of symbols to their corresponding icons
  - Default:
    ```lua
    {
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

- `opts.symbol.on_click()`: `fun(symbol: dropbar_symbol_t, min_width: integer?, n_clicks: integer?, button: string?, modifiers: string?)|false?`
  - Default function called when clicking or pressing `<CR>` on the symbol
  - Default:
    ```lua
    function(symbol)
      -- Update current context highlights if the symbol
      -- is shown inside a menu
      if symbol.entry and symbol.entry.menu then
        symbol.entry.menu:update_current_context_hl(symbol.entry.idx)
      elseif symbol.bar then
        symbol.bar:update_current_context_hl(symbol.bar_idx)
      end

      -- Determine menu configs
      local prev_win = nil ---@type integer?
      local entries_source = nil ---@type dropbar_symbol_t[]?
      local init_cursor = nil ---@type integer[]?
      local win_configs = {}
      if symbol.bar then -- If symbol inside a dropbar
        prev_win = symbol.bar.win
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
        entries_source = symbol.opts.children
      end

      -- Toggle existing menu
      if symbol.menu then
        symbol.menu:toggle({
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
      local configs = require('dropbar.configs')
      symbol.menu = menu.dropbar_menu_t:new({
        prev_win = prev_win,
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
      symbol.menu:toggle()
    end,
    ```
- `opts.symbol.preview.reorient`: `fun(win: integer, range: {start: {line: integer, character: integer}, end: {line: integer, character: integer}})`
  - Function to reorient the source window when previewing symbol given
    the source window `win` and the range of the symbol `range`
  - Default:
    ```lua
    function() end
    ```
- `opts.symbol.jump.reorient`: `fun(win: integer, range: {start: {line: integer, character: integer}, end: {line: integer, character: integer}})`
  - Function to reorient the source window after jumping to symbol given
    the source window `win` and the range of the symbol `range`
  - Default:
    ```lua
    function() end
    ```

#### Sources

These options live under `opts.sources` and are used to control the behavior of
each sources.

##### Path

- `opts.sources.path.max_depth`: `integer`
  - Maximum number of symbols to return
  - A smaller number can help to improve performance in deeply nested paths
  - Default: `16`
- `opts.sources.path.relative_to`: `string|fun(buf: integer, win: integer): string`
  - The path to use as the root of the relative path
  - If a function is provided, it will be called with the current buffer number
    and window id as arguments and should return a string to be used as the
    root of the relative path
  - Notice: currently does not support `..` relative paths
  - Default:
    ```lua
    function(_, win)
      -- Workaround for Vim:E5002: Cannot find window number
      local ok, cwd = pcall(vim.fn.getcwd, win)
      return ok and cwd or vim.fn.getcwd()
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
    symbol<sub>`dropbar_symbol_t`</sub> in the result got
    from the path source and returns an alternative
    symbol<sub>`dropbar_symbol_t`</sub> to show if the
    current buffer is modified
  - Default:
    ```lua
    function(sym)
      return sym
    end
    ```
  - To set a different icon, name, or highlights when the buffer is modified,
    you can change the corresponding fields in the returned
    symbol<sub>`dropbar_symbol_t`</sub>
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
- `opts.sources.path.preview`: `boolean|fun(path: string): boolean?|nil`
  - A boolean or a function that takes a file path and returns whether to
    preview the file under cursor
  - Default: `true`
- `opts.sources.path.min_widths`: `integer[]`
  - Minimum width of each symbols when truncated, in reverse order
    (e.g. `{10}` forces the last symbol has width >= 10)
  - Default: `{}`

##### Treesitter

- `opts.sources.treesitter.max_depth`: `integer`
  - Maximum number of symbols to return
  - A smaller number can help to improve performance in deeply nested trees
    (e.g. in big nested json files)
  - Default: `16`
- `opts.sources.treesitter.name_regex`: `string`
  - Vim regex used to extract a short name from the node text
  - Default: `[=[[#~!@\*&.]*[[:keyword:]]\+!\?\(\(\(->\)\+\|-\+\|\.\+\|:\+\|\s\+\)\?[#~!@\*&.]*[[:keyword:]]\+!\?\)*]=]`
- `opts.sources.treesitter.valid_types:` `string[]`
  - A list of treesitter node types to include in the results
  - Default:
    ```lua
    {
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
    }
    ```
- `opts.sources.treesitter.min_widths`: `integer[]`
  - Minimum width of each symbols when truncated, in reverse order
    (e.g. `{10}` forces the last symbol has width >= 10)
  - Default: `{}`

##### LSP

- `opts.sources.lsp.max_depth`: `integer`
  - Maximum number of symbols to return
  - A smaller number can help to improve performance when the language server
    returns huge list of nested symbols
  - Default: `16`
- `opts.sources.lsp.valid_symbols:` `string[]`
  - A list of LSP document symbols to include in the results
  - Default:
    ```lua
    {
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
    }
    ```
- `opts.sources.lsp.request.ttl_init`: `number`
  - Number of times to retry a request before giving up
  - Default: `60`
- `opts.sources.lsp.request.interval`: `number`
  - Number of milliseconds to wait between retries
  - Default: `1000`
- `opts.sources.lsp.min_widths`: `integer[]`
  - Minimum width of each symbols when truncated, in reverse order
    (e.g. `{10}` forces the last symbol has width >= 10)
  - Default: `{}`

##### Markdown

- `opts.sources.markdown.max_depth`: `integer`
  - Maximum number of symbols to return
  - Default: `6`
- `opts.sources.markdown.parse.look_ahead`: `number`
  - Number of lines to update when cursor moves out of the parsed range
  - Default: `200`
- `opts.sources.markdown.min_widths`: `integer[]`
  - Minimum width of each symbols when truncated, in reverse order
    (e.g. `{10}` forces the last symbol has width >= 10)
  - Default: `{}`

##### Terminal

Thanks [@willothy](https://github.com/willothy) for implementing this.

- `opts.sources.terminal.icon`: `string|fun(buf: integer): string`
  - Icon to show before terminal names
  - Default:
    ```lua
    function(_)
      return M.opts.icons.kinds.symbols.Terminal or ' '
    end
    ```

- `opts.sources.terminal.name`: `string|fun(buf: integer): string`
  - Default: `vim.api.nvim_buf_get_name`
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

- `opts.sources.terminal.show_current: boolean`
  - Show the current terminal buffer in the menu
  - Default: `true`

### Highlighting

`dropbar.nvim` defines sets of highlight groups. Override them in your
colorscheme to change the appearance of the drop-down menu:

| Highlight group                    | Description                                                          | Attributes                                 |
| ---------------------------------- | -------------------------------------------------------------        | ------------------------------------------ |
| DropBarCurrentContext              | Background of selected/clicked symbol in dropbar                     | `{ link = 'Visual' }`                      |
| DropBarCurrentContextIcon          | Highlight for selected/clicked symbol's icon in dropbar              | `{ link = 'DropBarCurrentContext' }`       |
| DropBarCurrentContextName          | Highlight for selected/clicked symbol's name in dropbar              | `{ link = 'DropBarCurrentContext' }`       |
| DropBarFzfMatch                    | Fzf fuzzy search matches                                             | `{ link = 'Special' }`                     |
| DropBarHover                       | Background of the dropbar symbol when the mouse is hovering over it  | `{ link = 'Visual' }`                      |
| DropBarIconKindDefault             | Default highlight for dropbar icons                                  | `{ link = 'Special' }`                     |
| DropBarIconKindDefaultNC           | Default highlight for dropbar icons in non-current windows           | `{ link = 'WinBarNC' }`                    |
| DropBarIconKind...                 | Highlights of corresponding symbol kind icons                        | `{ link = 'Repeat' }`                      |
| DropBarIconKind...NC               | Highlights of corresponding symbol kind icons in non-current windows | `{ link = 'DropBarIconKindDefaultNC' }`    |
| DropBarIconUIIndicator             | Shortcuts before entries in `utils.menu.select()`                    | `{ link = 'SpecialChar' }`                 |
| DropBarIconUIPickPivot             | Shortcuts shown before each symbol after entering pick mode          | `{ link = 'Error' }`                       |
| DropBarIconUISeparator             | Separator between each symbol in dropbar                             | `{ link = 'Comment' }`                     |
| DropBarIconUISeparatorMenu         | Separator between each symbol in dropbar menus                       | `{ link = 'DropBarIconUISeparator' }`      |
| DropBarMenuCurrentContext          | Background of current line in dropbar menus                          | `{ link = 'PmenuSel' }`                    |
| DropBarMenuFloatBorder             | Border of dropbar menus                                              | `{ link = 'FloatBorder' }`                 |
| DropBarMenuHoverEntry              | Background of hovered line in dropbar menus                          | `{ link = 'IncSearch' }`                   |
| DropBarMenuHoverIcon               | Background of hovered symbol icon in dropbar menus                   | `{ reverse = true }`                       |
| DropBarMenuHoverSymbol             | Background of hovered symbol name in dropbar menus                   | `{ bold = true }`                          |
| DropBarMenuNormalFloat             | Normal text in dropbar menus                                         | `{ link = 'NormalFloat' }`                 |
| DropBarMenuSbar                    | Scrollbar background of dropbar menus                                | `{ link = 'PmenuSbar' }`                   |
| DropBarMenuThumb                   | Scrollbar thumb of dropbar menus                                     | `{ link = 'PmenuThumb' }`                  |
| DropBarPreview                     | Range of the symbol under the cursor in source code                  | `{ link = 'Visual' }`                      |
| DropBarKind...                     | Highlights of corresponding symbol kind names                        | undefined                                  |
| DropBarKind...NC                   | Highlights of corresponding symbol kind names in non-current windows | undefined                                  |

### Configuration Examples

#### Custom Filename Highlight Group

This configuration highlights filenames from path source with custom highlight
group `DropBarFileName`.

```lua
local dropbar = require('dropbar')
local sources = require('dropbar.sources')
local utils = require('dropbar.utils')

vim.api.nvim_set_hl(0, 'DropBarFileName', { fg = '#FFFFFF', italic = true })

local custom_path = {
  get_symbols = function(buff, win, cursor)
    local symbols = sources.path.get_symbols(buff, win, cursor)
    symbols[#symbols].name_hl = 'DropBarFileName'
    if vim.bo[buff].modified then
      symbols[#symbols].name = symbols[#symbols].name .. ' [+]'
      symbols[#symbols].name_hl = 'DiffAdded'
    end
    return symbols
  end,
}

dropbar.setup({
  bar = {
    sources = function(buf, _)
      if vim.bo[buf].ft == 'markdown' then
        return {
          custom_path,
          sources.markdown,
        }
      end
      if vim.bo[buf].buftype == 'terminal' then
        return {
          sources.terminal,
        }
      end
      return {
        custom_path,
        utils.source.fallback {
          sources.lsp,
          sources.treesitter,
        },
      }
    end,
  },
})
```

#### Normalize Path in Special Buffers

Some plugins, e.g. [oil](https://github.com/stevearc/oil.nvim) and
[fugitive](https://github.com/tpope/vim-fugitive), have buffers with file path
confusing for dropbar.nvim. This is because their buffers names start with
things like `oil://` or `fugitive://`.

This configuration should addresses the issue:

```lua
require('dropbar').setup({
  bar = {
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
  },
  sources = {
    path = {
      relative_to = function(buf, win)
        -- Show full path in oil or fugitive buffers
        local bufname = vim.api.nvim_buf_get_name(buf)
        if
          vim.startswith(bufname, 'oil://')
          or vim.startswith(bufname, 'fugitive://')
        then
          local root = bufname:gsub('^%S+://', '', 1)
          while root and root ~= vim.fs.dirname(root) do
            root = vim.fs.dirname(root)
          end
          return root
        end

        local ok, cwd = pcall(vim.fn.getcwd, win)
        return ok and cwd or vim.fn.getcwd()
      end,
    },
  },
})
```

## Developers

### Architecture

The flow chart below should well illustrate what does `dropbar` do user moves
around in their window or clicks at a symbol in the winbar:

```
                                              ┌──────────────────┐
                                              │winbar at win 1000│ {k}th symbol clicked
                                              │ contaning buf 1  ├──────────────────────┐
                                              └───────┬─▲────────┘                      │
                                                      ▼ │                               │
                                                  _G.dropbar()                          │
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
          │ │                        __call() │ │ return string cache                   │
          │ │                             ┌───▼─┴───┐                    ┌──────────────▼──────────────┐
          │ │                             │dropbar_t├────────────────────▶     _G.dropbar.callbacks    │
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

### Making a New Source

A `dropbar_source_t` instance is just a table with
`get_symbols` field set to a function that returns an array of
`dropbar_symbol_t` instances given the buffer number, the
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

#### Source With Drop-Down Menus

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

`dropbar_symbol_t:new()` defines a default `on_click()`
callback if non is provided.

The default `on_click()` callback will look for these fields in the symbol
instance and create a drop-down menu accordingly on click, for more information
about these fields see `dropbar_symbol_t`.

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
[`lua/dropbar/sources`](lua/dropbar/sources).

## Similar Projects

- [nvim-navic](https://github.com/SmiteshP/nvim-navic)
