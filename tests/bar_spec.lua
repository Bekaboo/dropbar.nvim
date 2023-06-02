local dropbar = require('dropbar')
local bar = require('dropbar.bar')
local menu = require('dropbar.menu')
local spy = require('luassert.spy')
local stub = require('luassert.stub')

---@type dropbar_source_t
local source = {
  get_symbols = function()
    return {
      bar.dropbar_symbol_t:new(),
      bar.dropbar_symbol_t:new({
        icon = '󰅩 ',
        name = 'testing',
        icon_hl = 'DropBarIconTest',
        name_hl = 'DropBarNameTest',
        on_click = function(self)
          self.data = self.data or {}
          self.data.clicked = true
        end,
        menu = menu.dropbar_menu_t:new(),
        data = {
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
        },
      }),
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
  before_each(function()
    winbar =
      _G.dropbar.bars[vim.api.nvim_get_current_buf()][vim.api.nvim_get_current_win()]
    winbar:update()
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
      assert.are.same(2, #winbar.components)
    end)
    it('concatenates and converts to string', function()
      local plain_str = ' | 󰅩 testing    '
      local formatted_str = string.format(
        '%%#DropBar#%%*%%#DropBarIconUISeparator# | %%*%%@v:lua.dropbar.on_click_callbacks.buf%d.win%d.fn%d@%%#DropBarIconTest#󰅩 %%*%%#DropBarNameTest#testing%%*%%X%%#DropBar#    %%*',
        winbar.buf,
        winbar.win,
        winbar.components[2].bar_idx
      )
      assert.are.same(plain_str, winbar:cat(true))
      assert.are.same(formatted_str, winbar:cat())
      assert.are.same(formatted_str, tostring(winbar))
    end)
    it('calculates display width', function()
      assert.are.same(
        vim.fn.strdisplaywidth(' | 󰅩 testing    '),
        winbar:displaywidth()
      )
    end)
    it('truncates itself', function()
      vim.cmd.vsplit()
      vim.api.nvim_win_set_width(winbar.win, 10)
      winbar:truncate()
      assert.are.same(' | 󰅩 t...    ', winbar:cat(true))
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
    local symbol = winbar.components[2]
    it('creates new instances', function()
      assert.are.same('testing', symbol.name)
      assert.are.same('󰅩 ', symbol.icon)
      assert.are.same('DropBarNameTest', symbol.name_hl)
      assert.are.same('DropBarIconTest', symbol.icon_hl)
      symbol:on_click()
      assert.is_true(symbol.data.clicked)
    end)
    it('deletes associated menu when deleting itself', function()
      local agent = spy.on(symbol.menu, 'del')
      symbol:del()
      assert.spy(agent).was_called()
    end)
    it('concatenates', function()
      assert.are.same('󰅩 testing', symbol:cat(true))
      assert.are.same(
        string.format(
          '%%@v:lua.dropbar.on_click_callbacks.buf%d.win%d.fn%d@%%#DropBarIconTest#󰅩 %%*%%#DropBarNameTest#testing%%*%%X',
          symbol.bar.buf,
          symbol.bar.win,
          symbol.bar_idx
        ),
        symbol:cat()
      )
    end)
    it('calculates display width', function()
      assert.are.same(
        vim.fn.strdisplaywidth('󰅩 testing'),
        symbol:displaywidth()
      )
    end)
    it('calculates byte width', function()
      assert.are.same(#'󰅩 testing', symbol:bytewidth())
    end)
    it(
      'goes to the start of the range of the associated symbol tree node',
      function()
        vim.cmd.edit('tests/assets/blank.txt')
        winbar:update()
        symbol:goto_range_start()
        assert.are.same({
          symbol.data.range.start.line + 1,
          symbol.data.range.start.character,
        }, vim.api.nvim_win_get_cursor(0))
      end
    )
    it('swaps and restores its fields', function()
      local orig_name = symbol.name
      symbol:swap_field('name', 'swapped')
      assert.are.same('swapped', symbol.name)
      symbol:restore()
      assert.are.same(orig_name, symbol.name)
    end)
  end)
end)
