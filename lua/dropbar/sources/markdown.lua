local utils = require('dropbar.sources.utils')
local configs = require('dropbar.configs')

local initialized = false
local groupid = vim.api.nvim_create_augroup('DropBarMarkdown', {})

---@class markdown_heading_symbol_t
---@field name string
---@field level number
---@field lnum number
local markdown_heading_symbol_t = {}
markdown_heading_symbol_t.__index = markdown_heading_symbol_t

---Create a new markdown heading symbol object
---@param opts markdown_heading_symbol_t?
---@return markdown_heading_symbol_t
function markdown_heading_symbol_t:new(opts)
  return setmetatable(
    vim.tbl_deep_extend('force', {
      name = '',
      level = 0,
      lnum = 0,
    }, opts or {}),
    self
  )
end

---@class markdown_heading_symbols_parsed_list_t
---@field end { lnum: number, inside_code_block: boolean }
---@field symbols markdown_heading_symbol_t[]
local markdown_heading_symbols_parsed_list_t = {}
markdown_heading_symbols_parsed_list_t.__index =
  markdown_heading_symbols_parsed_list_t

---Create a new markdown heading symbols parsed object
---@param opts markdown_heading_symbols_parsed_list_t?
function markdown_heading_symbols_parsed_list_t:new(opts)
  return setmetatable(
    vim.tbl_deep_extend('force', {
      ['end'] = { lnum = 0, inside_code_block = false },
      symbols = {},
    }, opts or {}),
    self
  )
end

---@type markdown_heading_symbols_parsed_list_t[]
local markdown_heading_buf_symbols = {}
setmetatable(markdown_heading_buf_symbols, {
  __index = function(_, k)
    markdown_heading_buf_symbols[k] =
      markdown_heading_symbols_parsed_list_t:new()
    return markdown_heading_buf_symbols[k]
  end,
})

---Parse markdown file and update markdown heading symbols
---Side effect: change markdown_heading_buf_symbols
---@param buf integer buffer handler
---@param lnum_end integer update symbols backward from this line (1-based, inclusive)
---@param incremental? boolean incremental parsing
---@return nil
local function parse_buf(buf, lnum_end, incremental)
  local symbols_parsed = markdown_heading_buf_symbols[buf]
  local lnum_start = symbols_parsed['end'].lnum
  if not incremental then
    lnum_start = 0
    symbols_parsed.symbols = {}
    symbols_parsed['end'] = { lnum = 0, inside_code_block = false }
  end
  local lines = vim.api.nvim_buf_get_lines(buf, lnum_start, lnum_end, false)
  symbols_parsed['end'].lnum = lnum_start + #lines + 1

  for idx, line in ipairs(lines) do
    if line:match('^```') then
      symbols_parsed['end'].inside_code_block =
        not symbols_parsed['end'].inside_code_block
    end
    if not symbols_parsed['end'].inside_code_block then
      local _, _, heading_notation, heading_str = line:find('^(#+)%s+(.*)')
      local level = heading_notation and #heading_notation or 0
      if level >= 1 and level <= 6 then
        table.insert(
          symbols_parsed.symbols,
          markdown_heading_symbol_t:new({
            name = heading_str,
            level = #heading_notation,
            lnum = idx + lnum_start,
          })
        )
      end
    end
  end
end

---Unify markdown heading symbol into dropbar symbol tree format
---@param symbol markdown_heading_symbol_t markdown heading symbol
---@param symbols markdown_heading_symbol_t[] markdown heading symbols
---@param list_idx integer index of the symbol in the symbols list
---@param buf integer buffer handler
---@return dropbar_symbol_tree_t
local function unify(symbol, symbols, list_idx, buf)
  return setmetatable({
    name = symbol.name,
    kind = 'MarkdownH' .. symbol.level,
    data = { symbol = symbol },
  }, {
    ---@param self dropbar_symbol_tree_t
    __index = function(self, k)
      parse_buf(buf, -1, true) -- Parse whole buffer before opening menu
      if k == 'children' then
        self.children = {}
        local lev = symbol.level
        for i, heading in vim.iter(symbols):enumerate():skip(list_idx) do
          if heading.level <= symbol.level then
            break
          end
          if i == list_idx + 1 or heading.level < lev then
            lev = heading.level
          end
          if heading.level <= lev then
            table.insert(self.children, unify(heading, symbols, i, buf))
          end
        end
        return self.children
      end
      if k == 'siblings' or k == 'idx' then
        self.siblings = { self }
        for i = list_idx - 1, 1, -1 do
          if symbols[i].level < symbol.level then
            break
          end
          if symbols[i].level < self.siblings[1].data.symbol.level then
            while symbols[i].level < self.siblings[1].data.symbol.level do
              table.remove(self.siblings, 1)
            end
            table.insert(self.siblings, 1, unify(symbols[i], symbols, i, buf))
          else
            table.insert(self.siblings, 1, unify(symbols[i], symbols, i, buf))
          end
        end
        self.idx = #self.siblings
        for i = list_idx + 1, #symbols do
          if symbols[i].level < symbol.level then
            break
          end
          if symbols[i].level == symbol.level then
            table.insert(self.siblings, unify(symbols[i], symbols, i, buf))
          end
        end
        return self[k]
      end
      if k == 'range' then
        self.range = {
          start = {
            line = symbol.lnum - 1,
            character = 0,
          },
          ['end'] = {
            line = symbol.lnum - 1,
            character = 0,
          },
        }
        for heading in vim.iter(symbols):skip(list_idx) do
          if heading.level <= symbol.level then
            self.range['end'] = {
              line = heading.lnum - 2,
              character = 0,
            }
            break
          end
        end
        return self.range
      end
    end,
  })
