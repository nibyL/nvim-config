-- ============================================================================
-- MINIMAL INIT FOR TESTS
-- ============================================================================

vim.opt.rtp:prepend('.')
vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/site/pack/test/start/plenary.nvim')

-- Charge les modules de config (core uniquement)
require('core.options')
require('core.keymaps')
require('core.autocmds')

-- Charge les tools qui NE dépendent PAS de plugins externes
require('tools.autosave')
require('tools.compiler')

-- NOTE: tools.leap est chargé uniquement si leap.nvim est installé
if vim.fn.isdirectory(vim.fn.stdpath('data') .. '/site/pack/core/opt/leap.nvim') == 1 then
  require('tools.leap')
end
