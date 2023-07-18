local utils = require('dropbar.utils')

-- stylua: ignore start
local hlgroups = {
  DropBarCurrentContext            = { link = 'Visual' },
  DropBarHover                     = { link = 'Visual' },
  DropBarIconKindArray             = { link = 'Array' },
  DropBarIconKindBoolean           = { link = 'Boolean' },
  DropBarIconKindBreakStatement    = { link = 'Error' },
  DropBarIconKindCall              = { link = 'Function' },
  DropBarIconKindCaseStatement     = { link = 'Conditional' },
  DropBarIconKindClass             = { link = 'CmpItemKindClass' },
  DropBarIconKindConstant          = { link = 'Constant' },
  DropBarIconKindConstructor       = { link = 'CmpItemKindConstructor' },
  DropBarIconKindContinueStatement = { link = 'Repeat' },
  DropBarIconKindDeclaration       = { link = 'CmpItemKindSnippet' },
  DropBarIconKindDelete            = { link = 'Error' },
  DropBarIconKindDoStatement       = { link = 'Repeat' },
  DropBarIconKindElseStatement     = { link = 'Conditional' },
  DropBarIconKindEnum              = { link = 'CmpItemKindEnum' },
  DropBarIconKindEnumMember        = { link = 'CmpItemKindEnumMember' },
  DropBarIconKindEvent             = { link = 'CmpItemKindEvent' },
  DropBarIconKindField             = { link = 'CmpItemKindField' },
  DropBarIconKindFile              = { link = 'Directory' },
  DropBarIconKindFolder            = { link = 'Directory' },
  DropBarIconKindForStatement      = { link = 'Repeat' },
  DropBarIconKindFunction          = { link = 'Function' },
  DropBarIconKindH1Marker          = { link = 'markdownH1' },
  DropBarIconKindH2Marker          = { link = 'markdownH2' },
  DropBarIconKindH3Marker          = { link = 'markdownH3' },
  DropBarIconKindH4Marker          = { link = 'markdownH4' },
  DropBarIconKindH5Marker          = { link = 'markdownH5' },
  DropBarIconKindH6Marker          = { link = 'markdownH6' },
  DropBarIconKindIdentifier        = { link = 'CmpItemKindVariable' },
  DropBarIconKindIfStatement       = { link = 'Conditional' },
  DropBarIconKindInterface         = { link = 'CmpItemKindInterface' },
  DropBarIconKindKeyword           = { link = 'Keyword' },
  DropBarIconKindList              = { link = 'SpecialChar' },
  DropBarIconKindMacro             = { link = 'Macro' },
  DropBarIconKindMarkdownH1        = { link = 'markdownH1' },
  DropBarIconKindMarkdownH2        = { link = 'markdownH2' },
  DropBarIconKindMarkdownH3        = { link = 'markdownH3' },
  DropBarIconKindMarkdownH4        = { link = 'markdownH4' },
  DropBarIconKindMarkdownH5        = { link = 'markdownH5' },
  DropBarIconKindMarkdownH6        = { link = 'markdownH6' },
  DropBarIconKindMethod            = { link = 'CmpItemKindMethod' },
  DropBarIconKindModule            = { link = 'CmpItemKindModule' },
  DropBarIconKindNamespace         = { link = 'NameSpace' },
  DropBarIconKindNull              = { link = 'Constant' },
  DropBarIconKindNumber            = { link = 'Number' },
  DropBarIconKindObject            = { link = 'Statement' },
  DropBarIconKindOperator          = { link = 'Operator' },
  DropBarIconKindPackage           = { link = 'CmpItemKindModule' },
  DropBarIconKindPair              = { link = 'String' },
  DropBarIconKindProperty          = { link = 'CmpItemKindProperty' },
  DropBarIconKindReference         = { link = 'CmpItemKindReference' },
  DropBarIconKindRepeat            = { link = 'Repeat' },
  DropBarIconKindScope             = { link = 'NameSpace' },
  DropBarIconKindSpecifier         = { link = 'Specifier' },
  DropBarIconKindStatement         = { link = 'Statement' },
  DropBarIconKindString            = { link = 'String' },
  DropBarIconKindStruct            = { link = 'CmpItemKindStruct' },
  DropBarIconKindSwitchStatement   = { link = 'Conditional' },
  DropBarIconKindType              = { link = 'CmpItemKindClass' },
  DropBarIconKindTypeParameter     = { link = 'CmpItemKindTypeParameter' },
  DropBarIconKindUnit              = { link = 'CmpItemKindUnit' },
  DropBarIconKindValue             = { link = 'Number' },
  DropBarIconKindVariable          = { link = 'CmpItemKindVariable' },
  DropBarIconKindWhileStatement    = { link = 'Repeat' },
  DropBarIconUIIndicator           = { link = 'SpecialChar' },
  DropBarIconUIPickPivot           = { link = 'Error' },
  DropBarIconUISeparator           = { link = 'SpecialChar' },
  DropBarIconUISeparatorMenu       = { link = 'DropBarIconUISeparator' },
  DropBarMenuCurrentContext        = { link = 'PmenuSel' },
  DropBarMenuFloatBorder           = { link = 'FloatBorder' },
  DropBarMenuHoverEntry            = { link = 'Visual' },
  DropBarMenuHoverIcon             = { reverse = true },
  DropBarMenuHoverSymbol           = { bold = true },
  DropBarMenuNormalFloat           = { link = 'NormalFloat' },
  DropBarPreview                   = { link = 'Visual' },
}

