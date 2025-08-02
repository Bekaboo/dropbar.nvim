# Changelog

## [14.2.1](https://github.com/Bekaboo/dropbar.nvim/compare/v14.2.0...v14.2.1) (2025-07-31)


### Bug Fixes

* **sources.lsp:** error sorting LSP symbols with the same start position ([#255](https://github.com/Bekaboo/dropbar.nvim/issues/255)) ([498a8e6](https://github.com/Bekaboo/dropbar.nvim/commit/498a8e6a48d9948bbf27b3abd05f7d6e42d60f2b))
* **sources.lsp:** wrong request due to typo ([#259](https://github.com/Bekaboo/dropbar.nvim/issues/259)) ([80751f5](https://github.com/Bekaboo/dropbar.nvim/commit/80751f5e9db69b0cdf2a25d321f1e79745f9b324))
* **sources.terminal:** symbol icon is `nil` if `icons.enable` is `false` ([4f38124](https://github.com/Bekaboo/dropbar.nvim/commit/4f38124764135fb568c92efaf1d0e6533087f2a2))
* **tests.configs:** ensure that `term_buf` exists before cleaning up ([4110875](https://github.com/Bekaboo/dropbar.nvim/commit/4110875115bbccfad9beb3127465f8760ec8606e))

## [14.2.0](https://github.com/Bekaboo/dropbar.nvim/compare/v14.1.0...v14.2.0) (2025-07-14)


### Features

* **sources.lsp:** improve lsp symbol type hint ([8f8ae08](https://github.com/Bekaboo/dropbar.nvim/commit/8f8ae083cfc4dbc900cc73f5803fbc77346496ab))
* **sources.path:** highlight extended security marks in `ls` output ([64f5540](https://github.com/Bekaboo/dropbar.nvim/commit/64f5540824ab350f02dabc1276f4a1f4f141276b))


### Bug Fixes

* **configs:** default attach to terminals ([#247](https://github.com/Bekaboo/dropbar.nvim/issues/247)) ([12df0ef](https://github.com/Bekaboo/dropbar.nvim/commit/12df0effadec35529f3a4862e4a7caa3782a57af))
* **sources.lsp:** check buf valid before attaching/detaching ([85e4647](https://github.com/Bekaboo/dropbar.nvim/commit/85e4647589ede29ddf393963ad62efca443ab8a8))
* **sources.lsp:** sort lsp symbols by start position ([#250](https://github.com/Bekaboo/dropbar.nvim/issues/250)) ([9bdd4ac](https://github.com/Bekaboo/dropbar.nvim/commit/9bdd4ac87bcf88abb8ddddb394dc16ab8f111199))


### Performance Improvements

* **sources.lsp:** cancel previous lsp request on new request ([#249](https://github.com/Bekaboo/dropbar.nvim/issues/249)) ([1a40b4c](https://github.com/Bekaboo/dropbar.nvim/commit/1a40b4c83d10a7269471d16338dbe78078ef0fc0))

## [14.1.0](https://github.com/Bekaboo/dropbar.nvim/compare/v14.0.0...v14.1.0) (2025-06-01)


### Features

* **hlgrouos:** separate hl for current context icon and name ([#243](https://github.com/Bekaboo/dropbar.nvim/issues/243)) ([1cb3fac](https://github.com/Bekaboo/dropbar.nvim/commit/1cb3facee196a4ac7ee31df502d5dddeb77122e7))


### Bug Fixes

* **hlgroups:** shouldn't dim icons in menus ([b434e22](https://github.com/Bekaboo/dropbar.nvim/commit/b434e223f69d2ee101a3b1cb5c5a961344e4c832))

## [14.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v13.0.0...v14.0.0) (2025-05-17)


### ⚠ BREAKING CHANGES

* **hlgroups:** use `hl-WinBarNC` as default nc symbol name hl

### Features

* **hlgroups:** dim highlights in non-current windows ([#239](https://github.com/Bekaboo/dropbar.nvim/issues/239)) ([aff8629](https://github.com/Bekaboo/dropbar.nvim/commit/aff8629d14f9ea10ec843e460aa541c9d7e05d55))


### Code Refactoring

* **hlgroups:** use `hl-WinBarNC` as default nc symbol name hl ([a945b92](https://github.com/Bekaboo/dropbar.nvim/commit/a945b924d0803e4a24cb178e337bc364cdcd6abd))

## [13.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v12.0.2...v13.0.0) (2025-04-20)


### ⚠ BREAKING CHANGES

* drop neovim 0.10 support
* **configs:** remove 'module' from treesitter valid types ([#234](https://github.com/Bekaboo/dropbar.nvim/issues/234))

### Features

* **bar:** add config `min_widths` ([#237](https://github.com/Bekaboo/dropbar.nvim/issues/237)) ([a64fc20](https://github.com/Bekaboo/dropbar.nvim/commit/a64fc20c4ec7e10fc92dc80312457010755bb019))
* **configs,menu:** respect new `winborder` option in neovim 0.11 ([3ec39f1](https://github.com/Bekaboo/dropbar.nvim/commit/3ec39f1e65dbc643cefca55ce1dae03c96854905))
* **configs:** add support for goto & return statements ([bc30fac](https://github.com/Bekaboo/dropbar.nvim/commit/bc30facc6d8610a6e62c384cb045cd1b8bdfb68c))
* **configs:** add support to yaml blocks ([65cd22c](https://github.com/Bekaboo/dropbar.nvim/commit/65cd22c39f5cc0129852f6200ada486d91993865))
* **configs:** support treesitter 'section' nodes in markdown ([e7a980b](https://github.com/Bekaboo/dropbar.nvim/commit/e7a980b599ad37e1210031ded43db0467e75ffc2))
* **sources.path:** async preview with highlighting ([5f23a92](https://github.com/Bekaboo/dropbar.nvim/commit/5f23a92820d8d23eda1fbada141e3539840e404c))


### Bug Fixes

* **compat:** should check for neovim 0.11 instead of 0.10 ([2ce5c5c](https://github.com/Bekaboo/dropbar.nvim/commit/2ce5c5c48c81c1ae03d9bea204657dbb7e37fd16))
* **configs:** remove 'module' from treesitter valid types ([#234](https://github.com/Bekaboo/dropbar.nvim/issues/234)) ([873ba43](https://github.com/Bekaboo/dropbar.nvim/commit/873ba43f83398fd0e28880cf98fd89e6ce667c51))
* **sources.lsp:** add nil check for client id ([0bb3f12](https://github.com/Bekaboo/dropbar.nvim/commit/0bb3f1262fa8bfd8a1c05db29804d1116df32276))
* **sources.path:** disable hl in files with no filetype ([58abebe](https://github.com/Bekaboo/dropbar.nvim/commit/58abebe16b9c48615c651488847bf2dba72f8bdd))
* **sources.path:** possible error `Vim:E95` previewing same path in two buffers ([57ae5ec](https://github.com/Bekaboo/dropbar.nvim/commit/57ae5ec10a3aa0d9a3b59c68d6af3b827c003eae))


### Code Refactoring

* drop neovim 0.10 support ([da78f3e](https://github.com/Bekaboo/dropbar.nvim/commit/da78f3ec7e0030eb0985efc1f74d309c714cd7e5))

## [12.0.2](https://github.com/Bekaboo/dropbar.nvim/compare/v12.0.1...v12.0.2) (2025-03-05)


### Bug Fixes

* **sources.path:** 'empty file' displayed for directories ([009c214](https://github.com/Bekaboo/dropbar.nvim/commit/009c214b6eadf49ec50fc81055ceb08ca3fcb8e1))

## [12.0.1](https://github.com/Bekaboo/dropbar.nvim/compare/v12.0.0...v12.0.1) (2025-02-23)


### Bug Fixes

* **bar:** error opening menu containing symbols with newline in names ([a851224](https://github.com/Bekaboo/dropbar.nvim/commit/a851224002fde54927a4702b26d7bee7630b9442))
* **menu,utils:** compat with nvim 0.10 (fix [#224](https://github.com/Bekaboo/dropbar.nvim/issues/224)) ([a623911](https://github.com/Bekaboo/dropbar.nvim/commit/a6239111f2988cf8789cabd89c48114fb3f8dc90))
* **sources.path:** path preview on Windows ([#227](https://github.com/Bekaboo/dropbar.nvim/issues/227)) ([4a1c78e](https://github.com/Bekaboo/dropbar.nvim/commit/4a1c78eb0125412897005621b94d7bd44ac37592))

## [12.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v11.0.0...v12.0.0) (2025-02-05)


### ⚠ BREAKING CHANGES

* **configs:** don't reorient on jump or preview by default

### Features

* **configs:** add new option `opts.menu.hover` ([36eca19](https://github.com/Bekaboo/dropbar.nvim/commit/36eca199222dd2840e6a197f53f7f83ad514de0c))


### Bug Fixes

* avoid triggering menu close when entering fzf input window ([3afce85](https://github.com/Bekaboo/dropbar.nvim/commit/3afce85516c25823d5a1590f73ec19fe8553e2eb)), closes [#223](https://github.com/Bekaboo/dropbar.nvim/issues/223)
* **bar:** add at least 1 space after shortcut pivots ([#218](https://github.com/Bekaboo/dropbar.nvim/issues/218)) ([05d5fdc](https://github.com/Bekaboo/dropbar.nvim/commit/05d5fdc5a05c42b9741d21085da3f222f87c1467))
* **init,bar:** return empty string in deprecated functions ([f7b4958](https://github.com/Bekaboo/dropbar.nvim/commit/f7b4958553e01bbe8bc995d1e45e44c5981bd0c1))
* **menu:** menu entries wrapped ([#220](https://github.com/Bekaboo/dropbar.nvim/issues/220)) ([f11b273](https://github.com/Bekaboo/dropbar.nvim/commit/f11b27344dc3675cdaeffa9e1e5cab0442abb0fa))
* **menu:** menu not closed on leave ([9729526](https://github.com/Bekaboo/dropbar.nvim/commit/97295266ecb22597737b6022e6ce462d8dc9b6ad))
* **menu:** menu not closed on leave ([#222](https://github.com/Bekaboo/dropbar.nvim/issues/222)) ([c824f03](https://github.com/Bekaboo/dropbar.nvim/commit/c824f033d0e6b3a4cce550d7a767a516b99cee56))
* **menu:** scrollbar is focusable ([e53d047](https://github.com/Bekaboo/dropbar.nvim/commit/e53d0475f161f518c8937d466915838148fdc686))
* **sources.markdown:** last section wrong range ([f713778](https://github.com/Bekaboo/dropbar.nvim/commit/f7137785ed3ddce31d1e2837dc13792d24d217a8))
* **sources.path:** escape paths in `vim.fn.system()` call ([3312fb1](https://github.com/Bekaboo/dropbar.nvim/commit/3312fb14832f26ce4ad185d727cd542454429863))
* **sources.path:** properly escape special chars in files when edit ([f6ff378](https://github.com/Bekaboo/dropbar.nvim/commit/f6ff3785fbcf856c5b828ac1ac849172a8e6142a))
* The last section does not have a following section to upate its ([f713778](https://github.com/Bekaboo/dropbar.nvim/commit/f7137785ed3ddce31d1e2837dc13792d24d217a8))


### Performance Improvements

* **sources.markdown:** don't update in insert mode by default ([dcb1b81](https://github.com/Bekaboo/dropbar.nvim/commit/dcb1b81f997050735e196e033156a9d8f44197f8))


### Reverts

* "fix(menu): menu not closed on leave" ([0a152fd](https://github.com/Bekaboo/dropbar.nvim/commit/0a152fd7923bce65a85b56dd9e4938148b580d2f))
* "fix(sources.path): escape paths in `vim.fn.system()` call" ([0139787](https://github.com/Bekaboo/dropbar.nvim/commit/0139787b21426f300db54dd5bb986c2c8a41f16a))


### Code Refactoring

* **configs:** don't reorient on jump or preview by default ([b27bb03](https://github.com/Bekaboo/dropbar.nvim/commit/b27bb0353cb34bded65a8911e7d232b12100568b))

## [11.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v10.0.0...v11.0.0) (2025-01-19)


### ⚠ BREAKING CHANGES

* **configs:** increase default winbar update debounce to 32

### Features

* **configs:** add support for toml tables ([977117d](https://github.com/Bekaboo/dropbar.nvim/commit/977117d790849869e5f998a66916bdb606802a13))
* **menu:** add new method `root()` to find root menu ([7b8b13a](https://github.com/Bekaboo/dropbar.nvim/commit/7b8b13a4ef2d074c6e32519e6914b3e9090156a1))
* **sources.path:** disable win decorations when showing preview msg ([415701d](https://github.com/Bekaboo/dropbar.nvim/commit/415701dbada9f3278652ad6fd1ed4e1c3506e0ca))
* **sources.path:** follow symlinks when preview ([f19d5d2](https://github.com/Bekaboo/dropbar.nvim/commit/f19d5d22cd4f6bb85fd02075300b47b5962926b8))
* **sources.path:** support special bufs starting with `xxx://` ([#211](https://github.com/Bekaboo/dropbar.nvim/issues/211)) ([de3125a](https://github.com/Bekaboo/dropbar.nvim/commit/de3125ac765653788e5054c6e2df50a0f2191585))


### Bug Fixes

* Check components list length before padding. ([0a37764](https://github.com/Bekaboo/dropbar.nvim/commit/0a37764d845f847af16f2074aa893273088a205c))
* **menu:** handle menu entries without components ([0a37764](https://github.com/Bekaboo/dropbar.nvim/commit/0a37764d845f847af16f2074aa893273088a205c))
* **sources.path:** source buf not restored when mouse moves off sub menu ([d3ddf49](https://github.com/Bekaboo/dropbar.nvim/commit/d3ddf492bb68c6c756b2f2dd8864146c95bed68a))
* **sources.treesitter:** error getting treesitter node ([80538f5](https://github.com/Bekaboo/dropbar.nvim/commit/80538f5eee685c801d3049f6f42867f1ca33de4f))
* Wrap `vim.treesitter.get_node()` with `vim.F.npcall()`. ([80538f5](https://github.com/Bekaboo/dropbar.nvim/commit/80538f5eee685c801d3049f6f42867f1ca33de4f))


### Performance Improvements

* **configs:** increase default winbar update debounce to 32 ([289c4c3](https://github.com/Bekaboo/dropbar.nvim/commit/289c4c3283656a4f9fa837a881476fc6b8fd5b8d))
* **sources.path:** only load visible lines when preview ([51047f5](https://github.com/Bekaboo/dropbar.nvim/commit/51047f54a4535e775979272bfbeb685a6d229654))
* **sources.path:** stop treesitter before setting preview buf lines ([9f6a19a](https://github.com/Bekaboo/dropbar.nvim/commit/9f6a19aad3069c346738fd66d2f2679c3bb55e75))
* **sources.path:** use faster `readfile()` when preview ([d2792fc](https://github.com/Bekaboo/dropbar.nvim/commit/d2792fc7c163722b7d3607c9ad3aeb7192e009e4))

## [10.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v9.0.2...v10.0.0) (2024-12-28)


### ⚠ BREAKING CHANGES

* **bar:** use `__call()` to get string representation

### Features

* **configs:** allow overriding default `on_click()` callback ([b63fe2e](https://github.com/Bekaboo/dropbar.nvim/commit/b63fe2ef7cc84a2193f867a0cfb6988a1233ab31))
* **configs:** configure which LSP document symbols to show ([#203](https://github.com/Bekaboo/dropbar.nvim/issues/203)) ([b2c0fa8](https://github.com/Bekaboo/dropbar.nvim/commit/b2c0fa871a7b2f15f9ef32fa251a1052eb2abd99))
* **configs:** improve default `opts.bar.enable()` function ([d226c70](https://github.com/Bekaboo/dropbar.nvim/commit/d226c7028b66b9ae56e7055c89d90f7c8f6c89c1))
* **sources:** add `max_depth` option ([5439d2f](https://github.com/Bekaboo/dropbar.nvim/commit/5439d2f02bb744cecb878aaa23c6c6f8b21a351c))


### Bug Fixes

* **nvim:** `opts.bar.enable()` always return `false` when `buf == 0` ([34a29fe](https://github.com/Bekaboo/dropbar.nvim/commit/34a29fe385232b30383c6abfbf34643b2a964d08))


### Performance Improvements

* **configs:** `vim.treesitter.get_parser()` is slow in big files ([b2f778a](https://github.com/Bekaboo/dropbar.nvim/commit/b2f778a9ad153a1c222c8b5dc6df9fe1375eeea4))


### Code Refactoring

* **bar:** use `__call()` to get string representation ([e5eb834](https://github.com/Bekaboo/dropbar.nvim/commit/e5eb834c398cb985f1f1b3efdaf5e7822441f6e7))

## [9.0.2](https://github.com/Bekaboo/dropbar.nvim/compare/v9.0.1...v9.0.2) (2024-11-17)


### Bug Fixes

* **hlgroups:** don't remove winbar background in nightly ([#195](https://github.com/Bekaboo/dropbar.nvim/issues/195)) ([0065665](https://github.com/Bekaboo/dropbar.nvim/commit/006566571f7af2edf45c99fb997d550878c661ad))

## [9.0.1](https://github.com/Bekaboo/dropbar.nvim/compare/v9.0.0...v9.0.1) (2024-11-02)


### Bug Fixes

* Use personal access token (PAT), see discussion: ([22382f4](https://github.com/Bekaboo/dropbar.nvim/commit/22382f44f8ce0320d38023c6a68f3ef4087c8c10))

## [9.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v8.6.1...v9.0.0) (2024-10-31)


### ⚠ BREAKING CHANGES

* **configs:** deprecate `use_devicons`, allow dir/file icon callback
* **configs:** deprecate `opts.general`
* **hlgroups:** link to ts hl instead of regex syntax hl
* **hlgroups:** don't depend on cmp hlgroups
* **sources-treesitter & configs:** use vim regex to match ts node name

### Features

* **configs:** deprecate `use_devicons`, allow dir/file icon callback ([a1b893c](https://github.com/Bekaboo/dropbar.nvim/commit/a1b893ccc96080f0d167eef6e9310a40ef85ccba))
* **configs:** more sensible treesitter valid node types ([5186097](https://github.com/Bekaboo/dropbar.nvim/commit/5186097fe4896a571f9b009fd0159a416933f44a))
* **sources-path:** add filetype devicon as fallback ([#185](https://github.com/Bekaboo/dropbar.nvim/issues/185)) ([ede945e](https://github.com/Bekaboo/dropbar.nvim/commit/ede945efd60893b7b25a854c93a749c7b0d11241))
* **sources-treesitter & configs:** use vim regex to match ts node name ([678a59c](https://github.com/Bekaboo/dropbar.nvim/commit/678a59cb4b43d56e67939a37c065fc0d96c106fa))
* **sources-treesitter:** reduce consecutive spaces in ts symbol name ([35988af](https://github.com/Bekaboo/dropbar.nvim/commit/35988affc74c0cebb1484bcdfccfed523c0e7267))


### Bug Fixes

* **api:** shouldn't reorient when jumping to context ([61d1403](https://github.com/Bekaboo/dropbar.nvim/commit/61d1403532bf6fb3a28caef8394e34234cf674e6))
* **configs & hlgroups:** missing icons and hlgroups for ts types ([a12869f](https://github.com/Bekaboo/dropbar.nvim/commit/a12869f34f8cd236dc708fb2815ccf1663000bf4))
* **configs,sources.path:** concat nil when icons disabled ([#190](https://github.com/Bekaboo/dropbar.nvim/issues/190)) ([28bcb1c](https://github.com/Bekaboo/dropbar.nvim/commit/28bcb1cdd44cbddc0a2ec3137caabacc350b41eb))
* Remove use of deprecated `opts.sources.treesitter.name_pattern` ([ef933aa](https://github.com/Bekaboo/dropbar.nvim/commit/ef933aa4162d9cde23c20d9897b967913aaf5084))
* **setup:** avoid setup twice when using lazy.nvim ([#181](https://github.com/Bekaboo/dropbar.nvim/issues/181)) ([b7b0cd2](https://github.com/Bekaboo/dropbar.nvim/commit/b7b0cd2670cfab298afc955f2531206218736766))
* **setup:** dropbar attaches to wrong window ([6156e07](https://github.com/Bekaboo/dropbar.nvim/commit/6156e07759fd8c7cbf764414f583aa7e47470368))
* **sources-path:** `get_symbols()` error caused by drive name on Windows ([#175](https://github.com/Bekaboo/dropbar.nvim/issues/175)) ([d26bf92](https://github.com/Bekaboo/dropbar.nvim/commit/d26bf92161cd70e049dc138b44ffa0246dbf7178))
* **sources-path:** file icons not selected using filetype as fallback ([01ed539](https://github.com/Bekaboo/dropbar.nvim/commit/01ed539822237652e94ea076f78a44c50bdd634c))
* **sources-terminal:** icon shown when `opts.icons.enable` is `false` ([9d8cad9](https://github.com/Bekaboo/dropbar.nvim/commit/9d8cad9548804a33c9a1968fe305e46e95c911ae))
* **sources.treesitter:** ts source not returning symbols ([#189](https://github.com/Bekaboo/dropbar.nvim/issues/189)) ([ef933aa](https://github.com/Bekaboo/dropbar.nvim/commit/ef933aa4162d9cde23c20d9897b967913aaf5084))
* This is because `default` is set when calling `get_icon()` with ([01ed539](https://github.com/Bekaboo/dropbar.nvim/commit/01ed539822237652e94ea076f78a44c50bdd634c))


### Performance Improvements

* **configs:** by default don't update in insert mode ([ff02391](https://github.com/Bekaboo/dropbar.nvim/commit/ff02391435cfab0f4406d21a39b4f489853b4f5e))


### Code Refactoring

* **configs:** deprecate `opts.general` ([54590c0](https://github.com/Bekaboo/dropbar.nvim/commit/54590c06469eb5fbbcc6a417c91cbc250a801664))
* **hlgroups:** don't depend on cmp hlgroups ([5f0da7f](https://github.com/Bekaboo/dropbar.nvim/commit/5f0da7fa51e4e884e9ab1dc02cd32509252cdf19))
* **hlgroups:** link to ts hl instead of regex syntax hl ([9b58487](https://github.com/Bekaboo/dropbar.nvim/commit/9b58487682f446a9451fb3aa6da1cb017f12fa45))

## [8.6.1](https://github.com/Bekaboo/dropbar.nvim/compare/v8.6.0...v8.6.1) (2024-07-25)


### Bug Fixes

* **configs:** winbar attached to floating windows ([6567d50](https://github.com/Bekaboo/dropbar.nvim/commit/6567d50fd792056e2001663f5cd4d8bfb6840604))

## [8.6.0](https://github.com/Bekaboo/dropbar.nvim/compare/v8.5.0...v8.6.0) (2024-06-14)


### Features

* **hlgroups:** add workaround for winbar background issue ([#118](https://github.com/Bekaboo/dropbar.nvim/issues/118)) ([98aec7c](https://github.com/Bekaboo/dropbar.nvim/commit/98aec7ca97da2a271ff32c6a151873a75f15a691))


### Bug Fixes

* **compat-0.11:** use `vim.islist` if available ([#158](https://github.com/Bekaboo/dropbar.nvim/issues/158)) ([9fc10fa](https://github.com/Bekaboo/dropbar.nvim/commit/9fc10fa1a34ec3e55b470962e4e94644611bd209))
* **menu:** cursor position not restored after exiting fzf mode ([cd79d3c](https://github.com/Bekaboo/dropbar.nvim/commit/cd79d3c9fbe6548b80ed6107405f33387d907e5c))
* **sources-path:** not switching to selected file if selected from fzf ([fd917b7](https://github.com/Bekaboo/dropbar.nvim/commit/fd917b70535371d45285bc94f9eb6387677c6dce))

## [8.5.0](https://github.com/Bekaboo/dropbar.nvim/compare/v8.4.0...v8.5.0) (2024-04-20)


### Features

* **configs:** show warning messages when file is too large to preview ([e3c7de9](https://github.com/Bekaboo/dropbar.nvim/commit/e3c7de9f733587373959b220d5a1970c476a3d9f))

## [8.4.0](https://github.com/Bekaboo/dropbar.nvim/compare/v8.3.0...v8.4.0) (2024-03-24)


### Features

* **menu:** set &winfixbuf in menu windows ([a5f3d6a](https://github.com/Bekaboo/dropbar.nvim/commit/a5f3d6a172fceadcfed58b8c209ac3211635a3c8))

## [8.3.0](https://github.com/Bekaboo/dropbar.nvim/compare/v8.2.1...v8.3.0) (2024-03-03)


### Features

* **path:** support file preview for path source ([#86](https://github.com/Bekaboo/dropbar.nvim/issues/86)) ([0a557bd](https://github.com/Bekaboo/dropbar.nvim/commit/0a557bdbe3c8fbf0ba15d773c5d3b19a7214de95))
* **sources-path & configs:** add `opts.sources.path.preview` ([0a557bd](https://github.com/Bekaboo/dropbar.nvim/commit/0a557bdbe3c8fbf0ba15d773c5d3b19a7214de95))


### Bug Fixes

* **sources-path:** indexing nil value when previewing dirs/links, etc. ([0a557bd](https://github.com/Bekaboo/dropbar.nvim/commit/0a557bdbe3c8fbf0ba15d773c5d3b19a7214de95))

## [8.2.1](https://github.com/Bekaboo/dropbar.nvim/compare/v8.2.0...v8.2.1) (2024-02-24)


### Bug Fixes

* **configs:** do not pass filetype directly ([#143](https://github.com/Bekaboo/dropbar.nvim/issues/143)) ([a133a7d](https://github.com/Bekaboo/dropbar.nvim/commit/a133a7deed7431496d8e87e8e4cc9c09a9d78945))

## [8.2.0](https://github.com/Bekaboo/dropbar.nvim/compare/v8.1.0...v8.2.0) (2024-02-17)


### Features

* **fzf:** allow fzf win_configs to contain functions, fix vertical offsets ([#131](https://github.com/Bekaboo/dropbar.nvim/issues/131)) ([ef73236](https://github.com/Bekaboo/dropbar.nvim/commit/ef7323643390083177bc9a397c0752d84fd1faf1))
* **ui-select:** support optional preview of items ([#124](https://github.com/Bekaboo/dropbar.nvim/issues/124)) ([f835519](https://github.com/Bekaboo/dropbar.nvim/commit/f83551969f796dddd05b57782f471dc2a50c35ee))


### Bug Fixes

* **autocmd:** add missing setup event `BufNewFile` ([#140](https://github.com/Bekaboo/dropbar.nvim/issues/140)) ([fa43ea3](https://github.com/Bekaboo/dropbar.nvim/commit/fa43ea3546f9e8a8fab5eecc18bce2cfd2946249))
* **configs:** attach dropbar to both windows in diff (close [#135](https://github.com/Bekaboo/dropbar.nvim/issues/135)) ([4855b9b](https://github.com/Bekaboo/dropbar.nvim/commit/4855b9b74133b138aa09827b41597f17aca3c207))
* **event:** `vim.v.event.windows` is nil after `:doau WinResized` ([e4fd982](https://github.com/Bekaboo/dropbar.nvim/commit/e4fd98274f3fed310d0085c16353e7e7b3ce86a1))
* This is because we set the `border[2]` to ' ' (space). ([c3de6fe](https://github.com/Bekaboo/dropbar.nvim/commit/c3de6fee0dbd836568cbacb0f7ce7b312ca03f27))
* **utils:** menu: `ui.select` menu has thick bottom border ([c3de6fe](https://github.com/Bekaboo/dropbar.nvim/commit/c3de6fee0dbd836568cbacb0f7ce7b312ca03f27))

## [8.1.0](https://github.com/Bekaboo/dropbar.nvim/compare/v8.0.2...v8.1.0) (2024-01-25)


### Features

* **api:** improve fuzzy-find api and doc ([55040ca](https://github.com/Bekaboo/dropbar.nvim/commit/55040ca442447691bab44d3e741a6cf7b730826a))
* **configs:** new keymap `&lt;C-n&gt;` & `<C-p>` to navigate when fuzzy-find ([ffa36d8](https://github.com/Bekaboo/dropbar.nvim/commit/ffa36d85e245796c0f13c1f89e50970f1084b828))
* **menu:** `fuzzy_find_navigate()` accepts integer as direction ([b485e43](https://github.com/Bekaboo/dropbar.nvim/commit/b485e43490f52593589309fd567283c383841ddd))
* **menu:** use autocmd to close fzf window after leaving insert mode ([d197d2c](https://github.com/Bekaboo/dropbar.nvim/commit/d197d2c141571c2eb11321d2a7c6d239ab111a1f))
* **utils:** menu: improve `ui.select()` function ([0c3b4f6](https://github.com/Bekaboo/dropbar.nvim/commit/0c3b4f6b64af8e24c115f5f4fd7b35c978ee43db))


### Bug Fixes

* **menu:** `col` field missing in fzf window config ([eb3c3d8](https://github.com/Bekaboo/dropbar.nvim/commit/eb3c3d86a631d150555ec016cf7feca892584a12))
* **menu:** `has_bottom_border` is wrong when `border == { "" }` ([bad67c3](https://github.com/Bekaboo/dropbar.nvim/commit/bad67c399a393c2fb1dc59132ba9fadc76d23bba))
* **menu:** force fzf-window anchor to 'NW' to ensure alignment ([#131](https://github.com/Bekaboo/dropbar.nvim/issues/131)) ([589c1cf](https://github.com/Bekaboo/dropbar.nvim/commit/589c1cf7fc664268b184110a3e1e7f37b91a6323))
* **menu:** make sure fzf-window aligns with menu window ([#131](https://github.com/Bekaboo/dropbar.nvim/issues/131)) ([a296281](https://github.com/Bekaboo/dropbar.nvim/commit/a29628111535f197aaaffe7bfaf11829d5b55a68))
* **menu:** scrollbar thumb not visiable (commit e68e054) ([6f01ec8](https://github.com/Bekaboo/dropbar.nvim/commit/6f01ec88413850af9d02a8f1a788d510521141de))
* **menu:** should align based on menu win's border not fzf win's ([22263e6](https://github.com/Bekaboo/dropbar.nvim/commit/22263e6aa5fe50a6377d61cbae7364a333054ac8))
* **types:** add `./lua` and `$VIMRUNTIME/lua` to library  in `.luarc.json` ([#134](https://github.com/Bekaboo/dropbar.nvim/issues/134)) ([9a8e498](https://github.com/Bekaboo/dropbar.nvim/commit/9a8e498374276dd0281736c75b42098ef9fb5622))

## [8.0.2](https://github.com/Bekaboo/dropbar.nvim/compare/v8.0.1...v8.0.2) (2024-01-17)


### Bug Fixes

* **bar:** also escape percent signs in icons ([#128](https://github.com/Bekaboo/dropbar.nvim/issues/128)) ([4d8e7ac](https://github.com/Bekaboo/dropbar.nvim/commit/4d8e7acfa2a93835b305df144eae37904aa5ecc1))
* **bar:** escape percent signs in symbol_t component names ([#128](https://github.com/Bekaboo/dropbar.nvim/issues/128)) ([b1b5979](https://github.com/Bekaboo/dropbar.nvim/commit/b1b59792a26e212a61acf8c78d393e4d4295dfc1))

## [8.0.1](https://github.com/Bekaboo/dropbar.nvim/compare/v8.0.0...v8.0.1) (2024-01-12)


### Bug Fixes

* **menu:** preview not updated after returning to prev menu ([bfba257](https://github.com/Bekaboo/dropbar.nvim/commit/bfba257774f78de384cca898d88cc1bb14c5a228))
* The issue stems from the conditional check in ([bfba257](https://github.com/Bekaboo/dropbar.nvim/commit/bfba257774f78de384cca898d88cc1bb14c5a228))

## [8.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v7.3.0...v8.0.0) (2023-12-23)


### ⚠ BREAKING CHANGES

* **bar:** make callback indexing more robust

### Features

* **bar:** truncate leading symbols in extreme narrow windows ([053f7f3](https://github.com/Bekaboo/dropbar.nvim/commit/053f7f30fd07e99f4d1c92b7931bcd1f2a6d723e))
* **configs:** use `&lt;Esc&gt;` in normal mode to close current menu ([ee3a356](https://github.com/Bekaboo/dropbar.nvim/commit/ee3a356254ab494c0e280b809969a7a3a7e38fb7))
* use dropbar menu for `ui.select` (opt-in) ([#120](https://github.com/Bekaboo/dropbar.nvim/issues/120)) ([86a7736](https://github.com/Bekaboo/dropbar.nvim/commit/86a7736f097f2a3fea7da1fc75c16f4ff1a50914))


### Bug Fixes

* **configs & menu:** default mapping in visual mode causes confusion ([10b2873](https://github.com/Bekaboo/dropbar.nvim/commit/10b2873a6aa8fd5046b4c5d752d4e842e5dbbb6c))


### Performance Improvements

* **menu:** make preview smoother; reduce unnecessary cursor jumps ([4f22910](https://github.com/Bekaboo/dropbar.nvim/commit/4f22910fe08592ddcc0684bc930538b8ce1fbf8f))


### Code Refactoring

* **bar:** make callback indexing more robust ([3dd2c28](https://github.com/Bekaboo/dropbar.nvim/commit/3dd2c282b4fb3410eced46b2debd21e292e6fad1))

## [7.3.0](https://github.com/Bekaboo/dropbar.nvim/compare/v7.2.1...v7.3.0) (2023-12-09)


### Features

* **menu:** scrollbar customization options ([#96](https://github.com/Bekaboo/dropbar.nvim/issues/96)) ([e68e054](https://github.com/Bekaboo/dropbar.nvim/commit/e68e054db7533822bf3121c24bc92c81745c60cd))


### Bug Fixes

* **bar:** should set jumplist before dropbar_symbol_t:jump() ([f54d926](https://github.com/Bekaboo/dropbar.nvim/commit/f54d926d67d66e226b94e3b626e5f13224bc961d))
* **menu-scrollbar:** scrollbar thumb covered by menu border ([2b7c2d5](https://github.com/Bekaboo/dropbar.nvim/commit/2b7c2d53363cb3d93376904dac3ea6d52dd900c5))
* remove hover highlight on FocusLost ([#119](https://github.com/Bekaboo/dropbar.nvim/issues/119)) ([50319e2](https://github.com/Bekaboo/dropbar.nvim/commit/50319e295d80241bee284386ad38781fb3411112))
* **sources-markdown:** check buffer validity, close [#114](https://github.com/Bekaboo/dropbar.nvim/issues/114) ([9885b34](https://github.com/Bekaboo/dropbar.nvim/commit/9885b34a05de6c2dc97d3ceda554a02e33c460ff))
* update hover highlight on FocusGained ([7b65210](https://github.com/Bekaboo/dropbar.nvim/commit/7b65210700ba3886bfbf8ab8686d50b62f36fc9f))

## [7.2.1](https://github.com/Bekaboo/dropbar.nvim/compare/v7.2.0...v7.2.1) (2023-11-24)


### Bug Fixes

* **sources-treesitter:** active ts parser ignore if highlight disabled ([c88c4ff](https://github.com/Bekaboo/dropbar.nvim/commit/c88c4ffbb41c10dfd36e3405f4619e355ebee58d))

## [7.2.0](https://github.com/Bekaboo/dropbar.nvim/compare/v7.1.0...v7.2.0) (2023-11-14)


### Features

* **configs:** add default keymap `q` to close current menu ([183587d](https://github.com/Bekaboo/dropbar.nvim/commit/183587de8899a8a61edd974ade9c4df73e6b6a49))


### Bug Fixes

* **sources-path:** infinate loop finding root on Windows system ([#111](https://github.com/Bekaboo/dropbar.nvim/issues/111)) ([c8a209e](https://github.com/Bekaboo/dropbar.nvim/commit/c8a209ee319bb93e41e4daebc02eb1614409c350))

## [7.1.0](https://github.com/Bekaboo/dropbar.nvim/compare/v7.0.1...v7.1.0) (2023-11-10)


### Features

* **configs:** improve preview reorient function ([09d2898](https://github.com/Bekaboo/dropbar.nvim/commit/09d289822244bc1dc115d1ee59cf4be9cfc5ddbb))
* **menu & configs:** more responsive hovering & clicking in normal mode ([927cc56](https://github.com/Bekaboo/dropbar.nvim/commit/927cc566c562db8665ff52dd9e2df0ef6c37b1b2))


### Bug Fixes

* **configs & icons:** add missing terminal icon ([76e72ca](https://github.com/Bekaboo/dropbar.nvim/commit/76e72cac6f6cedcc9d09c56a909ae284f5dc62c7))


### Performance Improvements

* **configs:** remove some rarely-used events ([68eebfd](https://github.com/Bekaboo/dropbar.nvim/commit/68eebfde164db0d310f134f80600d0979d8e6ece))

## [7.0.1](https://github.com/Bekaboo/dropbar.nvim/compare/v7.0.0...v7.0.1) (2023-11-03)


### Bug Fixes

* **configs:** cannot find winnr (again) ([9f86b27](https://github.com/Bekaboo/dropbar.nvim/commit/9f86b27005031e5a418a8a46633f3db86925b978))
* **configs:** cannot find winnr (invalid window ID) ([0242c97](https://github.com/Bekaboo/dropbar.nvim/commit/0242c976119a0d115e38930125461082ecff4b55))
* **memory:** dereference global callbacks correctly ([3435bb8](https://github.com/Bekaboo/dropbar.nvim/commit/3435bb87cb3887d92ecd2675ae7e3ee986c421eb))
* **sources-path & configs:** should use window-local cwd ([d42a135](https://github.com/Bekaboo/dropbar.nvim/commit/d42a1354d450fa82b341edb04094b2e201cb78bc))

## [7.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v6.0.0...v7.0.0) (2023-10-19)


### ⚠ BREAKING CHANGES

* **configs:** use only markdown source for markdown file symbols

### Features

* **configs:** use only markdown source for markdown file symbols ([c8b3013](https://github.com/Bekaboo/dropbar.nvim/commit/c8b30136d18e79228a48db32e090c82428af34c9))


### Bug Fixes

* **sources-lsp:** handle out-of-spec lsp symbol number, close [#104](https://github.com/Bekaboo/dropbar.nvim/issues/104) ([6e52712](https://github.com/Bekaboo/dropbar.nvim/commit/6e52712cadded5ecc667930c2559ce10550d8ff9))

## [6.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v5.1.0...v6.0.0) (2023-10-07)


### ⚠ BREAKING CHANGES

* **fzf/configs:** remove config option `opts.fzf.hl`
* **menu:** add background for scrollbar; simplify scrollbar logic
* **hlgroups:** link `hl-DropBarMenuScrollBar` to `hl-PmenuThumb` by default
* add builtin source for terminal buffers ([#78](https://github.com/Bekaboo/dropbar.nvim/issues/78))

### Features

* add builtin source for terminal buffers ([#78](https://github.com/Bekaboo/dropbar.nvim/issues/78)) ([6b88dab](https://github.com/Bekaboo/dropbar.nvim/commit/6b88dab5d24b9750f50984e731de9b8bd1fef044))
* **menu:** add background for scrollbar; simplify scrollbar logic ([eac1b26](https://github.com/Bekaboo/dropbar.nvim/commit/eac1b2661fa139d934215cb20989aaed79861ea1))
* **menu:** add scrollbar to the menu when the symbol list is too long ([#84](https://github.com/Bekaboo/dropbar.nvim/issues/84)) ([54813b4](https://github.com/Bekaboo/dropbar.nvim/commit/54813b42387535413c5b9f8bd175810559e81d32))
* **menu:** allow showing virtual text below entries ([#92](https://github.com/Bekaboo/dropbar.nvim/issues/92)) ([3daffc1](https://github.com/Bekaboo/dropbar.nvim/commit/3daffc1215d715a4e9c544e2c71db16aab61d86f))
* **menu:** fuzzy finding ([#77](https://github.com/Bekaboo/dropbar.nvim/issues/77)) ([8da1555](https://github.com/Bekaboo/dropbar.nvim/commit/8da155550dbd4d2da6740a4a8d6bddb75d6964dd))


### Bug Fixes

* always ensure that offset is no larger than ([b4b6b4a](https://github.com/Bekaboo/dropbar.nvim/commit/b4b6b4ab7bfed6dfedc81ced43c67d83dc14a54a))
* **api:** dropbar_menu_t:fuzzy_find_close() param ([2254b1d](https://github.com/Bekaboo/dropbar.nvim/commit/2254b1d5846d2d83b42beccfc375872435b02ce6))
* **bar:** potential bug in the return value of dropbar_t:pick_mode_wrap() ([648a19c](https://github.com/Bekaboo/dropbar.nvim/commit/648a19c9002eb36af85d6088727e13032e01f413))
* **fzf:** ensure `fzf_entry.pos` is non-nil in `on_update` ([#98](https://github.com/Bekaboo/dropbar.nvim/issues/98)) ([9fc12e3](https://github.com/Bekaboo/dropbar.nvim/commit/9fc12e3f16948a82465509f69474544efc5fd23a)), closes [#97](https://github.com/Bekaboo/dropbar.nvim/issues/97)
* **fzf:** hover highlighting of last entry in fzf ([#91](https://github.com/Bekaboo/dropbar.nvim/issues/91)) ([044dbc7](https://github.com/Bekaboo/dropbar.nvim/commit/044dbc7748025bdcf8562e351b5dc8361ea77f99))
* highlight current terminal buffer properly in menu ([1869204](https://github.com/Bekaboo/dropbar.nvim/commit/1869204a43203a632beaaaa5bf514e5d428dda6a))
* **hover:** clear if no component if under mouse, close [#80](https://github.com/Bekaboo/dropbar.nvim/issues/80) ([28436bf](https://github.com/Bekaboo/dropbar.nvim/commit/28436bffad9511d2775e4b44af6ae3bbe8c04c43))
* **menu-scrollbar:** revert 2debe82 ([#94](https://github.com/Bekaboo/dropbar.nvim/issues/94)) ([7a91b7b](https://github.com/Bekaboo/dropbar.nvim/commit/7a91b7ba15fcf78ba0d0081cbce7e31a73963b1c)), closes [#93](https://github.com/Bekaboo/dropbar.nvim/issues/93)
* **menu-scrollbar:** scrollbar not at bottom when last line is shown (partially fix [#93](https://github.com/Bekaboo/dropbar.nvim/issues/93)) ([dc11786](https://github.com/Bekaboo/dropbar.nvim/commit/dc11786bc5a57d9317ab70b3bffa5f480f95816d))
* **menu-scrollbar:** scrollbar should be covered by sub-menus ([5b957d5](https://github.com/Bekaboo/dropbar.nvim/commit/5b957d533673568411eb3532554c9bbce8214154))
* **menu-scrollbar:** scrollbar underflow ([b4b6b4a](https://github.com/Bekaboo/dropbar.nvim/commit/b4b6b4ab7bfed6dfedc81ced43c67d83dc14a54a))
* **menu:** allow `relative` win settings other than `win`; improve fzf window placement ([#90](https://github.com/Bekaboo/dropbar.nvim/issues/90)) ([2d383f4](https://github.com/Bekaboo/dropbar.nvim/commit/2d383f40262258b10974e9ae9b3f76b95730de63))
* **menu:** scrollbar position ([eb61e57](https://github.com/Bekaboo/dropbar.nvim/commit/eb61e57c7c6870ce101e0083afd12adb6b4e105e))
* **sources:** terminal: add missing name highlight ([2d94c28](https://github.com/Bekaboo/dropbar.nvim/commit/2d94c28264fc43eb65a56c227ee2f4526cd8dfa8))


### Code Refactoring

* **fzf/configs:** remove config option `opts.fzf.hl` ([deaa54d](https://github.com/Bekaboo/dropbar.nvim/commit/deaa54dd445275dc51639fa23e648ec3e0dce0f9))
* **hlgroups:** link `hl-DropBarMenuScrollBar` to `hl-PmenuThumb` by default ([813c032](https://github.com/Bekaboo/dropbar.nvim/commit/813c032cc941e1e470b8b2836d854e1d3fc2fd74))

## [5.1.0](https://github.com/Bekaboo/dropbar.nvim/compare/v5.0.3...v5.1.0) (2023-08-28)


### Features

* **config:** make attach events configurable, fix [#70](https://github.com/Bekaboo/dropbar.nvim/issues/70) ([b2695b7](https://github.com/Bekaboo/dropbar.nvim/commit/b2695b7880fdafe1b270927c13dd6714416d990c))


### Bug Fixes

* **menu:** duplicate current-context highlight in the first menu ([348a318](https://github.com/Bekaboo/dropbar.nvim/commit/348a318747b266da13e91636b657a069d26fd942))

## [5.0.3](https://github.com/Bekaboo/dropbar.nvim/compare/v5.0.2...v5.0.3) (2023-08-22)


### Bug Fixes

* **bar:** check if buf number is valid before truncating ([8825367](https://github.com/Bekaboo/dropbar.nvim/commit/8825367c86cdcd8577732419ef68258c9ad6d398))

## [5.0.2](https://github.com/Bekaboo/dropbar.nvim/compare/v5.0.1...v5.0.2) (2023-08-10)


### Bug Fixes

* **bar:** hovering highlight not updated for dropbar at non-current windows ([fb97d5e](https://github.com/Bekaboo/dropbar.nvim/commit/fb97d5e4432aba6c14ef1a73c6fbf7091be33fa3))
* **bar:** remove debug print ([b201f50](https://github.com/Bekaboo/dropbar.nvim/commit/b201f500d19e632cc08b87ca8ad31eef41a7b2fe))
* **highlights:** current context & hovering highlight priorities in menu ([88d71c6](https://github.com/Bekaboo/dropbar.nvim/commit/88d71c6fc8002b236549052944efb3fa1a6970ed))
* **highlights:** winbar highlights changed after hovering/clicking if not defined ([4785774](https://github.com/Bekaboo/dropbar.nvim/commit/47857743232f7d97d51da25196724b7657472fd0))

## [5.0.1](https://github.com/Bekaboo/dropbar.nvim/compare/v5.0.0...v5.0.1) (2023-07-10)


### Bug Fixes

* **dropbar:** WinResized not updating all affected windows ([#56](https://github.com/Bekaboo/dropbar.nvim/issues/56)) ([03bfd62](https://github.com/Bekaboo/dropbar.nvim/commit/03bfd620f4d98a889bc7a0059ddb21dd24abdd7f))
* **menu:** highlighting issues that occur during menu navigation ([#52](https://github.com/Bekaboo/dropbar.nvim/issues/52)) ([a34d3e6](https://github.com/Bekaboo/dropbar.nvim/commit/a34d3e6d19903d4e81c3bef3c743464117af631f))
* **sources.path/highlights:** `DropBarKindFile` not used ([dd0a43d](https://github.com/Bekaboo/dropbar.nvim/commit/dd0a43d0bdd2918bef5ed7f42caacb1bbe5d7d92))
* **sources:** lsp source should not request for winbar update, fix [#55](https://github.com/Bekaboo/dropbar.nvim/issues/55) ([7341bee](https://github.com/Bekaboo/dropbar.nvim/commit/7341beee61e7ab48d504fc5f4989dfa934d2151c))

## [5.0.0](https://github.com/Bekaboo/dropbar.nvim/compare/v4.0.0...v5.0.0) (2023-07-06)


### ⚠ BREAKING CHANGES

* **sources/config:** treesitter/markdown: perfer treesitter parser
* **sources/config:** treesitter: improve default name pattern and logic
* **highlights:** remove hl-DropBarIconCurrentContext

### Features

* **api:** get_dropbar() accepts empty buffer number ([9a94a22](https://github.com/Bekaboo/dropbar.nvim/commit/9a94a2205d0702dc6258ccdcae34da73a08b9e7b))
* **bar:** add truncate mark after the left padding ([3b7412c](https://github.com/Bekaboo/dropbar.nvim/commit/3b7412c13494ffc23519a4dcc3a29c56a22dd9ab))
* **bar:** highlight the symbol under mouse hovering in the winbar ([c2f49e8](https://github.com/Bekaboo/dropbar.nvim/commit/c2f49e81156038254fe8789a73d08c76fc4db94d))
* **bar:** support swapping and restoring nil values in dropbar_symbol_t ([31b6fe0](https://github.com/Bekaboo/dropbar.nvim/commit/31b6fe0a77e7ab39143031d305731db103898762))
* **sources/config:** treesitter: improve default name pattern and logic ([c72bd7f](https://github.com/Bekaboo/dropbar.nvim/commit/c72bd7f09f6038540a51dd34c0fc52dce469dabd))
* **sources/config:** treesitter/markdown: perfer treesitter parser ([15115eb](https://github.com/Bekaboo/dropbar.nvim/commit/15115ebbbec87bdf6f2b6891d451309422e37066))
* **sources:** treesitter: add json pair to valid treesitter types ([5c8bd1a](https://github.com/Bekaboo/dropbar.nvim/commit/5c8bd1a4afe55c211c56b27a0a068ca1ff709c6e))
* **sources:** treesitter: handle cursor pos in insert mode differently ([c25bef8](https://github.com/Bekaboo/dropbar.nvim/commit/c25bef89bce0300cb3913a51f711502f6b2ca310))


### Bug Fixes

* **config:** wrong sources path ([#46](https://github.com/Bekaboo/dropbar.nvim/issues/46)) ([a718484](https://github.com/Bekaboo/dropbar.nvim/commit/a718484ab639c8dc839d2c9c1031052ec6766072))
* **menu:** error if execute `:bw` in dropbar menu ([62590d6](https://github.com/Bekaboo/dropbar.nvim/commit/62590d609c806563b9ff9a8e8818d3ce60e4a049))


### Reverts

* "feat(bar): add truncate mark after the left padding" ([e07ef94](https://github.com/Bekaboo/dropbar.nvim/commit/e07ef941ec496bd5ed5ea353ffeb8be6167110d2))


### Code Refactoring

* **highlights:** remove hl-DropBarIconCurrentContext ([24106ff](https://github.com/Bekaboo/dropbar.nvim/commit/24106ff3be3de91c9d455e0bbd0fc505b98b08fc))

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
