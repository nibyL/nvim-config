-- ============================================================================
-- CHARGEMENT SÉCURISÉ DE MODULES
-- ============================================================================

local M = {}
local notify = require('utils.notify')

--- Charge un module avec gestion d'erreur.
--- @param module_name string
--- @param opts? { optional?: boolean }
--- @return table|nil
function M.require(module_name, opts)
  opts = opts or {}
  local ok, result = pcall(require, module_name)

  if not ok then
    local emitter = opts.optional and notify.warn or notify.error
    emitter('Module introuvable : ' .. module_name .. '\n' .. tostring(result))
    return nil
  end

  return result
end

--- Exécute une fonction en sécurité.
--- @param fn function
--- @param context? string
--- @return boolean
function M.call(fn, context)
  local ok, err = pcall(fn)
  if not ok then
    notify.error('Erreur dans ' .. (context or 'inconnu') .. ' :\n' .. tostring(err))
    return false
  end
  return true
end

return M
