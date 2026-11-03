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

vim.opt.foldenable = false

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Activer le folding Treesitter uniquement si un parser est dispo',
  callback = function(args)
    -- pcall(vim.treesitter.get_parser, buf) renvoie true si un parser existe
    local ok, _ = pcall(vim.treesitter.get_parser, args.buf)
    if ok then
      vim.opt_local.foldmethod = 'expr'
      vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    else
      vim.opt_local.foldmethod = 'manual'
    end
  end,
})

-- ============================================================================
-- INDENTATION
-- ============================================================================
-- vim.opt.indentexpr = 'v:lua.vim.treesitter.indent()'
