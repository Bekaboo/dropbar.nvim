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
  "Array",
  "Boolean",
  "BreakStatement",
  "Call",
  "CaseStatement",
  "Class",
  "Constant",
  "Constructor",
  "ContinueStatement",
  "Declaration",
  "Delete",
  "DoStatement",
  "ElseStatement",
  "Enum",
  "EnumMember",
  "Event",
  "Field",
  "File",
  "Folder",
  "ForStatement",
  "Function",
  "H1Marker",
  "H2Marker",
  "H3Marker",
  "H4Marker",
  "H5Marker",
  "H6Marker",
  "Identifier",
  "IfStatement",
  "Interface",
  "Keyword",
  "List",
  "Macro",
  "MarkdownH1",
  "MarkdownH2",
  "MarkdownH3",
  "MarkdownH4",
  "MarkdownH5",
  "MarkdownH6",
  "Method",
  "Module",
  "Namespace",
  "Null",
  "Number",
  "Object",
  "Operator",
  "Package",
  "Pair",
  "Property",
  "Reference",
  "Repeat",
  "Scope",
  "Specifier",
  "Statement",
  "String",
  "Struct",
  "SwitchStatement",
  "Type",
  "TypeParameter",
  "Unit",
  "Value",
  "Variable",
  "WhileStatement",
}
-- stylua: ignore end

---Set winbar highlight groups and override background if needed
---@return nil
local function set_hlgroups()
  local bg_hlgroup = require'dropbar.configs'.opts.highlight.background
  if type(bg_hlgroup) ~= 'string' then
    for hl_name, hl_settings in pairs(hlgroups) do
      hl_settings.default = true
      vim.api.nvim_set_hl(0, hl_name, hl_settings)
    end
    return
  end

  local bg_color = vim.api.nvim_get_hl(0, {
    name = bg_hlgroup,
    link = false,
  }).bg

  local ignore = {
    "DropBarMenuFloatBorder",

    "DropBarCurrentContext",
    "DropBarMenuCurrentContext",
    "DropBarHover",
    "DropBarMenuHoverEntry",
    "DropBarMenuHoverIcon",
    "DropBarMenuHoverSymbol",

    "DropBarPreview",
  }

  vim.api.nvim_set_hl(0, "WinBar", { bg = bg_color })
  vim.api.nvim_set_hl(0, "WinBarNC", { bg = bg_color })

  for hl_name, hl_info in pairs(hlgroups) do
    if vim.tbl_contains(ignore, hl_name) then
      hl_info.default = true
    else
      if hl_info.link then
        hl_info = vim.api.nvim_get_hl(0, {
          name = hl_info.link,
          link = false,
        })
      end
      hl_info = vim.tbl_extend('force', hl_info, {
        default = true,
        bg = bg_color
      })
    end
    vim.api.nvim_set_hl(0, hl_name, hl_info)
  end

  -- ***note(theofabilous): initializing these groups at the beginning should 
  -- probably be done regardless of whether or not the background is overridden
  for _, kind in ipairs(kinds) do
    vim.api.nvim_set_hl(0, 'DropBarKind' .. kind, { bg = bg_color })
  end
end

---Initialize highlight groups for dropbar
local function init()
  set_hlgroups()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('DropBarHlGroups', {}),
    callback = set_hlgroups,
  })
end

return {
  init = init,
}
