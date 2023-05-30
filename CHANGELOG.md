# Changelog

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
