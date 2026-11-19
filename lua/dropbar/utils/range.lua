local M = {}

local utils = require('dropbar.utils')

---@class dropbar_range_t
---@field start dropbar_pos_t
---@field end dropbar_pos_t

---Check if r1 contains r2
---Strict indexing -- if r1 == r2, return false
---@param r1 dropbar_range_t 0-based range
---@param r2 dropbar_range_t 0-based range
---@param strict boolean? only return true if `range1` fully contains `range2` (no overlapping boundaries), default false
---@return boolean
function M.contains(r1, r2, strict)
  return (
    r2.start.line > r1.start.line
    or (
      r2.start.line == r1.start.line
      and (
        r2.start.character > r1.start.character
        or not strict and r2.start.character == r1.start.character
      )
    )
  )
    and (r2.start.line < r1['end'].line or (r2.start.line == r1['end'].line and (r2.start.character < r1['end'].character or not strict and r2.start.character == r1['end'].character)))
    and (r2['end'].line > r1.start.line or (r2['end'].line == r1.start.line and (r2['end'].character > r1.start.character or not strict and r2['end'].character == r1.start.character)))
    and (
      r2['end'].line < r1['end'].line
      or (
        r2['end'].line == r1['end'].line
        and (
          r2['end'].character < r1['end'].character
          or not strict and r2['end'].character == r1['end'].character
        )
      )
    )
end

---Check if cursor is in range
---@param cursor integer[] cursor position (line, character); (1, 0)-based
---@param range dropbar_range_t 0-based range
---@param strict boolean? only return true if `cursor` is fully contained in `range` (not on the boundary), default false
---@return boolean
function M.contains_cursor(cursor, range, strict)
  cursor = cursor or vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local char = cursor[2]
  return (
    line > range.start.line
    or (
      line == range.start.line
      and (
        char > range.start.character
        or not strict and char == range.start.character
      )
    )
  )
    and (
      line < range['end'].line
      or (
        line == range['end'].line
        and (
          char < range['end'].character
          or not strict and char == range['end'].character
        )
      )
    )
end

---Check if two ranges match at either boundary within a tolerance
---Two ranges 'match' when their starts are on the same line and within `tol` columns,
---or their ends are on the same line and within `tol` columns.
---@param r1 dropbar_range_t 0-based range
---@param r2 dropbar_range_t 0-based range
---@param tol integer maximum allowed column delta for boundary comparison (>= 0)
---@return boolean
function M.matches(r1, r2, tol)
  return utils.pos.matches(r1.start, r2.start, tol)
    or utils.pos.matches(r1['end'], r2['end'], tol)
end

return M
