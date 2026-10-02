-- ============================================================================
-- MINIMAL INIT FOR TESTS
-- ============================================================================
-- Charge uniquement ce qui est nécessaire pour les tests.
-- ============================================================================

-- Ajoute le dossier courant au runtimepath
vim.opt.rtp:prepend('.')

-- Ajoute plenary pour les helpers de test
vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/site/pack/test/start/plenary.nvim')

-- Charge les modules de config
require('core.options')
require('core.keymaps')
require('core.autocmds')

-- Charge les modules tools (définissent F5/F6 et s/S)
require('tools.autosave')
require('tools.compiler')
require('tools.leap')
