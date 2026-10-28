-- ============================================================================
-- GESTION DES PLUGINS (Lazy Loading)
-- ============================================================================

local lazyload = require('core.lazyload')
local safe = require('utils.safe')

-- Plugin natif de Neovim
vim.cmd('packadd! nohlsearch')

-- ============================================================================
-- FONCTION DE SÉCURISATION DE L'INSTALLATION
-- ============================================================================
local function pack_add_safe(plugins, label)
  local ok, err = pcall(vim.pack.add, plugins, { confirm = false })
  if not ok then
    safe.call('plugins.init:' .. label, function()
      error('Échec de l\'installation du groupe "' .. label .. '" : ' .. tostring(err))
    end)
  end
  return ok
end

-- ============================================================================
-- 1. CHARGEMENT IMMÉDIAT (Nécessaires pour l'UI de base)
-- ============================================================================
pack_add_safe({
  'https://github.com/folke/snacks.nvim',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/D0nw0r/dark2026.nvim',
  'https://github.com/Mofiqul/dracula.nvim',
  'https://github.com/folke/tokyonight.nvim',
  'https://github.com/Mofiqul/vscode.nvim',
}, 'core_ui')

-- ============================================================================
-- 2. CHARGEMENT PAR ÉVÉNEMENT
-- ============================================================================

-- Complétion : uniquement quand on tape du texte
lazyload.on('BufReadPost', {
  'https://github.com/saghen/blink.lib',
  'https://github.com/saghen/blink.cmp',
})

-- Git : uniquement quand on ouvre un fichier (ou revient sur un buffer)
lazyload.on('BufReadPost', {
  'https://github.com/lewis6991/gitsigns.nvim',
})

-- Diagnostics UI : uniquement quand un fichier est ouvert
lazyload.on('BufEnter', {
  'https://github.com/rachartier/tiny-inline-diagnostic.nvim',
  'https://github.com/stevearc/quicker.nvim',
})

-- Autopairs : uniquement en insertion
lazyload.on('InsertEnter', {
  'https://github.com/windwp/nvim-autopairs',
})

-- Leap : on le laisse immédiat (ou on pourrait le mettre sur des touches)
vim.pack.add({ 'https://codeberg.org/andyg/leap.nvim' }, { confirm = false })

-- LSP Config (nécessaire pour l'autocomplétion LSP)
vim.pack.add({ 'https://github.com/neovim/nvim-lspconfig' }, { confirm = false })
