-- ============================================================================
-- TREESITTER (API moderne - Nouvelle version main)
-- ============================================================================

-- NOTE IMPORTANTE :
-- La nouvelle version de nvim-treesitter a supprimé 'ensure_installed'.
-- L'installation des parsers se fait désormais manuellement via la commande :
-- :TSInstall! c cpp lua rust javascript typescript html css json
-- (Le "!" est crucial sur Windows pour utiliser les binaires pré-compilés)

-- ============================================================================
-- ACTIVATION DU PARSING
-- ============================================================================

-- Démarre le parsing Treesitter pour le buffer actuel
vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

-- ============================================================================
-- FOLDING
-- ============================================================================

-- Folding basé sur Treesitter
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldenable = false

-- ============================================================================
-- INDENTATION
-- ============================================================================
-- vim.opt.indentexpr = 'v:lua.vim.treesitter.indent()'
