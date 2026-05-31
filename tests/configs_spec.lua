---@diagnostic disable: undefined-field

local dropbar = require('dropbar')

describe('[terminal]', function()
  local term_buf = nil
  local term_win = nil

  before_each(function()
    vim.cmd.terminal()
    term_buf = vim.api.nvim_get_current_buf()
    term_win = vim.api.nvim_get_current_win()
    -- Wait for terminal to be ready and dropbar to attach
    vim.wait(100)
  end)

  after_each(function()
    -- Clean up terminal buffer
    if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
      vim.api.nvim_buf_delete(term_buf, { force = true })
    end
  end)

  it('attaches dropbar to terminal buffers', function()
    assert.are.equal('terminal', vim.bo[term_buf].bt)

    assert.is_not_nil(_G.dropbar.bars[term_buf])
    assert.is_not_nil(_G.dropbar.bars[term_buf][term_win])

    local winbar = _G.dropbar.bars[term_buf][term_win]
    assert.is_not_nil(winbar)
    assert.is_table(winbar.components)
  end)
end)

describe('[events]', function()
  it('registers autocmd with pattern for structured events', function()
    dropbar.setup({
      bar = {
        update_events = {
          win = {
            'CursorMoved',
          },
          buf = {},
          global = {
            {
              event = 'OptionSet',
              pattern = 'modified',
            },
          },
        },
      },
    })

    local autocmds = vim.api.nvim_get_autocmds({
      group = 'dropbar',
      event = 'OptionSet',
    })
    assert.are.equal(1, #autocmds)
    assert.are.equal('modified', autocmds[1].pattern)
  end)

  it('registers autocmd without pattern for simple string events', function()
    dropbar.setup({
      bar = {
        update_events = {
          win = {},
          buf = {},
          global = {
            'DirChanged',
          },
        },
      },
    })

    local autocmds = vim.api.nvim_get_autocmds({
      group = 'dropbar',
      event = 'DirChanged',
    })
    assert.is_not_nil(autocmds[1])
  end)

  it('mixes string and structured events in the same list', function()
    dropbar.setup({
      bar = {
        update_events = {
          win = {
            'CursorMoved',
            {
              event = 'WinResized',
            },
          },
          buf = {},
          global = {},
        },
      },
    })

    local autocmds = vim.api.nvim_get_autocmds({
      group = 'dropbar',
      event = 'WinResized',
    })
    assert.is_not_nil(autocmds[1])
  end)

  it('filters pattern from structured events for buffer autocmds', function()
    local events = {
      'TextChanged',
      { event = 'OptionSet', pattern = 'modified' },
    }
    local filtered = vim
      .iter(events)
      :map(function(event)
        return type(event) == 'table' and event.event or event
      end)
      :totable()
    assert.are.same({ 'TextChanged', 'OptionSet' }, filtered)
  end)
end)
