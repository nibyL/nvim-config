-- ============================================================================
-- REGISTRE CENTRALISÉ DES SERVEURS LSP
-- ============================================================================

return {
  { name = 'clangd', bin = 'clangd' },
  { name = 'lua_ls', bin = 'lua-language-server' },
  { name = 'rust_analyzer', bin = 'rust-analyzer' },
  { name = 'pyright', bin = 'pyright-langserver' },
  { name = 'ts_ls', bin = 'typescript-language-server' },
  { name = 'html', bin = 'vscode-html-language-server' },
  { name = 'emmet_ls', bin = 'emmet-ls' },
  { name = 'asm_lsp', bin = 'asm-lsp' },
  { name = 'jinja_lsp', bin = 'jinja-lsp' },
  { name = 'nushell', bin = 'nu' },
  { name = 'svelte', bin = 'svelteserver' },
}
