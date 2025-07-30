---@diagnostic disable: undefined-field

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
