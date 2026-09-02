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
