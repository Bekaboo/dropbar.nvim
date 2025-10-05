local configs = require('dropbar.configs')
local bar = require('dropbar.bar')
local utils = require('dropbar.utils')
local groupid = vim.api.nvim_create_augroup('dropbar.sources.lsp', {})
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

---@class lsp_symbol_information_tree_t: lsp_symbol_information_t
---@field parent? lsp_symbol_information_tree_t
---@field children? lsp_symbol_information_tree_t[]
---@field siblings? lsp_symbol_information_tree_t[]

---@alias lsp_symbol_t lsp_document_symbol_t|lsp_symbol_information_t

-- Map symbol number to symbol kind
-- stylua: ignore start
local symbol_kind_names = setmetatable({
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
}, {
  __index = function()
    return ''
  end,
})
-- stylua: ignore end

---@alias lsp_symbol_type_t 'SymbolInformation'|'DocumentSymbol'

---Return type of the symbol table
---@param symbols lsp_symbol_t[] symbol table
---@return lsp_symbol_type_t? type symbol type
local function symbol_type(symbols)
  if symbols[1] and symbols[1].location then
    return 'SymbolInformation'
  end
  if symbols[1] and symbols[1].range then
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

---Convert LSP DocumentSymbol into winbar symbol
---@param document_symbol lsp_document_symbol_t LSP DocumentSymbol
---@param buf integer buffer number
---@param win integer window number
---@param siblings lsp_document_symbol_t[]? siblings of the symbol
---@param idx integer? index of the symbol in siblings
---@return dropbar_symbol_t
local function convert_document_symbol(
  document_symbol,
  buf,
  win,
  siblings,
  idx
)
  local kind = symbol_kind_names[document_symbol.kind]
  return bar.dropbar_symbol_t:new(setmetatable({
    buf = buf,
    win = win,
    name = document_symbol.name,
    icon = configs.opts.icons.kinds.symbols[kind],
    name_hl = 'DropBarKind' .. kind,
    icon_hl = 'DropBarIconKind' .. kind,
    range = document_symbol.range,
    sibling_idx = idx,
  }, {
    __index = function(self, k)
      if k == 'children' then
        if not document_symbol.children then
          return nil
        end
        self.children = vim.tbl_map(function(child)
          return convert_document_symbol(child, buf, win)
        end, document_symbol.children)
        return self.children
      end

      if k == 'siblings' then
        if not siblings then
          return nil
        end
        self.siblings = vim.tbl_map(function(sibling)
          return convert_document_symbol(sibling, buf, win, siblings)
        end, siblings)
        return self.siblings
      end
    end,
  }))
end

---Convert LSP DocumentSymbol[] into a list of dropbar symbols
---Side effect: change dropbar_symbols
---LSP Specification document: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/
---@param lsp_symbols lsp_document_symbol_t[]
---@param dropbar_symbols dropbar_symbol_t[] (reference to) dropbar symbols
---@param buf integer buffer number
---@param win integer window number
---@param cursor integer[] cursor position
local function convert_document_symbol_list(
  lsp_symbols,
  dropbar_symbols,
  buf,
  win,
  cursor
)
  if #dropbar_symbols >= configs.opts.sources.lsp.max_depth then
    return
  end

  -- Parse in reverse order so that the symbol with the largest start position
  -- is preferred
  for idx, symbol in vim.iter(lsp_symbols):enumerate():rev() do
    if cursor_in_range(cursor, symbol.range) then
      if
        vim.tbl_contains(
          configs.opts.sources.lsp.valid_symbols,
          symbol_kind_names[symbol.kind]
        )
      then
        table.insert(
          dropbar_symbols,
          convert_document_symbol(symbol, buf, win, lsp_symbols, idx)
        )
      end
      if symbol.children then
        convert_document_symbol_list(
          symbol.children,
          dropbar_symbols,
          buf,
          win,
          cursor
        )
      end
      return
    end
  end
end

---Convert LSP SymbolInformation[] into DocumentSymbol[]
---@param symbols lsp_symbol_t LSP symbols
---@return lsp_document_symbol_t[]
local function unify(symbols)
  if symbol_type(symbols) == 'DocumentSymbol' or vim.tbl_isempty(symbols) then
    return symbols
  end
  -- Convert SymbolInformation[] to DocumentSymbol[]
  for _, sym in ipairs(symbols) do
    sym.range = sym.location.range
  end
  local document_symbols = { symbols[1] }
  -- According to the result get from pylsp, the SymbolInformation list is
  -- ordered in increasing order by the start position of the range, so a
  -- symbol can only be a child or a sibling of the previous symbol in the
  -- same list
  for list_idx, sym in vim.iter(symbols):enumerate():skip(1) do
    local prev = symbols[list_idx - 1] --[[@as lsp_symbol_information_tree_t]]
    -- If the symbol is a child of the previous symbol
    if range_contains(prev.location.range, sym.location.range) then
      sym.parent = prev
    else -- Else the symbol is a sibling of the previous symbol
      sym.parent = prev.parent
    end
    if sym.parent then
      sym.parent.children = sym.parent.children or {}
      table.insert(sym.parent.children, sym)
    else
      table.insert(document_symbols, sym)
    end
  end
  return document_symbols
