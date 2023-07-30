---@class fzf_mod_t
---@field load fun(): boolean
---@field loaded boolean
---@field native ffi.namespace*
---@field fzf_entry_t ffi.ctype*
---@field fzf_entry_array_t ffi.ctype*
---@field fzf_state_t fzf_state_t
---@field lib fzf_lib_t
---@field buf_get_line fun(buf: integer, line: integer): string?
local M = {
  loaded = false,
}

if not jit then
  return nil
end

---@class fzf_lib_t
---@field get_score
---| fun(input: ffi_str_t, pattern: fzf_pattern_t, slab: fzf_slab_t): number
---@field get_pos
---| fun(input: ffi_str_t, pattern: fzf_pattern_t, slab: fzf_slab_t): nil|number[]
---@field parse_pattern
---| fun(pattern: string, case_mode: integer?, fuzzy: boolean): fzf_pattern_t
---@field free_pattern fun(pattern: fzf_pattern_t)
---@field allocate_slab fun(): fzf_slab_t
---@field free_slab fun(slab: fzf_slab_t)
local fzf_lib = (function()
  local ok, lib = pcall(require, 'fzf_lib')
  return ok and lib or nil
end)()
M.lib = fzf_lib

if not fzf_lib then
  return nil
end

---@alias ffi_userdata_t userdata | ffi.cdata*
---@alias fzf_position_t { data: integer[], size: integer, cap: integer } | ffi.cdata*
---@alias fzf_pattern_t ffi_userdata_t
---@alias fzf_slab_t ffi_userdata_t
---@alias ffi_str_t string|ffi.cdata*

local ffi = require('ffi')
local C = ffi.C

ffi.cdef([[
  typedef int32_t linenr_T;
  typedef int handle_T;
  typedef handle_T Buffer;
  typedef enum {
    kErrorTypeNone = -1,
    kErrorTypeException,
    kErrorTypeValidation,
  } ErrorType;

  typedef struct {
    uint32_t index;
    char* str;
    uint16_t* locations;
    int32_t score;
    uint32_t first_position;
    fzf_position_t* pos;
  } fzf_entry_t;

  typedef struct {
    ErrorType type;
    char *msg;
  } Error;

  /* nvim/api/private/helpers.h */
  buf_T *find_buffer_by_handle(
    /* Buffer -> handle_T -> int */ int buffer,
    Error *err
  );

  /* nvim/memline.c */
  char* ml_get_buf(
    buf_T* buf,
    /* linenr_T -> int32_t */ int32_t lnum,
    bool will_change
  );

  void *calloc( size_t num, size_t size );
  void *malloc( size_t size );
  void free( void *ptr );
]])

---Get a single line from a buffer, equivalent to:
--- `vim.api.nvim_buf_get_lines(buf, line, line + 1, false)[1]`
---but much faster and jit-compilable.
---@param buf integer buffer handle
---@param line integer line number, 1-indexed
---@return string? line contents, or `nil` if an error occurred
local function buf_get_line(buf, line)
  local error = ffi.new('Error[1]')
  local buf_obj = C.find_buffer_by_handle(buf, error)
  if buf_obj == nil then
    return nil
  end
  local c_str = C.ml_get_buf(buf_obj, line, false)
  if c_str == nil then
    return nil
  end
  return ffi.string(c_str)
end
M.buf_get_line = buf_get_line

---@class fzf_entry_t
---@field index integer
---@field str string|ffi.cdata*
---@field locations integer[]
---@field score integer
---@field first_position integer
---@field pos fzf_position_t?
local fzf_entry_t = ffi.typeof('fzf_entry_t') --[[@as fzf_entry_t]]
local fzf_entry_array_t = ffi.typeof('fzf_entry_t[?]')
M.fzf_entry_t = fzf_entry_t --[[@as ffi.ctype*]]
M.fzf_entry_array_t = fzf_entry_array_t

---@class fzf_state_t
---@field slab fzf_slab_t
---@field menu_entries dropbar_menu_entry_t[]
---@field entries fzf_entry_t[]
---@field win integer
---@field proxy userdata
---@field allocated boolean
---@field num_entries integer
local fzf_state_t = {}
fzf_state_t.__index = fzf_state_t
M.fzf_state_t = fzf_state_t

