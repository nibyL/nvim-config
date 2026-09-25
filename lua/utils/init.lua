-- ============================================================================
-- UTILS - API PUBLIQUE
-- ============================================================================

local ok_dh, directory_history = pcall(require, 'utils.directory_history')

return {
  notify            = require('utils.notify'),
  safe              = require('utils.safe'),
  env               = require('utils.env'),
  directory_history = ok_dh and directory_history or nil,
}
