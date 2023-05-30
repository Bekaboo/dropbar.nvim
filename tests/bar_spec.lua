local bar = require('dropbar.bar')
local menu = require('dropbar.menu')
local spy = require('luassert.spy')

local on_click_target = nil
local symbol = nil
local winbar = nil

describe('[bar]', function()
  describe('dropbar_symbol_t', function()
    before_each(function()
      on_click_target = nil
      symbol = bar.dropbar_symbol_t:new({
        name = 'test',
        icon = ' ',
        name_hl = 'DropBarNameTest',
        icon_hl = 'DropBarIconTest',
        on_click = function()
          on_click_target = true
        end,
        menu = menu.dropbar_menu_t:new(),
        symbol = {
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
      })
      winbar = bar.dropbar_t:new({
        sources = {
          {
            get_symbols = function()
              return {
                bar.dropbar_symbol_t:new(),
                symbol,
              }
            end,
          },
        },
        buf = 0,
        win = 0,
        extends = bar.dropbar_symbol_t:new({
          icon = '...',
        }),
        separator = bar.dropbar_symbol_t:new({
          icon = ' | ',
        }),
        padding = {
          left = 0,
          right = 4,
        },
      })
    end)

    it('creates new instances', function()
      assert.are.same('test', symbol.name)
      assert.are.same(' ', symbol.icon)
      assert.are.same('DropBarNameTest', symbol.name_hl)
      assert.are.same('DropBarIconTest', symbol.icon_hl)
      symbol:on_click()
      assert.is_true(on_click_target)
    end)
    it('deletes associated menu when deleting symbol', function()
      local agent = spy.on(symbol.menu, 'del')
      symbol:del()
      assert.spy(agent).was_called()
    end)
    it('concatenates', function()
      assert.are.same(' test', symbol:cat(true))
      assert.are.same(' test', symbol:cat()) -- currently no bar is associated
      winbar:update() -- bar gets symbols from source, symbol is now associated
      assert.are.same(' test', symbol:cat(true))
      assert.are.same(
        '%@v:lua.dropbar.on_click_callbacks.buf0.win0.fn2@%#DropBarIconTest# %*%#DropBarNameTest#test%*%X',
        symbol:cat()
      )
    end)
    it('calculates display width', function()
      assert.are.same(
        vim.fn.strdisplaywidth(' test'),
        symbol:displaywidth()
      )
    end)
    it('calculates byte width', function()
      assert.are.same(#' test', symbol:bytewidth())
    end)
    it(
      'goes to the start of the range of the associated symbol tree node',
      function()
        vim.cmd.edit('tests/assets/blank.txt')
        winbar:update()
        symbol:goto_start()
        assert.are.same({
          symbol.symbol.range.start.line + 1,
          symbol.symbol.range.start.character,
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
