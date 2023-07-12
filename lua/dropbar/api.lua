---Get the dropbar
---@param buf? integer
---@param win integer
---@return dropbar_t?
local function get_dropbar(buf, win)
  buf = buf or vim.api.nvim_win_get_buf(win)
  if rawget(_G.dropbar.bars, buf) then
    return rawget(_G.dropbar.bars[buf], win)
  end
end

---Get current dropbar
---@return dropbar_t?
local function get_current_dropbar()
  return get_dropbar(
    vim.api.nvim_get_current_buf(),
    vim.api.nvim_get_current_win()
  )
end

---Get dropbar menu
---@param win integer
---@return dropbar_menu_t?
local function get_dropbar_menu(win)
  return _G.dropbar.menus[win]
end

---Get current dropbar menu
---@return dropbar_menu_t?
local function get_current_dropbar_menu()
  return get_dropbar_menu(vim.api.nvim_get_current_win())
end

---Goto the start of context
---If `count` is 0, goto the start of current context, or the start at
---prev context if cursor is already at the start of current context;
---If `count` is positive, goto the start of `count` prev context
---@param count integer? default vim.v.count
local function goto_context_start(count)
  count = count or vim.v.count
  local bar = get_current_dropbar()
  if not bar or not bar.components or vim.tbl_isempty(bar.components) then
    return
  end
  local current_sym = bar.components[#bar.components]
  if not current_sym.range then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  if
    count == 0
    and current_sym.range.start.line == cursor[1] - 1
    and current_sym.range.start.character == cursor[2]
  then
    count = count + 1
  end
  while count > 0 do
    count = count - 1
    local prev_sym = bar.components[current_sym.bar_idx - 1]
    if not prev_sym or not prev_sym.range then
      break
    end
    current_sym = prev_sym
  end
  current_sym:jump()
end

---Open the menu of current context to select the next context
local function select_next_context()
  local bar = get_current_dropbar()
  if not bar or not bar.components or vim.tbl_isempty(bar.components) then
    return
  end
  bar:pick_mode_wrap(function()
    bar.components[#bar.components]:on_click()
  end)
end

---Pick a component from current dropbar
---@param idx integer?
local function pick(idx)
  local bar = get_current_dropbar()
  if bar then
    bar:pick(idx)
  end
end

---Open a prompt to fuzzy find a menu entry
---@param menu dropbar_menu_t
---@param opts table?
local function fuzzy_find(menu, opts)
  opts = opts or {}
  if not menu.win or not menu.buf or not menu.is_opened then
    return
  end
  if not jit then
    vim.notify('fzf-lib requires luaJIT', vim.log.levels.ERROR)
    return
  end

  -- 'nvim-telescope/telescope-fzf-native.nvim'
  local fzf = require('fzf_lib')
  if not fzf then
    vim.notify('fzf-lib is not installed', vim.log.levels.ERROR)
    return
  end

  local ns_name = 'DropBarFzf' .. tostring(menu.win)
  local augroup = vim.api.nvim_create_augroup(ns_name, { clear = true })
  local ns_id = vim.api.nvim_create_namespace(ns_name)

  local hl_group = opts.hl_group
  if not hl_group then
    local fg = vim.api.nvim_get_hl(0, { name = '@tag', link = false }).fg
    hl_group = {
      fg = fg,
      underline = true,
    }
  elseif type(hl_group) == 'string' then
    hl_group = vim.api.nvim_get_hl(0, { name = hl_group, link = false })
  end
  vim.api.nvim_set_hl(0, 'DropBarFzfMatch', hl_group)

  local function fuzzy_find_stop()
    local fzf_state = menu.data and menu.data.fzf
    if not fzf_state then
      return
    end
    if fzf_state.slab then
      fzf.free_slab(fzf_state.slab)
      fzf_state.slab = nil
    end
    if fzf_state.pattern then
      fzf.free_pattern(fzf_state.pattern)
      fzf_state.pattern = nil
    end
    menu.entries = fzf_state.save
    menu:fill_buf()
    menu.data.fzf = nil
    vim.bo[menu.buf].modifiable = false
  end

  vim.bo[menu.buf].modifiable = true
  vim.api.nvim_win_set_cursor(menu.win, { 1, 1 })
  local input_buf = vim.api.nvim_create_buf(false, true)
  local input_win = vim.api.nvim_open_win(
    input_buf,
    false,
    vim.tbl_extend('force', menu._win_configs, {
      row = menu._win_configs.row + menu._win_configs.height,
      col = menu._win_configs.col - 1,
      height = 1,
      border = 'single',
    }, opts._win_configs or {})
  )
  vim.wo[input_win].stc = opts.prompt or '%#@tag# '

  ---@type fun(line: string): string, integer[]
  local locations_map = opts.locations_map
    or function(line)
      local line_size = #line
      local chars = {}
      local locations = {}
      local c = string.find(line, '[%w%p]')
      while c and c < line_size do
        table.insert(chars, line:sub(c, c))
        table.insert(locations, c)
        c = string.find(line, '[%w%p]', c + 1)
      end
      return table.concat(chars), locations
    end

  -- impractical and error prone to use numerical indices, but its faster than
  -- hash table lookups

  ---@alias fzf_line_t { [1]: number, [2]: string, [3]: integer[], [4]: number, [5]: dropbar_menu_entry_t, [6]: integer[]? }
  ---@type fzf_line_t[]
  local lines = {}
  for i, entry in ipairs(menu.entries) do
    local buffer_line =
      vim.api.nvim_buf_get_lines(menu.buf, i - 1, i, false)[1]
    local str, locs = locations_map(buffer_line)
    lines[i] = { i, str, locs, 0, entry, nil }
  end
  if menu.data and menu.data.fzf then
    fuzzy_find_stop()
  end
  menu.data = menu.data or {}
  menu.data.fzf = {
    slab = fzf.allocate_slab(), -- must be freed, not garbage collected
    pattern = nil,
    save = vim.deepcopy(menu.entries),
    lines = lines,
  }
  local function move_cursor(pos)
    vim.api.nvim_win_set_cursor(menu.win, pos)
    menu:update_hover_hl(pos)
    menu:preview_symbol_at(pos)
  end

  ---@param last boolean
  local function select(last)
    if vim.api.nvim_buf_line_count(menu.buf) < 1 then
      return
    end
    vim.cmd('silent! stopinsert')
    local cursor = vim.api.nvim_win_get_cursor(menu.win)
    local line = menu.data.fzf.lines[cursor[1]]
    cursor[1] = line[1]
    fuzzy_find_stop()
    vim.api.nvim_win_close(input_win, false)
    vim.api.nvim_win_set_cursor(menu.win, cursor)
    vim.api.nvim_feedkeys('l', 'nt', false)
    if last then
      vim.schedule(function()
        local entry = menu.entries[cursor[1]]
        for i = #entry.components, 1, -1 do
          local component = entry.components[i]
          if component.on_click then
            menu:click_on(component)
            break
          end
        end
      end)
    else
      vim.schedule(function()
        local target, _ = menu.entries[cursor[1]]:first_clickable(0)
        if target then
          menu:click_on(target)
        end
      end)
    end
  end

  local keymaps = vim.tbl_extend('force', {
    ['<Esc>'] = function()
      vim.cmd('silent! stopinsert')
      fuzzy_find_stop()
      vim.api.nvim_win_close(input_win, false)
      vim.api.nvim_feedkeys('l', 'nt', false)
    end,
    ['<Enter>'] = function()
      select(true)
    end,
    ['<S-Enter>'] = function()
      select(false)
    end,
    ['<Up>'] = function()
      if vim.api.nvim_buf_line_count(menu.buf) <= 1 then
        return
      end
      local cursor = vim.api.nvim_win_get_cursor(menu.win)
      cursor[1] = math.max(1, cursor[1] - 1)
      move_cursor(cursor)
    end,
    ['<Down>'] = function()
      local line_count = vim.api.nvim_buf_line_count(menu.buf)
      if line_count <= 1 then
        return
      end
      local cursor = vim.api.nvim_win_get_cursor(menu.win)
      cursor[1] = math.min(line_count, cursor[1] + 1)
      move_cursor(cursor)
    end,
  }, opts.keymaps or {})

  for key, func in pairs(keymaps) do
    vim.keymap.set('i', key, func, { buffer = input_buf })
  end

  vim.api.nvim_set_current_win(input_win)
  vim.schedule(function()
    move_cursor({ 1, 1 })
    vim.cmd('silent! startinsert')
  end)

  local function on_update()
    if not menu.data or not menu.data.fzf then
      -- return true to detach from buffer
      return true
    end
    local text = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)[1]
    if not text or #text < 1 then
      vim.schedule(function()
        menu.entries = vim.deepcopy(menu.data.fzf.save)
        menu:fill_buf()
        move_cursor({ 1, 1 })
      end)
      return
    end
    if menu.data.fzf.pattern then
      -- free it before allocating a new one, this isn't garbage collected
      fzf.free_pattern(menu.data.fzf.pattern)
    end
    menu.data.fzf.pattern = fzf.parse_pattern(text, 0, true)
    for _, line in ipairs(menu.data.fzf.lines) do
      line[4] =
        fzf.get_score(line[2], menu.data.fzf.pattern, menu.data.fzf.slab)
      if line[4] > 1 then
        line[6] =
          fzf.get_pos(line[2], menu.data.fzf.pattern, menu.data.fzf.slab)
      else
        line[6] = nil
      end
    end
    table.sort(menu.data.fzf.lines, function(a, b)
      -- break ties by comparing line numbers
      if a[4] == b[4] then
        return a[1] < b[1]
      end
      return a[4] > b[4]
    end)
    local entries = {}
    for _, line in ipairs(menu.data.fzf.lines) do
      if line[4] < 2 then
        break
      end
      table.insert(entries, line[5])
      entries[#entries].idx = #entries
    end
    vim.schedule(function()
      vim.api.nvim_buf_clear_namespace(menu.buf, ns_id, 0, -1)
      menu.entries = entries
      menu:fill_buf()
      for i, fzf_line in ipairs(menu.data.fzf.lines) do
        if fzf_line[4] < 2 then
          break
        end
        for _, c in ipairs(fzf_line[6]) do
          local col = fzf_line[3][c]
          vim.api.nvim_buf_set_extmark(menu.buf, ns_id, i - 1, col - 1, {
            end_col = col,
            hl_group = 'DropBarFzfMatch',
            priority = vim.highlight.priorities.user + 10,
          })
        end
      end
      if #entries > 0 then
        move_cursor({ 1, 1 })
      else
        if menu.symbol_previewed then
          menu.symbol_previewed:preview_restore_hl()
          menu.symbol_previewed:preview_restore_view()
          menu.symbol_previewed = nil
          menu:update_hover_hl()
        end
      end
    end)
  end

  vim.api.nvim_buf_attach(input_buf, false, { on_lines = on_update })

  -- make sure allocated memory is freed (done in fuzzy_find_stop())
  vim.api.nvim_create_autocmd({ 'BufUnload', 'BufWinLeave' }, {
    group = augroup,
    buffer = input_buf,
    callback = fuzzy_find_stop,
    once = true,
  })
end

return {
  get_dropbar = get_dropbar,
  get_current_dropbar = get_current_dropbar,
  get_dropbar_menu = get_dropbar_menu,
  get_current_dropbar_menu = get_current_dropbar_menu,
  goto_context_start = goto_context_start,
  select_next_context = select_next_context,
  pick = pick,
  fuzzy_find = fuzzy_find,
}
