-- If not built with LuaJIT, the ffi module will not be available,
-- and neither will the fzf-native module (which is written in C and
-- uses ffi).
if not jit then
  return false
end

---@class fzf_lib_t
---@field get_score
---| fun(input: string, pattern: ffi.cdata*, slab: ffi.cdata*): number
---@field get_pos
---| fun(input: string, pattern: ffi.cdata*, slab: ffi.cdata*): nil|number[]
---@field parse_pattern
---| fun(pattern: string, case_mode: integer?, fuzzy: boolean): ffi.cdata*
---@field free_pattern fun(pattern: ffi.cdata*)
---@field allocate_slab fun(): ffi.cdata*
---@field free_slab fun(slab: ffi.cdata*)
local fzf_lib = vim.F.ok_or_nil(pcall(require, 'fzf_lib'))

if not fzf_lib then
  return false
end

---@class fzf_entry_t
---@field index integer
---@field str string
---@field locations integer[]
---@field score integer
---@field first integer
---@field pos integer[]?

---@class fzf_state_t
---@field slab ffi.cdata*
---@field menu_entries dropbar_menu_entry_t[]
---@field entries fzf_entry_t[]
---@field win integer
---@field proxy userdata
---@field num_entries integer
local fzf_state_t = {}
fzf_state_t.__index = fzf_state_t

---Create a new `fzf_state_t`. This extracts the
---@param menu dropbar_menu_t
---@param win integer
---@param opts table
---@return fzf_state_t?
---@version JIT
function fzf_state_t:new(menu, win, opts)
  local num_entries = #menu.entries
  local char_pattern = opts.char_pattern
  local entries = {}
  local space_char = string.byte(' ')
  local encountered_space = false
  local retain_inner_spaces = opts.retain_inner_spaces
  for i = 1, num_entries do
    local char_idx = 1
    local chars = {}
    local locations = {}
    local line = vim.api.nvim_buf_get_lines(menu.buf, i - 1, i, false)[1]
    if not line then
      return nil
    end
    local line_size = #line
    local c = string.find(line, char_pattern)
    while c and c <= line_size do
      chars[char_idx] = line:sub(c, c)
      locations[char_idx] = c
      char_idx = char_idx + 1
      c = c + 1
      -- this is used to keep a single space (if any) between words, because fzf's
      -- algorithm prioritizes patterns that are at word beginnings
      if
        retain_inner_spaces
        and not encountered_space
        and line:byte(c) == space_char
      then
        encountered_space = true
      else
        encountered_space = false
        c = string.find(line, char_pattern, c)
      end
    end
    entries[i] = {
      locations = locations,
      index = i,
      str = table.concat(chars),
      score = 0,
    }
  end
  local state = setmetatable({
    slab = fzf_lib.allocate_slab(),
    menu_entries = { unpack(menu.entries) },
    entries = entries,
    win = win,
    num_entries = num_entries,
    proxy = newproxy(true),
  }, self)
  -- in lua 5.1, __gc metamethods are reserved for userdata
  -- so we need to set it on a proxy object
  getmetatable(state.proxy).__gc = function(_)
    state:gc()
  end
  return state
end

---Free the memory allocated by the fuzzy finder
---@version JIT
function fzf_state_t:gc()
  if self.slab ~= nil then
    fzf_lib.free_slab(self.slab)
  end
  self.slab = nil
end

return {
  fzf_lib = fzf_lib,
  fzf_state_t = fzf_state_t,
}
