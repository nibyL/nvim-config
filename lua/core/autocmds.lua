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
    if not vim.bo[args.buf].modifiable then
      return
    end

    -- On force la détection si le filetype est vide OU s'il est 'conf' (souvent par défaut sur Windows)
    local current_ft = vim.bo[args.buf].filetype
    if current_ft == '' or current_ft == 'conf' then
      -- On tente de détecter par le nom/extension du fichier
      local ft =
        vim.filetype.match({ buf = args.buf, filename = vim.api.nvim_buf_get_name(args.buf) })
      if ft then
        vim.bo[args.buf].filetype = ft
      end
    end
  end,
})
