---@diagnostic disable: undefined-field

local dropbar = require('dropbar')
local source_treesitter = require('dropbar.sources.treesitter')
local stub = require('luassert.stub')

---@param opts? {
---  type_name?: string,
---  text?: string,
---  range?: integer[],
---  named?: boolean,
---  children?: TSNode[],
---  fields?: (string|nil)[],
---}
---@return TSNode
local function ts_node(opts)
  opts = opts or {}
  local children = opts.children or {}
  local fields = opts.fields or {}
  local ts = {
    _type = opts.type_name or 'identifier',
    _text = opts.text or '',
    _range = opts.range or { 0, 0, 0, 0 },
    _named = opts.named ~= false,
    _children = children,
    _fields = fields,
    _parent = nil,
    _index = nil,
  }

  for i, child in ipairs(children) do
    child._parent = ts
    child._index = i
  end

  ts.type = function(self)
    return self._type
  end
  ts.range = function(self)
    return unpack(self._range)
  end
  ts.parent = function(self)
    return self._parent
  end
  ts.named = function(self)
    return self._named
  end
  ts.child_count = function(self)
    return #self._children
  end
  ts.named_child_count = function(self)
    local count = 0
    for _, child in ipairs(self._children) do
      if child:named() then
        count = count + 1
      end
    end
    return count
  end
  ts.iter_children = function(self)
    local i = 0
    return function()
      i = i + 1
      local child = self._children[i]
      if not child then
        return nil
      end
      return child, self._fields[i]
    end
  end
  ts.prev_sibling = function(self)
    local parent = self._parent
    if not parent or not self._index or self._index <= 1 then
      return nil
    end
    return parent._children[self._index - 1]
  end
  ts.next_sibling = function(self)
    local parent = self._parent
    if not parent or not self._index then
      return nil
    end
    return parent._children[self._index + 1]
  end

  return ts
end

---@param cursor_node TSNode
---@param stubs luassert.stub[]
local function stub_treesitter(cursor_node, stubs)
  table.insert(
    stubs,
    stub(vim.treesitter, 'get_parser', function()
      return true
    end)
  )
  table.insert(
    stubs,
    stub(vim.filetype, 'match', function()
      return 'nickel'
    end)
  )
  table.insert(
    stubs,
    stub(vim.treesitter, 'get_node', function()
      return cursor_node
    end)
  )
  table.insert(
    stubs,
    stub(vim.treesitter, 'get_node_text', function(node)
      return node._text
    end)
  )
  table.insert(
    stubs,
    stub(vim.treesitter, 'get_node_range', function(node_or_range)
      if type(node_or_range) == 'table' and node_or_range._range then
        return unpack(node_or_range._range)
      end
      return unpack(node_or_range)
    end)
  )
  table.insert(
    stubs,
    stub(vim.treesitter, 'node_contains', function(node, range)
      local node_start_row, node_start_col, node_end_row, node_end_col =
        unpack(node._range)
      local range_start_row, range_start_col, range_end_row, range_end_col =
        unpack(range)
      local node_starts_before_range = node_start_row < range_start_row
        or (
          node_start_row == range_start_row
          and node_start_col <= range_start_col
        )
      local node_ends_after_range = node_end_row > range_end_row
        or (node_end_row == range_end_row and node_end_col >= range_end_col)
      return node_starts_before_range and node_ends_after_range
    end)
  )
end

---@param symbols dropbar_symbol_t[]
---@return string[]
local function symbol_names(symbols)
  return vim.tbl_map(function(symbol)
    return symbol.name
  end, symbols)
end