---Create a new `fzf_state_t`. This extracts the
---@param menu dropbar_menu_t
---@param win integer
---@param opts table
---@return fzf_state_t?
---@version JIT
function fzf_state_t:new(menu, win, opts)
  local num_entries = #menu.entries
  local char_pattern = opts.char_pattern

  ---@type fzf_entry_t[]
  -- local entries = ffi.new('fzf_entry_t[?]', num_entries)
  local entries = fzf_entry_array_t(num_entries)
  local buff_size = 256
  local chars_buff = ffi.new('char[?]', buff_size)
  local locations_buff = ffi.new('int16_t[?]', buff_size)
  local space_char = string.byte(' ')
  local encountered_space = false
  local retain_inner_spaces = opts.retain_inner_spaces

  -- todo: remove string.find() and string.byte() calls
  for i = 1, num_entries do
    local line = buf_get_line(menu.buf, i)
    if not line then
      for j = 1, i - 1 do
        C.free(entries[j - 1].locations)
        C.free(entries[j - 1].str)
      end
      return nil
    end
    local line_size = #line
    local buff_idx = 0
    local c = string.find(line, char_pattern)
    while c and c <= line_size and buff_idx < buff_size do
      chars_buff[buff_idx] = line:byte(c)
      locations_buff[buff_idx] = c - 1
      buff_idx = buff_idx + 1
      c = c + 1
      -- this is used to keep a single space (if any) between words, because fzf's
      -- algorithm prioritizes patterns that are at word beginnings
      -- e.g. without this, the query "foo" would prioritize '<something long>:fXoo'
      -- over 'X foo' because ':' is a word boundary and the space between 'a' and 'foo' is ignored
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

    local chars = ffi.cast('char*', C.calloc(buff_idx + 1, ffi.sizeof('char')))
    local locations = C.calloc(buff_idx, ffi.sizeof('int16_t'))
    if chars == nil or locations == nil then
      if chars ~= nil then
        C.free(chars)
      end
      if locations ~= nil then
        C.free(locations)
      end
      for j = 1, i - 1 do
        C.free(entries[j - 1].locations)
        C.free(entries[j - 1].str)
      end
      return nil
    end

    ffi.copy(chars, chars_buff, buff_idx * ffi.sizeof('char'))
    chars[buff_idx] = 0
    ffi.copy(locations, locations_buff, buff_idx * ffi.sizeof('int16_t'))

    -- *** NOTE ***
    -- On my machine, certain field initialization orderings
    -- cause 'illegal instruction' crashes, not sure why.
    -- This ordering works.
    local entry = entries[i - 1]
    entry.locations = locations
    entry.index = i
    entry.str = chars
    entry.score = 0
  end

  local state = setmetatable({
    slab = fzf_lib.allocate_slab(),
    menu_entries = { unpack(menu.entries) },
    entries = entries,
    win = win,
    allocated = true,
    num_entries = num_entries,
    proxy = newproxy(true),
  }, self)

  -- in lua 5.1, __gc metamethods are reserved for userdata
  -- so we need to set it on a proxy object
  -- This ensures that any abnormal termination of the fuzzy find
  -- that isn't handled by explicit stop or autocmds will still
  -- free the allocated memory
  getmetatable(state.proxy).__gc = function(_)
    if state.allocated then
      state:gc()
    end
  end

  return state
end

function fzf_state_t:gc()
  if self.slab ~= nil then
    fzf_lib.free_slab(self.slab)
  end
  self.slab = nil
  local fzf_entries = self.entries
  if fzf_entries ~= nil then
    for i = 0, self.num_entries - 1 do
      local entry = fzf_entries[i]
      C.free(entry.str)
      C.free(entry.locations)
    end
  end
  self.entries = nil
  self.allocated = false
end

---Fallback loader for *fzf_lib* if the plugin's path cannot be found from
---`debug.getinfo`. Currently not implemented.
local function fallback()
  -- for now, not implemented, but we could fallback
  -- to other search paths
  vim.notify('Could not find fzf_lib source', vim.log.levels.ERROR)
  return false
