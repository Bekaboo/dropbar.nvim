---@diagnostic disable: undefined-field

local dropbar = require('dropbar')
local lsp_source = require('dropbar.sources.lsp')
local configs = require('dropbar.configs')
local spy = require('luassert.spy')
local stub = require('luassert.stub')

describe('[source][lsp]', function()
  ---@diagnostic disable-next-line: missing-fields
  local mock_client = {} ---@type vim.lsp.Client

  stub(vim.lsp, 'get_clients', function()
    return { mock_client }
  end)

  before_each(function()
    ---@diagnostic disable-next-line: missing-fields
    mock_client = {
      id = 1,
      name = 'mock-lsp',
      supports_method = function(method)
        return method == 'textDocument/documentSymbol'
      end,
    }
  end)

  it('cancels previous request before making new request', function()
    ---@diagnostic disable: assign-type-mismatch
    mock_client.cancel_request = spy.new(function() end)
    mock_client.request = spy.new(function()
      return true, 1
    end)
    ---@diagnostic enable: assign-type-mismatch

    -- First request
    lsp_source.get_symbols(
      vim.api.nvim_get_current_buf(),
      vim.api.nvim_get_current_win(),
      { 1, 0 }
    )

    assert.spy(mock_client.request).was.called(1)
    assert.spy(mock_client.cancel_request).was.called(0)

    local first_request_id = mock_client._dropbar_request_id

    -- Second request, use autocmd to trigger update
    -- Don't use `get_symbols()` here as the result from first request is
    -- cached
    vim.api.nvim_exec_autocmds(configs.opts.bar.update_events.buf[1], {
      buffer = 0,
    })

    -- Should have canceled first request and made new request
    assert.spy(mock_client.cancel_request).was.called(1)
    assert
      .spy(mock_client.cancel_request).was
      .called_with(mock_client, first_request_id)
    assert.spy(mock_client.request).was.called(2)
  end)

  it('sorts symbols by their start positions', function()
    -- Make sure function type is a valid LSP symbol type so that symbols in
    -- mock client response will be included in `get_symbols()` result
    dropbar.setup({
      sources = {
        lsp = {
          valid_symbols = {
            'Function', -- code = 12
          },
        },
      },
    })

    -- Mock a client that returns response with disordered symbols on
    -- textDocument/documentSymbol request
    ---@diagnostic disable-next-line: assign-type-mismatch
    mock_client.request = function(_, method, _, handler)
      if method ~= 'textDocument/documentSymbol' then
        return
      end

      handler(nil, {
        {
          name = 's3',
          kind = 12, -- Function
          range = {
            start = { line = 10, character = 0 },
            ['end'] = { line = 15, character = 0 },
          },
        },
        {
          name = 's1',
          kind = 12, -- Function
          range = {
            start = { line = 0, character = 0 },
            ['end'] = { line = 5, character = 0 },
          },
        },
        {
          name = 's2',
          kind = 12, -- Function
          range = {
            start = { line = 5, character = 0 },
            ['end'] = { line = 10, character = 0 },
          },
        },
      }, {
        method = 'textDocument/documentSymbol',
        client_id = mock_client.id,
      })

      return true, 1
    end

    -- Trigger LSP update
    vim.api.nvim_exec_autocmds(configs.opts.bar.update_events.buf[1], {
      buffer = 0,
    })

    local symbols = lsp_source.get_symbols(
      vim.api.nvim_get_current_buf(),
      vim.api.nvim_get_current_win(),
      { 3, 0 }
    )

    -- Should contain `s1` as result with siblings `s1`, `s2`, and `s3` in
    -- order
    assert.are.same(
      { 's1' },
      vim.tbl_map(function(sym)
        return sym.name
      end, symbols)
    )
    assert.are.same(
      { 's1', 's2', 's3' },
      vim.tbl_map(function(sym)
        return sym.name
      end, symbols[1].siblings)
    )
  end)

  it(
    'handles symbols with identical start positions without sorting error',
    function()
      -- Make sure function type is a valid LSP symbol type so that symbols in
      -- mock client response will be included in `get_symbols()` result
      dropbar.setup({
        sources = {
          lsp = {
            valid_symbols = {
              'Function', -- code = 12
            },
          },
        },
      })

      -- Mock a client that returns symbols with identical start positions
      ---@diagnostic disable-next-line: assign-type-mismatch
      mock_client.request = function(_, method, _, handler)
        if method ~= 'textDocument/documentSymbol' then
          return
        end

        handler(nil, {
          {
            name = 's2',
            kind = 12,
            range = {
              start = { line = 5, character = 10 },
              ['end'] = { line = 8, character = 0 },
            },
          },
          {
            name = 's3',
            kind = 12,
            range = {
              start = { line = 5, character = 10 }, -- Same position as `s2`
              ['end'] = { line = 10, character = 0 },
            },
          },
          {
            name = 's4',
            kind = 12,
            range = {
              start = { line = 5, character = 10 }, -- Same position as `s2` and `s3`
              ['end'] = { line = 12, character = 0 },
            },
          },
          {
            name = 's1',
            kind = 12,
            range = {
              start = { line = 3, character = 5 },
              ['end'] = { line = 6, character = 0 },
            },
          },
        }, {
          method = 'textDocument/documentSymbol',
          client_id = mock_client.id,
        })

        return true, 1
      end

      -- Should not throw 'invalid order function for sorting' error
      assert.is_true(pcall(function()
        -- Trigger LSP update
        vim.api.nvim_exec_autocmds(configs.opts.bar.update_events.buf[1], {
          buffer = 0,
        })

        lsp_source.get_symbols(
          vim.api.nvim_get_current_buf(),
          vim.api.nvim_get_current_win(),
          { 6, 0 }
        )
      end))

      -- Verify siblings are in correct order:
      -- `s1` should be the first, followed by `s2/3/4` in any order since
      -- they have identical positions
      local symbols = lsp_source.get_symbols(
        vim.api.nvim_get_current_buf(),
        vim.api.nvim_get_current_win(),
        { 6, 0 }
      )
      local siblings = symbols[1].siblings ---@type dropbar_symbol_t[]
      assert.is_truthy(siblings)
      assert.are.equal(4, #siblings)
      assert.is.same('s1', siblings[1].name)
      assert.are.same({
        s2 = true,
        s3 = true,
        s4 = true,
      }, {
        [siblings[2].name] = true,
        [siblings[3].name] = true,
        [siblings[4].name] = true,
      })
    end
  )
end)
