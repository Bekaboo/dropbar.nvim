local configs = require('dropbar.configs')
local bar = require('dropbar.bar')
local utils = require('dropbar.utils')

---Normalize executable path
---If `cmd` is executable, it is returned as is; else we try to find it under
---git installation and return its path; return `false` if we cannot find it
---@type table<string, string|false>
local exepath = vim.defaulttable(function(cmd)
  if vim.fn.executable(cmd) == 1 then
    return cmd
  end

  -- Windows git intallation ships some GNU tools, so try to find tools under
  -- git installation
  local git = vim.fn.exepath('git')
  if git == '' then
    return false
  end

  cmd = vim.fs.joinpath(
    vim.fs.joinpath(vim.fs.dirname(vim.fs.dirname(git)), 'usr/bin'),
    cmd
  )
  return vim.fn.executable(cmd) == 1 and cmd or false
end)

---@return string
local function preview_get_filler()
  return vim.opt_local.fillchars:get().diff or '-'
end

---Generate lines to show a message when preview is not available
---@param msg string
---@param height integer
---@param width integer
---@return string[]
local function preview_msg(msg, height, width)
  local lines = {}
  local fillchar = preview_get_filler()
  local msglen = #msg + 4
  local padlen_l = math.max(0, math.floor((width - msglen) / 2))
  local padlen_r = math.max(0, width - msglen - padlen_l)
  local line_fill = fillchar:rep(width)
  local half_fill_l = fillchar:rep(padlen_l)
  local half_fill_r = fillchar:rep(padlen_r)
  local line_above = half_fill_l .. string.rep(' ', msglen) .. half_fill_r
  local line_below = line_above
  local line_msg = half_fill_l .. '  ' .. msg .. '  ' .. half_fill_r
  local half_height_u = math.max(0, math.floor((height - 3) / 2))
  local half_height_d = math.max(0, height - 3 - half_height_u)
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

