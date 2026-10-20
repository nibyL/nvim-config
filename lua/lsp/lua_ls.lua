-- ============================================================================
-- LSP : lua_ls (lua-language-server)
-- ============================================================================
-- Configuration spécifique pour le développement Neovim lui-même.
-- ============================================================================

return {
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          -- Décommentez si vous voulez la complétion des plugins installés :
          -- vim.fn.stdpath('data') .. '/site/pack/core/opt/*',
        },
      },
      diagnostics = {
        globals = { 'vim' },
      },
      telemetry = {
        enable = false,
      },
    },
  },
}
