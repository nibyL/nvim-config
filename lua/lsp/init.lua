-- ============================================================================
-- LSP — point d'entrée
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. FONCTION D'INITIALISATION DU LSP
-- ----------------------------------------------------------------------------
local function init_lsp()
  if vim.g._lsp_initialized then return end
  vim.g._lsp_initialized = true

  -- Récupération des capabilities de blink.cmp
  local ok_blink, blink = pcall(require, 'blink.cmp')
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  if ok_blink and blink and type(blink.get_lsp_capabilities) == 'function' then
    local ok_caps, caps = pcall(blink.get_lsp_capabilities)
    if ok_caps and caps then
      capabilities = caps
    end
  end

  -- Configuration globale avec les capabilities
  vim.lsp.config('*', { capabilities = capabilities })

  -- Keymaps LSP (via LspAttach, buffer-local)
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

  -- Activation des serveurs
  local servers = {
    'clangd', 'lua_ls', 'rust_analyzer', 'pyright', 'asm_lsp',
    'ts_ls', 'html', 'emmet_ls', 'jinja_lsp', 'nushell', 'svelte',
  }

  for _, name in ipairs(servers) do
    local ok, override = pcall(require, 'lsp.' .. name)
    if ok and type(override) == 'table' then
      vim.lsp.config(name, override)
    end
    vim.lsp.enable(name)
  end
end

-- ----------------------------------------------------------------------------
-- 2. EXÉCUTION (Attente de blink.cmp)
-- ----------------------------------------------------------------------------
local is_blink_loaded = pcall(require, 'blink.cmp')

if is_blink_loaded then
  init_lsp()
else
  -- On attend que blink soit chargé
  vim.api.nvim_create_autocmd('User', {
    pattern = 'BlinkCmpLoaded',
    once = true,
    callback = function()
      init_lsp()
    end,
  })

  -- FALLBACK de sécurité : si blink ne se charge pas (ex: on ouvre un fichier sans taper de texte),
  -- on initialise le LSP après 100ms avec les capabilities par défaut.
  vim.defer_fn(function()
    if not vim.g._lsp_initialized then
      init_lsp()
    end
  end, 100)
end
