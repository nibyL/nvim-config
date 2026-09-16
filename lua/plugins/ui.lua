-- ============================================================================
-- UI & OUTILS
-- ============================================================================

-- ============================================================================
-- AUTOPAIRS
-- ============================================================================

require('nvim-autopairs').setup({})

-- ============================================================================
-- QUICKFIX / LOCATION LIST
-- ============================================================================

require('quicker').setup({})

-- ============================================================================
-- GITSIGNS
-- ============================================================================

require('gitsigns').setup({})

-- ============================================================================
-- SNACKS
-- ============================================================================

require("snacks").setup({
    terminal = {
        enabled = true,
        win = {
            keys = {
                term_normal = {
                    "<Esc>",
                    "<C-\\><C-n>",
                    mode = "t",
                    desc = "Quitter le mode terminal",
                },
            },
        },
    },


    picker = {
        enabled = true,
        hidden = true,  -- Affiche les fichiers cachés (.vscode, etc.)
        ignored = true, -- Affiche les fichiers du .gitignore (.venv, etc.)

        -- On supprime la variable de tableau dynamique d'ici
        sources = {
            hybrid = {
                name = "hybrid",
                title = "📂 Projet + 🌍 Historique Global",

                multi = {
                    {
                        source = "files",
                        cwd = function()
                            return vim.fs.root(0, ".git") or vim.fn.getcwd()
                        end,
                    },
                    {
                        source = "recent",
                    },
                },

                transform = function(item, ctx)
                    return require("snacks.picker.transform").unique_file(item, ctx)
                end,
            }
        },
    },
})



-- ============================================================================
-- SNACKS + :RESTART
-- ============================================================================

vim.api.nvim_create_autocmd("ExitPre", {
    desc = "Préparer Snacks avant :restart",
    callback = function()
        if not vim.v.exitreason:match("^restart") then return end

        local snacks = require("snacks")

        -- 1. GESTION DE L'EXPLORER : Enregistrer la présence du volet
        local exp = snacks.explorer
        vim.g.snacks_explorer_was_open = (exp.win and exp.win:is_valid()) or false

        if vim.g.snacks_explorer_was_open then
            local exp_buf = exp.win:get_buf()
            snacks.explorer.close()
            if vim.api.nvim_buf_is_valid(exp_buf) then
                pcall(vim.api.nvim_buf_delete, exp_buf, { force = true })
            end
        end

        -- 2. GESTION DES TERMINAUX : [VOTRE CODE STRICT POUR LES TERMINAUX]
        for _, term in ipairs(snacks.terminal.list()) do
            if term.augroup then
                for _, ac in ipairs(vim.api.nvim_get_autocmds({
                    group = term.augroup,
                    event = "ExitPre",
                })) do
                    pcall(vim.api.nvim_del_autocmd, ac.id)
                end
            end
        end
    end,
})


-- ============================================================================
-- THÈME PERSISTANT (Se souvient de votre choix après :restart)
-- ============================================================================

local state_file = vim.fn.stdpath('data') .. '/theme_state'
local my_theme = 'dark2026'

-- 1. Lire le thème sauvegardé (par défaut : dark2026)
local saved_theme = my_theme
if vim.fn.filereadable(state_file) == 1 then
    saved_theme = vim.fn.readfile(state_file)[1]
end

-- 2. Appliquer le thème au démarrage
local ok = pcall(vim.cmd.colorscheme, saved_theme)
if not ok then
    vim.cmd.colorscheme('habamax')
    vim.notify('Thème ' .. saved_theme .. ' introuvable, fallback habamax', vim.log.levels.WARN)
end



-- ============================================================================
-- MARKDOWN PREVIEW (Rendu Navigateur)
-- ============================================================================
-- Force Neovim à compiler le serveur interne du plugin s'il n'existe pas
if vim.fn.exists('*mkdp#util#install') == 1 then
  vim.fn['mkdp#util#install']()
end

-- Options de confort
vim.g.mkdp_auto_start = 0    -- 0 = Ne lance pas le navigateur tout seul à l'ouverture du fichier
vim.g.mkdp_auto_close = 1    -- 1 = Ferme l'onglet du navigateur automatiquement quand vous quittez Neovim
vim.g.mkdp_refresh_slow = 0  -- 0 = Rafraîchissement ultra-rapide au fil de la frappe
vim.g.mkdp_echo_preview_url = 1
