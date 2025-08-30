local configs = require('dropbar.configs')
local bar = require('dropbar.bar')
local utils = require('dropbar.utils')

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
---@return string name
local function get_node_short_name(node, buf)
  return (
    vim
      .trim(
        vim.fn.matchstr(
          vim.treesitter.get_node_text(node, buf):gsub('\n', ' '),
          configs.opts.sources.treesitter.name_regex
        )
      )
      :gsub('%s+', ' ')
  )
end

---Get valid treesitter node type name
---@param node TSNode
---@return string type_name
local function get_node_short_type(node)
  local ts_type = node:type()
  for _, type in ipairs(configs.opts.sources.treesitter.valid_types) do
    if vim.startswith(ts_type, type) then
      return type
    end
  end
  return ''
end

---Check if treesitter node is valid
---@param node TSNode
---@param buf integer buffer handler
---@return boolean
local function valid_node(node, buf)
  return get_node_short_type(node) ~= ''
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

  local current = node ---@type TSNode?
  while current do
    if valid_node(current, buf) then
      table.insert(siblings, 1, current)
    else
      siblings = vim.list_extend(get_node_children(current, buf), siblings)
    end
    current = current:prev_sibling()
  end
  local idx = #siblings

  current = node:next_sibling()
  while current do
    if valid_node(current, buf) then
      table.insert(siblings, current)
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
      end

      if k == 'siblings' or k == 'sibling_idx' then
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
  buf = vim._resolve_bufnr(buf)
  if
    not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win)
  then
    return {}
  end

  local ts_ok = pcall(vim.treesitter.get_parser, buf or 0)
  if not ts_ok then
    return {}
  end

  local symbols = {} ---@type dropbar_symbol_t[]

  -- Prevent errors when getting node from filetypes without a parser
  local node = vim.F.npcall(vim.treesitter.get_node, {
    ft = vim.filetype.match({ buf = buf }),
    bufnr = buf,
    pos = {
      cursor[1] - 1,
      cursor[2]
        - (cursor[2] >= 1 and vim.startswith(vim.fn.mode(), 'i') and 1 or 0),
    },
  })

  while node and #symbols < configs.opts.sources.treesitter.max_depth do
    if valid_node(node, buf) then
      table.insert(symbols, 1, convert(node, buf, win))
    end
    node = node:parent()
  end

  utils.bar.set_min_widths(symbols, configs.opts.sources.treesitter.min_widths)
  return symbols
end

return { get_symbols = get_symbols }