end

---Convert markdown heading symbols into a list of dropbar symbols according to
---cursor position
---@param symbols markdown_heading_symbol_t[] markdown heading symbols
---@param buf integer buffer handler
---@param cursor integer[] cursor position
---@return dropbar_symbol_t[]
local function convert(symbols, buf, cursor)
  local result = {}
  local current_level = 7
  for idx, symbol in vim.iter(symbols):enumerate():rev() do
    if symbol.lnum <= cursor[1] and symbol.level < current_level then
      current_level = symbol.level
      table.insert(
        result,
        1,
        utils.to_dropbar_symbol(unify(symbol, symbols, idx, buf))
      )
      if current_level == 1 then
        break
      end
    end
  end
  return result
end

---Attach markdown heading parser to buffer
---@param buf integer buffer handler
---@return nil
local function attach(buf)
  if vim.b[buf].dropbar_markdown_heading_parser_attached then
    return
  end
  local function _update()
    local cursor = vim.api.nvim_win_get_cursor(0)
    parse_buf(buf, cursor[1])
  end
  vim.b[buf].dropbar_markdown_heading_parser_attached = vim.api.nvim_create_autocmd(
    { 'TextChanged', 'TextChangedI' },
    {
      desc = 'Update markdown heading symbols on buffer change.',
      group = groupid,
      buffer = buf,
      callback = _update,
    }
  )
  _update()
end

---Detach markdown heading parser from buffer
---@param buf integer buffer handler
---@return nil
local function detach(buf)
  if vim.b[buf].dropbar_markdown_heading_parser_attached then
    vim.api.nvim_del_autocmd(
      vim.b[buf].dropbar_markdown_heading_parser_attached
    )
    vim.b[buf].dropbar_markdown_heading_parser_attached = nil
    markdown_heading_buf_symbols[buf] = nil
  end
end

---Initialize markdown heading source
---@return nil
local function init()
  if initialized then
    return
  end
  initialized = true
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].filetype == 'markdown' then
      attach(buf)
    end
  end
  vim.api.nvim_create_autocmd({ 'FileType' }, {
    desc = 'Attach markdown heading parser to markdown buffers.',
    group = groupid,
    callback = function(info)
      if info.match == 'markdown' then
        attach(info.buf)
      else
        detach(info.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufUnload', 'BufWipeOut' }, {
    desc = 'Detach markdown heading parser from buffer on buffer delete/unload/wipeout.',
    group = groupid,
    callback = function(info)
      if vim.bo[info.buf].filetype == 'markdown' then
        detach(info.buf)
      end
    end,
  })
end

---Get dropbar symbols from buffer according to cursor position
---@param buf integer buffer handler
---@param cursor integer[] cursor position
---@return dropbar_symbol_t[] symbols dropbar symbols
local function get_symbols(buf, cursor)
  if vim.bo[buf].filetype ~= 'markdown' then
    return {}
  end
  if not initialized then
    init()
  end
  local buf_symbols = markdown_heading_buf_symbols[buf]
  if buf_symbols['end'].lnum < cursor[1] then
    parse_buf(
      buf,
      cursor[1] + configs.opts.sources.markdown.parse.look_ahead,
      true
    )
  end
  return convert(buf_symbols.symbols, buf, cursor)
end

return {
  get_symbols = get_symbols,
}
