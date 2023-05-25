local utils = require('dropbar.sources.utils')
local configs = require('dropbar.configs')

---Unify a path into a dropbar tree symbol tree structure
---@param path string full path
---@return dropbar_path_symbol_tree_t
local function unify(path)
  return setmetatable({
    name = vim.fs.basename(path),
    kind = '',
    data = { path = path },
  }, {
    ---@param self dropbar_symbol_tree_t
    __index = function(self, k)
      if k == 'children' then
        self.children = {}
        for name in vim.fs.dir(path) do
          if configs.opts.sources.path.filter(name) then
            table.insert(self.children, unify(path .. '/' .. name))
          end
        end
        return self.children
      end
      if k == 'siblings' or k == 'idx' then
        local parent_dir = vim.fs.dirname(path)
        self.siblings = {}
        self.idx = 1
        for idx, name in vim.iter(vim.fs.dir(parent_dir)):enumerate() do
          if configs.opts.sources.path.filter(name) then
            table.insert(self.siblings, unify(parent_dir .. '/' .. name))
            if name == self.name then
              self.idx = idx
            end
          end
        end
        return self[k]
      end
    end,
  })
end

---Get list of dropbar symbols of the parent directories of given buffer
---@param buf integer buffer handler
---@param _ integer[] cursor position, ignored
---@return dropbar_symbol_t[] dropbar symbols
local function get_symbols(buf, _)
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
    table.insert(
      symbols,
      1,
      utils.to_dropbar_symbol_from_path(unify(current_path))
    )
    current_path = vim.fs.dirname(current_path)
  end
  return symbols
end

return {
  get_symbols = get_symbols,
}
