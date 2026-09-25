-- ============================================================================
-- Neovim 0.12+ - Configuration personnelle (Chef d'orchestre)
-- ============================================================================

local safe   = require('utils.safe')
local notify = require('utils.notify')

-- ----------------------------------------------------------------------------
-- Déclaration des modules par criticité
-- ----------------------------------------------------------------------------

local CORE_MODULES = {
  'core.options',
  'core.keymaps',
  'core.autocmds',
  'core.statusline',
}

local PLUGIN_MODULES = {
  'plugins.init',
  'plugins.ui',
  'plugins.diagnostics',
  'plugins.treesitter',
  'plugins.blink',
}

local TOOL_MODULES = {
  'tools.autosave',
  'tools.compiler',
  'tools.leap',
}

-- ----------------------------------------------------------------------------
-- Chargement
-- ----------------------------------------------------------------------------

for _, mod in ipairs(CORE_MODULES) do
  safe.require(mod, { optional = false })
end

for _, mod in ipairs(PLUGIN_MODULES) do
  safe.require(mod, { optional = true })
end

-- LSP dépend de blink.cmp → chargé après les plugins
-- safe.require('lsp', { optional = false })

for _, mod in ipairs(TOOL_MODULES) do
  safe.require(mod, { optional = true })
end

notify.info('Configuration chargée avec succès ! 🚀')


