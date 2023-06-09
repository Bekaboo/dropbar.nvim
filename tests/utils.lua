_G.test = {}
_G.test.utils = {}

---Build a nested table from dropbar symbol tree
---@param symbol dropbar_symbol_t
---@param tbl table (reference to) to the nested table
---@return nil
function test.utils.build_nested_tbl(symbol, tbl)
  tbl[symbol.name] = {}
  if symbol.children then
    for _, child in ipairs(symbol.children) do
      test.utils.build_nested_tbl(child, tbl[symbol.name])
    end
  end
end

---Get the location of a testpoint in the current buffer.
---@param test_point integer
---@return integer[] { lnum, col }
function test.utils.get_testpoint(test_point)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for lnum, line in ipairs(lines) do
    local col = line:find('TESTPOINT' .. test_point)
    if col then
      return { lnum, col - 1 } -- (1, 0) indexed
    end
  end
  error('TESTPOINT' .. test_point .. ' not found')
end

---Compare the name of symbols got at a testpoint with the expected symbol
---names
---@param test_point integer
---@param expected_names string[]
---@param source dropbar_source_t
---@return fun(test_point: integer, expected_headings: string[]) tester
function test.utils.test_symbol_path_at_test_point(
  test_point,
  expected_names,
  source
)
  return function()
    local symbols = source.get_symbols(
      vim.api.nvim_get_current_buf(),
      vim.api.nvim_get_current_win(),
      test.utils.get_testpoint(test_point)
    )
    assert.are.same(
      expected_names,
      vim.tbl_map(function(symbol)
        return symbol.name
      end, symbols)
    )
  end
end

---Get the names of a field of a symbol, the value of the field must be a list
---@param field string
---@param symbol dropbar_symbol_t
---@return string[]
function test.utils.get_names_of(field, symbol)
  if not symbol[field] then
    return {}
  end
  return vim.tbl_map(function(sym)
    return sym.name
  end, symbol[field])
end
