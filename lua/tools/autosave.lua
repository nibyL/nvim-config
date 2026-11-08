-- ============================================================================
-- SAUVEGARDE AUTOMATIQUE
-- ============================================================================

local autosave_group = vim.api.nvim_create_augroup('AutosaveGroup', { clear = true })

local save_timers = {}

-- ============================================================================
-- SAUVEGARDE SÉCURISÉE D'UN BUFFER
-- ============================================================================

local function safe_save(buf)
  -- Le buffer existe-t-il encore ?
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Le buffer est-il réellement modifié ?
  if not vim.bo[buf].modified then
    return
  end

  -- Ignorer les buffers spéciaux (terminal, quickfix, etc.)
  if vim.bo[buf].buftype ~= '' then
    return
  end

  -- Récupérer le nom du fichier
  local filename = vim.api.nvim_buf_get_name(buf)

  if filename == '' then
    return
  end

  -- Vérifier que le dossier existe
  local dir = vim.fn.fnamemodify(filename, ':h')

  if vim.fn.isdirectory(dir) ~= 1 then
    return
  end

  -- Sauvegarder dans le contexte du bon buffer
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('silent! update')
  end)
end

-- ============================================================================
-- SAUVEGARDE APRÈS 1 SECONDE D'INACTIVITÉ
-- ============================================================================

vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
  group = autosave_group,
  desc = 'Sauvegarde automatique après inactivité',

  callback = function()
    local buf = vim.api.nvim_get_current_buf()

    -- Annuler le timer précédent pour ce buffer
    if save_timers[buf] then
      save_timers[buf]:stop()
      save_timers[buf] = nil
    end

    -- Nouveau timer de 1 seconde
    save_timers[buf] = vim.defer_fn(function()
      safe_save(buf)
      save_timers[buf] = nil
    end, 1000)
  end,
})

-- ============================================================================
-- SAUVEGARDE À LA PERTE DE FOCUS
-- ============================================================================

vim.api.nvim_create_autocmd('FocusLost', {
  group = autosave_group,
  desc = 'Sauvegarde à la perte de focus',

  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      safe_save(buf)
    end
  end,
})

-- ============================================================================
-- NETTOYAGE DES TIMERS À LA FERMETURE D'UN BUFFER
-- ============================================================================

vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
  group = autosave_group,
  desc = 'Nettoyage des timers à la fermeture du buffer',
  callback = function(args)
    local buf = args.buf
    if save_timers[buf] then
      save_timers[buf]:stop()
      save_timers[buf] = nil
    end
  end,
})

vim.api.nvim_create_autocmd('VimLeavePre', {
  group = autosave_group,
  desc = 'Nettoyage des timers',

  callback = function()
    for buf, timer in pairs(save_timers) do
      if timer then
        timer:stop()
      end

      save_timers[buf] = nil
    end
  end,
})
