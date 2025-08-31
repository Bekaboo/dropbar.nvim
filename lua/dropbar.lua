local hlgroups = require('dropbar.hlgroups')
local bar = require('dropbar.bar')
local configs = require('dropbar.configs')
local utils = require('dropbar.utils')

_G.dropbar = setmetatable({}, {
  __call = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    return _G.dropbar.bars[buf][win]()
  end,
})

---Store the on_click callbacks for each dropbar symbol
---Make it accessible from global only because nvim's viml-lua interface
---(v:lua) only support calling global lua functions
---@type table<string, table<string, function>>
---@see dropbar_t:update
_G.dropbar.callbacks = setmetatable({}, {
  __index = function(self, buf)
    self[buf] = setmetatable({}, {
      __index = function(this, win)
        this[win] = {}
        return this[win]
      end,
    })
    return self[buf]
  end,
})

---@type table<integer, table<integer, dropbar_t>>
_G.dropbar.bars = setmetatable({}, {
  __index = function(self, buf)
    self[buf] = setmetatable({}, {
      __index = function(this, win)
        this[win] = bar.dropbar_t:new({
          sources = configs.eval(configs.opts.bar.sources, buf, win),
        })
        return this[win]
      end,
    })
    return self[buf]
  end,
})

---Get dropbar string for current window
---@deprecated
---@return string
function _G.dropbar.get_dropbar_str()
  vim.notify_once(
    '[dropbar.nvim] _G.dropbar.get_dropbar_str() is deprecated, use _G.dropbar() instead',
    vim.log.levels.WARN
  )
  return ''
end

---Setup dropbar
---@param opts dropbar_configs_t?
local function setup(opts)
  if 1 ~= vim.fn.has('nvim-0.11.0') then
    vim.api.nvim_err_writeln(
      '[dropbar.nvim] dropbar.nvim requires at least nvim-0.11.0'
    )
    return
  end

  configs.set(opts)
  hlgroups.init()

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    utils.bar.attach(vim.api.nvim_win_get_buf(win), win)
  end

  local groupid = vim.api.nvim_create_augroup('dropbar', {})

  if not vim.tbl_isempty(configs.opts.bar.attach_events) then
    vim.api.nvim_create_autocmd(configs.opts.bar.attach_events, {
      group = groupid,
      callback = function(args)
        -- Try attaching dropbar to all windows containing the buffer
        -- Notice that we cannot simply let `win=0` here since the current
        -- buffer isn't necessarily the window containing the buffer
        for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
          utils.bar.attach(args.buf, win, args)
        end
      end,
      desc = 'Attach dropbar',
    })
  end

  if not vim.tbl_isempty(configs.opts.bar.update_events.win) then
    vim.api.nvim_create_autocmd(configs.opts.bar.update_events.win, {
      group = groupid,
      callback = function(args)
        if args.event == 'WinResized' then
          for _, win in ipairs(vim.v.event.windows or {}) do
            utils.bar.exec('update', { win = win })
          end
        else
          utils.bar.exec('update', {
            win = args.event == 'WinScrolled' and tonumber(args.match)
              or vim.api.nvim_get_current_win(),
          })
        end
      end,
      desc = 'Update a single winbar.',
    })
  end

  if not vim.tbl_isempty(configs.opts.bar.update_events.buf) then
    vim.api.nvim_create_autocmd(configs.opts.bar.update_events.buf, {
      group = groupid,
      callback = function(args)
        utils.bar.exec('update', { buf = args.buf })
      end,
      desc = 'Update all winbars associated with buf.',
    })
  end

  if not vim.tbl_isempty(configs.opts.bar.update_events.global) then
    vim.api.nvim_create_autocmd(configs.opts.bar.update_events.global, {
      group = groupid,
      callback = function()
        utils.bar.exec('update')
      end,
      desc = 'Update all winbars.',
    })
  end

  if configs.opts.bar.hover then
    vim.on_key(function(key)
      if key == vim.keycode('<MouseMove>') then
        utils.bar.update_hover_hl(vim.fn.getmousepos())
      end
    end)

    vim.api.nvim_create_autocmd('FocusLost', {
      group = groupid,
      callback = function()
        utils.bar.update_hover_hl({})
      end,
      desc = 'Remove hover highlight on focus lost.',
    })

    vim.api.nvim_create_autocmd('FocusGained', {
      group = groupid,
      callback = function()
        utils.bar.update_hover_hl(vim.fn.getmousepos())
      end,
      desc = 'Update hover highlight on focus gained.',
    })
  end

  -- Garbage collection
  vim.api.nvim_create_autocmd('BufDelete', {
    group = groupid,
    callback = function(args)
      utils.bar.exec('del', { buf = args.buf })
    end,
    desc = 'Remove dropbar from cache on buffer delete.',
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = groupid,
    callback = function(args)
      utils.bar.exec('del', { win = tonumber(args.match) })
    end,
    desc = 'Remove dropbar from cache on window closed.',
  })

  local gc_timer = vim.uv.new_timer()
  if gc_timer then
    gc_timer:start(
      configs.opts.bar.gc.interval,
      configs.opts.bar.gc.interval,
      vim.schedule_wrap(function()
        for buf, _ in pairs(_G.dropbar.bars) do
          if not vim.api.nvim_buf_is_valid(buf) then
            utils.bar.exec('del', { buf = buf })
            goto continue
          end
          for win, _ in pairs(_G.dropbar.bars[buf]) do
            if not vim.api.nvim_win_is_valid(win) then
              utils.bar.exec('del', { win = win })
            end
          end
          ::continue::
        end
      end)
    )
  end

  vim.g.loaded_dropbar = true
end

return { setup = setup }