end

---Update LSP symbols from an LSP client
---Side effect: update symbol_list
---@param buf integer buffer handler
---@param ttl integer? limit the number of recursive requests, default 60
local function update_symbols(buf, ttl)
  ttl = ttl or configs.opts.sources.lsp.request.ttl_init
  if ttl <= 0 or not vim.api.nvim_buf_is_valid(buf) then
    lsp_buf_symbols[buf] = nil
    return
  end

  local function defer_update_symbols()
    vim.defer_fn(function()
      update_symbols(buf, ttl - 1)
    end, configs.opts.sources.lsp.request.interval)
  end

  local client = vim.lsp.get_clients({
    bufnr = buf,
    method = 'textDocument/documentSymbol',
  })[1]
  if not client then
    defer_update_symbols()
    return
  end

  ---@diagnostic disable: param-type-mismatch, inject-field
  -- Cancel previous request before making new request since
  -- responses from outdated requests are not helpful, fix
  -- https://github.com/Bekaboo/dropbar.nvim/issues/249
  if client._dropbar_request_id then
    client:cancel_request(client._dropbar_request_id)
  end

  local _, request_id = client:request(
    'textDocument/documentSymbol',
    { textDocument = vim.lsp.util.make_text_document_params(buf) },
    function(err, symbols, _)
      if err or not symbols or vim.tbl_isempty(symbols) then
        defer_update_symbols()
        return
      end

      -- Unify symbols to common format and sort by position since LSP
      -- responses can be disordered i.e. later symbols can appear first
      lsp_buf_symbols[buf] = unify(symbols)

      ---@param s1 lsp_document_symbol_t
      ---@param s2 lsp_document_symbol_t
      ---@return boolean precedes true if `s1` appears before `s2`
      table.sort(lsp_buf_symbols[buf], function(s1, s2)
        local l1, l2, c1, c2 =
          s1.range.start.line,
          s2.range.start.line,
          s1.range.start.character,
          s2.range.start.character

        -- Pitfall: don't use `l1 == l2 and c1 <= c2` here as sort algorithm is
        -- not stable and we shouldn't return `true` for two elements with equal
        -- total order, i.e. symbols with the same start position (both line &
        -- column), else lua will throw the error: 'invalid order function for
        -- sorting', see:
        -- - https://blog.csdn.net/twwk120120/article/details/102697411
        -- - https://www.lua.org/manual/5.4/manual.html#pdf-table.sort
        return l1 < l2 or l1 == l2 and c1 < c2
      end)
    end,
    buf
  )
  client._dropbar_request_id = request_id
  ---@diagnostic enable: param-type-mismatch, inject-field
end

---Attach LSP symbol getter to buffer
---@param buf integer buffer handler
local function attach(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  if vim.b[buf].dropbar_lsp_attached then
    return
  end

  update_symbols(buf)
  vim.b[buf].dropbar_lsp_attached =
    vim.api.nvim_create_autocmd(configs.opts.bar.update_events.buf, {
      group = groupid,
      buffer = buf,
      callback = function(args)
        update_symbols(args.buf)
      end,
    })
end

---Detach LSP symbol getter from buffer
---@param buf integer buffer handler
local function detach(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

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
    if
      not vim.tbl_isempty(vim.lsp.get_clients({
        bufnr = buf,
        method = 'textDocument/documentSymbol',
      }))
    then
      attach(buf)
    end
  end

  vim.api.nvim_create_autocmd({ 'LspAttach' }, {
    desc = 'Attach LSP symbol getter to buffer when an LS that supports documentSymbol attaches.',
    group = groupid,
    callback = function(args)
      local id = args.data and args.data.client_id
      if not id then
        return
      end
      local client = vim.lsp.get_client_by_id(id)
      if client and client:supports_method('textDocument/documentSymbol') then
        attach(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'LspDetach' }, {
    desc = 'Detach LSP symbol getter from buffer when no LS supporting documentSymbol is attached.',
    group = groupid,
    -- Schedule to wait for lsp that triggers `LspDetach` to actually detach
    callback = vim.schedule_wrap(function(args)
      if
        vim.tbl_isempty(vim.lsp.get_clients({
          bufnr = args.buf,
          method = 'textDocument/documentSymbol',
        }))
      then
        detach(args.buf)
      end
    end),
  })

  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufUnload', 'BufWipeOut' }, {
    desc = 'Detach LSP symbol getter from buffer on buffer delete/unload/wipeout.',
    group = groupid,
    callback = function(args)
      detach(args.buf)
    end,
  })
end

---@param buf integer buffer handler
---@param win integer window handler
---@param cursor integer[] cursor position
---@return dropbar_symbol_t[] symbols dropbar symbols
local function get_symbols(buf, win, cursor)
  buf = vim._resolve_bufnr(buf)
  if
    not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win)
  then
    return {}
  end

  if not initialized then
    init()
  end

  local result = {}
  convert_document_symbol_list(lsp_buf_symbols[buf], result, buf, win, cursor)
  utils.bar.set_min_widths(result, configs.opts.sources.lsp.min_widths)
  return result
end

return { get_symbols = get_symbols }
