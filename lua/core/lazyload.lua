-- ============================================================================
-- LAZY LOADING (Zéro dépendance)
-- ============================================================================
-- Permet de charger des plugins vim.pack uniquement sur un événement donné.
-- ============================================================================

local M = {}

--- Charge un plugin et rejoue la chaîne d'événements pour lui.
--- @param plugins string[] Liste des URLs de plugins à charger
--- @param event string L'événement qui a déclenché le chargement (ex: 'InsertEnter')
function M.load_on_event(plugins, event)
    -- 1. On installe/charge les plugins dans le runtimepath
    vim.pack.add(plugins, { confirm = false })

    -- 2. On rejoue l'événement pour que le plugin qui vient d'être chargé
    -- reçoive l'événement qu'il a "manqué" (très important pour FileType, BufRead, etc.)
    vim.schedule(function()
        vim.api.nvim_exec_autocmds(event, { pattern = '*' })
    end)
end

--- Enregistre un déclencheur (très simplifié pour notre usage)
--- @param event string
--- @param plugins string[]
function M.on(event, plugins)
    vim.api.nvim_create_autocmd(event, {
        once = true,
        callback = function()
            M.load_on_event(plugins, event)
        end,
    })
end

return M
