local configs = require('dropbar.configs')
local bar = require('dropbar.bar')

---Preview file represented by symbol `sym`
---@param sym dropbar_symbol_t
---@return nil
local function preview(sym)
  -- Cannot preview a symbol without corresponding source window
  if not sym.win or not vim.api.nvim_win_is_valid(sym.win) then
    return
  end

  if not configs.eval(configs.opts.sources.path.preview, sym.data.path) then
    return
  end

  if
    not sym.data.preview_buf
    or not vim.api.nvim_buf_is_valid(sym.data.preview_buf)
  then
    sym.data.preview_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[sym.data.preview_buf].bufhidden = 'wipe'
    vim.bo[sym.data.preview_buf].filetype = 'dropbar_preview'
    vim.api.nvim_win_call(sym.win, function()
      vim.api.nvim_set_current_buf(sym.data.preview_buf)
    end)
  end

  -- Preview buffer already contains contents of file to preview
  local preview_bufname = vim.fn.bufname(sym.data.preview_buf)
  local preview_bufnewname = 'dropbar_preview://' .. sym.data.path
  if preview_bufname == preview_bufnewname then
    return
  end

  local stat = sym.data.path and vim.uv.fs_stat(sym.data.path)
  local preview_win_height = vim.api.nvim_win_get_height(sym.win)
  local preview_win_width = vim.api.nvim_win_get_width(sym.win)
  local add_syntax = false

  ---Generate lines for preview window when preview is not available
  ---@param msg string
  ---@return string[]
  local function nopreview(msg)
    local lines = {}
    local fillchar = vim.opt_local.fillchars:get().diff or '-'
    local msglen = #msg + 4
    local padlen_l = math.max(0, math.floor((preview_win_width - msglen) / 2))
    local padlen_r = math.max(0, preview_win_width - msglen - padlen_l)
    local line_fill = fillchar:rep(preview_win_width)
    local half_fill_l = fillchar:rep(padlen_l)
    local half_fill_r = fillchar:rep(padlen_r)
    local line_above = half_fill_l .. string.rep(' ', msglen) .. half_fill_r
    local line_below = line_above
    local line_msg = half_fill_l .. '  ' .. msg .. '  ' .. half_fill_r
    local half_height_u = math.max(0, math.floor((preview_win_height - 3) / 2))
    local half_height_d = math.max(0, preview_win_height - 3 - half_height_u)
    for _ = 1, half_height_u do
      table.insert(lines, line_fill)
    end
    table.insert(lines, line_above)
    table.insert(lines, line_msg)
    table.insert(lines, line_below)
    for _ = 1, half_height_d do
      table.insert(lines, line_fill)
    end
    return lines
  end

  vim.api.nvim_buf_set_name(sym.data.preview_buf, preview_bufnewname)
  vim.api.nvim_buf_call(sym.data.preview_buf, function()
    vim.treesitter.stop(sym.data.preview_buf)
    vim.bo.syntax = ''
  end)

  local lines = not stat and nopreview('Not a file or directory')
    or stat.type == 'directory' and vim.fn.systemlist(
      'ls -lhA ' .. vim.fn.shellescape(sym.data.path)
    )
    or stat.size == 0 and nopreview('Empty file')
    or not vim.fn.system({ 'file', sym.data.path }):match('text') and nopreview(
      'Binary file, no preview available'
    )
    or (function()
        add_syntax = true
        return true
      end)()
      and vim
        .iter(io.lines(sym.data.path))
        :take(preview_win_height)
        :map(function(line)
          return (line:gsub('\x0d$', ''))
        end)
        :totable()

  vim.bo[sym.data.preview_buf].modifiable = true
  vim.api.nvim_buf_set_lines(sym.data.preview_buf, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(sym.data.preview_buf, 0, -1, false, lines)
  vim.bo[sym.data.preview_buf].modifiable = false

  if not add_syntax then
    return
  end

  local ft = vim.filetype.match({
    buf = sym.data.preview_buf,
    filename = sym.data.path,
  })
  if ft and not pcall(vim.treesitter.start, sym.data.preview_buf, ft) then
    vim.bo[sym.data.preview_buf].syntax = ft
  end
end

---@param sym dropbar_symbol_t
local function preview_restore_view(sym)
  if not sym.win then
    return
  end
  if sym.entry.menu.prev_buf then
    vim.api.nvim_win_set_buf(sym.win, sym.entry.menu.prev_buf)
  end
  if sym.view then
    vim.api.nvim_win_call(sym.win, function()
      vim.fn.winrestview(sym.view)
    end)
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
    data = { path = path },
    ---Override the default jump function
    jump = function(self)
      vim.cmd.edit(self.data.path)
      vim.cmd.normal({ "m'", bang = true })
    end,
    preview = preview,
    preview_restore_view = preview_restore_view,
  }, {
    ---@param self dropbar_symbol_t
    __index = function(self, k)
      if not self.data or not self.data.path then
        return
      end

      if k == 'children' then
        self.children = {}
        for name in vim.fs.dir(self.data.path) do
          if path_opts.filter(name) then
            table.insert(
              self.children,
              convert(self.data.path .. '/' .. name, buf, win)
            )
          end
        end
        return self.children
      end

      if k == 'siblings' or k == 'sibling_idx' then
        local parent_dir = vim.fs.dirname(self.data.path)
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

local fs_normalize = not vim.uv.os_uname().sysname:find('Windows', 1, true)
    -- Normalization function for Unix-like file systems
    and function(path, ...)
      -- Use `string.gsub()` to remove prefixes e.g. `oil://`, `fugitive://`
      -- in some plugin special buffers
      return vim.fs.normalize(path:gsub('^%S+://', '', 1), ...)
    end
  ---Normalize path on Windows, see #174
  ---In addition to normalizing the path with `vim.fs.normalize()`, we convert
  ---the drive letter to uppercase.
  ---This is a workaround for the issue that the path is case-insensitive on
  ---Windows, as a result `vim.api.nvim_buf_get_name()` and `vim.fn.getcwd()`
  ---can return the same drive letter with different cases, e.g. 'C:' and 'c:'.
  ---To standardize this, we convert the drive letter to uppercase.
  ---@param path string full path
  ---@return string: path with uppercase drive letter
  or function(path, ...)
    return (
      string.gsub(
        vim.fs.normalize(path:gsub('^%S+://', '', 1), ...),
        '^([a-zA-Z]):',
        function(c)
          return c:upper() .. ':'
        end
      )
    )
  end

---Get list of dropbar symbols of the parent directories of given buffer
---@param buf integer buffer handler
---@param win integer window handler
---@param _ integer[] cursor position, ignored
---@return dropbar_symbol_t[] dropbar symbols
local function get_symbols(buf, win, _)
  local path_opts = configs.opts.sources.path
  local symbols = {} ---@type dropbar_symbol_t[]
  local current_path = fs_normalize((vim.api.nvim_buf_get_name(buf)))
  local root = fs_normalize(configs.eval(path_opts.relative_to, buf, win))
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
