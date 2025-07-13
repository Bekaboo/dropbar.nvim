local configs = require('dropbar.configs')
local source_lsp = require('dropbar.sources.lsp')
local spy = require('luassert.spy')
local stub = require('luassert.stub')

describe('[source][lsp]', function()
  ---@type vim.lsp.Client
  ---@diagnostic disable-next-line: missing-fields
  local mock_client = {
    id = 1,
    name = 'mock-lsp',
    supports_method = function(method)
      return method == 'textDocument/documentSymbol'
    end,
    request = spy.new(function()
      return true, 1
    end),
    cancel_request = spy.new(function() end),
  }

  stub(vim.lsp, 'get_clients', function()
    return { mock_client }
  end)

  it('cancels previous request before making new request', function()
    -- First request
    source_lsp.get_symbols(0, 0, { 1, 0 })
    vim.wait(100)

    assert.spy(mock_client.request).was.called(1)
    assert.spy(mock_client.cancel_request).was.called(0)

    local first_request_id = mock_client._dropbar_request_id

    -- Second request, use autocmd to trigger update
    -- Don't use `get_symbols()` here as the result from first request is
    -- cached
    vim.api.nvim_exec_autocmds(configs.opts.bar.update_events.buf[1], {
      buffer = 0,
    })
    vim.wait(100)

    -- Should have canceled first request and made new request
    assert.spy(mock_client.cancel_request).was.called(1)
    assert
      .spy(mock_client.cancel_request).was
      .called_with(mock_client, first_request_id)
    assert.spy(mock_client.request).was.called(2)
  end)
end)
