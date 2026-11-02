# Neovim Config

Personal Neovim configuration optimized for **Windows + WSL** with focus on:
- **Modular architecture** (core, plugins, tools, utils)
- **Cross-platform portability** (Windows / Linux / macOS / WSL)
- **Native Neovim 0.12+ APIs** (no wrapper plugin)
- **Strict fail-fast contract** (missing core modules crash explicitly, not silently)
- **Quality tooling** (stylua, luacheck, plenary tests)

---

## Requirements

| Tool | Required | Install |
|---|---|---|
| **Neovim** ≥ 0.12 | ✅ | `choco install neovim` |
| **Git** | ✅ | `choco install git` |
| **ripgrep** | ✅ | `choco install ripgrep` |
| **fd** | ✅ | `choco install fd` |
| **make** | ✅ | `winget install GnuWin32.Make` |
| **stylua** | ✅ | `choco install stylua` |
| **LLVM (clang)** | 🟡 | `choco install llvm` |
| **PowerShell 7** | 🟡 | `choco install powershell-core` |
| **WSL** | 🟡 | `wsl --install` |
| **Pandoc** | 🟡 | `choco install pandoc` |
| **LazyGit** | 🟡 | `choco install lazygit` |
| **GCC / G++** | 🟡 | *Via WSL ou MinGW* |

---

## Installation

### 1. Backup your existing config

```powershell
Move-Item $env:LOCALAPPDATA\nvim $env:LOCALAPPDATA\nvim.bak
```

### 2. Clone this repository

```powershell
git clone https://github.com/nibyL/nvim-config $env:LOCALAPPDATA\nvim
```

### 3. Launch Neovim

```powershell
nvim
```

Wait for plugin installation prompts, answer `Y` (Yes).

### 4. Verify environment

In Neovim:

```
:CheckConfig
```

This opens the health check showing what's installed and what's missing. If a **core module** fails to load, Neovim will explicitly refuse to start and write to `stdpath('log')/startup.log`.

### 5. Install Treesitter parsers

```
:TSInstall! c cpp lua rust javascript typescript html css json markdown
```

The `!` is important on Windows (uses pre-built binaries).

---

## Structure

```
lua/
├── core/           Options, keymaps, autocmds, statusline
├── plugins/        Plugin configuration (snacks, blink, etc.)
├── lsp/            LSP servers configuration
├── tools/          Custom tools (compiler, autosave, leap, pandoc)
├── utils/          Reusable helpers (env, notify, safe, health)
└── monprofil/      Health check entry point

tests/              Plenary test suite (40 tests)
docs/               Additional documentation
```

For more details, see [docs/architecture.md](docs/architecture.md).

---

## Key Features

- **`<leader>tt`** — Floating terminal (Snacks, PowerShell 7)
- **`<leader>ff`** — Fuzzy file picker (project + history)
- **`<leader>sg`** — Live grep in project
- **`<leader>fD`** — Browse all disk roots (C:, D:, etc.)
- **`<leader>th`** — Theme selector (dark2026, tokyonight, etc.)
- **`<leader>lg`** — LazyGit integration
- **`<leader>mp`** — Markdown preview via Pandoc
- **`F5` / `F6`** — Compile & run (C/C++/ASM/Python)
  - *C/C++:* Native `gcc`/`g++` if available, fallback to WSL.
  - *ASM:* Forced WSL for `nasm -f elf64` compatibility.
  - *Python:* Native Windows Python.
- **`s` / `S`** — Leap motion (fast navigation)
- **`Alt+h/j/k/l`** — Window navigation (normal, insert, terminal)

For the full list, see [docs/keymaps.md](docs/keymaps.md).

---

## Development

```powershell
make help    # Show available targets
make fmt     # Format Lua files with stylua
make lint    # Lint Lua files with luacheck
make test    # Run plenary test suite
make check   # Run fmt + lint
```

### Test suite

The configuration ships with a **plenary test suite** verifying:
- Keymaps exist (13 tests)
- Autocmds registered (3 tests)
- Options configured (7 tests)
- Utils modules load (5 tests)
- Environment detection (4 tests)
- Safe module loader (8 tests)

Total: **40 tests**. CI runs them on Ubuntu, Windows, and macOS (Neovim nightly and v0.11.4).

---

## License

MIT — see [LICENSE](LICENSE).

---

## Acknowledgements

Built with:
- [snacks.nvim](https://github.com/folke/snacks.nvim) — UI toolkit
- [blink.cmp](https://github.com/saghen/blink.cmp) — Completion
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) — Syntax
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) — LSP
