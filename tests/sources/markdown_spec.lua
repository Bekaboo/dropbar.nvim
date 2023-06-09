local dropbar = require('dropbar')
local source_markdown = require('dropbar.sources.markdown')

describe('[source][markdown]', function()
  before_each(function()
    dropbar.setup({
      bar = {
        sources = {
          source_markdown,
        },
      },
    })
    vim.cmd.edit('tests/assets/test.md')
  end)

  describe('symbol path', function()
    it(
      'is correct with ordered headings',
      test.utils.test_symbol_path_at_test_point(
        1,
        { 'H1', 'H2', 'H3' },
        source_markdown
      )
    )
    it(
      'is correct with headings with skipped levels',
      test.utils.test_symbol_path_at_test_point(
        2,
        { 'H1', 'H2', 'H3', 'H5' },
        source_markdown
      )
    )
    it(
      'is correct with unordered headings',
      test.utils.test_symbol_path_at_test_point(
        3,
        { 'H1', 'H2', 'H3', 'H4' },
        source_markdown
      )
    )
    it(
      'is correct with repeated heading levels',
      test.utils.test_symbol_path_at_test_point(
        4,
        { 'H1', 'H2', 'H3', 'H4', 'H6.2' },
        source_markdown
      )
    )
    it(
      'should ignore heading patterns inside code blocks',
      test.utils.test_symbol_path_at_test_point(
        5,
        { 'H1', 'H2.1' },
        source_markdown
      )
    )
  end)

  describe('symbol tree', function()
    it('has correct structure', function()
      local tree = {}
      test.utils.build_nested_tbl(
        unpack(
          source_markdown.get_symbols(
            vim.api.nvim_get_current_buf(),
            vim.api.nvim_get_current_win(),
            test.utils.get_testpoint(0)
          )
        ),
        tree
      )
      assert.are.same({
        H1 = {
          H2 = {
            H3 = {
              H5 = {},
              H4 = {
                H6 = {},
                ['H6.1'] = {},
                ['H6.2'] = {},
              },
            },
          },
          ['H2.1'] = {},
        },
      }, tree)
    end)
  end)
end)
