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
  local cwd
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
    -- Use the canonical cwd so buffer paths share a prefix with
    -- `opts.sources.path.relative_to` even when `tmpdir` goes through a
    -- symlink (e.g. macOS `/var` -> `/private/var`)
    cwd = vim.fn.getcwd()
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
    local buf1, win1 = add_buffer(cwd .. '/a/foo.lua')
    local buf2, win2 = add_buffer(cwd .. '/b/foo.lua')

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
    local buf1, win1 = add_buffer(cwd .. '/a/b/c')
    local buf2, win2 = add_buffer(cwd .. '/d/b/c')
    local buf3, win3 = add_buffer(cwd .. '/e/c')

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
    local buf, win = add_buffer(cwd .. '/x/bar.lua')

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

    local buf1, win1 = add_buffer(cwd .. '/a/foo.lua')
    local buf2, win2 = add_buffer(cwd .. '/b/foo.lua')

    assert.are.same(
      { 'foo.lua' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )
    assert.are.same(
      { 'foo.lua' },
      symbol_names(source_path.get_symbols(buf2, win2, {}))
    )
  end)

  it('extends depth when buffers share parent directories (#287)', function()
    dropbar.setup({
      sources = {
        path = {
          unique = true,
          max_depth = 2,
        },
      },
    })

    local buf1, win1 = add_buffer(cwd .. '/a/b/init.lua')
    local buf2, win2 = add_buffer(cwd .. '/c/b/init.lua')

    assert.are.same(
      { 'a', 'b', 'init.lua' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )
    assert.are.same(
      { 'c', 'b', 'init.lua' },
      symbol_names(source_path.get_symbols(buf2, win2, {}))
    )
  end)

  it('extends depth across deeply shared ancestor chains', function()
    dropbar.setup({
      sources = {
        path = {
          unique = true,
          max_depth = 2,
        },
      },
    })

    local buf1, win1 = add_buffer(cwd .. '/x/p/q/r/init.lua')
    local buf2, win2 = add_buffer(cwd .. '/y/p/q/r/init.lua')

    assert.are.same(
      { 'x', 'p', 'q', 'r', 'init.lua' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )
    assert.are.same(
      { 'y', 'p', 'q', 'r', 'init.lua' },
      symbol_names(source_path.get_symbols(buf2, win2, {}))
    )
  end)

  it('disambiguates overlapping suffix paths', function()
    dropbar.setup({
      sources = {
        path = {
          unique = true,
          max_depth = 2,
        },
      },
    })

    local buf1, win1 = add_buffer(cwd .. '/a/b/init.lua')
    local buf2, win2 = add_buffer(cwd .. '/c/a/b/init.lua')

    assert.are.same(
      { 'a', 'b', 'init.lua' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )
    assert.are.same(
      { 'c', 'a', 'b', 'init.lua' },
      symbol_names(source_path.get_symbols(buf2, win2, {}))
    )
  end)

  it('disambiguates top-level and nested files with shared names', function()
    dropbar.setup({
      sources = {
        path = {
          unique = true,
          max_depth = 2,
        },
      },
    })

    local buf1, win1 = add_buffer(cwd .. '/init.lua')
    local buf2, win2 = add_buffer(cwd .. '/a/init.lua')

    assert.are.same(
      { 'init.lua' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )
    assert.are.same(
      { 'a', 'init.lua' },
      symbol_names(source_path.get_symbols(buf2, win2, {}))
    )
  end)

  it('disambiguates nested suffix and deeper parent path', function()
    dropbar.setup({
      sources = {
        path = {
          unique = true,
          max_depth = 2,
        },
      },
    })

    local buf1, win1 = add_buffer(cwd .. '/b/init.lua')
    local buf2, win2 = add_buffer(cwd .. '/a/b/init.lua')

    assert.are.same(
      { 'b', 'init.lua' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )
    assert.are.same(
      { 'a', 'b', 'init.lua' },
      symbol_names(source_path.get_symbols(buf2, win2, {}))
    )
  end)

  it('keeps max_depth when the same buffer is open in two windows', function()
    dropbar.setup({
      sources = {
        path = {
          unique = true,
          max_depth = 2,
        },
      },
    })

    local buf1, win1 = add_buffer(cwd .. '/a/b/init.lua')
    vim.cmd.vsplit()
    local win2 = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win2, buf1)
    table.insert(created_wins, win2)
    _G.dropbar.bars[buf1][win2] = bar.dropbar_t:new({
      buf = buf1,
      win = win2,
      sources = { source_path },
    })

    assert.are.same(
      { 'b', 'init.lua' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )
    assert.are.same(
      { 'b', 'init.lua' },
      symbol_names(source_path.get_symbols(buf1, win2, {}))
    )
  end)

  it('caps depth at custom relative_to root', function()
    local buf1, win1 = add_buffer(cwd .. '/a/b/init.lua')
    local buf2, win2 = add_buffer(cwd .. '/c/b/init.lua')

    dropbar.setup({
      sources = {
        path = {
          unique = true,
          max_depth = 2,
          relative_to = function(buf, _)
            return buf == buf1 and (cwd .. '/a/b') or cwd
          end,
        },
      },
    })

    assert.are.same(
      { 'init.lua' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )
    assert.are.same(
      { 'c', 'b', 'init.lua' },
      symbol_names(source_path.get_symbols(buf2, win2, {}))
    )
  end)

  it('ignores hidden buffers no longer displayed in a window', function()
    dropbar.setup({
      sources = {
        path = {
          unique = true,
          max_depth = 2,
        },
      },
    })

    local buf1, win1 = add_buffer(cwd .. '/a/b/init.lua')
    local _, win2 = add_buffer(cwd .. '/c/b/init.lua')

    assert.are.same(
      { 'a', 'b', 'init.lua' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )

    local buf3 = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf3, cwd .. '/other.lua')
    table.insert(created_bufs, buf3)
    vim.api.nvim_win_set_buf(win2, buf3)
    _G.dropbar.bars[buf3] = {}
    _G.dropbar.bars[buf3][win2] = bar.dropbar_t:new({
      buf = buf3,
      win = win2,
      sources = { source_path },
    })

    assert.are.same(
      { 'b', 'init.lua' },
      symbol_names(source_path.get_symbols(buf1, win1, {}))
    )
  end)

  it(
    'does not extend depth with shared parents when unique is disabled',
    function()
      dropbar.setup({
        sources = {
          path = {
            unique = false,
            max_depth = 2,
          },
        },
      })

      local buf1, win1 = add_buffer(cwd .. '/a/b/init.lua')
      local buf2, win2 = add_buffer(cwd .. '/c/b/init.lua')

      assert.are.same(
        { 'b', 'init.lua' },
        symbol_names(source_path.get_symbols(buf1, win1, {}))
      )
      assert.are.same(
        { 'b', 'init.lua' },
        symbol_names(source_path.get_symbols(buf2, win2, {}))
      )
    end
  )
end)
