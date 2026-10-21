-- ============================================================================
-- APERÇU MARKDOWN VIA PANDOC
-- ============================================================================
-- Génère un HTML standalone à partir du fichier Markdown courant, puis
-- l'ouvre dans le navigateur par défaut.
-- ============================================================================

local env = require('utils.env')

vim.keymap.set('n', '<leader>mp', function()
  local file = vim.fn.expand('%:p')
  local ext = vim.fn.expand('%:e'):lower()

  if ext ~= 'md' and ext ~= 'markdown' then
    vim.notify('Ce fichier n’est pas du Markdown', vim.log.levels.WARN, {
      title = 'Pandoc',
    })
    return
  end

  local output = vim.fn.expand('%:p:r') .. '.html'

  vim.fn.jobstart({
    'pandoc',
    file,
    '-o',
    output,
    '--standalone',
    '--embed-resources',
    '--highlight-style=tango',
  }, {
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify('Échec de la conversion Pandoc', vim.log.levels.ERROR, {
          title = 'Pandoc',
        })
        return
      end

      -- Ouverture via la commande spécifique à l'OS
      vim.fn.jobstart(vim.list_extend(env.get_explorer_cmd(), { output }), { detach = true })

      vim.notify(
        'Aperçu Pandoc généré : ' .. vim.fn.fnamemodify(output, ':t'),
        vim.log.levels.INFO,
        { title = 'Pandoc' }
      )
    end,
  })
end, { desc = 'Aperçu Markdown avec Pandoc' })
