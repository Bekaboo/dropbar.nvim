local menu = require('dropbar.menu')
local bar = require('dropbar.bar')

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
      icon = ' ',
      icon_hl = 'Special',
      name = 'lua',
    }),
    bar.dropbar_symbol_t:new({
      icon = '󰊕 ',
      name = 'fn',
      name_hl = 'Function',
      on_click = function()
        print('clicked on 2nd component')
      end,
    }),
    bar.dropbar_symbol_t:new({
      icon = '󰀫 ',
      name = 'var',
      on_click = function()
        print('clicked on 3rd component')
      end,
    }),
  },
})

describe('Menu', function()
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
  end)
end)
