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
---@param text string
---@return string
local function extract_short_name(text)
  return vim
    .trim(vim.fn.matchstr(text, configs.opts.sources.treesitter.name_regex))
    :gsub('%s+', ' ')
end

---@param node TSNode
---@return { start: { line: integer, character: integer }, ['end']: { line: integer, character: integer } }
local function get_node_range(node)
  local range = { node:range() }
  return {
    start = {
      line = range[1],
      character = range[2],
    },
    ['end'] = {
      line = range[3],
      character = range[4],
    },
  }
end

---@param node TSNode
---@param buf integer
---@return { name: string, source_range?: { start: { line: integer, character: integer }, ['end']: { line: integer, character: integer } } }
local function resolve_node_short_name(node, buf)
  local function has_anonymous_only_children(candidate)
    return candidate:child_count() > 0 and candidate:named_child_count() == 0
  end

  local has_named_children = false
  local named_children = {} ---@type TSNode[]
  local node_start_line = select(1, node:range())

  for child, field_name in node:iter_children() do
    if child:named() then
      if has_anonymous_only_children(child) then
        goto continue
      end

      has_named_children = true
      table.insert(named_children, child)

      if field_name then
        local name = extract_short_name(
          vim.treesitter.get_node_text(child, buf):gsub('\n', ' ')
        )
        if name ~= '' then
          return {
            name = name,
            source_range = get_node_range(child),
          }
        end
      end
    end

    ::continue::
  end

  for _, child in ipairs(named_children) do
    local child_start_line = select(1, child:range())
    if child_start_line ~= node_start_line then
      goto continue
    end

    local name = extract_short_name(
      vim.treesitter.get_node_text(child, buf):gsub('\n', ' ')
    )
    if name ~= '' then
      return {
        name = name,
        source_range = get_node_range(child),
      }
    end

    ::continue::
  end

  if has_named_children then
    return { name = '' }
  end

  local name =
    extract_short_name(vim.treesitter.get_node_text(node, buf):gsub('\n', ' '))
  if name == '' then
    return { name = '' }
  end

  return {
    name = name,
    source_range = get_node_range(node),
  }
end

---@param node TSNode
---@param buf integer buffer handler
---@return string name
local function get_node_short_name(node, buf)
  return resolve_node_short_name(node, buf).name
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

---@param a_pos { line: integer, character: integer }
---@param b_pos { line: integer, character: integer }
---@return integer
local function compare_pos(a_pos, b_pos)
  if a_pos.line ~= b_pos.line then
    return a_pos.line < b_pos.line and -1 or 1
  end
  if a_pos.character ~= b_pos.character then
    return a_pos.character < b_pos.character and -1 or 1
  end
  return 0
end

---@param lhs_pos { line: integer, character: integer }
---@param rhs_pos { line: integer, character: integer }
---@param max_offset integer
---@return boolean
local function pos_matches_with_offset(lhs_pos, rhs_pos, max_offset)
  return lhs_pos.line == rhs_pos.line
    and math.abs(lhs_pos.character - rhs_pos.character) <= max_offset
end

---@param outer dropbar_symbol_t
---@param inner dropbar_symbol_t
---@return boolean
local function range_contains(outer, inner)
  return compare_pos(outer.range.start, inner.range.start) <= 0
    and compare_pos(outer.range['end'], inner.range['end']) >= 0
end

---@param lhs_range { start: { line: integer, character: integer }, ['end']: { line: integer, character: integer } }
---@param rhs_range { start: { line: integer, character: integer }, ['end']: { line: integer, character: integer } }
---@return boolean
local function range_boundary_matches(lhs_range, rhs_range)
  return pos_matches_with_offset(lhs_range.start, rhs_range.start, 2)
    or pos_matches_with_offset(lhs_range['end'], rhs_range['end'], 2)
end

---@param outer_range { start: { line: integer, character: integer }, ['end']: { line: integer, character: integer } }
---@param inner_range { start: { line: integer, character: integer }, ['end']: { line: integer, character: integer } }
---@return boolean
local function range_contains_range(outer_range, inner_range)
  return compare_pos(outer_range.start, inner_range.start) <= 0
    and compare_pos(outer_range['end'], inner_range['end']) >= 0
end

---@param lhs dropbar_symbol_t
---@param rhs dropbar_symbol_t
---@return boolean
local function should_dedupe_adjacent(lhs, rhs)
  if lhs.name ~= rhs.name or lhs.name == '' then
    return false
  end

  if lhs.name_source and rhs.name_source then
    if range_boundary_matches(lhs.name_source, rhs.name_source) then
      return true
    end
  end

  local same_start = compare_pos(lhs.range.start, rhs.range.start) == 0
  local same_end = compare_pos(lhs.range['end'], rhs.range['end']) == 0
  if not same_start and not same_end then
    return false
  end

  return range_contains(lhs, rhs) or range_contains(rhs, lhs)
end

---@param symbols dropbar_symbol_t[]
---@return dropbar_symbol_t[]
local function dedupe_adjacent_symbols(symbols)
  if #symbols < 2 then
    return symbols
  end

  local deduped = { symbols[1] }
  for i = 2, #symbols do
    local current = symbols[i]
    local previous = deduped[#deduped]

    if
      previous.name_source
      and current.name_source
      and range_contains_range(previous.name_source, current.name_source)
    then
      local same_start = compare_pos(
        previous.name_source.start,
        current.name_source.start
      ) == 0
      local current_ends_earlier = compare_pos(
        current.name_source['end'],
        previous.name_source['end']
      ) < 0
      if
        same_start
        and current_ends_earlier
        and previous.name_source['end'].line
          ~= current.name_source['end'].line
      then
        deduped[#deduped] = current
        goto continue
      end

      if
        previous.name_source.start.line == current.name_source.start.line
        and previous.name_source['end'].line
          == current.name_source['end'].line
      then
        goto continue
      end
    end

    if should_dedupe_adjacent(previous, current) then
      local previous_contains_current = range_contains(previous, current)
      local current_contains_previous = range_contains(current, previous)
      if previous_contains_current and not current_contains_previous then
        -- Keep narrower symbol when names overlap.
        deduped[#deduped] = current
      elseif current_contains_previous and not previous_contains_current then
        -- Keep narrower symbol when names overlap.
        deduped[#deduped] = previous
      else
        -- Equal ranges: keep the deeper (later) symbol.
        deduped[#deduped] = current
      end
    else
      table.insert(deduped, current)
    end

    ::continue::
  end

  return deduped
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
  local short_type = get_node_short_type(ts_node)
  if short_type == '' then
    return nil
  end

  local name_info = resolve_node_short_name(ts_node, buf)
  if name_info.name == '' then
    return nil
  end

  local kind = snake_to_camel(short_type)
  return bar.dropbar_symbol_t:new(setmetatable({
    buf = buf,
    win = win,
    kind = kind,
    name = name_info.name,
    name_source = name_info.source_range,
    icon = configs.opts.icons.kinds.symbols[kind],
    name_hl = 'DropBarKind' .. kind,
    icon_hl = 'DropBarIconKind' .. kind,
    range = get_node_range(ts_node),
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

  symbols = dedupe_adjacent_symbols(symbols)

  utils.bar.set_min_widths(symbols, configs.opts.sources.treesitter.min_widths)
  return symbols
end

return { get_symbols = get_symbols }
