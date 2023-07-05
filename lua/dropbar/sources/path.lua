local configs = require('dropbar.configs')
local bar = require('dropbar.bar')
local hlgroups = require('dropbar.hlgroups')

---Get icon and icon highlight group of a path
---@param path string
---@return string icon
---@return string? icon_hl
local function get_icon(path)
  local icon = configs.opts.icons.kinds.symbols.File
  local icon_hl = 'DropBarIconKindFile'
  local stat = vim.loop.fs_stat(path)
  if not stat then
    return icon, icon_hl
  elseif stat.type == 'directory' then
    icon = configs.opts.icons.kinds.symbols.Folder
    icon_hl = 'DropBarIconKindFolder'
  end
  if configs.opts.icons.kinds.use_devicons then
    local devicons_ok, devicons = pcall(require, 'nvim-web-devicons')
    if devicons_ok and stat and stat.type ~= 'directory' then
      local devicon, devicon_hl = devicons.get_icon(
        vim.fs.basename(path),
        vim.fn.fnamemodify(path, ':e'),
        { default = true }
      )
      icon = devicon and devicon .. ' ' or icon
      icon_hl = hlgroups.get_devicon_hlgroup(devicon_hl)
    end
  end
  return icon, icon_hl
end

---Convert a path to a dropbar symbol
---@param path string full path
---@param buf integer buffer handler
---@param win integer window handler
---@return dropbar_symbol_t
local function convert(path, buf, win)
  local icon, icon_hl = get_icon(path)
  return bar.dropbar_symbol_t:new(setmetatable({
    buf = buf,
    win = win,
    name = vim.fs.basename(path),
    icon = icon,
    name_hl = 'DropBarKindFolder',
    icon_hl = icon_hl,
    ---Override the default jump function
    jump = function(_)
      vim.cmd.edit(path)
    end,
  }, {
    ---@param self dropbar_symbol_t
    __index = function(self, k)
      if k == 'children' then
        self.children = {}
        for name in vim.fs.dir(path) do
          if configs.opts.sources.path.filter(name) then
            table.insert(
              self.children,
              convert(vim.fs.joinpath(path, name), buf, win)
            )
          end
        end
        local path_is_dir = 1 == vim.fn.isdirectory(path)
        if configs.opts.sources.path.filter('..') and path_is_dir then
          table.insert(
            self.children,
            convert(vim.fs.joinpath(path, '..'), buf, win)
          )
        elseif not path_is_dir and (
          vim.fs.normalize(path) ==
          vim.fs.normalize(
            vim.fn.fnamemodify((vim.api.nvim_buf_get_name(buf)), ':p')
          )
        ) then
          local ts_symbols = require('dropbar.sources.treesitter')
                            .get_symbols(buf, win, { 0, 0 }, { all_symbols = true })
          vim.list_extend(self.children, ts_symbols)
          self.data = self.data or {}
          self.data.ui_icon_hl_override = 'DropBarIconUISeparatorSpecial'
        end
        return self.children
      end
      if k == 'siblings' or k == 'sibling_idx' then
        local parent_dir = vim.fs.dirname(path)
        self.siblings = {}
        self.sibling_idx = 1
        for idx, name in vim.iter(vim.fs.dir(parent_dir)):enumerate() do
          if configs.opts.sources.path.filter(name) then
            table.insert(
              self.siblings,
              convert(vim.fs.joinpath(parent_dir, name), buf, win)
            )
            if name == self.name then
              self.sibling_idx = idx
            end
          end
        end
        if configs.opts.sources.path.filter('..') then
          table.insert(
            self.siblings,
            convert(vim.fs.joinpath(parent_dir, '..'), buf, win)
          )
        end
        return self[k]
      end
    end,
  }))
end

---Get list of dropbar symbols of the parent directories of given buffer
---@param buf integer buffer handler
---@param win integer window handler
---@param _ integer[] cursor position, ignored
---@return dropbar_symbol_t[] dropbar symbols
local function get_symbols(buf, win, _)
  local symbols = {} ---@type dropbar_symbol_t[]
  local current_path = vim.fs.normalize(
    vim.fn.fnamemodify((vim.api.nvim_buf_get_name(buf)), ':p')
  )
  while
    current_path ~= '.'
    and current_path ~= '/'
    and current_path
      ~= vim.fs.normalize(
        configs.eval(configs.opts.sources.path.relative_to, buf)
      )
  do
    table.insert(symbols, 1, convert(current_path, buf, win))
    current_path = vim.fs.dirname(current_path)
  end
  if vim.bo[buf].mod then
    symbols[#symbols] = configs.opts.sources.path.modified(symbols[#symbols])
  end
  return symbols
end

return {
  get_symbols = get_symbols,
}
