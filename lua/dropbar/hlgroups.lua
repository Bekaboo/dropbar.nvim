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
  DropBarIconKindH1Marker          = { link = 'markdownH1' },
  DropBarIconKindH2Marker          = { link = 'markdownH2' },
  DropBarIconKindH3Marker          = { link = 'markdownH3' },
  DropBarIconKindH4Marker          = { link = 'markdownH4' },
  DropBarIconKindH5Marker          = { link = 'markdownH5' },
  DropBarIconKindH6Marker          = { link = 'markdownH6' },
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

---Set WinBar & WinBarNC background to Normal background
---@return nil
local function clear_winbar_bg()
  ---@param name string
  ---@return nil
  local function _clear_bg(name)
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    if hl.bg or hl.ctermbg then
      hl.bg = nil
      hl.ctermbg = nil
      vim.api.nvim_set_hl(0, name, hl)
    end
  end

  _clear_bg('WinBar')
  _clear_bg('WinBarNC')
end

---Initialize highlight groups for dropbar
local function init()
  local groupid = vim.api.nvim_create_augroup('DropBarHlGroups', {})

  set_hlgroups()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = groupid,
    callback = set_hlgroups,
  })

  -- Remove winbar background for non-nightly versions as a workaround for
  -- https://github.com/Bekaboo/dropbar.nvim/issues/118, also see
  -- https://github.com/neovim/neovim/issues/26037#issuecomment-1838548013
  if vim.fn.has('nvim-0.11.0') == 0 then
    clear_winbar_bg()
    vim.api.nvim_create_autocmd('ColorScheme', {
      desc = 'Remove WinBar background color as a workaround.',
      group = groupid,
      callback = clear_winbar_bg,
    })
    vim.api.nvim_create_autocmd('OptionSet', {
      desc = 'Remove WinBar background color as a workaround.',
      pattern = 'background',
      group = groupid,
      callback = clear_winbar_bg,
    })
  end
end

return {
  init = init,
}
