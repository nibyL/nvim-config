-- ============================================================================
-- DIAGNOSTICS (Deferred Setup)
-- ============================================================================

return function()
  vim.schedule(function()
    local ok, tid = pcall(require, 'tiny-inline-diagnostic')
    if not ok then
      return
    end

    -- Configuration native de Neovim (toujours dispo)
    vim.diagnostic.config({
      virtual_text = false,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = '●',
          [vim.diagnostic.severity.WARN] = '●',
          [vim.diagnostic.severity.INFO] = '●',
          [vim.diagnostic.severity.HINT] = '●',
        },
      },
    })

    -- Configuration du plugin
    tid.setup({
      options = {
        multilines = { enabled = true },
      },
      preset = 'ghost',
    })
  end)
end
