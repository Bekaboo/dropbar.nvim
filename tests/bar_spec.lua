local dropbar = require('dropbar')
local bar = require('dropbar.bar')
local menu = require('dropbar.menu')
local spy = require('luassert.spy')
local stub = require('luassert.stub')

---@type dropbar_source_t
local source = {
  get_symbols = function(buf, win, _)
    return {
      bar.dropbar_symbol_t:new({
        buf = buf,
        win = win,
        on_click = false,
      }),
      bar.dropbar_symbol_t:new({
        buf = buf,
        win = win,
        icon = '󰅩 ',
        name = 'sym2',
        icon_hl = 'DropBarIconTest',
        name_hl = 'DropBarNameTest',
        on_click = function(self)
          self.data = self.data or {}
          self.data.clicked = true
        end,
        menu = menu.dropbar_menu_t:new(),
        range = {
          start = {
            line = 3,
            character = 4,
          },
          ['end'] = {
            line = 5,
            character = 6,
          },
        },
      }),
      bar.dropbar_symbol_t:new({
        buf = buf,
        win = win,
        name = 'sym3',
        siblings = {
          bar.dropbar_symbol_t:new({
            buf = buf,
            win = win,
            name = 'sym3s1',
          }),
        },
      }),
      bar.dropbar_symbol_t:new(setmetatable({
        buf = buf,
        win = win,
        name = 'sym4',
      }, {
        __index = function(self, key)
          if key == 'siblings' then
            self.siblings = {
              bar.dropbar_symbol_t:new({
                buf = buf,
                win = win,
                name = 'sym4s1',
              }),
            }
            return self.siblings
          end
        end,
      })),
    }
  end,
}

dropbar.setup({
  icons = {
    ui = {
      bar = {
        extends = '...',
        separator = ' | ',
      },
    },
  },
  bar = {
    sources = {
      source,
    },
    padding = {
      left = 0,
      right = 4,
    },
  },
})

