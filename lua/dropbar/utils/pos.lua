local M = {}

---@class dropbar_pos_t
---@field line integer
---@field character integer

---Check if two positions are equal within a column tolerance
---Requires both positions to be on the same line; columns may differ by at most `tol`.
---@param pos1 dropbar_pos_t 0-based position
---@param pos2 dropbar_pos_t 0-based position
---@param tol integer maximum allowed column delta (>= 0)
---@return boolean
function M.matches(pos1, pos2, tol)
  return pos1.line == pos2.line
    and math.abs(pos1.character - pos2.character) <= tol
end

return M
