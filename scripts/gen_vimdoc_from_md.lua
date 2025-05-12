require('ts-vimdoc.formatting').style_elements = {
  header_break = {
    string.rep('=', 78), -- atx_h1_marker
    string.rep('=', 78), -- atx_h2_marker
    string.rep('-', 78), -- atx_h3_marker
  },
}

require('ts-vimdoc').docgen({
  input_file = 'README.md',
  output_file = 'doc/dropbar.txt',
  project_name = 'dropbar',
  table_of_contents = false,
})
