-- ============================================================================
-- LAZY LOADING (Zéro dépendance)
-- ============================================================================
-- Permet de charger des plugins vim.pack uniquement sur un événement donné.
-- ============================================================================

local M = {}
local safe = require('utils.safe')

-- Table pour éviter d'appeler vim.pack.add plusieurs fois pour le même groupe
local loaded_groups = {}

--- Charge un plugin et rejoue la chaîne d'événements pour lui.
--- @param plugins string[] Liste des URLs de plugins à charger
--- @param event string L'événement qui a déclenché le chargement (ex: 'InsertEnter')
--- @return boolean success
function M.load_on_event(plugins, event)
  local group_key = table.concat(plugins, '|')

  -- Si déjà chargé avec succès, on ne fait rien
  if loaded_groups[group_key] then
    return true
  end

  -- 1. On installe/charge les plugins dans le runtimepath de manière sécurisée
  local ok, err = pcall(vim.pack.add, plugins, { confirm = false })

  if not ok then
    -- On utilise safe.call pour enregistrer l'échec proprement
    safe.call('lazyload:' .. event, function()
      error('Échec de vim.pack.add pour ' .. group_key .. ' : ' .. tostring(err))
    end)
    return false
  end

  loaded_groups[group_key] = true

  -- 2. On rejoue l'événement de manière ciblée pour que le plugin qui vient
  -- d'être chargé reçoive l'événement qu'il a "manqué" (FileType, BufRead, etc.)
  vim.schedule(function()
    -- On rejoue uniquement sur le buffer courant.
    -- Nvim interdit 'pattern' et 'buffer' en même temps.
    vim.api.nvim_exec_autocmds(event, {
      buffer = vim.api.nvim_get_current_buf(),
    })
  end)

  return true
end

--- Enregistre un déclencheur
--- @param event string
--- @param plugins string[]
function M.on(event, plugins)
  vim.api.nvim_create_autocmd(event, {
    once = true,
    callback = function()
      -- Si l'échec est dû au réseau, on ne "consomme" pas définitivement l'événement.
      -- On ré-enregistre l'autocmd pour qu'il retente au prochain déclenchement.
      local success = M.load_on_event(plugins, event)
      if not success then
        M.on(event, plugins)
      end
    end,
  })
end

return M