describe('[bar]', function()
  local winbar = nil ---@type dropbar_t
  local sym1 = nil ---@type dropbar_symbol_t
  local sym2 = nil ---@type dropbar_symbol_t
  local sym3 = nil ---@type dropbar_symbol_t
  local sym4 = nil ---@type dropbar_symbol_t
  before_each(function()
    winbar =
      _G.dropbar.bars[vim.api.nvim_get_current_buf()][vim.api.nvim_get_current_win()]
    vim.wait(10, winbar:update())
    sym1 = winbar.components[1]
    sym2 = winbar.components[2]
    sym3 = winbar.components[3]
    sym4 = winbar.components[4]
  end)
  after_each(function()
    winbar:del()
    assert.is_nil(rawget(_G.dropbar.bars[winbar.buf], winbar.win))
  end)

  describe('dropbar_t', function()
    it(
      'creates instances correctly when indexing into _G.dropbar.bars',
      function()
        assert.are.same(vim.api.nvim_get_current_buf(), winbar.buf)
        assert.are.same(vim.api.nvim_get_current_win(), winbar.win)
        assert.are.same('...', winbar.extends.icon)
        assert.are.same(' | ', winbar.separator.icon)
        assert.are.same({
          left = 0,
          right = 4,
        }, winbar.padding)
      end
    )
    it('get components from sources on update', function()
      assert.are.same(4, #winbar.components)
    end)
    it('concatenates and converts to string', function()
      -- stylua: ignore start
      local plain_str = ' | 󰅩 sym2 | sym3 | sym4    '
      local start_str = '%#DropBar#'
      local end_str = '    %*'
      local sep_str = '%#DropBarIconUISeparator# | %*'
      local sym2_str = '%@v:lua.dropbar.on_click_callbacks.buf1.win1000.fn2@%#DropBarIconTest#󰅩 %*%#DropBarNameTest#sym2%*%X'
      local sym3_str = '%@v:lua.dropbar.on_click_callbacks.buf1.win1000.fn3@sym3%X'
      local sym4_str = '%@v:lua.dropbar.on_click_callbacks.buf1.win1000.fn4@sym4%X'
      -- stylua: ignore end
      local representation_str = start_str
        .. sep_str
        .. sym2_str
        .. sep_str
        .. sym3_str
        .. sep_str
        .. sym4_str
        .. end_str
      assert.are.same(plain_str, winbar:cat(true))
      assert.are.same(representation_str, winbar:cat())
      assert.are.same(representation_str, tostring(winbar))
    end)
    it('calculates display width', function()
      assert.are.same(
        vim.fn.strdisplaywidth(' | 󰅩 sym2 | sym3 | sym4    '),
        winbar:displaywidth()
      )
    end)
    it('truncates itself', function()
      vim.cmd.vsplit()
      vim.api.nvim_win_set_width(winbar.win, 10)
      winbar:truncate()
      assert.are.same(' | 󰅩 sym2 | sym3 | sym4    ', winbar:cat(true))
      vim.api.nvim_win_close(vim.api.nvim_get_current_win(), true)
    end)
    it('sets and restores pick mode correctly', function()
      assert.is_falsy(winbar.in_pick_mode)
      winbar:pick_mode_wrap(function()
        assert.is_true(winbar.in_pick_mode)
        winbar:pick_mode_wrap(function()
          assert.is_true(winbar.in_pick_mode)
        end)
        assert.is_true(winbar.in_pick_mode)
      end)
      assert.is_falsy(winbar.in_pick_mode)
    end)
    it('picks in interactive pick mode', function()
      local agent = spy.on(winbar.components[2], 'on_click')
      -- stubbing vim.fn.getchar to always return the char number of 'b'
      -- without user input to simulate selecting the second symbol
      stub(vim.fn, 'getchar', function()
        return vim.fn.char2nr('b')
      end)
      winbar:pick()
      vim.fn.getchar:revert()
      assert.spy(agent).was_called()
    end)
    it('picks directly', function()
      local agent = spy.on(winbar.components[2], 'on_click')
      winbar.in_pick_mode = true
      winbar:pick(2)
      assert.spy(agent).was_called()
    end)
    it('deletes itself', function()
      local agents = vim.tbl_map(function(component)
        return spy.on(component, 'del')
      end, winbar.components)
      winbar:del()
      assert.is_nil(rawget(_G.dropbar.bars[winbar.buf], winbar.win))
      assert.is_nil(
        rawget(_G.dropbar.on_click_callbacks[winbar.buf], winbar.win)
      )
      for _, agent in ipairs(agents) do
        assert.spy(agent).was_called()
      end
    end)
  end)

  describe('dropbar_symbol_t', function()
    it('creates new instances', function()
      assert.are.same('sym2', sym2.name)
      assert.are.same('󰅩 ', sym2.icon)
      assert.are.same('DropBarNameTest', sym2.name_hl)
      assert.are.same('DropBarIconTest', sym2.icon_hl)
      sym2:on_click()
      assert.is_true(sym2.data.clicked)
    end)
    it(
      'setting on_click to false suppresses creation of the default on_click callback',
      function()
        assert.is_nil(sym1.on_click)
      end
    )
    it(
      "default on_click() function creates menus according to symbol's siblings",
      function()
        sym3:on_click()
        -- First component: expandable indicator
        -- Second component: symbol sym3s1
        assert.are.same('sym3s1', sym3.menu.entries[1].components[2].name)
        sym4:on_click()
        assert.are.same('sym4s1', sym4.menu.entries[1].components[2].name)
      end
    )
    it('creates new instances by with merged options', function()
      local new_symbol = sym2:merge({ name = 'new_symbol', icon = '󰅨 ' })
      assert.are.same('new_symbol', new_symbol.name)
      assert.are.same('󰅨 ', new_symbol.icon)
    end)
    it('deletes associated menu when deleting itself', function()
      local agent = spy.on(sym2.menu, 'del')
      sym2:del()
      assert.spy(agent).was_called()
    end)
    it('concatenates', function()
      assert.are.same('󰅩 sym2', sym2:cat(true))
      assert.are.same(
        '%@v:lua.dropbar.on_click_callbacks.buf1.win1000.fn2@%#DropBarIconTest#󰅩 %*%#DropBarNameTest#sym2%*%X',
        sym2:cat()
      )
    end)
    it('calculates display width', function()
      assert.are.same(vim.fn.strdisplaywidth('󰅩 sym2'), sym2:displaywidth())
    end)
    it('calculates byte width', function()
      assert.are.same(#'󰅩 sym2', sym2:bytewidth())
    end)
    it(
      'jumps to the start of the range of the associated symbol tree node',
      function()
        vim.cmd.edit('tests/assets/blank.txt')
        vim.wait(10, winbar:update())
        sym2:jump()
        assert.are.same({
          sym2.range.start.line + 1,
          sym2.range.start.character,
        }, vim.api.nvim_win_get_cursor(0))
      end
    )
    it(
      'previews the symbol and restore the orignal view in the source window after preview',
      function()
        vim.cmd.edit('tests/assets/blank.txt')
        vim.wait(10, winbar:update())
        local orig_view = vim.api.nvim_win_call(1000, vim.fn.winsaveview)
        sym2:preview()
        assert.are.same({
          sym2.range.start.line + 1,
          sym2.range.start.character,
        }, vim.api.nvim_win_get_cursor(1000))
        sym2:preview_restore_view()
        assert.are.same(
          orig_view,
          vim.api.nvim_win_call(1000, vim.fn.winsaveview)
        )
      end
    )
    it('swaps and restores its fields', function()
      local orig_name = sym2.name
      sym2:swap_field('name', 'swapped')
      assert.are.same('swapped', sym2.name)
      sym2:restore()
      assert.are.same(orig_name, sym2.name)
    end)
  end)
end)
