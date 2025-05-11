.PHONY: all
all: format-check lint test

# Test / doc generation dependencies
deps:
	mkdir deps

deps/plenary.nvim: | deps
	git -C deps clone --depth=1 --filter=blob:none \
		https://github.com/nvim-lua/plenary.nvim

deps/telescope-fzf-native.nvim: | deps
	git -C deps clone --depth=1 --filter=blob:none \
		https://github.com/nvim-telescope/telescope-fzf-native.nvim
	(cd deps/telescope-fzf-native.nvim && make)

.PHONY: test
test: | deps/plenary.nvim deps/telescope-fzf-native.nvim
	nvim --clean --headless -u tests/minimal_init.lua \
		+"PlenaryBustedDirectory tests { minimal_init = 'tests/minimal_init.lua' }" \
		+qa!

.PHONY: test-file
test-file:
	nvim --clean --headless -u tests/minimal_init.lua \
		+"lua require(\"plenary.busted\").run(\"tests/$(WHICH)_spec.lua\")" \
		+qa!

.PHONY: format-check
format-check:
	stylua . --check

.PHONY: format
format:
	stylua .

.PHONY: lint
lint:
	luacheck .
