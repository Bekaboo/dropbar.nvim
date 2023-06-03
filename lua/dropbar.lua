_G.dropbar = {}
local hlgroups = require('dropbar.hlgroups')
local bar = require('dropbar.bar')
local configs = require('dropbar.configs')

---Store the on_click callbacks for each dropbar symbol
---Make it assessable from global only because nvim's viml-lua interface
---(v:lua) only support calling global lua functions
---@type table<string, table<string, function>>
---@see dropbar_t:update
_G.dropbar.on_click_callbacks = setmetatable({}, {
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
---@return string
function _G.dropbar.get_dropbar_str()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  return tostring(_G.dropbar.bars[buf][win])
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
  ---Enable/disable dropbar
  ---@param win integer
  ---@param buf integer
  local function _switch(buf, win)
    if configs.eval(configs.opts.general.enable, buf, win) then
      vim.wo.winbar = '%{%v:lua.dropbar.get_dropbar_str()%}'
    end
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    _switch(vim.api.nvim_win_get_buf(win), win)
  end
  vim.api.nvim_create_autocmd({ 'OptionSet', 'BufWinEnter', 'BufWritePost' }, {
    group = groupid,
    callback = function(info)
      _switch(info.buf, 0)
    end,
    desc = 'Enable/disable dropbar',
  })
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufUnload', 'BufWipeOut' }, {
    group = groupid,
    callback = function(info)
      if not rawget(_G.dropbar.bars, info.buf) then
        return
      end
      for win, _ in pairs(_G.dropbar.bars[info.buf]) do
        _G.dropbar.bars[info.buf][win]:del()
      end
      _G.dropbar.bars[info.buf] = nil
    end,
    desc = 'Remove dropbar from cache on buffer delete/unload/wipeout.',
  })
  if not vim.tbl_isempty(configs.opts.general.update_events.win) then
    vim.api.nvim_create_autocmd(configs.opts.general.update_events.win, {
      group = groupid,
      callback = function(info)
        local win = info.event == 'WinScrolled' and tonumber(info.match)
          or vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_win_get_buf(win)
        if
          rawget(_G.dropbar.bars, buf) and rawget(_G.dropbar.bars[buf], win)
        then
          _G.dropbar.bars[buf][win]:update()
        end
      end,
      desc = 'Update a single winbar.',
    })
  end
  if not vim.tbl_isempty(configs.opts.general.update_events.buf) then
    vim.api.nvim_create_autocmd(configs.opts.general.update_events.buf, {
      group = groupid,
      callback = function(info)
        if rawget(_G.dropbar.bars, info.buf) then
          for win, _ in pairs(_G.dropbar.bars[info.buf]) do
            _G.dropbar.bars[info.buf][win]:update()
          end
        end
      end,
      desc = 'Update all winbars associated with buf.',
    })
  end
  if not vim.tbl_isempty(configs.opts.general.update_events.global) then
    vim.api.nvim_create_autocmd(configs.opts.general.update_events.global, {
      group = groupid,
      callback = function()
        for buf, _ in pairs(_G.dropbar.bars) do
          for win, _ in pairs(_G.dropbar.bars[buf]) do
            _G.dropbar.bars[buf][win]:update()
          end
        end
      end,
      desc = 'Update all winbars.',
    })
  end
  vim.api.nvim_create_autocmd({ 'WinClosed' }, {
    group = groupid,
    callback = function(info)
      if not rawget(_G.dropbar.bars, info.buf) then
        return
      end
      local win = tonumber(info.match)
      if win then
        _G.dropbar.bars[info.buf][win]:del()
      end
    end,
    desc = 'Remove dropbar from cache on window closed.',
  })
  vim.g.loaded_dropbar = true
end

return {
  setup = setup,
}
