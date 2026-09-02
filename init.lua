-- ============================================================================
-- Neovim 0.12+ - Configuration personnelle (Chef d'orchestre)
-- ============================================================================

-- 1. CORE (Options, Raccourcis, Autocmds, Statusline)
require('core.options')
require('core.keymaps')
require('core.autocmds')
require('core.statusline')

-- 2. PLUGINS (Installation et configuration visuelle)
require('plugins.init')
require('plugins.ui')       -- <-- C'est ici que dark2026 sera activé
require('plugins.diagnostics')
require('plugins.treesitter')
require('plugins.blink')

-- 3. LSP (Dépend de blink.cmp et des plugins)
require('lsp')

-- 4. OUTILS (Fonctions personnalisées)
require('tools.autosave')
require('tools.compiler')
require('tools.leap')

-- ============================================================================
-- FIN
-- ============================================================================

vim.notify('Configuration chargée avec succès ! 🚀', vim.log.levels.INFO)