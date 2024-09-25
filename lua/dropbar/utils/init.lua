return setmetatable({}, {
  __index = function(_, key)
    return require('dropbar.utils.' .. key)
  end,
})
