# Changelog

## [4.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v3.2.0...v4.0.0) (2023-07-02)


### ⚠ BREAKING CHANGES

* **config:** open menu relative to clicked symbol by default, fix #37

### Features

* **bar/highlights:** add current context highlighting to winbar ([36125e5](https://github.com/Bekaboo/dropbar.nvim/commit/36125e51764406f163942f48743d201467325062))
* **config:** open menu relative to clicked symbol by default, fix [#37](https://github.com/Bekaboo/dropbar.nvim/issues/37) ([a0faad2](https://github.com/Bekaboo/dropbar.nvim/commit/a0faad2b9fb7e5f88a59bc22f9be20445ebc13a1))


### Bug Fixes

* **bar:** invalid buffer number after `:bw &lt;buffer&gt;` ([2cc0381](https://github.com/Bekaboo/dropbar.nvim/commit/2cc0381cd7ef1d69d289a36715a3ea817bee2691))


### Performance Improvements

* **symbol:** cache string and length for symbols ([2c02b28](https://github.com/Bekaboo/dropbar.nvim/commit/2c02b280b2f4661e634dc07fb287af165512d464))

## [3.2.0](https://github.com/Bekaboo/dropbar.nvim/compare/v3.1.0...v3.2.0) (2023-06-25)


### Features

* **highlights:** add hl-DropBarMenu[NormalFloat,FloatBorder] ([#16](https://github.com/Bekaboo/dropbar.nvim/issues/16)) ([54ab3ee](https://github.com/Bekaboo/dropbar.nvim/commit/54ab3ee9134e6787dd7d3ff190c279392600ad1f))


### Bug Fixes

* **highlights:** fix hl-DropbarMenuFloatBorder and hl-DropBarMenuNormalFloat mappings ([15f32c0](https://github.com/Bekaboo/dropbar.nvim/commit/15f32c0b1c646b5608b52440599577799ce20425))


### Performance Improvements

* provide option to prevent frequent update while scrolling ([9d39fb4](https://github.com/Bekaboo/dropbar.nvim/commit/9d39fb49fb49e85a6d2dd068863e1c16ed35eccb))

## [3.1.0](https://github.com/Bekaboo/dropbar.nvim/compare/v3.0.0...v3.1.0) (2023-06-16)


### Features

* **config:** add option to reorient the source window after jump ([4df9092](https://github.com/Bekaboo/dropbar.nvim/commit/4df90921aebf9d51e5772db4901056f61029a0f4))
* **config:** include '*' in treesitter default name pattern ([a620873](https://github.com/Bekaboo/dropbar.nvim/commit/a620873beb6e581dd83b4d55671710f99ce91a1b))


### Bug Fixes

* **menu:** detect if mouse is at the border of the menu window, fix [#39](https://github.com/Bekaboo/dropbar.nvim/issues/39) ([0ba1af6](https://github.com/Bekaboo/dropbar.nvim/commit/0ba1af67c5f93b80e91b03b8eff1b908d66a70f0))
* **sources:** path: should use file icons for symbols of type 'file' ([190dcc1](https://github.com/Bekaboo/dropbar.nvim/commit/190dcc1c47e8ddb0deea583af58f983423dc8e1b))


### Performance Improvements

* **bar:** avoid unnecessary redraw, also fix [#38](https://github.com/Bekaboo/dropbar.nvim/issues/38) ([0ccb5d7](https://github.com/Bekaboo/dropbar.nvim/commit/0ccb5d743c7c6349c50e397504bfb2a331e590d2))

## [3.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v2.1.1...v3.0.0) (2023-06-10)


### ⚠ BREAKING CHANGES

* **config:** move preview reorient configs under opts.symbol
* **symbol:** preview symbol in source window

### Features

* **config:** add option to disable icons ([f08ab63](https://github.com/Bekaboo/dropbar.nvim/commit/f08ab6306176813d58cb936b3f2d40a568c8e5cc))
* **config:** move preview reorient configs under opts.symbol ([e136c7f](https://github.com/Bekaboo/dropbar.nvim/commit/e136c7f381b36ce3164e78aeca26d6cb189cd399))
* **config:** preview symbol on mouse hovering ([5ec3fa0](https://github.com/Bekaboo/dropbar.nvim/commit/5ec3fa0fa35c68c1387d84fa9aee019f64ec6552))
* **highlights:** reset hlgroups on ColorScheme ([befe881](https://github.com/Bekaboo/dropbar.nvim/commit/befe88172faf58a2b952b135b5ee2fcaca042e1a))
* **menu:** enable menu quick navigation by default ([#3](https://github.com/Bekaboo/dropbar.nvim/issues/3)) ([54c1dba](https://github.com/Bekaboo/dropbar.nvim/commit/54c1dbaf4e390f219adc6fd7efd9093a0958b9e3))
* **menu:** only move cursor to the first symbol on entering a new menu ([ca6741c](https://github.com/Bekaboo/dropbar.nvim/commit/ca6741cb13f2c3580baedcb068952fc79b8f1c03))
* **symbol:** preview symbol in source window ([3882ee3](https://github.com/Bekaboo/dropbar.nvim/commit/3882ee30a2aa07d735a2747ef7f6e1767aeec725))


### Bug Fixes

* **config:** should not disable icons when new_opts.icons.disable is not provided ([#31](https://github.com/Bekaboo/dropbar.nvim/issues/31)) ([1254ba2](https://github.com/Bekaboo/dropbar.nvim/commit/1254ba22a26ad179dffd094f410f0ee32c26c4fa))
* **highlights:** fix hlgroup names ([f217fde](https://github.com/Bekaboo/dropbar.nvim/commit/f217fdee5f286d93112893c3280b94d69865c8fb))
* **highlights:** fix hlgroup names (again) ([990cae9](https://github.com/Bekaboo/dropbar.nvim/commit/990cae99d581ff94a746b4f4acb13c85620756c6))
* **highlights:** update current context highlights correctly ([7367616](https://github.com/Bekaboo/dropbar.nvim/commit/7367616a558d60d4f64bd53a6349adcf4932466b))
* **menu:** convert mouse.column to 0-based ([04e04cc](https://github.com/Bekaboo/dropbar.nvim/commit/04e04cc10a3f1333d3948138b0faaad61a4bf481))
* **menu:** cursor not set to first clickable component in current entry ([4ef2dac](https://github.com/Bekaboo/dropbar.nvim/commit/4ef2dacd5889f07f16f097de606c5bde9668c81e))
* **menu:** drop-down menu position ([1bee80f](https://github.com/Bekaboo/dropbar.nvim/commit/1bee80f8fc142755444a210f93a4ff9a5af0820a))
* **menu:** fix default keymaps in menu ([1072eff](https://github.com/Bekaboo/dropbar.nvim/commit/1072eff3e0f28d3dc08f2b1782e0f5de6cd814c3))
* **menu:** pass prev_win on opening/toggling menus ([29e9b76](https://github.com/Bekaboo/dropbar.nvim/commit/29e9b76411f7b22a61a230663527c20f959c7ea3))
* **menu:** set init cursor pos only on the first time opening a menu ([1e56ced](https://github.com/Bekaboo/dropbar.nvim/commit/1e56ced0596261303f6c6d997494e3b21a715500))
* **menu:** should set cursor to previous position explicitly ([7d20061](https://github.com/Bekaboo/dropbar.nvim/commit/7d20061c8dd5dc7e8771dd35741e63d18a68a238))
* **menu:** wrong prev_window if opened from non-current window ([094f34d](https://github.com/Bekaboo/dropbar.nvim/commit/094f34dbf31409c1ba7cf110d982c66143a17584))
* **sources:** treesitter: add missing call to ipairs() ([d6775ce](https://github.com/Bekaboo/dropbar.nvim/commit/d6775cefc2f7e7fcd5f6febdb4ab89f0556be510))
* **sources:** treesitter: duplicate current node in siblings list ([eb242a2](https://github.com/Bekaboo/dropbar.nvim/commit/eb242a22959231db844d5c633846a43b13e09d29))
* **sources:** treesitter: order of siblings is reversed ([94b8d52](https://github.com/Bekaboo/dropbar.nvim/commit/94b8d521aa973034939151cb53013b91e2b3748b))

## [2.1.1](https://github.com/Bekaboo/dropbar.nvim/compare/v2.1.0...v2.1.1) (2023-06-04)


### Bug Fixes

* **highlights:** fix the name of hl-DropBarMenuHoverSymbol ([63ab461](https://github.com/Bekaboo/dropbar.nvim/commit/63ab4610da3d98208af08a7aa80b7c571209858d))

## [2.1.0](https://github.com/Bekaboo/dropbar.nvim/compare/v2.0.0...v2.1.0) (2023-06-04)


### Features

* **menu:** highlight entries/symbols under current mouse/cursor position ([#3](https://github.com/Bekaboo/dropbar.nvim/issues/3)) ([54284b3](https://github.com/Bekaboo/dropbar.nvim/commit/54284b3fe5f23e94792b5b7e57e8fb3dbabc1af4))


### Bug Fixes

* **general behavior:** invalid buffer error when clicking on winbar symbols ([6553d3a](https://github.com/Bekaboo/dropbar.nvim/commit/6553d3ab071f13936bf346afa3c027fe26d7d335))
* **menu:** fix &lt;MouseMove&gt; keymap ([103a808](https://github.com/Bekaboo/dropbar.nvim/commit/103a808c5bc591b8a6647e688616b76bea7419a7))
* **sources:** markdown: error when clicking on markdown heading symbol ([ab3ed40](https://github.com/Bekaboo/dropbar.nvim/commit/ab3ed4064ec2a4133864fc8abe466c5084fa9f0f))

## [2.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v1.0.0...v2.0.0) (2023-06-03)


### ⚠ BREAKING CHANGES

* **general behavior:** deprecate opts.general.update_events
* **highlights:** use hl-DropBarKind* for text highlights ([#18](https://github.com/Bekaboo/dropbar.nvim/issues/18))
* **general behavior:** do not clear the winbar when not enabled
* **highlights:** add hl-DropBarMenuNormalFloat linking to hl-WinBar ([#16](https://github.com/Bekaboo/dropbar.nvim/issues/16))

### Features

* **general behavior:** deprecate opts.general.update_events ([415a587](https://github.com/Bekaboo/dropbar.nvim/commit/415a5872d3090f14721160f4c911c10c8b08c661))
* **highlights:** add hl-DropBarMenuNormalFloat linking to hl-WinBar ([#16](https://github.com/Bekaboo/dropbar.nvim/issues/16)) ([aeea703](https://github.com/Bekaboo/dropbar.nvim/commit/aeea7038f52cfebe12bc901cd2db9070c36fdbcf))
* **highlights:** use hl-DropBarKind* for text highlights ([#18](https://github.com/Bekaboo/dropbar.nvim/issues/18)) ([36ce8a1](https://github.com/Bekaboo/dropbar.nvim/commit/36ce8a1715c69816b6fdfbabdb2496db204e1593))
* notify neovim version requirement ([#15](https://github.com/Bekaboo/dropbar.nvim/issues/15)) ([d3ebf22](https://github.com/Bekaboo/dropbar.nvim/commit/d3ebf2253ddf0da91437ded2ffb5b8a2bfc6c4ba))
* **sources:** lsp: check nil before indexing info.data.client_id ([#13](https://github.com/Bekaboo/dropbar.nvim/issues/13)) ([4c746bc](https://github.com/Bekaboo/dropbar.nvim/commit/4c746bc7c8474980df29a72b73327bf1c91f1bc0))
* **sources:** path: add opts to change file symbol when modified is set ([#14](https://github.com/Bekaboo/dropbar.nvim/issues/14)) ([6c568de](https://github.com/Bekaboo/dropbar.nvim/commit/6c568de9c01efbba99f4b20e84c5cfb772241039))


### Bug Fixes

* **bar & highlights:** hl-DropBarIconUISeparator not set in winbar ([96b3fad](https://github.com/Bekaboo/dropbar.nvim/commit/96b3fad938f1b9e6747848fe2cc9509612e207d0))
* **general behavior:** do not clear the winbar when not enabled ([5d7030f](https://github.com/Bekaboo/dropbar.nvim/commit/5d7030f88813a53200b23c71b906f9bbb8934019))
* **general behavior:** update winbar on BufModifiedSet ([06e233a](https://github.com/Bekaboo/dropbar.nvim/commit/06e233a110e7c4b7209fa085b9758941f6806613))
* **highlights:** add missing hl-DropBarMenuCurrentContext ([5c51448](https://github.com/Bekaboo/dropbar.nvim/commit/5c5144890cbcde884dabc984cb3e79b48f2e0cd1))
* **menu:** should close existing sub-menus on opening sub-menus ([#8](https://github.com/Bekaboo/dropbar.nvim/issues/8)) ([10318d1](https://github.com/Bekaboo/dropbar.nvim/commit/10318d16e73ba4ce4b54c31f97d664c97accf289))

## 1.0.0 (2023-05-30)


### ⚠ BREAKING CHANGES

* convert codepoints from nerdfonts v2 to v3

### Features

* **bar:** dropbar_symbol_t:cat() returns plain text when no bar is associated ([7ae61cc](https://github.com/Bekaboo/dropbar.nvim/commit/7ae61cc14877dcfe5e127b8c66c87247b1ef2eaa))


### Bug Fixes

* **autocmds:** winbar not updated in time in insert mode ([e54c1a6](https://github.com/Bekaboo/dropbar.nvim/commit/e54c1a6f48c5dee436750214836e3ba84f46b60f))
* **bar:** check nil before calling on_click() in dropbar_t:pick() ([e920832](https://github.com/Bekaboo/dropbar.nvim/commit/e9208326c8726595c3f67a1b9b6021f1fe43554d))
* **bar:** dropbar_t separator and extends losts metatable if merged with opts ([dfa59b6](https://github.com/Bekaboo/dropbar.nvim/commit/dfa59b6c5d0a5a1f443eeda33234193d10325dda))
* convert codepoints from nerdfonts v2 to v3 ([03f6e86](https://github.com/Bekaboo/dropbar.nvim/commit/03f6e8635d413805d1143f4a2614c814a4e798d9))
* error: not allowed in sandbox ([0624308](https://github.com/Bekaboo/dropbar.nvim/commit/0624308db7bb4190bff1a1f50eda4225a38f41e2))
* **lint:** unused variable self ([5d31a34](https://github.com/Bekaboo/dropbar.nvim/commit/5d31a3484db9779051192d5fb46e0f70454d6b71))
* **menu:** dropbar_menu_entry_t separator losts metatable if merged with opts ([bb8a146](https://github.com/Bekaboo/dropbar.nvim/commit/bb8a146c8249cfe2b64d1140e74fca3b92172d67))
* **menu:** dropbar_menu_entry_t:cat() & :find_first_clickable() indexing ([9dc9dd0](https://github.com/Bekaboo/dropbar.nvim/commit/9dc9dd0a5a6e0979e14ab7d7800851d880a2b1e0))
* **menu:** dropbar_menu_t:click_on() wrongly updates clicked_at column number ([867c5dd](https://github.com/Bekaboo/dropbar.nvim/commit/867c5dd8c34d992bbeec9abb99ab0b4feb771a36))
* **sources:** markdown parser children symbols resolution logic ([37d34e5](https://github.com/Bekaboo/dropbar.nvim/commit/37d34e5bd85c12efb0e486a8f1324ea52d23be7f))
* **sources:** markdown parser init ['end'].lnum ([6d9c78c](https://github.com/Bekaboo/dropbar.nvim/commit/6d9c78c01aaa94442f13d9a827b6cd756e430c31))
