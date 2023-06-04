# Changelog

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