describe('[source][treesitter]', function()
  local stubs = {}

  before_each(function()
    dropbar.setup({
      bar = {
        sources = {
          source_treesitter,
        },
      },
      sources = {
        treesitter = {
          valid_types = {
            'classProperty',
            'modifier',
            'pair',
            'identifier',
            'class',
            'function',
          },
          name_regex = '[A-Za-z_][A-Za-z0-9_.]*',
        },
      },
    })
  end)

  after_each(function()
    for _, s in ipairs(stubs) do
      s:revert()
    end
    stubs = {}
  end)

  it('resolves names from named children, not anonymous tokens', function()
    local local_token = ts_node({
      type_name = 'string',
      text = 'local',
      range = { 0, 0, 0, 5 },
      named = false,
    })
    local modifier = ts_node({
      type_name = 'modifier',
      text = 'local',
      range = { 0, 0, 0, 5 },
      children = { local_token },
      fields = { nil },
    })
    local identifier = ts_node({
      type_name = 'identifier',
      text = 'myField',
      range = { 0, 6, 0, 13 },
    })
    local class_property = ts_node({
      type_name = 'classProperty',
      text = 'local myField',
      range = { 0, 0, 0, 13 },
      children = { modifier, identifier },
      fields = { nil, 'name' },
    })

    stub_treesitter(class_property, stubs)

    local symbols = source_treesitter.get_symbols(
      vim.api.nvim_get_current_buf(),
      vim.api.nvim_get_current_win(),
      { 1, 7 }
    )

    assert.are.same({ 'myField' }, symbol_names(symbols))
  end)

  it(
    'collapses same-line contained path segments into parent breadcrumb',
    function()
      local path = ts_node({
        type_name = 'identifier',
        text = 'grammar.source.git',
        range = { 1, 2, 1, 20 },
      })
      local grammar = ts_node({
        type_name = 'identifier',
        text = 'grammar',
        range = { 1, 2, 1, 9 },
      })
      local source = ts_node({
        type_name = 'identifier',
        text = 'source',
        range = { 1, 10, 1, 16 },
      })
      grammar._parent = path
      source._parent = grammar

      stub_treesitter(source, stubs)

      local symbols = source_treesitter.get_symbols(
        vim.api.nvim_get_current_buf(),
        vim.api.nvim_get_current_win(),
        { 2, 12 }
      )

      assert.are.same({ 'grammar.source.git' }, symbol_names(symbols))
    end
  )

  it(
    'keeps child symbol when parent and child names are on different lines',
    function()
      local path = ts_node({
        type_name = 'identifier',
        text = 'grammar.source.git',
        range = { 1, 2, 1, 20 },
      })
      local rev = ts_node({
        type_name = 'identifier',
        text = 'rev',
        range = { 2, 4, 2, 7 },
      })
      rev._parent = path

      stub_treesitter(rev, stubs)

      local symbols = source_treesitter.get_symbols(
        vim.api.nvim_get_current_buf(),
        vim.api.nvim_get_current_win(),
        { 3, 5 }
      )

      assert.are.same({ 'grammar.source.git', 'rev' }, symbol_names(symbols))
    end
  )

  it(
    'prefers narrower name when broader parent starts same place across lines',
    function()
      local broad = ts_node({
        type_name = 'identifier',
        text = 'self.get_base_types_for_class',
        range = { 0, 17, 2, 33 },
      })
      local self_symbol = ts_node({
        type_name = 'identifier',
        text = 'self',
        range = { 0, 17, 1, 29 },
      })
      self_symbol._parent = broad

      stub_treesitter(self_symbol, stubs)

      local symbols = source_treesitter.get_symbols(
        vim.api.nvim_get_current_buf(),
        vim.api.nvim_get_current_win(),
        { 1, 18 }
      )

      assert.are.same({ 'self' }, symbol_names(symbols))
    end
  )

  it('deduplicates wrapper symbols with identical names', function()
    local settings_pair = ts_node({
      type_name = 'pair',
      text = 'settings = { ... }',
      range = { 0, 2, 8, 0 },
    })
    local settings_id = ts_node({
      type_name = 'identifier',
      text = 'settings',
      range = { 0, 2, 0, 10 },
    })
    local server_pair = ts_node({
      type_name = 'pair',
      text = 'server = { ... }',
      range = { 1, 4, 7, 2 },
    })
    local server_id = ts_node({
      type_name = 'identifier',
      text = 'server',
      range = { 1, 4, 1, 10 },
    })
    local host_id = ts_node({
      type_name = 'identifier',
      text = 'host',
      range = { 2, 6, 2, 10 },
    })

    settings_id._parent = settings_pair
    server_pair._parent = settings_id
    server_id._parent = server_pair
    host_id._parent = server_id

    stub_treesitter(host_id, stubs)

    local symbols = source_treesitter.get_symbols(
      vim.api.nvim_get_current_buf(),
      vim.api.nvim_get_current_win(),
      { 3, 8 }
    )

    assert.are.same({ 'settings', 'server', 'host' }, symbol_names(symbols))
  end)

  it(
    'does not deduplicate non-wrapper symbols that just share names',
    function()
      local class_foo = ts_node({
        type_name = 'class',
        text = 'Foo',
        range = { 0, 0, 10, 0 },
      })
      local function_foo = ts_node({
        type_name = 'function',
        text = 'Foo',
        range = { 2, 2, 4, 2 },
      })
      local identifier = ts_node({
        type_name = 'identifier',
        text = 'x',
        range = { 3, 4, 3, 5 },
      })
      function_foo._parent = class_foo
      identifier._parent = function_foo

      stub_treesitter(identifier, stubs)

      local symbols = source_treesitter.get_symbols(
        vim.api.nvim_get_current_buf(),
        vim.api.nvim_get_current_win(),
        { 4, 5 }
      )

      assert.are.same({ 'Foo', 'Foo', 'x' }, symbol_names(symbols))
    end
  )
end)
