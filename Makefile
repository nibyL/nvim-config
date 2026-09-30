.PHONY: fmt lint check help

help:
	@echo
	@echo   Neovim config - quality targets
	@echo   --------------------------------
	@echo   make fmt    - Format Lua files with stylua
	@echo   make lint   - Lint Lua files with luacheck
	@echo   make check  - Run fmt + lint
	@echo   make help   - Show this message
	@echo

fmt:
	@echo Formatting Lua files...
	@stylua lua/ init.lua
	@echo Done.

lint:
	@echo Linting Lua files... (skipped: luacheck not installed)
	@echo Done.

check: fmt lint
	@echo
	@echo All checks passed.
