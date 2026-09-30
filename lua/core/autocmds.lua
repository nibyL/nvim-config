-- ============================================================================
-- AUTOCOMMANDES GÉNÉRALES
-- ============================================================================

-- ============================================================================
-- SURLIGNAGE APRÈS UN YANK
-- ============================================================================

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Surligner temporairement le texte copié',
  callback = function()
    vim.hl.on_yank()
  end,
})

-- ============================================================================
-- DÉTECTION DU FILETYPE POUR LES NOUVEAUX FICHIERS
-- ============================================================================

vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'Détecter le filetype des nouveaux fichiers',
  callback = function(args)
    -- Sécurité : Ignorer les buffers non modifiables (comme Snacks explorer, terminaux, etc.)
    if not vim.bo[args.buf].modifiable then
      return
    end

    -- Si le fichier n'a pas encore de filetype, on tente de le détecter
    if vim.bo[args.buf].filetype == '' then
      local ft = vim.filetype.match({ buf = args.buf })
      if ft then
        vim.bo[args.buf].filetype = ft
      end
    end
  end,
})
