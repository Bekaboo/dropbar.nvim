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
    vim.api.nvim_exec_autocmds('TextChanged', {
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
    vim.api.nvim_exec_autocmds('TextChanged', {
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
        vim.api.nvim_exec_autocmds('TextChanged', {
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

  describe('refresh on LSP load', function()
    local bar = require('dropbar.bar')
    local utils = require('dropbar.utils')
    local orig_buf = nil ---@type integer
    local test_buf = nil ---@type integer
    local win = nil ---@type integer

    before_each(function()
      win = vim.api.nvim_get_current_win()
      orig_buf = vim.api.nvim_get_current_buf()
      test_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
        'function foo()',
        '  return 1',
        'end',
      })
      vim.api.nvim_win_set_buf(win, test_buf)
      vim.api.nvim_win_set_cursor(win, { 2, 0 })
      mock_client.cancel_request = function() end
      mock_client.supports_method = function(_, method)
        return method == 'textDocument/documentSymbol'
      end
      stub(vim.lsp, 'get_client_by_id', function(id)
        if id == mock_client.id then
          return mock_client
        end
      end)
    end)

    after_each(function()
      if vim.lsp.get_client_by_id.revert then
        vim.lsp.get_client_by_id:revert()
      end
      utils.menu.exec('close')
      if orig_buf and vim.api.nvim_buf_is_valid(orig_buf) then
        vim.api.nvim_win_set_buf(win, orig_buf)
      end
      if test_buf and vim.api.nvim_buf_is_valid(test_buf) then
        vim.api.nvim_buf_delete(test_buf, { force = true })
      end
    end)

    it('refreshes dropbar when LSP finishes loading symbols', function()
      local ready = false
      ---@type dropbar_source_t
      local fallback_source = {
        get_symbols = function(buf, w, _)
          return {
            bar.dropbar_symbol_t:new({
              buf = buf,
              win = w,
              name = 'ts_fn',
            }),
          }
        end,
      }

      dropbar.setup({
        bar = {
          update_debounce = 0,
          sources = {
            utils.source.fallback({
              lsp_source,
              fallback_source,
            }),
          },
        },
        sources = {
          lsp = {
            valid_symbols = { 'Function' },
            request = {
              ttl_init = 5,
              interval = 10,
            },
          },
        },
      })

      ---@diagnostic disable-next-line: assign-type-mismatch
      mock_client.request = function(_, method, _, handler)
        if method ~= 'textDocument/documentSymbol' then
          return
        end
        if not ready then
          handler(nil, {}, {
            method = 'textDocument/documentSymbol',
            client_id = mock_client.id,
          })
        else
          handler(nil, {
            {
              name = 'lsp_fn',
              kind = 12,
              range = {
                start = { line = 0, character = 0 },
                ['end'] = { line = 2, character = 3 },
              },
            },
          }, {
            method = 'textDocument/documentSymbol',
            client_id = mock_client.id,
          })
        end
        return true, 1
      end

      local winbar = _G.dropbar.bars[test_buf][win]
      winbar:update()
      vim.api.nvim_exec_autocmds('LspAttach', {
        buffer = test_buf,
        data = { client_id = mock_client.id },
      })

      assert.are.same('ts_fn', winbar.components[1].name)

      ready = true
      local refreshed = vim.wait(200, function()
        return winbar.components[1] and winbar.components[1].name == 'lsp_fn'
      end, 10)
      assert.is_true(refreshed)
    end)

    it(
      'refreshes dropbar on LspProgress end after initial requests gave up',
      function()
        local ready = false
        ---@type dropbar_source_t
        local fallback_source = {
          get_symbols = function(buf, w, _)
            return {
              bar.dropbar_symbol_t:new({
                buf = buf,
                win = w,
                name = 'ts_fn',
              }),
            }
          end,
        }

        dropbar.setup({
          bar = {
            update_debounce = 0,
            sources = {
              utils.source.fallback({
                lsp_source,
                fallback_source,
              }),
            },
          },
          sources = {
            lsp = {
              valid_symbols = { 'Function' },
              request = {
                ttl_init = 1,
                interval = 10,
              },
            },
          },
        })

        mock_client.attached_buffers = { [test_buf] = true }
        ---@diagnostic disable-next-line: assign-type-mismatch
        mock_client.request = function(_, method, _, handler)
          if method ~= 'textDocument/documentSymbol' then
            return
          end
          if not ready then
            handler(nil, {}, {
              method = 'textDocument/documentSymbol',
              client_id = mock_client.id,
            })
          else
            handler(nil, {
              {
                name = 'lsp_progress_fn',
                kind = 12,
                range = {
                  start = { line = 0, character = 0 },
                  ['end'] = { line = 2, character = 3 },
                },
              },
            }, {
              method = 'textDocument/documentSymbol',
              client_id = mock_client.id,
            })
          end
          return true, 1
        end

        local winbar = _G.dropbar.bars[test_buf][win]
        winbar:update()
        vim.api.nvim_exec_autocmds('LspAttach', {
          buffer = test_buf,
          data = { client_id = mock_client.id },
        })
        vim.wait(30)
        assert.are.same('ts_fn', winbar.components[1].name)

        ready = true
        vim.api.nvim_exec_autocmds('LspProgress', {
          pattern = 'end',
          data = { client_id = mock_client.id },
        })

        local refreshed = vim.wait(200, function()
          return winbar.components[1]
            and winbar.components[1].name == 'lsp_progress_fn'
        end, 10)
        assert.is_true(refreshed)
      end
    )

    it('holds back dropbar refresh until user leaves open menu', function()
      local pending_handler = nil ---@type function?
      ---@type dropbar_source_t
      local fallback_source = {
        get_symbols = function(buf, w, _)
          return {
            bar.dropbar_symbol_t:new({
              buf = buf,
              win = w,
              name = 'ts_fn',
              siblings = {
                bar.dropbar_symbol_t:new({
                  buf = buf,
                  win = w,
                  name = 'ts_fn',
                  children = {
                    bar.dropbar_symbol_t:new({
                      buf = buf,
                      win = w,
                      name = 'ts_child',
                    }),
                  },
                }),
              },
            }),
          }
        end,
      }

      dropbar.setup({
        bar = {
          update_debounce = 0,
          sources = {
            utils.source.fallback({
              lsp_source,
              fallback_source,
            }),
          },
        },
        sources = {
          lsp = {
            valid_symbols = { 'Function' },
          },
        },
      })

      ---@diagnostic disable-next-line: assign-type-mismatch
      mock_client.request = function(_, method, _, handler)
        if method ~= 'textDocument/documentSymbol' then
          return
        end
        pending_handler = handler
        return true, 1
      end

      local winbar = _G.dropbar.bars[test_buf][win]
      winbar:update()
      vim.api.nvim_exec_autocmds('LspAttach', {
        buffer = test_buf,
        data = { client_id = mock_client.id },
      })

      assert.are.same('ts_fn', winbar.components[1].name)
      assert.is_function(pending_handler)

      -- Open root menu and a nested sub-menu from the fallback treesitter symbol
      winbar.components[1]:on_click()
      local root_menu = winbar.components[1].menu
      assert.is_truthy(root_menu)
      assert.is_true(root_menu.is_opened)

      root_menu.entries[1].components[1]:on_click()
      local sub_menu = root_menu.sub_menu
      assert.is_truthy(sub_menu)
      assert.is_true(sub_menu.is_opened)
      assert.are.equal(sub_menu.win, vim.api.nvim_get_current_win())

      -- LSP finishes loading while user is browsing sub-menu
      pending_handler(nil, {
        {
          name = 'lsp_fn',
          kind = 12,
          range = {
            start = { line = 0, character = 0 },
            ['end'] = { line = 2, character = 3 },
          },
        },
      }, {
        method = 'textDocument/documentSymbol',
        client_id = mock_client.id,
      })

      vim.wait(50)
      assert.is_true(root_menu.is_opened)
      assert.is_true(sub_menu.is_opened)
      assert.are.equal(sub_menu.win, vim.api.nvim_get_current_win())
      assert.are.same('ts_fn', winbar.components[1].name)

      -- Closing only the sub-menu keeps user in root menu; update stays held back
      sub_menu:close()
      vim.wait(50)
      assert.is_true(root_menu.is_opened)
      assert.are.equal(root_menu.win, vim.api.nvim_get_current_win())
      assert.are.same('ts_fn', winbar.components[1].name)

      -- Closing root menu leaves menu completely; held-back update now runs
      root_menu:close()
      local refreshed = vim.wait(200, function()
        return winbar.components[1] and winbar.components[1].name == 'lsp_fn'
      end, 10)
      assert.is_true(refreshed)
    end)
  end)
end)
