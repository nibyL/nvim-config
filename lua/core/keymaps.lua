-- ============================================================================
-- RACCOURCIS GÉNÉRAUX
-- ============================================================================

-- ============================================================================
-- TERMINAL
-- ============================================================================

-- Échap pour quitter le mode Terminal
vim.keymap.set(
  't',
  '<Esc>',
  '<C-\\><C-n>',
  { desc = 'Quitter le mode terminal' }
)

-- ============================================================================
-- NAVIGATION ENTRE LES FENÊTRES
-- ============================================================================

for _, dir in ipairs({ 'h', 'j', 'k', 'l' }) do

  -- Mode Normal
  vim.keymap.set(
    'n',
    '<A-' .. dir .. '>',
    '<C-w>' .. dir,
    { desc = 'Fenêtre ' .. dir }
  )

  -- Mode Insertion
  vim.keymap.set(
    'i',
    '<A-' .. dir .. '>',
    '<C-o><C-w>' .. dir,
    { desc = 'Fenêtre ' .. dir }
  )

  -- Mode Terminal
  vim.keymap.set(
    't',
    '<A-' .. dir .. '>',
    '<C-\\><C-n><C-w>' .. dir,
    { desc = 'Fenêtre ' .. dir }
  )
end


-- ============================================================================
-- BASCULEMENT DE THÈME (TOGGLE PERSISTANT)
-- ============================================================================

local state_file = vim.fn.stdpath('data') .. '/theme_state'
local my_theme = 'dark2026'

vim.keymap.set('n', '<leader>tt', function()
  -- Déterminer le prochain thème
  local current = vim.g.colors_name
  local next_theme = (current == my_theme) and 'default' or my_theme

  -- Appliquer le thème
  pcall(vim.cmd.colorscheme, next_theme)

  -- LA MAGIE : Sauvegarder le choix sur le disque dur
  vim.fn.writefile({ next_theme }, state_file)

  vim.notify('Thème changé pour : ' .. next_theme, vim.log.levels.INFO)
end, { desc = 'Basculer le thème (Persistant)' })
