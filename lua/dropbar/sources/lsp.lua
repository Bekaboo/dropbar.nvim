local utils = require('dropbar.sources.utils')
local configs = require('dropbar.configs')
local groupid = vim.api.nvim_create_augroup('DropBarLsp', {})
local initialized = false

---@type table<integer, lsp_document_symbol_t[]>
local lsp_buf_symbols = {}
setmetatable(lsp_buf_symbols, {
  __index = function(_, k)
    lsp_buf_symbols[k] = {}
    return lsp_buf_symbols[k]
  end,
})

---@alias lsp_client_t table

---@class lsp_range_t
---@field start {line: integer, character: integer}
---@field end {line: integer, character: integer}

---@class lsp_location_t
---@field uri string
---@field range lsp_range_t

---@class lsp_document_symbol_t
---@field name string
---@field kind integer
---@field tags? table
---@field deprecated? boolean
---@field detail? string
---@field range? lsp_range_t
---@field selectionRange? lsp_range_t
---@field children? lsp_document_symbol_t[]

---@class lsp_symbol_information_t
---@field name string
---@field kind integer
---@field tags? table
---@field deprecated? boolean
---@field location? lsp_location_t
---@field containerName? string

---@alias lsp_symbol_t lsp_document_symbol_t|lsp_symbol_information_t

-- Map symbol number to symbol kind
-- stylua: ignore start
local symbol_kind_names = {
  [1]  = 'File',
  [2]  = 'Module',
  [3]  = 'Namespace',
  [4]  = 'Package',
  [5]  = 'Class',
  [6]  = 'Method',
  [7]  = 'Property',
  [8]  = 'Field',
  [9]  = 'Constructor',
  [10] = 'Enum',
  [11] = 'Interface',
  [12] = 'Function',
  [13] = 'Variable',
  [14] = 'Constant',
  [15] = 'String',
  [16] = 'Number',
  [17] = 'Boolean',
  [18] = 'Array',
  [19] = 'Object',
  [20] = 'Keyword',
  [21] = 'Null',
  [22] = 'EnumMember',
  [23] = 'Struct',
  [24] = 'Event',
  [25] = 'Operator',
  [26] = 'TypeParameter',
}
-- stylua: ignore end

---Return type of the symbol table
---@param symbols lsp_symbol_t[] symbol table
---@return string? symbol type
local function symbol_type(symbols)
  if symbols[1] and symbols[1].location then
    return 'SymbolInformation'
  elseif symbols[1] and symbols[1].range then
    return 'DocumentSymbol'
  end
end

---Check if cursor is in range
---@param cursor integer[] cursor position (line, character); (1, 0)-based
---@param range lsp_range_t 0-based range
---@return boolean
local function cursor_in_range(cursor, range)
  local cursor0 = { cursor[1] - 1, cursor[2] }
  -- stylua: ignore start
  return (
    cursor0[1] > range.start.line
    or (cursor0[1] == range.start.line
        and cursor0[2] >= range.start.character)
  )
    and (
      cursor0[1] < range['end'].line
      or (cursor0[1] == range['end'].line
          and cursor0[2] <= range['end'].character)
    )
  -- stylua: ignore end
end

---Check if range1 contains range2
---Strict indexing -- if range1 == range2, return false
---@param range1 lsp_range_t 0-based range
---@param range2 lsp_range_t 0-based range
---@return boolean
local function range_contains(range1, range2)
  -- stylua: ignore start
  return (
    range2.start.line > range1.start.line
    or (range2.start.line == range1.start.line
        and range2.start.character > range1.start.character)
    )
    and (
      range2.start.line < range1['end'].line
      or (range2.start.line == range1['end'].line
          and range2.start.character < range1['end'].character)
    )
    and (
      range2['end'].line > range1.start.line
      or (range2['end'].line == range1.start.line
          and range2['end'].character > range1.start.character)
    )
    and (
      range2['end'].line < range1['end'].line
      or (range2['end'].line == range1['end'].line
          and range2['end'].character < range1['end'].character)
    )
  -- stylua: ignore end
end

---Find the parent of a LSP SymbolInformation in a tree
---@param symbol lsp_symbol_information_t
---@param root dropbar_symbol_tree_t
---@return dropbar_symbol_tree_t? parent nil if parent not found in the subtree rooted at 'root'
local function symbol_information_find_parent(symbol, root)
  if not range_contains(root.range, symbol.location.range) then
    return nil
  end
  root.children = root.children or {}
  for _, child in ipairs(root.children) do
    local parent = symbol_information_find_parent(symbol, child)
    if parent then
      return parent
    end
  end
  return root
end

