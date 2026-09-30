-- ============================================================================
-- NOTIFICATIONS UNIFORMES
-- ============================================================================

local M = {}

local PREFIX = '⚙️  '

local function emit(msg, level, title)
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

return M
