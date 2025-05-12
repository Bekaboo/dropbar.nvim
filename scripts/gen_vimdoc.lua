require('gen').run({
  classes = {
    filename = 'doc/dropbar.txt',
    files = {
      'lua/dropbar/api.lua',
      'lua/dropbar/bar.lua',
      'lua/dropbar/menu.lua',
      'lua/dropbar/sources/init.lua',
      'lua/dropbar/utils',
    },
    section_order = {
      'lua/dropbar/api.lua',
      'lua/dropbar/bar.lua',
      'lua/dropbar/menu.lua',
      'lua/dropbar/sources/init.lua',
      'lua/dropbar/utils/bar.lua',
      'lua/dropbar/utils/menu.lua',
      'lua/dropbar/utils/source.lua',
      'lua/dropbar/utils/fzf.lua',
    },
    section_name = {
      ['lua/dropbar/api.lua'] = 'API',
      ['lua/dropbar/bar.lua'] = 'Bars',
      ['lua/dropbar/menu.lua'] = 'Menus',
      ['lua/dropbar/sources/init.lua'] = 'Source',
      ['lua/dropbar/utils/bar.lua'] = 'Bar Utils',
      ['lua/dropbar/utils/menu.lua'] = 'Menu Utils',
      ['lua/dropbar/utils/source.lua'] = 'Source Utils',
      ['lua/dropbar/utils/fzf.lua'] = 'Fzf Utils',
    },
    section_fmt = function(name)
      return string.format('DROPBAR %s', name:upper())
    end,
    helptag_fmt = function(name)
      return string.format('dropbar-%s', name:gsub(' ', '-'):lower())
    end,
  },
})
