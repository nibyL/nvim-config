-- ============================================================================
-- FIX WINDOWS (À placer tout en haut)
-- ============================================================================
-- Redirige les fichiers temporaires vers un dossier sans espaces.
-- Indispensable pour que le compilateur C (MinGW/GCC) de Treesitter fonctionne
-- avec votre nom d'utilisateur "HP ELITE BOOK".
vim.env.TMP = 'C:\\Temp'
vim.env.TEMP = 'C:\\Temp'
vim.fn.mkdir('C:\\Temp', 'p')
-- Forcer l'utilisation de Clang pour Treesitter (MinGW échoue sur les .so)
vim.env.CC = 'C:/Program Files/LLVM/bin/clang.exe'

-- ============================================================================
-- LEADER KEY (Doit être défini AVANT les plugins)
-- ============================================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- ============================================================================
-- OPTIONS GÉNÉRALES
-- ============================================================================

vim.o.number = true
vim.o.relativenumber = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.list = true
vim.o.confirm = true
vim.o.updatetime = 300
vim.o.winborder = 'rounded'
vim.o.clipboard = 'unnamedplus'
vim.o.showmode = false
vim.o.background = 'dark'

vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.keymodel = 'startsel,stopsel'
vim.opt.selectmode = 'mouse,key'

-- ============================================================================
-- APPARENCE DE BASE (Fallback avant le chargement du thème)
-- ============================================================================

vim.api.nvim_set_hl(0, 'Normal', {
  bg = '#0f0f0f',
})

vim.api.nvim_set_hl(0, 'NormalFloat', {
  bg = '#000000',
})