-- ============================================================================
-- FIX WINDOWS (À placer tout en haut)
-- ============================================================================
-- 1. On utilise des antislashs stricts pour Windows (essentiel pour pwsh)
vim.env.TMP = 'C:\\Temp\\NvimTemp'
vim.env.TEMP = 'C:\\Temp\\NvimTemp'

-- 2. CRUCIAL : On crée manuellement TOUT le chemin, y compris le sous-dossier '\nvim' 
-- pour empêcher Neovim et pwsh de s'emmêler les pinceaux au démarrage.
vim.fn.mkdir('C:\\Temp\\NvimTemp', 'p')
vim.fn.mkdir('C:\\Temp\\NvimTemp\\nvim', 'p')

-- Forcer l'utilisation de Clang pour Treesitter
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
vim.o.autoindent = true
vim.o.smartindent = true
vim.opt.keymodel = 'startsel,stopsel'
vim.opt.selectmode = 'mouse,key'

-- ============================================================================
-- APPARENCE DE BASE (Force le fond coloré même sans thème)
-- ============================================================================

-- 1. Définition des couleurs de fallback (Variables pour modification facile)
local fallback_bg_main = '#121212'
local fallback_bg_float = '#040202'

-- 2. Active le support des couleurs 24-bit (indispensable pour les hexadécimaux)
vim.o.termguicolors = true

-- 3. Force les couleurs de fond au démarrage (pour éviter le flash)
vim.api.nvim_set_hl(0, 'Normal', { bg = fallback_bg_main })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = fallback_bg_float })

-- 4. LA MAGIE : Réapplique ces couleurs si le thème par défaut essaie de les rendre transparentes
vim.api.nvim_create_autocmd('ColorScheme', {
    desc = 'Forcer le fond coloré même avec le thème par défaut',
    callback = function()
        -- On vérifie si aucun thème personnalisé n'est chargé
        if vim.g.colors_name == nil or vim.g.colors_name == 'default' then
            vim.api.nvim_set_hl(0, 'Normal', { bg = fallback_bg_main })
            vim.api.nvim_set_hl(0, 'NormalFloat', { bg = fallback_bg_float })
        end
    end,
})


-- ============================================================================
-- SHELL (PowerShell au lieu de CMD)
-- ============================================================================

-- 'pwsh' pour PowerShell 7+ (recommandé, plus rapide et moderne)
-- 'powershell' pour Windows PowerShell 5.1 (inclus par défaut dans Windows 10/11)
vim.o.shell = 'pwsh'

-- Arguments pour un démarrage propre et rapide de PowerShell
vim.o.shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command'


-- ============================================================================
-- AJOUTER CHOCOLATEY AU PATH (pour ripgrep et autres outils)
-- ============================================================================
local choco_path = 'C:\\ProgramData\\chocolatey\\bin'
if vim.fn.isdirectory(choco_path) == 1 then
    vim.env.PATH = choco_path .. ';' .. vim.env.PATH
end
