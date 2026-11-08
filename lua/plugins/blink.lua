-- ============================================================================
-- BLINK.CMP (Deferred Setup)
-- ============================================================================
-- Ne fait plus de require au chargement. Attend que le plugin soit dispo.

return function()
  -- vim.schedule repousse l'exécution après que le runtimepath ait été mis à jour
  vim.schedule(function()
    local ok, blink = pcall(require, 'blink.cmp')
    if not ok then
      -- Le plugin n'est pas encore téléchargé (première installation)
      -- On laisse safe.require gérer l'erreur silencieusement
      return
    end

    -- Construction du moteur fuzzy (asynchrone)
    if not blink.library_available() then
      vim.notify(
        'Blink.cmp : compilation du moteur Rust en arrière-plan...',
        vim.log.levels.INFO,
        { title = 'Blink' }
      )
      -- On lance le build sans bloquer Neovim
      -- (blink.build() retourne un objet avec :wait() bloquant,
      -- mais sans :wait() il lance le job en tâche de fond)
      blink.build({ notify = false })
    end

    blink.setup({
      keymap = {
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<Esc>'] = { 'cancel', 'fallback' },
        ['<C-Space>'] = { 'show', 'show_documentation', 'hide' },
      },
      completion = {
        accept = {
          auto_brackets = { enabled = true },
        },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      fuzzy = {
        implementation = 'rust',
      },
    })

    -- NOUVEAU : Force l'ouverture du menu si on est déjà en mode insertion
    -- (utile si blink vient de se charger alors qu'on tapait déjà)
    vim.api.nvim_create_autocmd('InsertEnter', {
      callback = function()
        vim.schedule(function()
          if blink.is_enabled() then
            blink.show()
          end
        end)
      end,
    })

    -- On prévient le reste de la config que blink est prêt
    vim.schedule(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'BlinkCmpLoaded' })
    end)
  end)
end