local kinds = {
  "DropBarKindArray",
  "DropBarKindBoolean",
  "DropBarKindBreakStatement",
  "DropBarKindCall",
  "DropBarKindCaseStatement",
  "DropBarKindClass",
  "DropBarKindConstant",
  "DropBarKindConstructor",
  "DropBarKindContinueStatement",
  "DropBarKindDeclaration",
  "DropBarKindDelete",
  "DropBarKindDoStatement",
  "DropBarKindElseStatement",
  "DropBarKindEnum",
  "DropBarKindEnumMember",
  "DropBarKindEvent",
  "DropBarKindField",
  "DropBarKindFile",
  "DropBarKindFolder",
  "DropBarKindForStatement",
  "DropBarKindFunction",
  "DropBarKindH1Marker",
  "DropBarKindH2Marker",
  "DropBarKindH3Marker",
  "DropBarKindH4Marker",
  "DropBarKindH5Marker",
  "DropBarKindH6Marker",
  "DropBarKindIdentifier",
  "DropBarKindIfStatement",
  "DropBarKindInterface",
  "DropBarKindKeyword",
  "DropBarKindList",
  "DropBarKindMacro",
  "DropBarKindMarkdownH1",
  "DropBarKindMarkdownH2",
  "DropBarKindMarkdownH3",
  "DropBarKindMarkdownH4",
  "DropBarKindMarkdownH5",
  "DropBarKindMarkdownH6",
  "DropBarKindMethod",
  "DropBarKindModule",
  "DropBarKindNamespace",
  "DropBarKindNull",
  "DropBarKindNumber",
  "DropBarKindObject",
  "DropBarKindOperator",
  "DropBarKindPackage",
  "DropBarKindPair",
  "DropBarKindProperty",
  "DropBarKindReference",
  "DropBarKindRepeat",
  "DropBarKindScope",
  "DropBarKindSpecifier",
  "DropBarKindStatement",
  "DropBarKindString",
  "DropBarKindStruct",
  "DropBarKindSwitchStatement",
  "DropBarKindType",
  "DropBarKindTypeParameter",
  "DropBarKindUnit",
  "DropBarKindValue",
  "DropBarKindVariable",
  "DropBarKindWhileStatement",
}
-- stylua: ignore end

