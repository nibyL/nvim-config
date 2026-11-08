-- ============================================================================
-- Neovim 0.12+ - Configuration personnelle (Chef d'orchestre)
-- ============================================================================
-- Production-grade strict :
--   - Garde de version avant tout require
--   - Loader Lua natif activé
--   - Chargement par criticité avec isolation d'erreur
--   - Silence total en usage normal (Option A)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- GARDE DE VERSION (exécutée AVANT tout require)
-- ----------------------------------------------------------------------------
-- Toute API utilisée dans cette config suppose Neovim 0.12+ :
--   vim.pack, vim.lsp.config/enable, vim.hl.on_yank,
--   vim.diagnostic.count, vim.filetype.match({buf=}), vim.loader
-- Sur une version antérieure, on refuse de démarrer proprement.
-- ----------------------------------------------------------------------------
local _start_time = vim.uv.hrtime()
if vim.fn.has('nvim-0.12') == 0 then
  local detected = tostring(vim.version())
  vim.api.nvim_echo({
    {
      '════════════════════════════════════════════════════════\n',
      'ErrorMsg',
    },
    { ' Configuration Neovim : version incompatible\n', 'ErrorMsg' },
    {
      '════════════════════════════════════════════════════════\n',
      'ErrorMsg',
    },
    { '\n' },
    { ' Requis  : Neovim 0.12 ou supérieur\n', 'WarningMsg' },
    { ' Détecté : ' .. detected .. '\n', 'WarningMsg' },
    { '\n' },
    { ' Mettez à jour Neovim puis relancez.\n', 'Comment' },
    { ' https://github.com/neovim/neovim/releases\n', 'Comment' },
    { '\n' },
  }, true, {})
  vim.cmd('cq')
end

-- ----------------------------------------------------------------------------
-- LOADER LUA NATIF
-- ----------------------------------------------------------------------------
-- Compile les modules Lua en bytecode à la volée : gain moyen 30-50%
-- sur le temps de require au démarrage. Idempotent, sans effet de bord.
-- ----------------------------------------------------------------------------
vim.loader.enable()
vim.g.debug_mode = vim.env.NVIM_DEBUG == '1'

-- ----------------------------------------------------------------------------
-- MODULES UTILITAIRES (requis avant tout le reste)
-- ----------------------------------------------------------------------------
-- Ces deux modules sont volontairement chargés hors de safe.require :
-- s'ils échouent, on ne peut plus rien tracer. C'est le point de rupture.
-- ----------------------------------------------------------------------------
local ok_safe, safe = pcall(require, 'utils.safe')
if not ok_safe then
  vim.api.nvim_echo({
    { 'ERREUR CRITIQUE : utils.safe introuvable\n', 'ErrorMsg' },
    { tostring(safe) .. '\n', 'WarningMsg' },
  }, true, {})
  vim.cmd('cq')
end

-- ----------------------------------------------------------------------------
-- DÉCLARATION DES MODULES PAR CRITICITÉ
-- ----------------------------------------------------------------------------
-- Niveau 1 — CORE (required)     : sans eux, la config est inutilisable
-- Niveau 2 — PLUGINS (optional)  : sans eux, Neovim reste utilisable
-- Niveau 3 — LSP (required)      : dépend de blink pour les capabilities,
--                                  mais doit démarrer même si blink échoue
-- Niveau 4 — TOOLS (optional)    : confort, non bloquant
-- ----------------------------------------------------------------------------

local CORE_MODULES = {
  'core.options',
  'core.keymaps',
  'core.autocmds',
  'core.statusline',
  'core.on_demand',
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
  'tools.pandoc',
}

-- ----------------------------------------------------------------------------
-- CHARGEMENT
-- ----------------------------------------------------------------------------
-- safe.require enregistre chaque échec dans vim.g._failed_modules pour
-- que utils.health puisse les remonter dans :checkhealth monprofil.
-- ----------------------------------------------------------------------------

for _, mod in ipairs(CORE_MODULES) do
  safe.require(mod, { mode = 'fatal' })
end

for _, mod in ipairs(PLUGIN_MODULES) do
  local setup_fn = safe.require(mod, { mode = 'warn' })
  if type(setup_fn) == 'function' then
    safe.call(mod, setup_fn)
  end
end

safe.require('lsp', { mode = 'fatal' })

for _, mod in ipairs(TOOL_MODULES) do
  safe.require(mod, { mode = 'optional' })
end

vim.g._config_load_ms = (vim.uv.hrtime() - _start_time) / 1e6
-- ============================================================================
-- USER COMMANDS
-- ============================================================================

vim.api.nvim_create_user_command('CheckConfig', function()
  vim.cmd('checkhealth monprofil')
end, { desc = 'Vérifier la configuration Neovim' })

-- ============================================================================
-- AUCUNE NOTIFICATION DE DÉMARRAGE (Option A)
-- ============================================================================
-- Le silence est le signal par défaut. Toute anomalie a déjà été
-- remontée par safe.require() via utils.notify, et reste consultable
-- dans :checkhealth monprofil.
-- ----------------------------------------------------------------------------