---@param buf integer
---@return string?
local function preview_buf_get_path(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  return vim.fn.bufname(buf):match('dropbar_preview_%d+://(.*)')
end

---Disable window options, e.g. spell, number, signcolumn, etc. in given window
---@param win integer? default to current window
local function preview_disable_win_opts(win)
  vim.api.nvim_win_call(win or 0, function()
    vim.opt_local.spell = false
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = 'no'
    vim.opt_local.foldcolumn = '0'
    vim.opt_local.statuscolumn = ''
    vim.opt_local.winbar = ''
  end)
end

---Set window options, e.g. spell, number, signcolumn, etc. to global value
---@param win integer? default to current window
local function preview_restore_win_opts(win)
  vim.api.nvim_win_call(win or 0, function()
    vim.opt_local.spell = vim.go.spell
    vim.opt_local.number = vim.go.number
    vim.opt_local.relativenumber = vim.go.relativenumber
    vim.opt_local.signcolumn = vim.go.signcolumn
    vim.opt_local.foldcolumn = vim.go.foldcolumn
    vim.opt_local.statuscolumn = vim.go.statuscolumn
    vim.opt_local.winbar = vim.go.winbar
  end)
end

---Colorize preview buffer with syntax highlighting, set win opts, etc.
---@param win integer?
local function preview_decorate(win)
  win = win or 0
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local buf = vim.fn.winbufnr(win)
  local bufname = vim.fn.bufname(buf)
  local path = preview_buf_get_path(buf)
  if not path then
    return
  end

  -- Add syntax highlighting for message fillers
  if vim.b[buf]._dropbar_preview_msg_shown == bufname then
    -- Set some window options if showing messages instead of preview
    preview_disable_win_opts(win)
    vim.api.nvim_buf_call(buf, function()
      vim.treesitter.stop(buf)
      vim.bo.syntax = ''
      vim.cmd.syntax(
        string.format(
          'match NonText /\\V%s/',
          vim.fn.escape(preview_get_filler(), '/?')
        )
      )
    end)
    return
  end

  -- Add syntax highlighting to directories or files
  vim.uv.fs_stat(
    path,
    vim.schedule_wrap(function(_, stat)
      if not stat or preview_buf_get_path(buf) ~= path then
        return
      end

      -- Add syntax highlighting for `ls` output
      if stat.type == 'directory' then
        -- Disable window decorations when previewing a directory to match oil
        -- window appearance
        preview_disable_win_opts(win)
        vim.api.nvim_buf_call(buf, function()
          vim.treesitter.stop(buf)
          vim.bo.syntax = ''
          vim.cmd([[
            syn match DropbarDirPreviewHeader /^total.*/
            syn match DropbarDirPreviewTypeFile /^-/ nextgroup=DropbarDirPreviewFilePerms skipwhite
            syn match DropbarDirPreviewTypeDir /^d/ nextgroup=DropbarDirPreviewDirPerms skipwhite
            syn match DropbarDirPreviewTypeFifo /^p/ nextgroup=DropbarDirPreviewFifoPerms skipwhite
            syn match DropbarDirPreviewTypeLink /^l/ nextgroup=DropbarDirPreviewLinkPerms skipwhite
            syn match DropbarDirPreviewTypeSocket /^s/ nextgroup=DropbarDirPreviewSocketPerms skipwhite

            for type in ['File', 'Dir', 'Fifo', 'Link', 'Socket']
              exe substitute('syn match DropbarDirPreview%sPerms /\v[-rwxs]{9}[\.\@\+]?/ contained
                            \ contains=DropbarDirPreviewPermRead,DropbarDirPreviewPermWrite,
                                     \ DropbarDirPreviewPermExec,DropbarDirPreviewPermSetuid,
                                     \ DropbarDirPreviewPermNone,DropbarDirPreviewSecurityContext,
                                     \ DropbarDirPreviewSecurityExtended
                            \ nextgroup=DropbarDirPreview%sNumHardLinksNormal,
                                      \ DropbarDirPreview%sNumHardLinksMulti
                            \ skipwhite', '%s', type, 'g')
              exe substitute('syn match DropbarDirPreview%sNumHardLinksNormal /1/ contained nextgroup=DropbarDirPreview%sUser skipwhite', '%s', type, 'g')
              exe substitute('syn match DropbarDirPreview%sNumHardLinksMulti /\v[2-9]\d*|1\d+/ contained nextgroup=DropbarDirPreview%sUser skipwhite', '%s', type, 'g')
              exe substitute('syn match DropbarDirPreview%sUser /\v\S+/ contained nextgroup=DropbarDirPreview%sGroup skipwhite', '%s', type, 'g')
              exe substitute('syn match DropbarDirPreview%sGroup /\v\S+/ contained nextgroup=DropbarDirPreview%sSize skipwhite', '%s', type, 'g')
              exe substitute('syn match DropbarDirPreview%sSize /\v\S+/ contained nextgroup=DropbarDirPreview%sTime skipwhite', '%s', type, 'g')
              exe substitute('syn match DropbarDirPreview%sTime /\v(\S+\s+){3}/ contained
                            \ nextgroup=DropbarDirPreview%s,DropbarDirPreview%sHidden
                            \ skipwhite', '%s', type, 'g')

              exe substitute('hi def link DropbarDirPreview%sNumHardLinksNormal Number', '%s', type, 'g')
              exe substitute('hi def link DropbarDirPreview%sNumHardLinksMulti DropbarDirPreview%sNumHardLinksNormal', '%s', type, 'g')
              exe substitute('hi def link DropbarDirPreview%sSize Number', '%s', type, 'g')
              exe substitute('hi def link DropbarDirPreview%sTime String', '%s', type, 'g')
              exe substitute('hi def link DropbarDirPreview%sUser Operator', '%s', type, 'g')
              exe substitute('hi def link DropbarDirPreview%sGroup Structure', '%s', type, 'g')
           endfor

            syn match DropbarDirPreviewPermRead /r/ contained
            syn match DropbarDirPreviewPermWrite /w/ contained
            syn match DropbarDirPreviewPermExec /x/ contained
            syn match DropbarDirPreviewPermSetuid /s/ contained
            syn match DropbarDirPreviewPermNone /-/ contained
            syn match DropbarDirPreviewSecurityContext /\./ contained
            syn match DropbarDirPreviewSecurityExtended /@\|+/ contained

            syn match DropbarDirPreviewDir /[^.].*/ contained
            syn match DropbarDirPreviewFile /[^.].*/ contained
            syn match DropbarDirPreviewSocket /[^.].*/ contained
            syn match DropbarDirPreviewLink /[^.].*/ contained contains=DropbarDirPreviewLinkTarget
            syn match DropbarDirPreviewLinkTarget /->.*/ contained

            syn match DropbarDirPreviewDirHidden /\..*/ contained
            syn match DropbarDirPreviewFileHidden /\..*/ contained
            syn match DropbarDirPreviewSocketHidden /\..*/ contained
            syn match DropbarDirPreviewLinkHidden /\..*/ contained contains=DropbarDirPreviewLinkTargetHidden
            syn match DropbarDirPreviewLinkTargetHidden /->.*/ contained

            hi def link DropBarDirPreviewHeader Title
            hi def link DropBarDirPreviewTypeFile DropBarIconKindFile
            hi def link DropBarDirPreviewTypeDir DropBarIconKindFolder
            hi def link DropBarDirPreviewTypeFifo Special
            hi def link DropBarDirPreviewTypeLink Constant
            hi def link DropBarDirPreviewTypeSocket Keyword

            hi def link DropBarDirPreviewPermRead DiagnosticSignWarn
            hi def link DropBarDirPreviewPermWrite DiagnosticSignError
            hi def link DropBarDirPreviewPermExec DiagnosticSignInfo
            hi def link DropBarDirPreviewPermSetuid DignosticSignHint
            hi def link DropBarDirPreviewPermNone NonText
            hi def link DropBarDirPreviewSecurityContext Special
            hi def link DropBarDirPreviewSecurityExtended Special

            hi def link DropBarDirPreviewDir Directory
            hi def link DropBarDirPreviewFile DropBarKindFile
            hi def link DropBarDirPreviewLink Constant
            hi def link DropBarDirPreviewLinkTarget Special
            hi def link DropBarDirPreviewSocket Keyword

            hi def link DropBarDirPreviewDirHidden NonText
            hi def link DropBarDirPreviewFileHidden DropBarDirPreviewFile
            hi def link DropBarDirPreviewLinkHidden DropBarDirPreviewLink
            hi def link DropBarDirPreviewLinkTargetHidden DropBarDirPreviewLinkTarget
            hi def link DropBarDirPreviewSocketHidden DropBarDirPreviewSocket
          ]])
        end)
        return
      end

      -- Add syntax/treesitter highlighting for normal files
      if vim.b[buf]._dropbar_preview_syntax == bufname then
        preview_restore_win_opts(win)
        local ft = vim.filetype.match({
          buf = buf,
          filename = path,
        })
        vim.api.nvim_buf_call(buf, function()
          if not ft then
            vim.treesitter.stop()
            vim.bo.syntax = ''
            return
          end
          if not pcall(vim.treesitter.start, buf, ft) then
            vim.treesitter.stop()
            vim.bo.syntax = ft
          end
        end)
      end
    end)
  )
end

---@param win integer
---@param lines string[]
---@param path string
local function preview_win_set_lines(win, lines, path)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local buf = vim.fn.winbufnr(win)
  if preview_buf_get_path(buf) ~= path then
    return
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  preview_decorate(win)
end

---@param win integer
local function preview_set_lines(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local bufname = vim.fn.bufname(buf)

  local path = preview_buf_get_path(buf)
  if not path then
    return
  end

  local stat = vim.uv.fs_stat(path)
  local win_height = vim.api.nvim_win_get_height(win)
  local win_width = vim.api.nvim_win_get_width(win)

  if not stat then
    vim.b[buf]._dropbar_preview_msg_shown = bufname
    preview_win_set_lines(
      win,
      preview_msg('Invalid path', win_height, win_width),
      path
    )
    return
  end

  -- Preview directories
  if stat.type == 'directory' then
    local ls_cmd = exepath.ls
    if not ls_cmd then
      preview_win_set_lines(
        win,
        preview_msg(
          '`ls` is required to previous directories',
          win_height,
          win_width
        ),
        path
      )
      return
    end

    vim.system(
      {
        ls_cmd,
        '-lhA',
        path,
      },
      { text = true },
      vim.schedule_wrap(function(obj)
        preview_win_set_lines(
          win,
          vim
            .iter(vim.gsplit(obj.stdout, '\n'))
            :take(win_height)
            :map(function(line)
              local result = vim.fn.match(line, '\\v^[-dpls][-rwxs]{9}') == -1
                  and line
                or line:sub(1, 1) .. ' ' .. line:sub(2)
              return result
            end)
            :totable(),
          path
        )
      end)
    )
    return
  end

  -- Preview files
  local function preview_file()
    if vim.fn.winbufnr(win) ~= buf then
      return
    end

    vim.b[buf]._dropbar_preview_syntax = bufname
    preview_win_set_lines(
      win,
      vim
        .iter(io.lines(path))
        :take(win_height)
        :map(function(line)
          return (line:gsub('\x0d$', ''))
        end)
        :totable(),
      path
    )
  end

  local file_cmd = exepath.file
  if not file_cmd then
    preview_file()
    return
  end

  -- Use `file` to check and preview text files only
  vim.system(
    { file_cmd, path },
    { text = true },
    vim.schedule_wrap(function(obj)
      if vim.fn.winbufnr(win) ~= buf then
        return
      end

      if obj.stdout:match('text') or obj.stdout:match('empty') then
        preview_file()
        return
      end

      vim.b[buf]._dropbar_preview_msg_shown = bufname
      preview_win_set_lines(
        win,
        preview_msg('Binary file', win_height, win_width),
        path
      )
    end)
  )
end

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
  local preview_bufnewname = ('dropbar_preview_%d://%s'):format(
    preview_buf,
    path
  )
  if preview_bufname == preview_bufnewname then
    return
  end
  vim.api.nvim_buf_set_name(preview_buf, preview_bufnewname)

  preview_set_lines(preview_win)
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

local fs_normalize = vim.uv.os_uname().sysname:find('Windows', 1, true)
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
  buf = vim._resolve_bufnr(buf)
  if
    not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win)
  then
    return {}
  end

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

  utils.bar.set_min_widths(symbols, path_opts.min_widths)
  return symbols
end

return { get_symbols = get_symbols }
