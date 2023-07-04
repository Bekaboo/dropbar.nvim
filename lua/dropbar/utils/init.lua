return setmetatable({}, {
  __index = function(self, key)
    self[key] = require('dropbar.utils.' .. key)
    return self[key]
  end,
})
