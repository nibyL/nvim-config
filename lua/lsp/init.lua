-- ============================================================================
-- LSP — point d'entrée
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. FONCTION D'INITIALISATION DU LSP
-- ----------------------------------------------------------------------------
local function init_lsp()
  if vim.g._lsp_initialized then
    return
  end
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
      vim.keymap.set(
        'n',
        'gd',
        vim.lsp.buf.definition,
        vim.tbl_extend('force', opts, { desc = 'Définition' })
      )
      vim.keymap.set(
        'n',
        'gD',
        vim.lsp.buf.declaration,
        vim.tbl_extend('force', opts, { desc = 'Déclaration' })
      )
      vim.keymap.set(
        'n',
        'gr',
        vim.lsp.buf.references,
        vim.tbl_extend('force', opts, { desc = 'Références' })
      )
      vim.keymap.set(
        'n',
        'gi',
        vim.lsp.buf.implementation,
        vim.tbl_extend('force', opts, { desc = 'Implémentation' })
      )
      vim.keymap.set(
        'n',
        'gt',
        vim.lsp.buf.type_definition,
        vim.tbl_extend('force', opts, { desc = 'Type' })
      )

      -- Documentation & signature
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover' }))
      vim.keymap.set(
        'i',
        '<C-k>',
        vim.lsp.buf.signature_help,
        vim.tbl_extend('force', opts, { desc = 'Signature' })
      )

      -- Édition
      vim.keymap.set(
        'n',
        '<leader>rn',
        vim.lsp.buf.rename,
        vim.tbl_extend('force', opts, { desc = 'Renommer' })
      )
      vim.keymap.set(
        { 'n', 'v' },
        '<leader>ca',
        vim.lsp.buf.code_action,
        vim.tbl_extend('force', opts, { desc = 'Code action' })
      )

      -- Diagnostics du buffer
      vim.keymap.set(
        'n',
        '<leader>cd',
        vim.diagnostic.open_float,
        vim.tbl_extend('force', opts, { desc = 'Diagnostic flottant' })
      )
      vim.keymap.set('n', '[d', function()
        vim.diagnostic.jump({ count = -1 })
      end, vim.tbl_extend('force', opts, { desc = 'Diagnostic précédent' }))
      vim.keymap.set('n', ']d', function()
        vim.diagnostic.jump({ count = 1 })
      end, vim.tbl_extend('force', opts, { desc = 'Diagnostic suivant' }))
    end,
  })

  -- Activation des serveurs depuis le registre centralisé
  local registry = require('lsp.registry')
  local safe = require('utils.safe')

  for _, srv in ipairs(registry) do
    local name = srv.name
    local ok, override = pcall(require, 'lsp.' .. name)

    if ok and type(override) == 'table' then
      vim.lsp.config(name, override)
    elseif not ok then
      -- Log the failure but still enable the server with defaults
      safe.call('lsp.config:' .. name, function()
        error('Impossible de charger les overrides pour ' .. name .. ' : ' .. tostring(override))
      end)
    end

    vim.lsp.enable(name)
  end
end

-- ----------------------------------------------------------------------------
-- 2. EXÉCUTION (Attente déterministe de blink.cmp)
-- ----------------------------------------------------------------------------
local done = false

local function try_init(reason)
  if done then
    return
  end
  done = true
  vim.g._lsp_init_reason = reason
  init_lsp()
end

if pcall(require, 'blink.cmp') then
  try_init('blink-already-loaded')
else
  -- On attend l'événement de blink
  local ev_id = vim.api.nvim_create_autocmd('User', {
    pattern = 'BlinkCmpLoaded',
    once = true,
    callback = function()
      try_init('blink-event')
    end,
  })

  -- Fallback de sécurité : si blink ne se charge pas, on l'initialise après 2000ms.
  vim.defer_fn(function()
    if done then
      return
    end
    -- On annule l'autocmd pour ne pas l'avoir en mémoire
    pcall(vim.api.nvim_del_autocmd, ev_id)
    try_init('timeout-no-blink')

    -- Message informatif (pas une erreur)
    if #vim.api.nvim_list_uis() > 0 then
      vim.notify(
        'LSP initialisé avec les capacités par défaut (blink.cmp chargé après 2s).',
        vim.log.levels.INFO,
        { title = 'LSP' }
      )
    end
  end, 2000)
end
