.PHONY: all
all: format-check lint test docs

.PHONY: clean
clean:
	rm -rf deps doc

# Test / doc generation dependencies
doc:
	mkdir doc

deps:
	mkdir deps

deps/plenary.nvim: | deps
	git -C deps clone --depth=1 --filter=blob:none \
		https://github.com/nvim-lua/plenary.nvim

deps/telescope-fzf-native.nvim: | deps
	git -C deps clone --depth=1 --filter=blob:none \
		https://github.com/nvim-telescope/telescope-fzf-native.nvim
	(cd deps/telescope-fzf-native.nvim && make)

deps/gen-vimdoc.nvim: | deps
	git -C deps clone --depth=1 --filter=blob:none \
		https://github.com/Bekaboo/gen-vimdoc.nvim

deps/ts-vimdoc.nvim: | deps
	git -C deps clone --depth=1 --filter=blob:none \
		https://github.com/ibhagwan/ts-vimdoc.nvim

define nvim_gen_vimdoc_from
	nvim --clean --headless -u scripts/minimal_init.lua -l scripts/gen_vimdoc_from_$1.lua
endef
doc/dropbar.txt: README.md lua | doc deps/ts-vimdoc.nvim deps/gen-vimdoc.nvim
	$(call nvim_gen_vimdoc_from,md) && sed -i '$$ d' $@ # remove modeline
	$(call nvim_gen_vimdoc_from,src)
	sed -i 's/[ \t]\+$$//' $@ # remove trailing whitespaces

.PHONY: test
test: | deps/plenary.nvim deps/telescope-fzf-native.nvim
	nvim --clean --headless -u tests/minimal_init.lua \
		+"PlenaryBustedDirectory tests { minimal_init = 'tests/minimal_init.lua' }" \
		+qa!

# Examples:
# test-file-bar (will run `tests/bar_spec.lua`)
# test-file-sources:lsp (will run `tests/sources/lsp_spec.lua`)
.PHONY: test-file-%
test-file-%:
	nvim --clean --headless -u tests/minimal_init.lua \
		+"lua require(\"plenary.busted\").run(\"tests/$(subst :,/,$*)_spec.lua\")" \
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

.PHONY: docs
docs: doc/dropbar.txt
