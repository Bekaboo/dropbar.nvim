-- stylua: ignore start
local hlgroups = {
  DropBarCurrentContext            = { link = 'Visual' },
  DropBarFzfMatch                  = { link = 'TelescopeMatching' },
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
  DropBarIconKindTerminal          = { link = 'Number' },
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

  -- Remove winbar background as a workaround for
  -- https://github.com/Bekaboo/dropbar.nvim/issues/118, also see
  -- https://github.com/neovim/neovim/issues/26037#issuecomment-1838548013

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

return {
  init = init,
}
