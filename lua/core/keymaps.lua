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
vim.keymap.set('n', '<leader>tt', function()
    -- 1. Ouvre le nouveau terminal en bas
    vim.cmd('botright 15split | terminal')
    local new_term_win = vim.api.nvim_get_current_win()

    -- 2. Ferme TOUS les autres buffers de type terminal (même les cachés)
    local current_buf = vim.api.nvim_win_get_buf(new_term_win)

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= current_buf and vim.bo[buf].buftype == 'terminal' then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end

    -- 3. Entre en mode insertion
    vim.cmd('startinsert')
end, { desc = 'Terminal unique en bas' })


-- ============================================================================
-- GESTION DES FICHIERS (Recherche, formatage,)
-- ============================================================================

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


-- ============================================================================
-- LAZYGIT (Interface Git visuelle)
-- ============================================================================
vim.keymap.set('n', '<leader>lg', function()
    require('snacks').lazygit()
end, { desc = 'Ouvrir Lazygit' })
