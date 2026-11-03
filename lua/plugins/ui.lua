-- ============================================================================
-- UI & OUTILS (Deferred Setup)
-- ============================================================================

return function()
  vim.schedule(function()
    local safe = require('utils.safe')

    -- Autopairs (chargé à la demande par le lazy loader)
    vim.api.nvim_create_autocmd('InsertEnter', {
      once = true,
      callback = function()
        safe.call('plugins.ui:autopairs', function()
          require('nvim-autopairs').setup({})
        end)
      end,
      desc = 'Setup nvim-autopairs après son chargement',
    })

    -- Quicker
    safe.call('plugins.ui:quicker', function()
      require('quicker').setup({})
    end)

    -- Gitsigns
    safe.call('plugins.ui:gitsigns', function()
      require('gitsigns').setup({})
    end)

    -- Snacks
    safe.call('plugins.ui:snacks', function()
      require('snacks').setup({
        terminal = {
          enabled = true,
          cmd = 'pwsh',
          win = {
            keys = {
              term_normal = {
                '<Esc>',
                '<C-\\><C-n>',
                mode = 't',
                desc = 'Quitter le mode terminal',
              },
            },
          },
        },
        picker = {
          enabled = true,
          hidden = true,
          ignored = true,
        },
      })
    end)

    -- Thème persistant (dans son propre safe.call pour ne pas bloquer si ça échoue)
    safe.call('plugins.ui:colorscheme', function()
      local state_file = vim.fn.stdpath('data') .. '/theme_state'
      local my_theme = 'dark2026'
      local saved_theme = my_theme

      if vim.fn.filereadable(state_file) == 1 then
        local ok, lines = pcall(vim.fn.readfile, state_file)
        if ok and lines and lines[1] and lines[1] ~= '' then
          saved_theme = lines[1]
        end
      end

      local ok_theme = pcall(vim.cmd.colorscheme, saved_theme)
      if not ok_theme then
        pcall(vim.cmd.colorscheme, 'habamax')
      end
    end)
  end)
end
