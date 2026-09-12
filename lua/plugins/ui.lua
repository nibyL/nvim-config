-- ============================================================================
-- UI & OUTILS
-- ============================================================================

-- ============================================================================
-- AUTOPAIRS
-- ============================================================================

require('nvim-autopairs').setup({})

-- ============================================================================
-- QUICKFIX / LOCATION LIST
-- ============================================================================

require('quicker').setup({})

-- ============================================================================
-- GITSIGNS
-- ============================================================================

require('gitsigns').setup({})

-- ============================================================================
-- SNACKS
-- ============================================================================
require("snacks").setup({
  picker = {
    enabled = true,
    -- Configure l'explorateur et les fenêtres de recherche pour TOUT afficher par défaut
    win = {
      input = {
        keys = {
          -- Ces options forcent la visibilité dès l'ouverture
          ["<a-i>"] = { "toggle_ignored", mode = { "n", "i" } },
          ["<a-h>"] = { "toggle_hidden", mode = { "n", "i" } },
        },
      },
    },
    -- Configuration par défaut pour les recherches et l'explorateur
    hidden = true,   -- <-- Affiche les fichiers commençant par un point (.vscode)
    ignored = true,  -- <-- Affiche les fichiers exclus par le .gitignore (.venv)
    sources = {
      hybrid = {
        name = "hybrid",
        title = "📂 Projet + 🌍 Historique Global",
        multi = { "files", "recent" },
        transform = function(item, ctx)
          return require("snacks.picker.transform").unique_file(item, ctx)
        end,
      }
    },
  },
})


-- ============================================================================
-- THÈME PERSISTANT (Se souvient de votre choix après :restart)
-- ============================================================================

local state_file = vim.fn.stdpath('data') .. '/theme_state'
local my_theme = 'dark2026'

-- 1. Lire le thème sauvegardé (par défaut : dark2026)
local saved_theme = my_theme
if vim.fn.filereadable(state_file) == 1 then
  saved_theme = vim.fn.readfile(state_file)[1]
end

-- 2. Appliquer le thème au démarrage
local ok = pcall(vim.cmd.colorscheme, saved_theme)
if not ok then
  vim.cmd.colorscheme('habamax')
  vim.notify('Thème ' .. saved_theme .. ' introuvable, fallback habamax', vim.log.levels.WARN)
end
