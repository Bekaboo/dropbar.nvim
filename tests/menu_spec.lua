---@diagnostic disable: undefined-field

local menu = require('dropbar.menu')
local bar = require('dropbar.bar')
local spy = require('luassert.spy')
local match = require('luassert.match')

vim.cmd.edit('tests/assets/blank.txt')
local source_buf = vim.api.nvim_get_current_buf()
local source_win = vim.api.nvim_get_current_win()

local entry_it = menu.dropbar_menu_entry_t:new({
  separator = bar.dropbar_symbol_t:new({
    name = 'separator ',
    name_hl = 'NormalFloat',
    icon = '  ',
    icon_hl = 'DropBarSeparator',
  }),
  padding = {
    left = 3,
    right = 2,
  },
  components = {
    bar.dropbar_symbol_t:new({
      buf = source_buf,
      win = source_win,
      icon = ' ',
      icon_hl = 'Special',
      name = 'lua',
      on_click = false,
    }),
    bar.dropbar_symbol_t:new({
      buf = source_buf,
      win = source_win,
      icon = '󰊕 ',
      name = 'fn',
      name_hl = 'Function',
      on_click = function() end,
    }),
    bar.dropbar_symbol_t:new({
      buf = source_buf,
      win = source_win,
      icon = '󰀫 ',
      name = 'var',
      on_click = function() end,
    }),
  },
})

local menu_it = menu.dropbar_menu_t:new({
  entries = {
    menu.dropbar_menu_entry_t:new({
      padding = {
        left = 3,
      },
      components = {
        bar.dropbar_symbol_t:new({
          buf = source_buf,
          win = source_win,
          name = '1',
          range = {
            ['start'] = {
              line = 3,
              character = 4,
            },
            ['end'] = {
              line = 5,
              character = 6,
            },
          },
          on_click = function() end,
        }),
        bar.dropbar_symbol_t:new({
          buf = source_buf,
          win = source_win,
          name = '12',
          on_click = function() end,
        }),
        bar.dropbar_symbol_t:new({
          buf = source_buf,
          win = source_win,
          name = '123',
        }),
      },
    }),
    menu.dropbar_menu_entry_t:new({
      components = {
        bar.dropbar_symbol_t:new({
          buf = source_buf,
          win = source_win,
          name = '2',
        }),
        bar.dropbar_symbol_t:new({
          buf = source_buf,
          win = source_win,
          name = '22',
        }),
      },
    }),
    menu.dropbar_menu_entry_t:new(),
  },
  win_configs = {
    border = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' },
  },
})

local sub_menu_it = menu.dropbar_menu_t:new({
  win_configs = {
    width = function()
      return 0.5 * vim.o.columns
    end,
  },
})

local sub_sub_menu_it = menu.dropbar_menu_t:new({})

