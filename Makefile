.PHONY: fmt lint check test help

help:
	@echo
	@echo   Neovim config - quality targets
	@echo   --------------------------------
	@echo   make fmt    - Format Lua files with stylua
	@echo   make lint   - Lint Lua files with luacheck
	@echo   make check  - Run fmt + lint
	@echo   make test   - Run plenary test suite
	@echo   make help   - Show this message
	@echo

fmt:
	@echo Formatting Lua files...
	stylua lua/ init.lua tests/
	@echo Done.

lint:
	@echo Linting Lua files...
	luacheck init.lua lua/core lua/plugins lua/lsp lua/tools lua/utils lua/monprofil tests/autocmds_spec.lua tests/env_spec.lua tests/keymaps_spec.lua tests/minimal_init.lua tests/safe_spec.lua
	@echo Done.

check: fmt lint
	@echo
	@echo All checks passed.

test:
	@echo Running tests...
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
	@echo Done.
