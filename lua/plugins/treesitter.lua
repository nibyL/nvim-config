-- ============================================================================
-- TREESITTER (API moderne 2025+)
-- ============================================================================

-- 1. Liste des parsers souhaités. 
-- Note : Pour les installer, ouvrez Neovim et tapez une seule fois :
-- :TSInstall! c cpp lua rust javascript typescript html css json
-- (Le "!" force l'utilisation des binaires pré-compilés, évitant les erreurs de compilation Windows)
local parsers_ensure = {
  'c', 'cpp', 'lua', 'rust',
  'javascript', 'typescript',
  'html', 'css', 'json',
}

-- Cette commande s'assure qu'ils sont présents sans bloquer le démarrage
require('nvim-treesitter.install').ensure_installed(parsers_ensure)

-- 2. Activation du highlighting et de l'indentation pour tous les fichiers
vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    -- Démarre le parsing Treesitter pour le buffer actuel
    pcall(vim.treesitter.start)
  end,
})

-- 3. Folding basé sur Treesitter
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldenable = false

-- 4. Indentation intelligente via Treesitter
vim.opt.indentexpr = 'v:lua.vim.treesitter.indent()'