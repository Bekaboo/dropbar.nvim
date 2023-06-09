local configs = require('dropbar.configs')
local bar = require('dropbar.bar')

---Convert a snake_case string to camelCase
---@param str string?
---@return string?
local function snake_to_camel(str)
  if not str then
    return nil
  end
  return (
    str:gsub('^%l', string.upper):gsub('_%l', string.upper):gsub('_', '')
  )
end

---Get short name of treesitter symbols in buffer buf
---@param node TSNode
---@param buf integer buffer handler
local function get_node_short_name(node, buf)
  return vim.trim(
    vim.treesitter
      .get_node_text(node, buf)
      :match(configs.opts.sources.treesitter.name_pattern)
      :gsub('\n.*', '')
  )
end

---Get valid treesitter node type name
---@param node TSNode
---@return string? type_name
---@return integer rank type rank
local function get_node_short_type(node)
  local ts_type = node:type()
  for i, type in ipairs(configs.opts.sources.treesitter.valid_types) do
    if ts_type:find(type, 1, true) then
      return type, i
    end
  end
  return nil, math.huge
end

---Check if treesitter node is valid
---@param node TSNode
---@param buf integer buffer handler
---@return boolean
local function valid_node(node, buf)
  return get_node_short_type(node) ~= nil
    and get_node_short_name(node, buf) ~= ''
end

---Get treesitter node children
---@param node TSNode
---@param buf integer buffer handler
---@return TSNode[] children
local function get_node_children(node, buf)
  local children = {}
  for child in node:iter_children() do
    if valid_node(child, buf) then
      table.insert(children, child)
    else
      vim.list_extend(children, get_node_children(child, buf))
    end
  end
  return children
end

---Get treesitter node siblings
---@param node TSNode
---@param buf integer buffer handler
---@return TSNode[] siblings
---@return integer idx index of the node in its siblings
local function get_node_siblings(node, buf)
  local siblings = {}
  local current = node
  while current do
    if valid_node(current, buf) then
      table.insert(siblings, 1, current)
    else
      vim.list_extend(siblings, get_node_children(current, buf))
    end
    current = current:prev_sibling()
  end
  local idx = #siblings
  current = node:next_sibling()
  while current do
    if valid_node(current, buf) then
      table.insert(siblings, 1, current)
    else
      vim.list_extend(siblings, get_node_children(current, buf))
    end
    current = current:next_sibling()
  end
  return siblings, idx
end

---Convert TSNode into winbar symbol structure
---@param ts_node TSNode
---@param buf integer buffer handler
---@param win integer window handler
---@return dropbar_symbol_t?
local function convert(ts_node, buf, win)
  if not valid_node(ts_node, buf) then
    return nil
  end
  local kind = snake_to_camel(get_node_short_type(ts_node))
  local range = { ts_node:range() }
  return bar.dropbar_symbol_t:new(setmetatable({
    buf = buf,
    win = win,
    name = get_node_short_name(ts_node, buf),
    icon = configs.opts.icons.kinds.symbols[kind],
    name_hl = 'DropBarKind' .. kind,
    icon_hl = 'DropBarIconKind' .. kind,
    range = {
      start = {
        line = range[1],
        character = range[2],
      },
      ['end'] = {
        line = range[3],
        character = range[4],
      },
    },
  }, {
    ---@param self dropbar_symbol_t
    ---@param k string|number
    __index = function(self, k)
      if k == 'children' then
        self.children = vim.tbl_map(function(child)
          return convert(child, buf, win)
        end, get_node_children(ts_node, buf))
        return self.children
      elseif k == 'siblings' or k == 'sibling_idx' then
        local siblings, idx = get_node_siblings(ts_node, buf)
        self.siblings = vim.tbl_map(function(sibling)
          return convert(sibling, buf, win)
        end, siblings)
        self.sibling_idx = idx
        return self[k]
      end
    end,
  }))
end

---Get treesitter symbols from buffer
---@param buf integer buffer handler
---@param win integer window handler
---@param cursor integer[] cursor position
---@return dropbar_symbol_t[] symbols winbar symbols
local function get_symbols(buf, win, cursor)
  if not vim.treesitter.highlighter.active[buf] then
    return {}
  end

  local symbols = {}
  local prev_type_rank = math.huge
  local prev_row = math.huge
  local current_node = vim.treesitter.get_node({
    bufnr = buf,
    pos = { cursor[1] - 1, cursor[2] },
  })
  while current_node do
    local name = get_node_short_name(current_node, buf)
    local type, type_rank = get_node_short_type(current_node)
    local range = { current_node:range() } ---@type Range4
    local start_row = range[1]
    local end_row = range[3]
    if
      valid_node(current_node, buf)
      and not (start_row == 0 and end_row == vim.fn.line('$'))
    then
      local lsp_type = snake_to_camel(type)
      if
        vim.tbl_isempty(symbols)
        or symbols[1].name ~= name
        or start_row < prev_row
      then
        table.insert(symbols, 1, convert(current_node, buf, win))
        prev_type_rank = type_rank
        prev_row = start_row
      elseif type_rank < prev_type_rank then
        symbols[1].icon = configs.opts.icons.kinds.symbols[lsp_type]
        symbols[1].icon_hl = 'DropBarIconKind' .. lsp_type
        symbols[1].name_hl = 'DropBarKind' .. lsp_type
        prev_type_rank = type_rank
        prev_row = start_row
      end
    end
    current_node = current_node:parent()
  end
  return symbols
end

return {
  get_symbols = get_symbols,
}
