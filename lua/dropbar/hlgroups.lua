-- stylua: ignore start
local hlgroups = {
  DropBarCurrentContext            = { link = 'Visual' },
  DropBarCurrentContextIcon        = { link = 'DropBarCurrentContext' },
  DropBarCurrentContextName        = { link = 'DropBarCurrentContext' },
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
  DropBarIconKindRule              = { link = '@lsp.type.namespace' },
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

  -- Highlight groups in non-current windows
  DropBarIconKindDefaultNC           = { link = 'WinBarNC' },
  DropBarIconKindArrayNC             = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindBlockMappingPairNC  = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindBooleanNC           = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindBreakStatementNC    = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindCallNC              = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindCaseStatementNC     = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindClassNC             = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindConstantNC          = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindConstructorNC       = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindContinueStatementNC = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindDeclarationNC       = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindDeleteNC            = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindDoStatementNC       = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindElementNC           = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindElseStatementNC     = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindEnumNC              = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindEnumMemberNC        = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindEventNC             = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindFieldNC             = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindFileNC              = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindFolderNC            = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindForStatementNC      = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindFunctionNC          = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindGotoStatementNC     = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindIdentifierNC        = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindIfStatementNC       = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindInterfaceNC         = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindKeywordNC           = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindListNC              = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindMacroNC             = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindMarkdownH1NC        = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindMarkdownH2NC        = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindMarkdownH3NC        = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindMarkdownH4NC        = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindMarkdownH5NC        = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindMarkdownH6NC        = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindMethodNC            = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindModuleNC            = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindNamespaceNC         = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindNullNC              = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindNumberNC            = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindObjectNC            = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindOperatorNC          = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindPackageNC           = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindPairNC              = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindPropertyNC          = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindReferenceNC         = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindRepeatNC            = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindReturnStatementNC   = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindRuleSetNC           = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindScopeNC             = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindSectionNC           = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindSpecifierNC         = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindStatementNC         = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindStringNC            = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindStructNC            = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindSwitchStatementNC   = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindTableNC             = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindTypeNC              = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindTypeParameterNC     = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindUnitNC              = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindValueNC             = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindVariableNC          = { link = 'DropBarIconKindDefaultNC' },
  DropBarIconKindWhileStatementNC    = { link = 'DropBarIconKindDefaultNC' },

  DropBarKindArrayNC                 = {},
  DropBarKindBlockMappingPairNC      = {},
  DropBarKindBooleanNC               = {},
  DropBarKindBreakStatementNC        = {},
  DropBarKindCallNC                  = {},
  DropBarKindCaseStatementNC         = {},
  DropBarKindClassNC                 = {},
  DropBarKindConstantNC              = {},
  DropBarKindConstructorNC           = {},
  DropBarKindContinueStatementNC     = {},
  DropBarKindDeclarationNC           = {},
  DropBarKindDeleteNC                = {},
  DropBarKindDoStatementNC           = {},
  DropBarKindElementNC               = {},
  DropBarKindElseStatementNC         = {},
  DropBarKindEnumNC                  = {},
  DropBarKindEnumMemberNC            = {},
  DropBarKindEventNC                 = {},
  DropBarKindFieldNC                 = {},
  DropBarKindFileNC                  = {},
  DropBarKindFolderNC                = {},
  DropBarKindForStatementNC          = {},
  DropBarKindFunctionNC              = {},
  DropBarKindGotoStatementNC         = {},
  DropBarKindIdentifierNC            = {},
  DropBarKindIfStatementNC           = {},
  DropBarKindInterfaceNC             = {},
  DropBarKindKeywordNC               = {},
  DropBarKindListNC                  = {},
  DropBarKindMacroNC                 = {},
  DropBarKindMarkdownH1NC            = {},
  DropBarKindMarkdownH2NC            = {},
  DropBarKindMarkdownH3NC            = {},
  DropBarKindMarkdownH4NC            = {},
  DropBarKindMarkdownH5NC            = {},
  DropBarKindMarkdownH6NC            = {},
  DropBarKindMethodNC                = {},
  DropBarKindModuleNC                = {},
  DropBarKindNamespaceNC             = {},
  DropBarKindNullNC                  = {},
  DropBarKindNumberNC                = {},
  DropBarKindObjectNC                = {},
  DropBarKindOperatorNC              = {},
  DropBarKindPackageNC               = {},
  DropBarKindPairNC                  = {},
  DropBarKindPropertyNC              = {},
  DropBarKindReferenceNC             = {},
  DropBarKindRepeatNC                = {},
  DropBarKindReturnStatementNC       = {},
  DropBarKindRuleSetNC               = {},
  DropBarKindScopeNC                 = {},
  DropBarKindSectionNC               = {},
  DropBarKindSpecifierNC             = {},
  DropBarKindStatementNC             = {},
  DropBarKindStringNC                = {},
  DropBarKindStructNC                = {},
  DropBarKindSwitchStatementNC       = {},
  DropBarKindTableNC                 = {},
  DropBarKindTypeNC                  = {},
  DropBarKindTypeParameterNC         = {},
  DropBarKindUnitNC                  = {},
  DropBarKindValueNC                 = {},
  DropBarKindVariableNC              = {},
  DropBarKindWhileStatementNC        = {},

  DropBarIconUISeparatorNC           = { link = 'Comment' },
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

---Check if `hl-WinBarNC` and `hl-WinBar` are equal
---@return boolean
local function winbar_hl_nc_equal()
  return vim.deep_equal(
    vim.api.nvim_get_hl(0, { name = 'WinBar', link = false, create = false }),
    vim.api.nvim_get_hl(0, { name = 'WinBarNC', link = false, create = false })
  )
end

---Dim/restore dropbar highlights in given window
---@param win? integer
---@param do_dim? boolean `true` to dim highlights, `false` to restore, default to `true`
local function dim(win, do_dim)
  win = win or vim.api.nvim_get_current_win()
  -- Don't dim for windows that does not have a winbar, this avoids extra
  -- overhead and most importantly, avoid dimming icons in drop-down menus
  if not vim.api.nvim_win_is_valid(win) or vim.wo[win].winbar == '' then
    return
  end

  local hl_map = {}
  for hl_name, _ in pairs(hlgroups) do
    if vim.endswith(hl_name, 'NC') then
      hl_map[hl_name:gsub('NC$', '')] = hl_name
    end
  end

  vim.api.nvim_win_call(win, function()
    if do_dim ~= false then
      ---@diagnostic disable-next-line: undefined-field
      vim.opt_local.winhl:append(hl_map)
    else
      ---@diagnostic disable-next-line: undefined-field
      vim.opt_local.winhl:remove(vim.tbl_keys(hl_map))
    end
  end)
end

---Dim highlights in non-current windows if `hl-WinBarNC` differs from
---`hl-WinBar`
local function dim_nc_wins()
  if winbar_hl_nc_equal() then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      dim(win, false)
    end
  else
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      dim(win)
    end
    dim(0, false)
  end
end

---Initialize highlight groups for dropbar
local function init()
  local groupid = vim.api.nvim_create_augroup('dropbar.hl', {})

  set_hlgroups()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = groupid,
    callback = set_hlgroups,
  })

  -- Dim dropbar highlights in non-current windows
  dim_nc_wins()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = groupid,
    callback = dim_nc_wins,
  })

  vim.api.nvim_create_autocmd('WinEnter', {
    group = groupid,
    callback = function()
      -- Only dim icon if current window's winbar color is the same as
      -- non-current windows'
      -- Also, don't dim for windows that does not have a winbar, this avoids
      -- extra overhead and most importantly, avoid dimming icons in drop-down
      -- menus
      if not winbar_hl_nc_equal() and vim.wo.winbar ~= '' then
        dim(0, false)
      end
    end,
  })

  vim.api.nvim_create_autocmd('WinLeave', {
    group = groupid,
    callback = function()
      if not winbar_hl_nc_equal() and vim.wo.winbar ~= '' then
        dim()
      end
    end,
  })
end

return { init = init }
