local configs = require('dropbar.configs')
local bar = require('dropbar.bar')

local _is_windows ---@type boolean?

---Check if nvim is running on Windows
---@return boolean
local function is_windows()
  if _is_windows ~= nil then
    return _is_windows
  end
  _is_windows = vim.uv.os_uname().sysname:find('Windows', 1, true) ~= nil
  return _is_windows
end

---Use GNU tools shipped with git on Windows
---@type table<string, string|false>
local gnu_tool_paths = vim.defaulttable(function(cmd)
  if not is_windows() then
    return cmd
  end
  local git = vim.fn.exepath('git')
  if git == '' then
    return false
  end
  return vim.fs.joinpath(
    vim.fs.joinpath(vim.fs.dirname(vim.fs.dirname(git)), 'usr/bin'),
    cmd
  )
end)

---Preview file represented by symbol `sym`
---@param sym dropbar_symbol_t
---@return nil
local function preview(sym)
  if not configs.eval(configs.opts.sources.path.preview, sym.data.path) then
    return
  end

  -- Cannot preview a symbol without corresponding source window
  local preview_win = sym.win
  if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
    return
  end

  local preview_buf = sym.data.preview_buf
  if not preview_buf or not vim.api.nvim_buf_is_valid(preview_buf) then
    preview_buf = vim.api.nvim_create_buf(false, true)
    sym.data.preview_buf = preview_buf
    vim.bo[preview_buf].bufhidden = 'wipe'
    vim.bo[preview_buf].filetype = 'dropbar_preview'
    vim.api.nvim_win_call(sym.win, function()
      vim.api.nvim_set_current_buf(preview_buf)
    end)
  end

  -- Follow symlinks
  local path = vim.F.npcall(vim.uv.fs_realpath, sym.data.path) or ''

  -- Preview buffer already contains contents of file to preview
  local preview_bufname = vim.fn.bufname(preview_buf)
  local preview_bufnewname = 'dropbar_preview://' .. path
  if preview_bufname == preview_bufnewname then
    return
  end

  local stat = path and vim.uv.fs_stat(path)
  local preview_win_height = vim.api.nvim_win_get_height(sym.win)
  local preview_win_width = vim.api.nvim_win_get_width(sym.win)
  local add_syntax = false
  local msg_shown = false

  ---Generate lines to show a message when preview is not available
  ---@param msg string
  ---@return string[]
  local function preview_msg(msg)
    msg_shown = true
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

  vim.api.nvim_buf_set_name(preview_buf, preview_bufnewname)
  vim.api.nvim_buf_call(preview_buf, function()
    vim.treesitter.stop(preview_buf)
    vim.bo.syntax = ''
  end)

  local lines = (function()
    if not stat then
      return preview_msg('Invalid path')
    end

    if stat.type == 'directory' then
      local ls_cmd = gnu_tool_paths.ls
      return ls_cmd and vim.fn.systemlist({ ls_cmd, '-lhA', path })
        or preview_msg('`ls` is required to preview directories')
    end

    if stat.size == 0 then
      return preview_msg('Empty file')
    end

    local file_cmd = gnu_tool_paths.file
    local ft = file_cmd and vim.system({ file_cmd, path }):wait().stdout
    if ft and not ft:match('text') then
      return preview_msg('Binary file')
    end

    add_syntax = true
    return vim.fn.readfile(path, '', preview_win_height)
  end)()

  vim.bo[preview_buf].modifiable = true
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
  vim.bo[preview_buf].modifiable = false

  if add_syntax then
    local ft = vim.filetype.match({
      buf = preview_buf,
      filename = path,
    })
    if ft and not pcall(vim.treesitter.start, preview_buf, ft) then
      vim.bo[preview_buf].syntax = ft
    end
  end

  if msg_shown then
    vim.api.nvim_win_call(preview_win or 0, function()
      vim.opt_local.spell = false
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.opt_local.signcolumn = 'no'
      vim.opt_local.foldcolumn = '0'
      vim.opt_local.statuscolumn = ''
      vim.opt_local.winbar = ''
    end)
  else
    vim.api.nvim_win_call(preview_win or 0, function()
      vim.opt_local.spell = vim.go.spell
      vim.opt_local.number = vim.go.number
      vim.opt_local.relativenumber = vim.go.relativenumber
      vim.opt_local.signcolumn = vim.go.signcolumn
      vim.opt_local.foldcolumn = vim.go.foldcolumn
      vim.opt_local.statuscolumn = vim.go.statuscolumn
      vim.opt_local.winbar = vim.go.winbar
    end)
  end
end

---@param sym dropbar_symbol_t
local function preview_restore_view(sym)
  if not sym.win or not sym.entry or not sym.entry.menu then
    return
  end

  local source_buf = sym.entry.menu:root().prev_buf
  if source_buf and vim.api.nvim_buf_is_valid(source_buf) then
    vim.api.nvim_win_set_buf(sym.win, source_buf)
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
      vim.cmd.edit(vim.fn.fnameescape(self.data.path))
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

local fs_normalize = not is_windows()
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
