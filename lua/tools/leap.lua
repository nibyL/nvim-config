-- ============================================================================
-- LEAP
-- ============================================================================

-- Force le gestionnaire natif à charger le plugin avant de l'appeler
vim.cmd('packadd leap.nvim')

local leap = require('leap')

-- ============================================================================
-- SAUT DANS LA FENÊTRE COURANTE
-- ============================================================================

vim.keymap.set(
  { 'n', 'x', 'o' },
  's',
  function()
    leap.leap({})
  end,
  {
    desc = 'Leap dans la fenêtre actuelle',
  }
)

-- ============================================================================
-- SAUT VERS TOUTES LES FENÊTRES ACCESSIBLES
-- ============================================================================

vim.keymap.set(
  'n',
  'S',
  function()
    -- Utilise la nouvelle méthode officielle recommandée pour cibler d'autres fenêtres
    leap.leap({
      target_windows = vim.api.nvim_tabpage_list_wins(0),
    })
  end,
  {
    desc = 'Leap vers une autre fenêtre',
  }
)
