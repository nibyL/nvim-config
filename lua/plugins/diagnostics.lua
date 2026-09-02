-- ============================================================================
-- DIAGNOSTICS
-- ============================================================================

-- ============================================================================
-- DIAGNOSTICS NATIFS DE NEOVIM
-- ============================================================================

vim.diagnostic.config({
  -- Les diagnostics seront affichés par tiny-inline-diagnostic
  virtual_text = false,

  -- Signes dans la colonne de gauche
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '●',
      [vim.diagnostic.severity.WARN] = '●',
      [vim.diagnostic.severity.INFO] = '●',
      [vim.diagnostic.severity.HINT] = '●',
    },
  },
})

-- ============================================================================
-- TINY INLINE DIAGNOSTIC
-- ============================================================================

require('tiny-inline-diagnostic').setup({
  options = {
    multilines = {
      enabled = true,
    },
  },

  preset = 'ghost',
})
