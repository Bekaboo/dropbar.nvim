local configs = require('dropbar.configs')
local bar = require('dropbar.bar')

---@param self dropbar_symbol_t
local function preview_prepare_buf(self, path)
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= 'file' then
    self:preview_restore_view()
    return
  end
  local buf = vim.fn.bufnr(path, false)
  if buf == nil or buf == -1 then
    buf = vim.fn.bufadd(path)
    if not buf then
      self:preview_restore_view()
      return
    end
    if not vim.api.nvim_buf_is_loaded(buf) then
      vim.fn.bufload(buf)
    end
  end
  if buf == nil or self.entry.menu == nil or self.entry.menu.win == nil then
    self:preview_restore_view()
    return
  end
  return buf
end

---@param self dropbar_symbol_t
local function preview_open(self, path)
  if not configs.eval(configs.opts.sources.path.preview, path) then
    return
  end
  local preview_buf = preview_prepare_buf(self, path)
  if not preview_buf then
    return
  end
  local buflisted = vim.bo[preview_buf].buflisted

  local preview_win = self.entry.menu:root_win()
  if not preview_win then
    return
  end
  self.entry.menu.prev_buf = self.entry.menu.prev_buf
    or vim.api.nvim_win_get_buf(preview_win)

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = self.entry.menu.buf,
    callback = function()
      self:preview_restore_view()
    end,
  })
  vim.api.nvim_win_set_buf(preview_win, preview_buf)
  -- set cursor to the last exited position in buf (:h '"), if available
  local last_exit = vim.api.nvim_buf_get_mark(preview_buf, '"')
  if last_exit[1] ~= 0 then
    vim.api.nvim_win_set_cursor(preview_win, last_exit)
  end

  vim.bo[preview_buf].buflisted = buflisted

  -- ensure dropbar still shows then the preview buffer is opened
  vim.wo[preview_win].winbar = '%{%v:lua.dropbar()%}'
end

---@param self dropbar_symbol_t
local function preview_close(self)
  if self.win then
    if self.entry.menu.prev_buf then
      vim.api.nvim_win_set_buf(self.win, self.entry.menu.prev_buf)
    end
    if self.view then
      vim.api.nvim_win_call(self.win, function()
        vim.fn.winrestview(self.view)
      end)
    end
  end
end

---Convert a path to a dropbar symbol
---@param path string full path
---@param buf integer buffer handler
---@param win integer window handler
---@return dropbar_symbol_t
local function convert(path, buf, win)
  local path_opts = configs.opts.sources.path
  local icon_opts = configs.opts.icons
  local icon ---@type string?
  local icon_hl ---@type string?
  local name_hl ---@type string?
  local stat = vim.uv.fs_stat(path)
  if stat and stat.type == 'directory' then
    icon, icon_hl = configs.eval(icon_opts.kinds.dir_icon, path)
    name_hl = 'DropBarKindDir'
  else
    icon, icon_hl = configs.eval(icon_opts.kinds.file_icon, path)
    name_hl = 'DropBarKindFile'
  end

  return bar.dropbar_symbol_t:new(setmetatable({
    buf = buf,
    win = win,
    name = vim.fs.basename(path),
    icon = icon,
    name_hl = name_hl,
    icon_hl = icon_hl,
    ---Override the default jump function
    jump = vim.schedule_wrap(function(_)
      vim.cmd.edit(path)
    end),
    preview = vim.schedule_wrap(function(self)
      preview_open(self, path)
    end),
    preview_restore_view = preview_close,
  }, {
    ---@param self dropbar_symbol_t
    __index = function(self, k)
      if k == 'children' then
        self.children = {}
        for name in vim.fs.dir(path) do
          if path_opts.filter(name) then
            table.insert(self.children, convert(path .. '/' .. name, buf, win))
          end
        end
        return self.children
      end
      if k == 'siblings' or k == 'sibling_idx' then
        local parent_dir = vim.fs.dirname(path)
        self.siblings = {}
        self.sibling_idx = 1
        if parent_dir then
          for idx, name in vim.iter(vim.fs.dir(parent_dir)):enumerate() do
            if path_opts.filter(name) then
              table.insert(
                self.siblings,
                convert(parent_dir .. '/' .. name, buf, win)
              )
              if name == self.name then
                self.sibling_idx = idx
              end
            end
          end
        end
        return self[k]
      end
    end,
  }))
end

local normalize = vim.fs.normalize
if vim.uv.os_uname().sysname:find('Windows', 1, true) then
  ---Normalize path on Windows, see #174
  ---In addition to normalizing the path with `vim.fs.normalize()`, we convert
  ---the drive letter to uppercase.
  ---This is a workaround for the issue that the path is case-insensitive on
  ---Windows, as a result `vim.api.nvim_buf_get_name()` and `vim.fn.getcwd()`
  ---can return the same drive letter with different cases, e.g. 'C:' and 'c:'.
  ---To standardize this, we convert the drive letter to uppercase.
  ---@param path string full path
  ---@return string: path with uppercase drive letter
  function normalize(path)
    return (
      string.gsub(vim.fs.normalize(path), '^([a-zA-Z]):', function(c)
        return c:upper() .. ':'
      end)
    )
  end
end

---Get list of dropbar symbols of the parent directories of given buffer
---@param buf integer buffer handler
---@param win integer window handler
---@param _ integer[] cursor position, ignored
---@return dropbar_symbol_t[] dropbar symbols
local function get_symbols(buf, win, _)
  local path_opts = configs.opts.sources.path
  local symbols = {} ---@type dropbar_symbol_t[]
  local current_path = normalize((vim.api.nvim_buf_get_name(buf)))
  local root = normalize(configs.eval(path_opts.relative_to, buf, win))
  while
    #symbols < configs.opts.sources.path.max_depth
    and current_path
    and current_path ~= '.'
    and current_path ~= root
    and current_path ~= vim.fs.dirname(current_path)
  do
    table.insert(symbols, 1, convert(current_path, buf, win))
    current_path = vim.fs.dirname(current_path)
  end
  if vim.bo[buf].mod then
    symbols[#symbols] = path_opts.modified(symbols[#symbols])
  end
  return symbols
end

return {
  get_symbols = get_symbols,
}
