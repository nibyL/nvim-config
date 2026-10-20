-- ============================================================================
-- LSP — point d'entrée
-- ============================================================================
-- Organisation :
--   1. Capabilities globales (avec fallback défensif si blink.cmp échoue)
--   2. Configuration commune via vim.lsp.config('*', {...})
--   3. Keymaps LSP via LspAttach (buffer-local)
--   4. Activation des serveurs via vim.lsp.enable()
--
-- Les configs spécifiques par serveur vivent dans lsp/<name>.lua
-- (auto-découvertes par Neovim 0.11+).
-- ============================================================================

local notify = require('utils.notify')

-- ----------------------------------------------------------------------------
-- 1. CAPABILITIES GLOBALES (avec fallback défensif)
-- ----------------------------------------------------------------------------
-- Si blink.cmp est indisponible, on retombe sur les capabilities par défaut
-- de Neovim plutôt que de planter tout le LSP.
-- ----------------------------------------------------------------------------
local ok_blink, blink = pcall(require, 'blink.cmp')
local capabilities

if ok_blink and blink and type(blink.get_lsp_capabilities) == 'function' then
  local ok_caps, caps = pcall(blink.get_lsp_capabilities)
  if ok_caps and caps then
    capabilities = caps
  else
    capabilities = vim.lsp.protocol.make_client_capabilities()
    notify.warn('blink.cmp : get_lsp_capabilities() a échoué, capabilities par défaut')
  end
else
  capabilities = vim.lsp.protocol.make_client_capabilities()
  notify.warn('blink.cmp indisponible, capabilities LSP par défaut')
end

-- ----------------------------------------------------------------------------
-- 2. CONFIGURATION COMMUNE À TOUS LES SERVEURS
-- ----------------------------------------------------------------------------
-- vim.lsp.config('*', ...) s'applique à tous les serveurs. Les fichiers
-- lsp/<name>.lua sont fusionnés par-dessus pour les spécificités.
-- ----------------------------------------------------------------------------
vim.lsp.config('*', {
  capabilities = capabilities,
})

-- ----------------------------------------------------------------------------
-- 3. KEYMAPS LSP (via LspAttach, buffer-local)
-- ----------------------------------------------------------------------------
-- Recommandation Neovim 0.11+ : ne plus utiliser on_attach, mais
-- l'autocmd LspAttach qui reçoit le buffer en argument.
-- ----------------------------------------------------------------------------
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspAttach', { clear = true }),
  desc = 'Keymaps LSP buffer-local',

  callback = function(args)
    local buf = args.buf
    local opts = { buffer = buf, silent = true }

    -- Navigation
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = 'Définition' }))
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = 'Déclaration' }))
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = 'Références' }))
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('force', opts, { desc = 'Implémentation' }))
    vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, vim.tbl_extend('force', opts, { desc = 'Type' }))

    -- Documentation & signature
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover' }))
    vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, { desc = 'Signature' }))

    -- Édition
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Renommer' }))
    vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = 'Code action' }))

    -- Diagnostics du buffer
    vim.keymap.set('n', '<leader>cd', vim.diagnostic.open_float, vim.tbl_extend('force', opts, { desc = 'Diagnostic flottant' }))
    vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, vim.tbl_extend('force', opts, { desc = 'Diagnostic précédent' }))
    vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end, vim.tbl_extend('force', opts, { desc = 'Diagnostic suivant' }))
  end,
})

-- ----------------------------------------------------------------------------
-- 4. ACTIVATION DES SERVEURS
-- ----------------------------------------------------------------------------
-- AVANT d'activer, on force la fusion de nos configs locales
-- pour contrer l'écrasement par nvim-lspconfig.
-- ----------------------------------------------------------------------------
local servers = {
  'clangd',
  'lua_ls',
  'rust_analyzer',
  'pyright',
  'asm_lsp',
  'ts_ls',
  'html',
  'emmet_ls',
  'jinja_lsp',
  'nushell',
  'svelte',
}

for _, name in ipairs(servers) do
  -- Charge notre fichier lsp/<name>.lua s'il existe
  local ok, override = pcall(require, 'lsp.' .. name)
  if ok and type(override) == 'table' then
    -- Fusionne notre override PAR-DESSUS la config par défaut
    vim.lsp.config(name, override)
  end
  vim.lsp.enable(name)
end