end

---Loads the native C implementation of *fzf_lib* and sets the `native` field in `M`
---to the ffi namespace. Returns `true` if successful, `false` otherwise. If already
---loaded, returns `true` immediately. If successful, sets `M.loaded` to `true`.
---@return boolean success
function M.load()
  if M.loaded then
    return true
  end
  local info = debug.getinfo(fzf_lib.get_pos, 'S')
  if not info or info.source:sub(1, 1) ~= '@' then
    return fallback()
  end

  local fzf_native_path = info.source:sub(2, #'/lua/fzf_lib.lua' * -1)
  local build_path = vim.fs.joinpath(fzf_native_path, 'build')
  if
    vim.fn.isdirectory(fzf_native_path) ~= 1
    or vim.fn.isdirectory(build_path) ~= 1
  then
    return false
  end
  local files = vim.iter(vim.fs.dir(build_path)):totable()
  if #files ~= 1 or files[1][2] ~= 'file' then
    return false
  end

  ---@type string
  local fzf_lib_path = files[1][1]
  if fzf_lib_path:sub(1, 3) ~= 'lib' then
    return false
  end

  M.native = ffi.load(vim.fs.joinpath(build_path, fzf_lib_path))
  M.loaded = true
  return true
end

---Copy the contents of `src` into `dst`
---@param dst fzf_entry_t
---@param src fzf_entry_t
local function copy_entry(dst, src)
  -- maybe use memcpy or ffi.copy?
  dst.index = src.index
  dst.str = src.str
  dst.locations = src.locations
  dst.score = src.score
  dst.first_position = src.first_position
  dst.pos = src.pos
end
M.copy_entry = copy_entry

---Compares the `a`-th and `b`-th entries in `entries`
---@param a integer
---@param b integer
---@param entries fzf_entry_t[]
---@return boolean # whether `entries[a]` should be sorted before `entries[b]`
local function compare(a, b, entries)
  local entry_a = entries[a]
  local entry_b = entries[b]
  if entry_a.score ~= entry_b.score then
    return entry_a.score > entry_b.score
  elseif entry_a.first_position ~= entry_b.first_position then
    return entry_a.first_position < entry_b.first_position
  else
    return entry_a.index < entry_b.index
  end
end

---Merges two sorted subarrays of `source` into `target`.
---The first subarray is `source[left..mid-1]` and the second is
---`source[mid..right-1]`.
---@param left integer
---@param mid integer
---@param right integer
---@param target ffi.cdata* array of integers
---@param source ffi.cdata* array of integers
---@param entries ffi.cdata* array of `fzf_entry_t`
local function merge(left, mid, right, target, source, entries)
  local i = left
  local j = mid

  for k = left, right - 1 do
    if i < mid and (j >= right or compare(source[i], source[j], entries)) then
      target[k] = source[i]
      i = i + 1
    else
      target[k] = source[j]
      j = j + 1
    end
  end
end

---Sort the entries in the `fzf_entries` array using bottom-up merge sort.
---Returns a pointer to an array of integers that represent the sorted indices,
---which points into the supplied `proxy_buff` array.
---**Side effect**: the `proxy_buff` array is modified.
---@param fzf_entries ffi.cdata* array of `fzf_entry_t`
---@param count number the number of entries in `fzf_entries`
---@param proxy_buff ffi.cdata* array of integers, twice the size of `count`
---@return ffi.cdata* pointer to the sorted indices
local function sort_entries(fzf_entries, count, proxy_buff)
  local min = math.min
  local src = proxy_buff + 0
  local dst = proxy_buff + count

  for i = 0, count - 1 do
    src[i] = i
  end

  local w = 1
  while w < count do
    local r = 0
    while r < count do
      local left = r
      local mid = min(r + w, count)
      local right = min(r + 2 * w, count)
      merge(left, mid, right, dst, src, fzf_entries)
      r = r + 2 * w
    end
    w = w * 2
    local tmp = src
    src = dst
    dst = tmp
  end

  return src
end
M.sort_entries = sort_entries

return M
