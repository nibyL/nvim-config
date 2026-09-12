-- ============================================================================
-- LSP
-- ============================================================================

local blink = require('blink.cmp')
local capabilities = blink.get_lsp_capabilities()

-- ============================================================================
-- CLANGD
-- ============================================================================

vim.lsp.config('clangd', {
  capabilities = capabilities,

  filetypes = {
    'c',
    'cpp',
    'objc',
    'objcpp',
    'cuda',
  },

  cmd = {
    'clangd',
    '--query-driver=C:/Strawberry/c/bin/gcc.exe,C:/Strawberry/c/bin/g++.exe',
    '--background-index',
  },
})

vim.lsp.enable('clangd')

-- ============================================================================
-- LUA_LS (réglages spécifiques, fusionnés avec la config générique ci-dessous)
-- ============================================================================

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
    },
  },
})

-- ============================================================================
-- AUTRES SERVEURS LSP
-- ============================================================================

local servers = {
  'lua_ls',
  'rust_analyzer',
  'html',
  'jinja_lsp',
  'emmet_ls',
  'ts_ls',
  'svelte',
  'nushell',
  'asm_lsp',
  'pyright',
}

for _, server in ipairs(servers) do
  vim.lsp.config(server, {
    capabilities = capabilities,
  })

  vim.lsp.enable(server)
end
