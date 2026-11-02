-- ============================================================================
-- NOTIFICATIONS UNIFORMES
-- ============================================================================
-- Politique de production :
--   - Silencieux en headless (CI, scripts)
--   - Déduplication temporelle (5s) pour éviter le spam
--   - Préfixe discret ⚙ pour identifier les messages de la config
-- ============================================================================

local M = {}

local PREFIX = '⚙ '

-- Déduplication : fenêtre temporelle de 5 secondes
local seen = {}
local DEDUP_WINDOW_MS = 5000

local function should_dedupe(level, msg)
  -- Les erreurs ne sont jamais dédupliquées
  if level >= vim.log.levels.ERROR then
    return false
  end

  local key = tostring(level) .. ':' .. msg
  local now = vim.uv.now()
  local entry = seen[key]

  if entry and (now - entry.last_ts) < DEDUP_WINDOW_MS then
    entry.count = entry.count + 1
    return false
  end

  seen[key] = { count = 1, last_ts = now }
  return true
end

local function emit(msg, level, title)
  -- Silence total en headless
  if #vim.api.nvim_list_uis() == 0 then
    return
  end

  if not should_dedupe(level, msg) then
    return
  end

  vim.notify(PREFIX .. msg, level, { title = title or 'Neovim' })
end

function M.info(msg, title)
  emit(msg, vim.log.levels.INFO, title)
end
function M.warn(msg, title)
  emit(msg, vim.log.levels.WARN, title)
end
function M.error(msg, title)
  emit(msg, vim.log.levels.ERROR, title)
end

function M.debug(msg, title)
  if vim.g.debug_mode then
    emit('[DEBUG] ' .. msg, vim.log.levels.DEBUG, title)
  end
end

--- Vide le cache de déduplication (utile pour les tests).
function M._reset()
  seen = {}
end

return M
