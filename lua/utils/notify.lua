-- ============================================================================
-- NOTIFICATIONS UNIFORMES
-- ============================================================================
-- Politique de production :
--   - Silencieux en headless (CI, scripts)
--   - Déduplication par (niveau, message) pour éviter le spam
--   - Préfixe discret ⚙ pour identifier les messages de la config
-- ============================================================================

local M = {}

local PREFIX = '⚙ '

-- Déduplication : une même notification n'apparaît qu'une fois par session.
-- Clé = "niveau:message". Les erreurs ne sont pas dédupliquées (toujours visibles).
local seen = {}

local function should_dedupe(level, msg)
  if level >= vim.log.levels.ERROR then return false end
  local key = tostring(level) .. ':' .. msg
  if seen[key] then return false end
  seen[key] = true
  return true
end

local function emit(msg, level, title)
  -- Silence total en headless
  if #vim.api.nvim_list_uis() == 0 then return end

  -- Déduplication (sauf erreurs)
  if not should_dedupe(level, msg) then return end

  vim.notify(PREFIX .. msg, level, { title = title or 'Neovim' })
end

function M.info(msg, title)  emit(msg, vim.log.levels.INFO,  title) end
function M.warn(msg, title)  emit(msg, vim.log.levels.WARN,  title) end
function M.error(msg, title) emit(msg, vim.log.levels.ERROR, title) end

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