---Build tree from SymbolInformation[] plain list
---@param symbols lsp_symbol_information_t[]
---@return dropbar_symbol_tree_t root
local function symbol_information_build_tree(symbols)
  local root = {
    range = {
      start = { line = 0, character = 0 },
      ['end'] = { line = math.huge, character = math.huge },
    },
    children = {},
  }
  for list_idx, symbol in ipairs(symbols) do
    local parent = symbol_information_find_parent(symbol, root)
    if parent then
      parent.children = parent.children or {}
      table.insert(parent.children, {
        name = symbol.name,
        kind = symbol_kind_names[symbol.kind],
        range = symbol.location.range,
        idx = #parent.children + 1,
        data = { list_idx = list_idx },
      })
    end
  end
  return root
end

---Unify LSP SymbolInformation into dropbar symbol tree structure
---@param symbol lsp_symbol_information_t LSP SymbolInformation
---@param symbols lsp_symbol_information_t[] SymbolInformation[]
---@param list_idx integer index of the symbol in SymbolInformation[]
---@return dropbar_symbol_tree_t
local function unify_symbol_information(symbol, symbols, list_idx)
  return setmetatable({
    name = symbol.name,
    kind = symbol_kind_names[symbol.kind],
    range = symbol.location.range,
  }, {
    __index = function(self, k)
      if k == 'children' or k == 'siblings' or k == 'idx' then
        local tree = symbol_information_build_tree(symbols)
        local parent = symbol_information_find_parent(symbol, tree)
        if not parent then
          return nil
        end
        self.siblings = parent.children
        for sib_idx, sibling in ipairs(parent.children) do
          if sibling.data and sibling.data.list_idx == list_idx then
            self.idx = sib_idx
            self.children = sibling.children
            break
          end
        end
        return self[k]
      end
    end,
  })
end

---Convert LSP SymbolInformation[] into a list of dropbar symbols
---Each SymbolInformation in the list is sorted by the start position of its
---range, so just need to traverse the list in order and add each symbol that
---contains the cursor to the dropbar_symbols list.
---Side effect: change dropbar_symbols
---LSP Specification document: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/
---@param lsp_symbols lsp_symbol_information_t[]
---@param dropbar_symbols dropbar_symbol_t[] (reference to) dropbar symbols
---@param cursor integer[] cursor position
local function convert_symbol_information_list(
  lsp_symbols,
  dropbar_symbols,
  cursor
)
  for idx, symbol in ipairs(lsp_symbols) do
    if cursor_in_range(cursor, symbol.location.range) then
      table.insert(
        dropbar_symbols,
        utils.to_dropbar_symbol(
          unify_symbol_information(symbol, lsp_symbols, idx)
        )
      )
    end
  end
end

---Unify LSP DocumentSymbol into dropbar symbol tree structure
---@param document_symbol lsp_document_symbol_t LSP DocumentSymbol
---@param siblings lsp_document_symbol_t[]? siblings of the symbol
---@param idx integer? index of the symbol in siblings
---@return dropbar_symbol_tree_t
local function unify_document_symbol(document_symbol, siblings, idx)
  return setmetatable({
    name = document_symbol.name,
    kind = symbol_kind_names[document_symbol.kind],
    range = document_symbol.range,
    idx = idx,
  }, {
    __index = function(self, k)
      if k == 'children' then
        if not document_symbol.children then
          return nil
        end
        self.children = vim.tbl_map(function(child)
          return unify_document_symbol(child)
        end, document_symbol.children)
        return self.children
      elseif k == 'siblings' then
        if not siblings then
          return nil
        end
        self.siblings = vim.tbl_map(function(sibling)
          return unify_document_symbol(sibling, siblings)
        end, siblings)
        return self.siblings
      end
    end,
  })
end

---Convert LSP DocumentSymbol[] into a list of dropbar symbols
---Side effect: change dropbar_symbols
---LSP Specification document: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/
---@param lsp_symbols lsp_document_symbol_t[]
---@param dropbar_symbols dropbar_symbol_t[] (reference to) dropbar symbols
---@param cursor integer[] cursor position
local function convert_document_symbol_list(
  lsp_symbols,
  dropbar_symbols,
  cursor
)
  -- Parse in reverse order so that the symbol with the largest start position
  -- is preferred
  for idx, symbol in vim.iter(lsp_symbols):enumerate():rev() do
    if cursor_in_range(cursor, symbol.range) then
      table.insert(
        dropbar_symbols,
        utils.to_dropbar_symbol(
          unify_document_symbol(symbol, lsp_symbols, idx)
        )
      )
      if symbol.children then
        convert_document_symbol_list(symbol.children, dropbar_symbols, cursor)
      end
      return
    end
  end
end

