# Architecture

This configuration follows a **modular, criticality-tiered architecture**.

---

## Module loading order

`init.lua` loads modules in four tiers:

### Tier 1 — Core (required, fatal)
- `core.options` — Neovim options and environment setup
- `core.keymaps` — All keymaps
- `core.autocmds` — Autocommands
- `core.statusline` — Native statusline
- `core.on_demand` — Event-driven plugin loading

If any of these fails, Neovim **refuses to start** and writes the error to `stdpath('log')/startup.log`.

### Tier 2 — Plugins (warn)
- `plugins.init` — Plugin installation via `vim.pack`
- `plugins.ui` — UI plugins (Snacks, gitsigns, etc.)
- `plugins.diagnostics` — Diagnostic display
- `plugins.treesitter` — Syntax highlighting
- `plugins.blink` — Completion engine

If any fails, Neovim starts with a warning and records the error in `:checkhealth monprofil`.

### Tier 3 — LSP (required, fatal)
- `lsp` — LSP configuration (requires blink.cmp)

If this fails, Neovim refuses to start.

### Tier 4 — Tools (optional)
- `tools.autosave` — Autosave after inactivity
- `tools.compiler` — F5/F6 compilation
- `tools.leap` — Leap motion
- `tools.pandoc` — Markdown preview

If any fails, Neovim starts without that feature.

---

## Utils layer

`lua/utils/` provides reusable helpers:

| Module | Purpose |
|---|---|
| `safe` | Safe module loading with strict fail-fast contract |
| `notify` | Uniform notifications with 5s dedup window |
| `env` | Cross-platform environment detection |
| `health` | Custom `:checkhealth` implementation |
| `directory_history` | Persistent directory history |

---

## Strict fail-fast contract

`utils/safe.lua` exposes `safe.require(module, { mode = ... })` with three modes:

- **`fatal`**: if the module fails to load, Neovim prints a message, writes to `startup.log`, and exits via `cq`.
- **`warn`**: if the module fails, an error is logged and recorded, but Neovim continues.
- **`optional`**: if the module fails, a warning is logged and Neovim continues.

**Default** is `warn`. A required module must be explicitely marked `fatal`.

---

## Environment portability

`utils/env.lua` handles **all** cross-platform differences:
- Detects OS (Windows, Linux, macOS, WSL)
- Configures shell (`pwsh` on Windows, `$SHELL` elsewhere)
- Sets up temp directory (no spaces!)
- Detects `clang` for Treesitter
- Adds custom paths to `PATH`

**No other file should contain hardcoded OS-specific paths.**

---

## Compilation (F5 / F6)

`tools/compiler.lua` uses a **dual strategy**:

- **C / C++**: uses native `gcc` / `g++` if available, otherwise falls back to WSL. Compiled programs run via `cmd.exe /c` on Windows (to preserve interactivity), or directly in WSL.
- **ASM**: forced WSL (because `nasm -f elf64` is Linux-specific).
- **Python**: always native (Windows or Linux).

The terminal used is always the visible Snacks terminal (bottom split). If none exists, one is created.

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
- Centralizes all failure registries (`safe.get_failures()`, `safe.get_setup_failures()`)

### Why `C:\Temp\NvimTemp` instead of `$LOCALAPPDATA\Temp`?

The user path contains spaces (`HP ELITE BOOK`). Several plugins break when parsing
paths with spaces. `C:\Temp\NvimTemp` avoids this issue.

---

## Testing

The test suite (`tests/`) uses **plenary.nvim**:
- `minimal_init.lua` — Minimal init for tests (no plugins)
- `keymaps_spec.lua` — 13 keymap tests
- `autocmds_spec.lua` — 3 autocmd tests, 7 option tests, 5 utils tests
- `env_spec.lua` — 4 environment detection tests
- `safe_spec.lua` — 8 module loading tests

**Total: 40 tests.** CI runs them on Ubuntu, Windows, and macOS (Neovim nightly and v0.11.4).

Run with `make test`.
