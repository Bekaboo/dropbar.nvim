---@diagnostic disable: undefined-field

local dropbar = require('dropbar')
local bar = require('dropbar.bar')
local source_path = require('dropbar.sources.path')

local function symbol_names(symbols)
  return vim.tbl_map(function(symbol)
    return symbol.name
  end, symbols)
end

describe('[source][path]', function()
  local tmpdir
  local created_bufs = {}
  local created_wins = {}

  ---Create a buffer named `path`, show it in a window, and register a dropbar
  ---using the path source for it
  ---@param path string
  ---@return integer buf
  ---@return integer win
  local function add_buffer(path)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, path)
    table.insert(created_bufs, buf)

    local win
    if #created_bufs == 1 then
      win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, buf)
    else
      vim.cmd.vsplit()
      win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, buf)
    end
    table.insert(created_wins, win)

    _G.dropbar.bars[buf] = {}
    _G.dropbar.bars[buf][win] = bar.dropbar_t:new({
      buf = buf,
      win = win,
      sources = { source_path },
    })
    return buf, win
  end

  before_each(function()
    tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, 'p')
    vim.cmd('cd ' .. vim.fn.fnameescape(tmpdir))
    dropbar.setup({
      sources = {
        path = {
          unique = true,
          max_depth = 1,
        },
      },
    })
  end)

  after_each(function()
    for _, win in ipairs(created_wins) do
      if vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
    for _, buf in ipairs(created_bufs) do
      _G.dropbar.bars[buf] = nil
      if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
    created_bufs = {}
    created_wins = {}
    pcall(vim.cmd, 'cd -')
    pcall(vim.fn.delete, tmpdir, 'rf')
  end)

  it('extends depth for buffers sharing a basename', function()
    local buf1, win1 = add_buffer(tmpdir .. '/a/foo.lua')
    local buf2, win2 = add_buffer(tmpdir .. '/b/foo.lua')

    assert.are.same(
      { 'a', 'foo.lua' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )
    assert.are.same(
      { 'b', 'foo.lua' },
      symbol_names(source_path.get_symbols(buf2, win2, {}))
    )
  end)

  it('extends depth by the minimum needed to disambiguate', function()
    local buf1, win1 = add_buffer(tmpdir .. '/a/b/c')
    local buf2, win2 = add_buffer(tmpdir .. '/d/b/c')
    local buf3, win3 = add_buffer(tmpdir .. '/e/c')

    assert.are.same(
      { 'a', 'b', 'c' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )
    assert.are.same(
      { 'd', 'b', 'c' },
      symbol_names(source_path.get_symbols(buf2, win2, {}))
    )
    assert.are.same(
      { 'e', 'c' },
      symbol_names(source_path.get_symbols(buf3, win3, {}))
    )
  end)

  it('keeps max_depth for buffers with unique basenames', function()
    local buf, win = add_buffer(tmpdir .. '/x/bar.lua')

    assert.are.same(
      { 'bar.lua' },
      symbol_names(source_path.get_symbols(buf, win, {}))
    )
  end)

  it('does not extend depth when unique is disabled', function()
    dropbar.setup({
      sources = {
        path = {
          unique = false,
          max_depth = 1,
        },
      },
    })

    local buf1, win1 = add_buffer(tmpdir .. '/a/foo.lua')
    local buf2, win2 = add_buffer(tmpdir .. '/b/foo.lua')

    assert.are.same(
      { 'foo.lua' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )
    assert.are.same(
      { 'foo.lua' },
      symbol_names(source_path.get_symbols(buf2, win2, {}))
    )
  end)
end)