---Convert LSP symbols into a list of dropbar symbols
---@param symbols lsp_symbol_t[] LSP symbols
---@param cursor integer[] cursor position
---@return dropbar_symbol_t[] symbol_path dropbar symbols
local function convert(symbols, cursor)
  local symbol_path = {}
  if symbol_type(symbols) == 'SymbolInformation' then
    convert_symbol_information_list(symbols, symbol_path, cursor)
  elseif symbol_type(symbols) == 'DocumentSymbol' then
    convert_document_symbol_list(symbols, symbol_path, cursor)
  end
  return symbol_path
end

---Update LSP symbols from an LSP client
---Side effect: update symbol_list
---@param buf integer buffer handler
---@param client lsp_client_t LSP client
---@param ttl integer? limit the number of recursive requests, default 60
local function update_symbols(buf, client, ttl)
  ttl = ttl or configs.opts.sources.lsp.request.ttl_init
  if
    ttl <= 0
    or not vim.api.nvim_buf_is_valid(buf)
    or not vim.b[buf].dropbar_lsp_attached
  then
    lsp_buf_symbols[buf] = nil
    return
  end
  local textdocument_params = vim.lsp.util.make_text_document_params(buf)
  client.request(
    'textDocument/documentSymbol',
    { textDocument = textdocument_params },
    function(err, symbols, _)
      if err or not symbols or vim.tbl_isempty(symbols) then
        vim.defer_fn(function()
          update_symbols(buf, client, ttl - 1)
        end, configs.opts.sources.lsp.request.interval)
      else -- Update symbol_list
        lsp_buf_symbols[buf] = symbols
        for _, dropbar in pairs(_G.dropbar.bars[buf]) do
          dropbar:update() -- Redraw dropbar after updating symbols
        end
      end
    end,
    buf
  )
end

---Attach LSP symbol getter to buffer
---@param buf integer buffer handler
local function attach(buf)
  if vim.b[buf].dropbar_lsp_attached then
    return
  end
  local function _update()
    local client = vim.tbl_filter(function(client)
      return client.supports_method('textDocument/documentSymbol')
    end, vim.lsp.get_active_clients({ bufnr = buf }))[1]
    update_symbols(buf, client)
  end
  vim.b[buf].dropbar_lsp_attached = vim.api.nvim_create_autocmd(
    { 'TextChanged', 'TextChangedI' },
    {
      group = groupid,
      buffer = buf,
      callback = _update,
    }
  )
  _update()
end

---Detach LSP symbol getter from buffer
---@param buf integer buffer handler
local function detach(buf)
  if vim.b[buf].dropbar_lsp_attached then
    vim.api.nvim_del_autocmd(vim.b[buf].dropbar_lsp_attached)
    vim.b[buf].dropbar_lsp_attached = nil
    lsp_buf_symbols[buf] = nil
    for _, dropbar in pairs(_G.dropbar.bars[buf]) do
      dropbar:update()
    end
  end
end

---Initialize lsp source
---@return nil
local function init()
  if initialized then
    return
  end
  initialized = true
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local clients = vim.tbl_filter(function(client)
      return client.supports_method('textDocument/documentSymbol')
    end, vim.lsp.get_active_clients({ bufnr = buf }))
    if not vim.tbl_isempty(clients) then
      attach(buf)
    end
  end
  vim.api.nvim_create_autocmd({ 'LspAttach' }, {
    desc = 'Attach LSP symbol getter to buffer when an LS that supports documentSymbol attaches.',
    group = groupid,
    callback = function(info)
      local client =
        vim.lsp.get_client_by_id(info.data and info.data.client_id)
      if client and client.supports_method('textDocument/documentSymbol') then
        attach(info.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ 'LspDetach' }, {
    desc = 'Detach LSP symbol getter from buffer when no LS supporting documentSymbol is attached.',
    group = groupid,
    callback = function(info)
      if
        vim.tbl_isempty(vim.tbl_filter(function(client)
          return client.supports_method('textDocument/documentSymbol')
            and client.id ~= info.data.client_id
        end, vim.lsp.get_active_clients({ bufnr = info.buf })))
      then
        detach(info.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufUnload', 'BufWipeOut' }, {
    desc = 'Detach LSP symbol getter from buffer on buffer delete/unload/wipeout.',
    group = groupid,
    callback = function(info)
      detach(info.buf)
    end,
  })
end

---Get dropbar symbols from buffer according to cursor position
---@param buf integer buffer handler
---@param cursor integer[] cursor position
---@return dropbar_symbol_t[] symbols dropbar symbols
local function get_symbols(buf, cursor)
  if not initialized then
    init()
  end
  return convert(lsp_buf_symbols[buf], cursor)
end

return {
  get_symbols = get_symbols,
}
