require('nvim-treesitter.install').commands.TSInstallSync['run!'](
  'markdown',
  'markdown_inline'
)

require('ts-vimdoc').docgen({
  input_file = 'README.md',
  output_file = 'doc/dropbar.txt',
  project_name = 'dropbar',
})
