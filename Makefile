.PHONY: all
all: format-check lint test

.PHONY: test
test:
	nvim --headless -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ \
			{ minimal_init = 'tests/minimal_init.lua' }"

.PHONY: test-file
test-file:
	nvim --headless -u tests/minimal_init.lua \
		-c "lua require(\"plenary.busted\").run(\"tests/$(WHICH)_spec.lua\")"

.PHONY: format-check
format-check:
	stylua . --check

.PHONY: format
format:
	stylua .

.PHONY: lint
lint:
	luacheck .
