-- ============================================================================
-- CHARGEMENT SÉCURISÉ DE MODULES
-- ============================================================================
-- Enregistre chaque échec dans un registre module-level (pas vim.g, qui
-- ne préserve pas les tables imbriquées). utils.health consomme ce registre
-- via M.get_failures().
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- REGISTRE MODULE-LEVEL
-- ----------------------------------------------------------------------------
-- Conservé en closure Lua (pas exposé à Vimscript).
-- Format : { [module_name] = { error, optional, timestamp } }
-- ----------------------------------------------------------------------------
local failures = {}

local function record_failure(name, err, optional)
  if failures[name] then
    return
  end -- idempotent

  failures[name] = {
    error = tostring(err),
    optional = optional,
    timestamp = os.time(),
  }
end

-- ----------------------------------------------------------------------------
-- NOTIFICATION (avec repli si utils.notify indisponible)
-- ----------------------------------------------------------------------------
local function emit(msg, level, optional)
  if #vim.api.nvim_list_uis() == 0 then
    return
  end

  local ok, notify = pcall(require, 'utils.notify')
  if ok and notify then
    if optional then
      notify.warn(msg, 'Chargement')
    else
      notify.error(msg, 'Chargement')
    end
  else
    vim.notify(msg, level, { title = 'Chargement' })
  end
end

-- ----------------------------------------------------------------------------
-- API PUBLIQUE
-- ----------------------------------------------------------------------------

--- Charge un module avec gestion d'erreur et enregistrement.
--- @param module_name string
--- @param opts? { optional?: boolean }
--- @return table|nil
function M.require(module_name, opts)
  opts = opts or {}
  local optional = opts.optional == true

  local ok, result = pcall(require, module_name)

  if not ok then
    record_failure(module_name, result, optional)

    local label = optional and 'Module optionnel indisponible' or 'Module requis introuvable'
    emit(
      string.format('%s : %s\n%s', label, module_name, tostring(result)),
      optional and vim.log.levels.WARN or vim.log.levels.ERROR,
      optional
    )
    return nil
  end

  return result
end

--- Exécute une fonction en sécurité (sans enregistrement de module).
--- @param fn function
--- @param context? string
--- @return boolean, any
function M.call(fn, context)
  local ok, err = pcall(fn)
  if not ok then
    emit(
      string.format('Erreur dans %s :\n%s', context or 'inconnu', tostring(err)),
      vim.log.levels.ERROR,
      false
    )
    return false, err
  end
  return true, nil
end

--- Accès en lecture au registre (pour utils.health).
--- @return table<string, {error: string, optional: boolean, timestamp: number}>
function M.get_failures()
  return failures
end

--- Efface le registre (tests uniquement).
function M._reset()
  failures = {}
end

return M
