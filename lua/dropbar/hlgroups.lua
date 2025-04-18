-- stylua: ignore start
local hlgroups = {
  DropBarCurrentContext            = { link = 'Visual' },
  DropBarFzfMatch                  = { link = 'Special' },
  DropBarHover                     = { link = 'Visual' },
  DropBarIconKindDefault           = { link = 'Special' },
  DropBarIconKindArray             = { link = 'Operator' },
  DropBarIconKindBlockMappingPair  = { link = 'DropBarIconKindDefault' },
  DropBarIconKindBoolean           = { link = 'Boolean' },
  DropBarIconKindBreakStatement    = { link = 'Error' },
  DropBarIconKindCall              = { link = 'Function' },
  DropBarIconKindCaseStatement     = { link = '@keyword.conditional' },
  DropBarIconKindClass             = { link = 'Type' },
  DropBarIconKindConstant          = { link = 'Constant' },
  DropBarIconKindConstructor       = { link = '@constructor' },
  DropBarIconKindContinueStatement = { link = 'Repeat' },
  DropBarIconKindDeclaration       = { link = 'DropBarIconKindDefault' },
  DropBarIconKindDelete            = { link = 'Error' },
  DropBarIconKindDoStatement       = { link = 'Repeat' },
  DropBarIconKindElement           = { link = 'DropBarIconKindDefault' },
  DropBarIconKindElseStatement     = { link = '@keyword.conditional' },
  DropBarIconKindEnum              = { link = 'Constant' },
  DropBarIconKindEnumMember        = { link = 'DropBarIconKindEnumMember' },
  DropBarIconKindEvent             = { link = '@lsp.type.event' },
  DropBarIconKindField             = { link = 'DropBarIconKindDefault' },
  DropBarIconKindFile              = { link = 'DropBarIconKindFolder' },
  DropBarIconKindFolder            = { link = 'Directory' },
  DropBarIconKindForStatement      = { link = 'Repeat' },
  DropBarIconKindFunction          = { link = 'Function' },
  DropBarIconKindGotoStatement     = { link = '@keyword.return' },
  DropBarIconKindIdentifier        = { link = 'DropBarIconKindDefault' },
  DropBarIconKindIfStatement       = { link = '@keyword.conditional' },
  DropBarIconKindInterface         = { link = 'Type' },
  DropBarIconKindKeyword           = { link = '@keyword' },
  DropBarIconKindList              = { link = 'Operator' },
  DropBarIconKindMacro             = { link = 'Macro' },
  DropBarIconKindMarkdownH1        = { link = 'markdownH1' },
  DropBarIconKindMarkdownH2        = { link = 'markdownH2' },
  DropBarIconKindMarkdownH3        = { link = 'markdownH3' },
  DropBarIconKindMarkdownH4        = { link = 'markdownH4' },
  DropBarIconKindMarkdownH5        = { link = 'markdownH5' },
  DropBarIconKindMarkdownH6        = { link = 'markdownH6' },
  DropBarIconKindMethod            = { link = 'Function' },
  DropBarIconKindModule            = { link = '@module' },
  DropBarIconKindNamespace         = { link = '@lsp.type.namespace' },
  DropBarIconKindNull              = { link = 'Constant' },
  DropBarIconKindNumber            = { link = 'Number' },
  DropBarIconKindObject            = { link = 'Statement' },
  DropBarIconKindOperator          = { link = 'Operator' },
  DropBarIconKindPackage           = { link = '@module' },
  DropBarIconKindPair              = { link = 'DropBarIconKindDefault' },
  DropBarIconKindProperty          = { link = 'DropBarIconKindDefault' },
  DropBarIconKindReference         = { link = 'DropBarIconKindDefault' },
  DropBarIconKindRepeat            = { link = 'Repeat' },
  DropBarIconKindReturnStatement   = { link = '@keyword.return' },
  DropBarIconKindRuleSet           = { link = '@lsp.type.namespace' },
  DropBarIconKindScope             = { link = '@lsp.type.namespace' },
  DropBarIconKindSection           = { link = 'Title' },
  DropBarIconKindSpecifier         = { link = '@keyword' },
  DropBarIconKindStatement         = { link = 'Statement' },
  DropBarIconKindString            = { link = '@string' },
  DropBarIconKindStruct            = { link = 'Type' },
  DropBarIconKindSwitchStatement   = { link = '@keyword.conditional' },
  DropBarIconKindTable             = { link = 'DropBarIconKindDefault' },
  DropBarIconKindTerminal          = { link = 'Number' },
  DropBarIconKindType              = { link = 'Type' },
  DropBarIconKindTypeParameter     = { link = 'DropBarIconKindDefault' },
  DropBarIconKindUnit              = { link = 'DropBarIconKindDefault' },
  DropBarIconKindValue             = { link = 'Number' },
  DropBarIconKindVariable          = { link = 'DropBarIconKindDefault' },
  DropBarIconKindWhileStatement    = { link = 'Repeat' },
  DropBarIconUIIndicator           = { link = 'SpecialChar' },
  DropBarIconUIPickPivot           = { link = 'Error' },
  DropBarIconUISeparator           = { link = 'Comment' },
  DropBarIconUISeparatorMenu       = { link = 'DropBarIconUISeparator' },
  DropBarMenuCurrentContext        = { link = 'PmenuSel' },
  DropBarMenuFloatBorder           = { link = 'FloatBorder' },
  DropBarMenuHoverEntry            = { link = 'IncSearch' },
  DropBarMenuHoverIcon             = { reverse = true },
  DropBarMenuHoverSymbol           = { bold = true },
  DropBarMenuNormalFloat           = { link = 'NormalFloat' },
  DropBarMenuSbar                  = { link = 'PmenuSbar' },
  DropBarMenuThumb                 = { link = 'PmenuThumb' },
  DropBarPreview                   = { link = 'Visual' },
}
-- stylua: ignore end

---Set winbar highlight groups
---@return nil
local function set_hlgroups()
  for hl_name, hl_settings in pairs(hlgroups) do
    hl_settings.default = true
    vim.api.nvim_set_hl(0, hl_name, hl_settings)
  end
end

---Initialize highlight groups for dropbar
local function init()
  local groupid = vim.api.nvim_create_augroup('DropBarHlGroups', {})

  set_hlgroups()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = groupid,
    callback = set_hlgroups,
  })
end

return {
  init = init,
}
