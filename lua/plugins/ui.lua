-- ============================================================================
-- UI & OUTILS (Deferred Setup)
-- ============================================================================

return function()
  vim.schedule(function()
    -- Autopairs
    local ok_ap, autopairs = pcall(require, 'nvim-autopairs')
    if ok_ap then
      autopairs.setup({})
    end

    -- Quicker
    local ok_q, quicker = pcall(require, 'quicker')
    if ok_q then
      quicker.setup({})
    end

    -- Gitsigns
    local ok_gs, gitsigns = pcall(require, 'gitsigns')
    if ok_gs then
      gitsigns.setup({})
    end

    -- Snacks
    local ok_snacks, snacks = pcall(require, 'snacks')
    if ok_snacks then
      snacks.setup({
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
    end

    -- Thème persistant
    local state_file = vim.fn.stdpath('data') .. '/theme_state'
    local my_theme = 'dark2026'
    local saved_theme = my_theme
    if vim.fn.filereadable(state_file) == 1 then
      local ok, lines = pcall(vim.fn.readfile, state_file)
      if ok and lines and lines[1] and lines[1] ~= '' then
        saved_theme = lines[1]
      end
    end

    local ok_theme, err_theme = pcall(vim.cmd.colorscheme, saved_theme)
    if not ok_theme then
      pcall(vim.cmd.colorscheme, 'habamax')
    end
  end)
end