local M = {
  namespaces = {
    current = vim.api.nvim_create_namespace('DropBarCurrent'),
    nc = 0,
    menu = vim.api.nvim_create_namespace('DropBarMenu'),
  },
  dropbar = {
    ---@type table<string, any>?
    current = nil,
    ---@type table<string, any>?
    nc = nil,
    ---@type table<string, any>?
    menu = nil,
  },
  ---@type table<string, boolean>
  devicons = {},
  ---@type table<string, boolean>
  managed = {},
}

---Create a highlight group with name `hl_name` and the given `hl_info`
---for each namespace
---@param hl_name string The name of the highlight group to create
---@param hl_info table<string, any>|string highlight group name to link or highlight attribute table
local function create_hl(hl_name, hl_info)
  hl_info = utils.hl.normalize(hl_info, true)
  for _, e in ipairs({ 'current', 'nc', 'menu' }) do
    vim.api.nvim_set_hl(
      M.namespaces[e],
      hl_name,
      utils.hl.merge(hl_info, M.dropbar[e])
    )
  end
end

---Get the patched highlight group for the given devicon highlight group or
---the given highlight group if no background color is set
---@param hlgroup string The highlight group to patch returned by get_icon()
---@return string highlight group name
function M.get_devicon_hlgroup(hlgroup)
  local new_hlgroup = 'DropBar' .. hlgroup
  if M.devicons[new_hlgroup] then
    return new_hlgroup
  end
  create_hl(new_hlgroup, hlgroup)
  M.devicons[new_hlgroup] = true
  return new_hlgroup
end

---Register a non-dropbar defined highlight group to be managed by dropbar,
---for example when setting icon/name highlights for symbols
---@param hlgroup string
---@return string: The managed highlight group name
function M.manage(hlgroup)
  M.managed[hlgroup] = true
  local managed_hlgroup = 'DropBarManaged' .. hlgroup
  create_hl(managed_hlgroup, hlgroup)
  return managed_hlgroup
end

---Set winbar highlight groups and override background if needed
---@return nil
function M.set_hlgroups()
  M.dropbar.current = utils.hl.without('WinBar', { 'fg', 'nocombine' })
  M.dropbar.nc = utils.hl.without('WinBarNC', { 'fg', 'nocombine' })
  M.dropbar.menu = utils.hl.without('WinBar', {
    'fg',
    'bold',
    'standout',
    'underline',
    'undercurl',
    'underdouble',
    'underdotted',
    'underdashed',
    'strikethrough',
    'italic',
    'reverse',
    'nocombine',
  })

  -- hack: set WinBarNC to WinBar in the namespace 'current' so that
  -- the dropbar is highlighted as if it is the current one even when inside a
  -- dropbar_menu_t
  vim.api.nvim_set_hl(M.namespaces.current, 'WinBarNC', M.dropbar.current)

  --- list of hlgroups that should not be overridden
  local ignore = {
    'DropBarCurrentContext',
    'DropBarMenuCurrentContext',
    'DropBarHover',
    'DropBarMenuHoverEntry',
    'DropBarMenuHoverIcon',
    'DropBarMenuHoverSymbol',
    'DropBarPreview',
  }

  for hl_name, hl_info in pairs(hlgroups) do
    if vim.tbl_contains(ignore, hl_name) then
      hl_info.default = true
      vim.api.nvim_set_hl(0, hl_name, hl_info)
    else
      create_hl(hl_name, hl_info)
    end
  end

  for _, kind in ipairs(kinds) do
    create_hl(kind, {})
  end

  for k, _ in pairs(M.managed) do
    M.manage(k)
  end

  vim.api.nvim_set_hl(
    M.namespaces.menu,
    'NormalFloat',
    { link = 'DropBarMenuNormalFloat', default = true }
  )
  vim.api.nvim_set_hl(
    M.namespaces.menu,
    'FloatBorder',
    { link = 'DropBarMenuFloatBorder', default = true }
  )
end

---Initialize highlight groups for dropbar
function M.init()
  M.set_hlgroups()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('DropBarHlGroups', {}),
    callback = M.set_hlgroups,
  })
end

return M
