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
-- SÉLECTEUR DE THÈME VISUEL (Espace + t + h)
-- ============================================================================

local state_file = vim.fn.stdpath('data') .. '/theme_state'

vim.keymap.set('n', '<leader>th', function()
    require('snacks').picker.colorschemes({
        confirm = function(picker, item)
            local theme = item.text

            picker:close()
            picker.preview.state.colorscheme = nil

            vim.schedule(function()
                vim.cmd.colorscheme(theme)
                vim.fn.writefile({ theme }, state_file)

                -- Notification de confirmation
                vim.notify('Thème appliqué : ' .. theme, vim.log.levels.INFO, { title = 'Thème' })
            end)
        end,
    })
end, { desc = 'Sélecteur de thème' })



-- ============================================================================
-- TERMINAL UNIQUE (Ouvre un terminal en bas, ferme TOUS les anciens)
-- ============================================================================
-- ============================================================================
-- TERMINAL SNACKS (Terminal flottant ultra-moderne)
-- ============================================================================
vim.keymap.set({ 'n', 't' }, '<leader>tt', function()
    require('snacks').terminal.toggle()
end, { desc = 'Terminal flottant (Toggle)' })


-- ============================================================================
-- GESTION DES DOSSIERS ET FICHIERS (Recherche, formatage,)
-- ============================================================================

--Recherche de dossiers dans l'historique des dossiers ouverts
vim.keymap.set('n', '<leader>fd', function()
    require('snacks').picker.recent({
        title = "Dossiers Récents",
        confirm = function(picker, item)
            picker:close()
            if item then vim.cmd('cd ' .. vim.fn.fnameescape(item.file)) end
        end,
        transform = function(item, ctx)
            item.file = vim.fn.fnamemodify(item.file, ":h")
            return require("snacks.picker.transform").unique_file(item, ctx)
        end,
    })
end, { desc = "Historique des dossiers" })


--Recherche de fichiers dans le projet courant et l'historique des fichiers ouverts
vim.keymap.set('n', '<leader>fo', function()
    require('snacks').picker('hybrid')
end, { desc = 'Fichiers (Projet + Historique)' })

-- Recherche de texte dans tout le projet (grep)
vim.keymap.set('n', '<leader>sg', function()
    require('snacks').picker.grep()
end, { desc = 'Chercher du texte dans le projet' })

-- Sélecteur de buffers ouverts (quand vous avez 10+ fichiers)
vim.keymap.set('n', '<leader>fb', function()
    require('snacks').picker.buffers()
end, { desc = 'Changer de buffer ouvert' })

-- Explorateur de fichiers latéral (pour voir l'arborescence)
vim.keymap.set('n', '<leader>e', function()
    local explorer = require('snacks').explorer
    if explorer.win and explorer.win:is_valid() then
        explorer.close()
    else
        explorer.open()
    end
end, { desc = 'Explorateur de fichiers (toggle)' })

-- Navigation ultra-rapide (une seule main, pas besoin de quitter la ligne de base)
vim.keymap.set('n', 'L', ':bnext<CR>', { desc = 'Buffer suivant' })
vim.keymap.set('n', 'H', ':bprevious<CR>', { desc = 'Buffer précédent' })

-- Formatage via LSP
vim.keymap.set('n', '<leader>fm', function()
    vim.lsp.buf.format({ async = true })
end, { desc = 'Formater le code' })

-- Recherche de fichiers dans tout le disque pour ouvrir un fichier pour la toute première fois dans néovim
vim.keymap.set('n', '<leader>fR', function()
    require('snacks').picker.files({
        -- Définir les dossiers racines à scanner simultanément
        dirs = { 'C:/', 'D:/' },
        -- Vos options de filtrage fd restent inchangées
        find_command = { 'fd', '-tf', '-E', '.git', '-E', 'node_modules', '-E', '*.exe', '-E', '*.dll' },
    })
end, { desc = 'Recherche C:/ et D:/' })


-- Fermer le buffer actuel (sans fermer Neovim)
vim.keymap.set('n', '<leader>q', ':bd<CR>', { desc = 'Fermer le buffer' })

-- ============================================================================
-- LAZYGIT (Interface Git visuelle)
-- ============================================================================
vim.keymap.set('n', '<leader>lg', function()
    require('snacks').lazygit()
end, { desc = 'Ouvrir Lazygit' })
