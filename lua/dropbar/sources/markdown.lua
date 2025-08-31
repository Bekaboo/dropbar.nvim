local configs = require('dropbar.configs')
local bar = require('dropbar.bar')
local utils = require('dropbar.utils')

local initialized = false
local groupid = vim.api.nvim_create_augroup('dropbar.sources.markdown', {})

---@class markdown_heading_symbol_t
---@field name string
---@field level integer
---@field lnum integer
local markdown_heading_symbol_t = {}
markdown_heading_symbol_t.__index = markdown_heading_symbol_t

---@class markdown_heading_symbol_opts_t
---@field name? string
---@field level? integer
---@field lnum? integer

---Create a new markdown heading symbol object
---@param opts markdown_heading_symbol_opts_t?
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
---@field end { lnum: integer, inside_code_block: boolean }
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
---@param buf? integer buffer handler
---@param lnum_end? integer update symbols backward from this line (1-based, inclusive), default to cursor line number
---@param incremental? boolean incremental parsing
---@return nil
local function parse_buf(buf, lnum_end, incremental)
  buf = vim._resolve_bufnr(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  lnum_end = lnum_end or vim.fn.line('.')
  if not vim.api.nvim_buf_is_valid(buf) then
    markdown_heading_buf_symbols[buf] = nil
    return
  end

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

---Convert a markdown heading symbol into a dropbar symbol
---@param symbol markdown_heading_symbol_t markdown heading symbol
---@param symbols markdown_heading_symbol_t[] markdown heading symbols
---@param list_idx integer index of the symbol in the symbols list
---@param buf integer buffer handler
---@param win integer window handler
---@return dropbar_symbol_t
local function convert(symbol, symbols, list_idx, buf, win)
  local kind = 'MarkdownH' .. symbol.level
  return bar.dropbar_symbol_t:new(setmetatable({
    buf = buf,
    win = win,
    name = symbol.name,
    icon = configs.opts.icons.kinds.symbols[kind],
    name_hl = 'DropBarKind' .. kind,
    icon_hl = 'DropBarIconKind' .. kind,
    data = {
      heading_symbol = symbol,
    },
  }, {
    ---@param self dropbar_symbol_t
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
            table.insert(self.children, convert(heading, symbols, i, buf, win))
          end
        end
        return self.children
      end
      if k == 'siblings' or k == 'idx' then
        self.siblings = { convert(symbol, symbols, list_idx, buf, win) }
        for i = list_idx - 1, 1, -1 do
          if symbols[i].level < symbol.level then
            break
          end
          if symbols[i].level < self.siblings[1].data.heading_symbol.level then
            while
              symbols[i].level
              < self.siblings[1].data.heading_symbol.level
            do
              table.remove(self.siblings, 1)
            end
            table.insert(
              self.siblings,
              1,
              convert(symbols[i], symbols, i, buf, win)
            )
          else
            table.insert(
              self.siblings,
              1,
              convert(symbols[i], symbols, i, buf, win)
            )
          end
        end
        self.sibling_idx = #self.siblings
        for i = list_idx + 1, #symbols do
          if symbols[i].level < symbol.level then
            break
          end
          if symbols[i].level == symbol.level then
            table.insert(
              self.siblings,
              convert(symbols[i], symbols, i, buf, win)
            )
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
            line = vim.api.nvim_buf_line_count(buf),
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
  }))
end

---Attach markdown heading parser to buffer
---@param buf integer buffer handler
---@return nil
local function attach(buf)
  if
    not vim.api.nvim_buf_is_valid(buf)
    or vim.bo[buf].ft ~= 'markdown'
    or vim.b[buf].dropbar_markdown_heading_parser_attached
  then
    return
  end

  vim.b[buf].dropbar_markdown_heading_parser_attached =
    vim.api.nvim_create_autocmd(configs.opts.bar.update_events.buf, {
      desc = 'Update markdown heading symbols on buffer change.',
      group = groupid,
      buffer = buf,
      callback = function(args)
        parse_buf(args.buf)
      end,
    })
  parse_buf(buf)
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
    callback = function(args)
      if args.match == 'markdown' then
        attach(args.buf)
      else
        detach(args.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufUnload', 'BufWipeOut' }, {
    desc = 'Detach markdown heading parser from buffer on buffer delete/unload/wipeout.',
    group = groupid,
    callback = function(args)
      if vim.bo[args.buf].filetype == 'markdown' then
        detach(args.buf)
      end
    end,
  })
end

---Get dropbar symbols from buffer according to cursor position
---@param buf integer buffer handler
---@param win integer window handler
---@param cursor integer[] cursor position
---@return dropbar_symbol_t[] symbols dropbar symbols
local function get_symbols(buf, win, cursor)
  buf = vim._resolve_bufnr(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return {}
  end

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

  local result = {}
  local current_level = 7
  for idx, symbol in vim.iter(buf_symbols.symbols):enumerate():rev() do
    if #result >= configs.opts.sources.markdown.max_depth then
      break
    end
    if symbol.lnum <= cursor[1] and symbol.level < current_level then
      current_level = symbol.level
      table.insert(
        result,
        1,
        convert(symbol, buf_symbols.symbols, idx, buf, win)
      )
      if current_level == 1 then
        break
      end
    end
  end
  utils.bar.set_min_widths(result, configs.opts.sources.markdown.min_widths)
  return result
end

return { get_symbols = get_symbols }
