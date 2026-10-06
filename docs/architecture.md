
# Architecture

This configuration follows a **modular, criticality-tiered architecture**.

---

## Module loading order

`init.lua` loads modules in three tiers:

### Tier 1 — Core (required)
- `core.options` — Neovim options and environment setup
- `core.keymaps` — All keymaps
- `core.autocmds` — Autocommands
- `core.statusline` — Native statusline

If any of these fails, Neovim still starts but shows an error.

### Tier 2 — Plugins (optional)
- `plugins.init` — Plugin installation via `vim.pack`
- `plugins.ui` — UI plugins (Snacks, gitsigns, etc.)
- `plugins.diagnostics` — Diagnostic display
- `plugins.treesitter` — Syntax highlighting
- `plugins.blink` — Completion engine

If any fails, Neovim starts and shows a warning.

### Tier 3 — LSP & Tools
- `lsp` — LSP configuration (requires blink.cmp)
- `tools.autosave` — Autosave after inactivity
- `tools.compiler` — F5/F6 compilation
- `tools.leap` — Leap motion

---

## Utils layer

`lua/utils/` provides reusable helpers:

| Module | Purpose |
|---|---|
| `safe` | Safe module loading with error handling |
| `notify` | Uniform notifications with prefix |
| `env` | Cross-platform environment detection |
| `health` | Custom `:checkhealth` implementation |
| `directory_history` | Persistent directory history |

---

## Environment portability

`utils/env.lua` handles **all** cross-platform differences:
- Detects OS (Windows, Linux, macOS, WSL)
- Configures shell (`pwsh`, `powershell`, `bash`)
- Sets up temp directory (no spaces!)
- Detects `clang` for Treesitter
- Adds custom paths to `PATH`

**No other file should contain hardcoded OS-specific paths.**

---

## Design decisions

### Why `vim.pack` instead of lazy.nvim?

Neovim 0.12+ ships with a native plugin manager (`vim.pack`). Using it means:
- Zero external dependencies for plugin management
- Less code to maintain
- Native performance

### Why native statusline instead of lualine?

- No plugin dependency
- Full control over styling
- Faster (no lua function calls per redraw)

### Why custom health check?

- Detects missing binaries specific to this config
- Checks Windows-specific paths (WindowsApps, LLVM)
- Documents the environment

### Why `C:\Temp\NvimTemp` instead of `$LOCALAPPDATA\Temp`?

The user path contains spaces (`HP ELITE BOOK`). Several plugins break when parsing
paths with spaces. `C:\Temp\NvimTemp` avoids this issue.

---

## Testing

The test suite (`tests/`) uses **plenary.nvim**:
- `minimal_init.lua` — Minimal init for tests (no plugins)
- `keymaps_spec.lua` — 13 keymap tests
- `autocmds_spec.lua` — 15 autocmd/options/utils tests

Run with `make test`.

---