describe('[menu]', function()
  describe('dropbar_menu_entry_t', function()
    it('creates new instances', function()
      assert.are.same('separator ', entry_it.separator.name)
      assert.are.same('NormalFloat', entry_it.separator.name_hl)
      assert.are.same('  ', entry_it.separator.icon)
      assert.are.same('DropBarSeparator', entry_it.separator.icon_hl)
      assert.are.same(3, entry_it.padding.left)
      assert.are.same(2, entry_it.padding.right)
      assert.are.same(1, entry_it.components[1].entry_idx)
      assert.are.same(2, entry_it.components[2].entry_idx)
      assert.are.same(3, entry_it.components[3].entry_idx)
      assert.are.equal(entry_it, entry_it.components[1].entry)
      assert.are.equal(entry_it, entry_it.components[2].entry)
      assert.are.equal(entry_it, entry_it.components[3].entry)
    end)
    it('concatenates', function()
      local concatenated, hl_info = entry_it:cat()
      assert.are.same(
        '    lua  separator 󰊕 fn  separator 󰀫 var  ',
        concatenated
      )
      assert.are.same({
        {
          start = #'   ',
          ['end'] = #'    ',
          hlgroup = 'Special',
        },
        {
          start = #'    lua',
          ['end'] = #'    lua  ',
          hlgroup = 'DropBarSeparator',
        },
        {
          start = #'    lua  ',
          ['end'] = #'    lua  separator ',
          hlgroup = 'NormalFloat',
        },
        {
          start = #'    lua  separator 󰊕 ',
          ['end'] = #'    lua  separator 󰊕 fn',
          hlgroup = 'Function',
        },
        {
          start = #'    lua  separator 󰊕 fn',
          ['end'] = #'    lua  separator 󰊕 fn  ',
          hlgroup = 'DropBarSeparator',
        },
        {
          start = #'    lua  separator 󰊕 fn  ',
          ['end'] = #'    lua  separator 󰊕 fn  separator ',
          hlgroup = 'NormalFloat',
        },
      }, hl_info)
    end)
    it('calculates displaywidth', function()
      assert.are.same(
        vim.fn.strdisplaywidth(
          '    lua  separator 󰊕 fn  separator 󰀫 var  '
        ),
        entry_it:displaywidth()
      )
    end)
    it('calculates bytewidth', function()
      assert.are.same(
        #'    lua  separator 󰊕 fn  separator 󰀫 var  ',
        entry_it:bytewidth()
      )
    end)
    it('gets the first clickable component', function()
      assert.are.equal(entry_it.components[2], entry_it:first_clickable())
      assert.are.equal(
        entry_it.components[2],
        entry_it:first_clickable(#'    lua  separator 󰊕 f')
      )
      assert.are.equal(
        entry_it.components[3],
        entry_it:first_clickable(#'    lua  separator 󰊕 fn')
      )
      assert.are.equal(
        entry_it.components[3],
        entry_it:first_clickable(
          #'    lua  separator 󰊕 fn  separator '
        )
      )
    end)
    it('gets the previous clickable component', function()
      assert.is_nil(entry_it:prev_clickable(0))
      assert.is_nil(
        entry_it:prev_clickable(#'    lua  separator 󰊕 fn')
      )
      assert.are.equal(
        entry_it.components[2],
        entry_it:prev_clickable(#'    lua  separator 󰊕 fn ')
      )
      assert.are.equal(
        entry_it.components[2],
        entry_it:prev_clickable(
          #'    lua  separator 󰊕 fn  separator 󰀫 var'
        )
      )
      assert.are.equal(
        entry_it.components[3],
        entry_it:prev_clickable(
          #'    lua  separator 󰊕 fn  separator 󰀫 var '
        )
      )
      it('gets the next clickable component', function()
        assert.are.equal(entry_it.components[2], entry_it:next_clickable(0))
        assert.are.equal(
          entry_it.components[2],
          entry_it:next_clickable(#'    lua  separator')
        )
        assert.are.equal(
          entry_it.components[3],
          entry_it:next_clickable(#'    lua  separator ')
        )
        assert.are.equal(
          entry_it.components[3],
          entry_it:next_clickable(
            #'    lua  separator 󰊕 fn  separator'
          )
        )
        assert.is_nil(
          entry_it:next_clickable(
            #'    lua  separator 󰊕 fn  separator '
          )
        )
      end)
    end)
  end)

  describe('dropbar_menu_t', function()
    before_each(function()
      menu_it:open({ prev_win = source_win })
      sub_menu_it:open({ prev_win = menu_it.win })
      sub_sub_menu_it:open({ prev_win = sub_menu_it.win })
    end)

    it('creates new instances successfully', function()
      assert.are.same(
        { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' },
        menu_it.win_configs.border
      )
      assert.are.same(1, menu_it.entries[1].idx)
      assert.are.same(2, menu_it.entries[2].idx)
      assert.are.same(3, menu_it.entries[3].idx)
      assert.are.equal(menu_it, menu_it.entries[1].menu)
      assert.are.equal(menu_it, menu_it.entries[2].menu)
      assert.are.equal(menu_it, menu_it.entries[3].menu)
    end)
    it('opens successfully', function()
      assert.is_true(vim.api.nvim_buf_is_valid(menu_it.buf))
      assert.is_true(vim.api.nvim_win_is_valid(menu_it.win))
      assert.is_true(vim.api.nvim_buf_is_valid(sub_menu_it.buf))
      assert.is_true(vim.api.nvim_win_is_valid(sub_menu_it.win))
      assert.is_true(vim.api.nvim_buf_is_valid(sub_sub_menu_it.buf))
      assert.is_true(vim.api.nvim_win_is_valid(sub_sub_menu_it.win))
    end)
    it('toggles successfully', function()
      local win = nil
      for _ = 1, 8 do
        win = vim.api.nvim_get_current_win()
        assert(win)
        menu_it:toggle() -- close
        assert.is_false(vim.api.nvim_win_is_valid(win))
        menu_it:toggle() -- open
        win = vim.api.nvim_get_current_win()
        assert(win)
        assert.is_true(vim.api.nvim_win_is_valid(win))
      end
    end)
    it('creates buffers with correct contents and options', function()
      assert.is_false(vim.bo[menu_it.buf].ma)
      assert.are.same('dropbar_menu', vim.bo[menu_it.buf].filetype)
      assert.are.same({
        '   1 12 123    ',
        ' 2 22          ',
        '               ',
      }, vim.api.nvim_buf_get_lines(menu_it.buf, 0, -1, false))
    end)
    it('gets component at {pos}', function()
      local entry1 = menu_it.entries[1]
      local component1 = entry1.components[1]
      local component2 = entry1.components[2]
      local component3 = entry1.components[3]
      assert.is_nil(menu_it:get_component_at({ 1, 0 }))
      assert.are.same(
        component1,
        menu_it:get_component_at({ 1, entry1.padding.left })
      )
      assert.are.same(
        component2,
        menu_it:get_component_at({
          1,
          entry1.padding.left
            + component1:bytewidth()
            + entry1.separator:bytewidth()
            + 1,
        })
      )
      assert.are.same(
        component3,
        menu_it:get_component_at({
          1,
          entry1.padding.left
            + component1:bytewidth()
            + entry1.separator:bytewidth()
            + component2:bytewidth()
            + entry1.separator:bytewidth()
            + 1,
        })
      )
    end)
    it('clicks at {pos}', function()
      local entry1 = menu_it.entries[1]
      local component1 = entry1.components[1]
      local component2 = entry1.components[2]
      local agent2 = spy.on(component2, 'on_click')
      local pos = {
        1,
        entry1.padding.left
          + component1:bytewidth()
          + entry1.separator:bytewidth()
          + 1,
      }
      menu_it:click_at(pos, 7, 2, 'r', 's')
      assert.are.same(pos, menu_it.clicked_at)
      assert
        .spy(agent2).was
        .called_with(match.is_ref(component2), 7, 2, 'r', 's')
    end)
    it('clicks on components', function()
      local entry1 = menu_it.entries[1]
      local component1 = entry1.components[1]
      local component2 = entry1.components[2]
      local agent1 = spy.on(component1, 'on_click')
      local agent2 = spy.on(component2, 'on_click')
      menu_it:click_on(component1, 3, 6, 'l', 'm')
      assert.are.same({
        1,
        entry1.padding.left,
      }, menu_it.clicked_at)
      assert
        .spy(agent1).was
        .called_with(match.is_ref(component1), 3, 6, 'l', 'm')
      menu_it:click_on(component2, 7, 2, 'r', 's')
      assert.are.same({
        1,
        entry1.padding.left
          + component1:bytewidth()
          + entry1.separator:bytewidth(),
      }, menu_it.clicked_at)
      assert
        .spy(agent2).was
        .called_with(match.is_ref(component2), 7, 2, 'r', 's')
    end)
    it('respects win_configs', function()
      assert.are.same(
        { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' },
        vim.api.nvim_win_get_config(menu_it.win).border
      )
      assert.are.same(
        vim.o.columns * 0.5,
        vim.api.nvim_win_get_config(sub_menu_it.win).width
      )
    end)
    it('respects the parent-child relationship', function()
      assert.are.equal(menu_it, sub_menu_it.prev_menu)
      assert.are.equal(sub_menu_it, sub_sub_menu_it.prev_menu)
      assert.are.equal(sub_menu_it, menu_it.sub_menu)
      assert.are.equal(sub_sub_menu_it, sub_menu_it.sub_menu)
      assert.are.equal(menu_it.win, sub_menu_it.prev_win)
      assert.are.equal(sub_menu_it.win, sub_sub_menu_it.prev_win)
    end)
    it('previews and restores symbol at {pos}', function()
      local orig_view =
        vim.api.nvim_win_call(menu_it.prev_win, vim.fn.winsaveview)
      menu_it:preview_symbol_at({ 1, 1 }, true)
      assert.are.same({ 4, 4 }, vim.api.nvim_win_get_cursor(menu_it.prev_win))
      menu_it:finish_preview()
      assert.are.same(
        orig_view,
        vim.api.nvim_win_call(menu_it.prev_win, vim.fn.winsaveview)
      )
    end)
    it('close() method always triggers when the window closes', function()
      local agent1 = spy.on(menu_it, 'close')
      local agent2 = spy.on(sub_menu_it, 'close')
      local agent3 = spy.on(sub_sub_menu_it, 'close')
      vim.api.nvim_win_close(menu_it.win, true)
      assert.spy(agent1).was.called(1)
      assert.spy(agent2).was.called(1)
      assert.spy(agent3).was.called(1)
    end)
    it('closing current menu will set cursor to parent menu', function()
      sub_sub_menu_it:close()
      assert.are.same(sub_sub_menu_it.prev_win, vim.api.nvim_get_current_win())
      assert.are.same(sub_sub_menu_it.prev_win, vim.api.nvim_get_current_win())
      sub_menu_it:close()
      assert.are.same(sub_menu_it.prev_win, vim.api.nvim_get_current_win())
      assert.are.same(sub_menu_it.prev_win, vim.api.nvim_get_current_win())
      menu_it:close()
      assert.are.same(menu_it.prev_win, vim.api.nvim_get_current_win())
    end)
    it('closing current menu will close all sub-menus', function()
      local win = menu_it.win
      local sub_win = sub_menu_it.win
      local sub_sub_win = sub_sub_menu_it.win
      menu_it:close()
      assert(win)
      assert(sub_win)
      assert(sub_sub_win)
      assert.is_false(vim.api.nvim_win_is_valid(win))
      assert.is_false(vim.api.nvim_win_is_valid(sub_win))
      assert.is_false(vim.api.nvim_win_is_valid(sub_sub_win))
    end)
    it('closes existing sub-menus on opening a new sub-menu', function()
      local win = menu_it.win
      local sub_win = sub_menu_it.win
      local sub_sub_win = sub_sub_menu_it.win
      vim.api.nvim_set_current_win(menu_it.win)
      local new_menu = menu.dropbar_menu_t:new()
      new_menu.prev_win = win
      new_menu:open() -- open a new sub-menu
      assert(win)
      assert(sub_win)
      assert(sub_sub_win)
      assert.is_false(vim.api.nvim_win_is_valid(sub_win))
      assert.is_false(vim.api.nvim_win_is_valid(sub_sub_win))
    end)
    it('deleteing current menu will delete all sub-menus', function()
      local buf = menu_it.buf
      local win = menu_it.win
      local sub_buf = sub_menu_it.buf
      local sub_win = sub_menu_it.win
      local sub_sub_buf = sub_sub_menu_it.buf
      local sub_sub_win = sub_sub_menu_it.win
      menu_it:del()
      assert.is_nil(menu_it.buf)
      assert.is_nil(menu_it.win)
      assert.is_nil(sub_menu_it.buf)
      assert.is_nil(sub_menu_it.win)
      assert.is_nil(sub_sub_menu_it.buf)
      assert.is_nil(sub_sub_menu_it.win)
      assert(buf)
      assert(win)
      assert(sub_buf)
      assert(sub_win)
      assert(sub_sub_buf)
      assert(sub_sub_win)
      assert.is_false(vim.api.nvim_buf_is_valid(buf))
      assert.is_false(vim.api.nvim_win_is_valid(win))
      assert.is_false(vim.api.nvim_buf_is_valid(sub_buf))
      assert.is_false(vim.api.nvim_win_is_valid(sub_win))
      assert.is_false(vim.api.nvim_buf_is_valid(sub_sub_buf))
      assert.is_false(vim.api.nvim_win_is_valid(sub_sub_win))
      assert.is_nil(_G.dropbar.menus[win])
      assert.is_nil(_G.dropbar.menus[sub_win])
      assert.is_nil(_G.dropbar.menus[sub_sub_win])
    end)
  end)
  describe('dropbar_menu_t:fuzzy_find*', function()
    before_each(function()
      menu_it:fuzzy_find_close()
      sub_menu_it:fuzzy_find_close()
      menu_it:close()
      sub_menu_it:close()
      menu_it:open({ prev_win = source_win })
    end)
    it('opens and closes the fuzzy finder', function()
      menu_it:fuzzy_find_open()
      assert(menu_it.fzf_state ~= nil)
      local win = menu_it.fzf_state.win
      assert.is_true(vim.api.nvim_win_is_valid(win))

      menu_it:fuzzy_find_close()
      assert.is_nil(menu_it.fzf_state)
      assert.is_false(vim.api.nvim_win_is_valid(win))
    end)
    it('closes fuzzy finder when menu is closed', function()
      menu_it:fuzzy_find_open()
      assert(menu_it.fzf_state ~= nil)
      local win = menu_it.fzf_state.win

      menu_it:close()

      assert.is_nil(menu_it.fzf_state)
      assert.is_false(vim.api.nvim_win_is_valid(win))
    end)
    it('opens fuzzy finder on new submenus', function()
      menu_it:fuzzy_find_open()
      sub_menu_it:open({ prev_win = menu_it.win })

      assert(sub_menu_it.fzf_state ~= nil)
      assert.is_nil(menu_it.fzf_state)
    end)
    it('closes old fuzzy finders when opening new submenus', function()
      menu_it:fuzzy_find_open()
      local win = menu_it.fzf_state.win
      sub_menu_it:open({ prev_win = menu_it.win })

      assert(sub_menu_it.fzf_state)
      assert.is_nil(menu_it.fzf_state)
      assert.is_false(vim.api.nvim_win_is_valid(win))
    end)
    it('filters entries', function()
      menu_it:fuzzy_find_open()
      local win = menu_it.fzf_state.win
      local buf = vim.api.nvim_win_get_buf(win)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, { '2' })
      assert.are.same(2, #menu_it.entries)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, { '12' })
      assert.are.same(1, #menu_it.entries)
    end)
    it('restores entries when exiting', function()
      menu_it:fuzzy_find_open()
      local win = menu_it.fzf_state.win
      local buf = vim.api.nvim_win_get_buf(win)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, { '12' })
      assert.are.same(1, #menu_it.entries)

      menu_it:fuzzy_find_close()

      assert.is_false(vim.api.nvim_win_is_valid(win))
      assert.is_false(vim.api.nvim_buf_is_valid(buf))
      assert.are.same(3, #menu_it.entries)
    end)
    it('frees memory with fzf_state:gc()', function()
      menu_it:fuzzy_find_open()
      local gc_metamethod = spy.on(menu_it.fzf_state, 'gc')

      menu_it:fuzzy_find_close()

      assert.spy(gc_metamethod).was.called(1)
    end)
  end)
end)
