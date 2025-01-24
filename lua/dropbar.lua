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
  if 1 ~= vim.fn.has('nvim-0.10.0') then
    vim.api.nvim_err_writeln('dropbar.nvim requires at least nvim-0.10.0')
    return
  end
  configs.set(opts)
  hlgroups.init()
  local groupid = vim.api.nvim_create_augroup('DropBar', {})
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    utils.bar.attach(vim.api.nvim_win_get_buf(win), win)
  end
  if not vim.tbl_isempty(configs.opts.bar.attach_events) then
    vim.api.nvim_create_autocmd(configs.opts.bar.attach_events, {
      group = groupid,
      callback = function(info)
        -- Try attaching dropbar to all windows containing the buffer
        -- Notice that we cannot simply let `win=0` here since the current
        -- buffer isn't necessarily the window containing the buffer
        for _, win in ipairs(vim.fn.win_findbuf(info.buf)) do
          utils.bar.attach(info.buf, win, info)
        end
      end,
      desc = 'Attach dropbar',
    })
  end
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufUnload', 'BufWipeOut' }, {
    group = groupid,
    callback = function(info)
      utils.bar.exec('del', { buf = info.buf })
      _G.dropbar.bars[info.buf] = nil
      _G.dropbar.callbacks['buf' .. info.buf] = nil
    end,
    desc = 'Remove dropbar from cache on buffer delete/unload/wipeout.',
  })
  if not vim.tbl_isempty(configs.opts.bar.update_events.win) then
    vim.api.nvim_create_autocmd(configs.opts.bar.update_events.win, {
      group = groupid,
      callback = function(info)
        if info.event == 'WinResized' then
          for _, win in ipairs(vim.v.event.windows or {}) do
            utils.bar.exec('update', { win = win })
          end
        else
          utils.bar.exec('update', {
            win = info.event == 'WinScrolled' and tonumber(info.match)
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
      callback = function(info)
        utils.bar.exec('update', { buf = info.buf })
      end,
      desc = 'Update all winbars associated with buf.',
    })
  end
  if not vim.tbl_isempty(configs.opts.bar.update_events.global) then
    vim.api.nvim_create_autocmd(configs.opts.bar.update_events.global, {
      group = groupid,
      callback = function(info)
        if vim.tbl_isempty(utils.bar.get({ buf = info.buf })) then
          return
        end
        utils.bar.exec('update')
      end,
      desc = 'Update all winbars.',
    })
  end
  vim.api.nvim_create_autocmd({ 'WinClosed' }, {
    group = groupid,
    callback = function(info)
      utils.bar.exec('del', { win = tonumber(info.match) })
    end,
    desc = 'Remove dropbar from cache on window closed.',
  })
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
  vim.g.loaded_dropbar = true
end

return {
  setup = setup,
}
