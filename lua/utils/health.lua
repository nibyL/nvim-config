-- ============================================================================
-- HEALTH CHECK
-- ============================================================================
-- Rapport :checkhealth monprofil
-- Sections :
--   - Environment        : OS, Neovim, shell, term, WSL
--   - Version guard      : Neovim >= 0.12, loader Lua
--   - Failed modules     : échecs de chargement enregistrés par utils.safe
--   - Required binaries  : git, rg, fd, pwsh
--   - Optional binaries  : clangd, clang, gcc, g++, nasm, pandoc, lazygit, wsl
--   - LSP servers        : activés dans lsp/init.lua vs. présents dans le PATH
--   - Directories        : TMP, TEMP, snacks lazygit
--   - Lockfile           : nvim-pack-lock.json présent et cohérent
--   - Lua modules        : core, plugins, tools, utils
--   - Theme              : thème actif
-- ============================================================================

local M = {}
local env = require('utils.env')

-- ----------------------------------------------------------------------------
-- HELPERS
-- ----------------------------------------------------------------------------

local function check_executable(name, required, hint, candidates)
  local path = env.find_executable(name, candidates)

  -- Fallback Windows : where.exe
  if not path and env.is_windows then
    local result = vim.fn.system({ 'where.exe', name })
    if vim.v.shell_error == 0 and result ~= '' then
      path = vim.split(result, '\n')[1]:gsub('\r', '')
    end
  end

  local found = path ~= nil
  local level = found and vim.health.ok or (required and vim.health.error or vim.health.warn)

  local msg = found
      and ('`' .. name .. '` found' .. (path and path ~= name and (' (' .. path .. ')') or ''))
    or ('`' .. name .. '` not found')

  if hint and not found then
    msg = msg .. '\n  → ' .. hint
  end
  level(msg)
end

local function check_directory(path, label)
  if vim.fn.isdirectory(path) == 1 then
    vim.health.ok((label or 'Directory') .. ' : ' .. path)
  else
    vim.health.error((label or 'Directory') .. ' missing : ' .. path)
  end
end

local function check_lua_module(name, required)
  local ok = pcall(require, name)
  local level = ok and vim.health.ok or (required and vim.health.error or vim.health.warn)
  level((ok and '✓ ' or '✗ ') .. name)
end

-- ----------------------------------------------------------------------------
-- SECTION : VERSION GUARD
-- ----------------------------------------------------------------------------

local function check_version_guard()
  vim.health.start('Version guard')

  if vim.fn.has('nvim-0.12') == 1 then
    vim.health.ok('Neovim >= 0.12 : ' .. tostring(vim.version()))
  else
    vim.health.error('Neovim < 0.12 détecté : ' .. tostring(vim.version()))
  end

  -- Loader Lua natif : pas d'accès direct à l'état, on vérifie indirectement
  -- via l'existence de la fonction (elle existe toujours, mais son usage est
  -- signalé par un flag interne non exposé). On se contente d'un OK informatif.
  vim.health.info('Loader Lua : activé au démarrage (init.lua)')

  -- Mode headless
  if #vim.api.nvim_list_uis() == 0 then
    vim.health.info('Mode headless détecté — notifications silencieuses')
  end
end

-- ----------------------------------------------------------------------------
-- SECTION : FAILED MODULES
-- ----------------------------------------------------------------------------

local function check_failed_modules()
  vim.health.start('Failed modules')

  -- Lecture via safe.get_failures() (closure Lua, pas vim.g)
  local ok, safe = pcall(require, 'utils.safe')
  if not ok then
    vim.health.error('utils.safe introuvable — impossible de lire le registre')
    return
  end

  local failed = safe.get_failures()
  if next(failed) == nil then
    vim.health.ok('Aucun échec de chargement enregistré')
  else
    local mode_to_health = {
      fatal = vim.health.error,
      warn = vim.health.error,
      optional = vim.health.warn,
    }
    for name, info in pairs(failed) do
      local level = mode_to_health[info.mode] or vim.health.error
      level(('%-30s [mode=%s]\n  → %s'):format(name, info.mode, info.error))
    end
  end

  local setup_failed = safe.get_setup_failures()
  if next(setup_failed) ~= nil then
    vim.health.start('Setup failures')
    for name, info in pairs(setup_failed) do
      vim.health.error(('%s\n  → %s'):format(name, info.error))
    end
  end
end

-- ----------------------------------------------------------------------------
-- SECTION : LSP SERVERS
-- ----------------------------------------------------------------------------
-- Détecte les serveurs activés dans lsp/init.lua mais absents du PATH.
-- Liste volontairement dupliquée : elle doit rester lisible dans le rapport
-- même si lsp/init.lua échoue au chargement.
-- ----------------------------------------------------------------------------

local EXPECTED_LSP = {
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

local function check_lsp_init_reason()
  vim.health.start('LSP initialization')
  local reason = vim.g._lsp_init_reason
  if not reason then
    vim.health.warn('LSP non initialisé (ou initialisation non tracée)')
    return
  end

  if reason == 'blink-already-loaded' or reason == 'blink-event' then
    vim.health.ok('LSP initialisé avec les capacités de blink.cmp (' .. reason .. ')')
  else
    vim.health.warn('LSP initialisé sans blink.cmp : ' .. reason)
  end
end

local function check_lsp_servers()
  vim.health.start('LSP servers (activés dans lsp/init.lua)')

  local missing = {}

  for _, srv in ipairs(EXPECTED_LSP) do
    local path = env.find_executable(srv.bin)
    if path then
      vim.health.ok(string.format('%s → %s', srv.name, path))
    else
      table.insert(missing, srv.name)
      vim.health.warn(string.format('%s → binaire `%s` introuvable', srv.name, srv.bin))
    end
  end

  if #missing > 0 then
    vim.health.info(
      string.format(
        '%d serveur(s) activé(s) mais absent(s) du PATH : %s\n'
          .. '  Ces serveurs sont silencieusement ignorés par vim.lsp.enable().\n'
          .. '  → Désactivez-les dans lsp/init.lua ou installez-les.',
        #missing,
        table.concat(missing, ', ')
      )
    )
  end
end

-- ----------------------------------------------------------------------------
-- SECTION : LOCKFILE
-- ----------------------------------------------------------------------------

local function check_lockfile()
  vim.health.start('Lockfile (vim.pack)')

  local lock = vim.fs.joinpath(vim.fn.stdpath('config'), 'nvim-pack-lock.json')

  if vim.fn.filereadable(lock) == 0 then
    vim.health.warn(
      'nvim-pack-lock.json introuvable\n'
        .. '  → Exécutez :vim.pack.update() puis committez le lockfile.\n'
        .. '  → Sans lockfile, les versions de plugins ne sont pas reproductibles.'
    )
    return
  end

  local ok, content = pcall(vim.fn.readfile, lock)
  if not ok then
    vim.health.error('Lecture impossible du lockfile : ' .. tostring(content))
    return
  end

  local ok_json, data = pcall(vim.json.decode, table.concat(content, '\n'))
  if not ok_json then
    vim.health.error('Lockfile JSON invalide : ' .. tostring(data))
    return
  end

  local count = data.plugins and vim.tbl_count(data.plugins) or 0
  vim.health.ok(string.format('nvim-pack-lock.json valide (%d plugin(s) épinglé(s))', count))
end

-- ----------------------------------------------------------------------------
-- SECTION : ENVIRONMENT
-- ----------------------------------------------------------------------------

local function check_environment()
  vim.health.start('Environment')
  vim.health.info('OS      : ' .. tostring(vim.uv.os_uname().sysname))
  vim.health.info('Neovim  : ' .. tostring(vim.version()))
  vim.health.info('Shell   : ' .. vim.o.shell)
  vim.health.info('Term    : ' .. (vim.env.TERM or 'unknown'))
  vim.health.info('Config  : ' .. vim.fn.stdpath('config'))
  vim.health.info('Data    : ' .. vim.fn.stdpath('data'))
  vim.health.info('State   : ' .. vim.fn.stdpath('state'))

  if env.is_wsl then
    vim.health.info('WSL     : detected')
  end
end

-- ----------------------------------------------------------------------------
-- SECTION : LAZY LOADING & PERFORMANCE
-- ----------------------------------------------------------------------------

local function check_lazy_loading()
  vim.health.start('Lazy Loading & Performance')

  -- 1. Vérification du temps de démarrage
  if vim.v.startuptime then
    local time = tonumber(vim.v.startuptime)
    if time and time > 0 then
      if time < 300 then
        vim.health.ok(string.format('Temps de démarrage : %d ms (Excellent)', time))
      elseif time < 600 then
        vim.health.ok(string.format('Temps de démarrage : %d ms (Bon)', time))
      else
        vim.health.warn(string.format('Temps de démarrage : %d ms (Lent)', time))
      end
    end
  else
    vim.health.info('Temps de démarrage : non disponible (mode headless)')
  end

  -- 2. Vérification des déclencheurs (événements en attente)
  local lazy_events = { 'BufReadPost', 'InsertEnter', 'BufEnter' }
  local has_lazy_triggers = false

  for _, event in ipairs(lazy_events) do
    local autocmds = vim.api.nvim_get_autocmds({ event = event })
    for _, ac in ipairs(autocmds) do
      if ac.desc and ac.desc:match('lazyload') then
        has_lazy_triggers = true
        break
      end
    end
    if has_lazy_triggers then
      break
    end
  end

  if has_lazy_triggers then
    vim.health.ok('Lazy loading : déclencheurs actifs en attente')
  else
    vim.health.info('Lazy loading : aucun déclencheur en attente (plugins déjà chargés ?)')
  end
end

-- ----------------------------------------------------------------------------
-- MAIN CHECK
-- ----------------------------------------------------------------------------

function M.check()
  vim.health.start('Ma config Neovim')

  check_environment()
  check_version_guard()
  check_failed_modules()
  check_lockfile()
  check_lazy_loading()
  check_lsp_init_reason()

  -- === REQUIRED EXECUTABLES ===
  vim.health.start('Required executables')
  check_executable('git', true, 'Install Git : https://git-scm.com')
  check_executable('rg', true, 'choco install ripgrep')
  check_executable('fd', true, 'choco install fd')
  check_executable('pwsh', env.is_windows, 'choco install powershell-core', {
    'C:/Program Files/PowerShell/7/pwsh.exe',
    vim.fn.glob(
      vim.fn.expand('$LOCALAPPDATA')
        .. '\\Microsoft\\WindowsApps\\Microsoft.PowerShellPreview_*\\pwsh.exe'
    ),
    vim.fn.expand('$LOCALAPPDATA') .. '\\Microsoft\\WindowsApps\\pwsh.exe',
  })

  -- === OPTIONAL EXECUTABLES ===
  vim.health.start('Optional executables')
  check_executable('clangd', false, 'LSP for C/C++ : choco install llvm', {
    'C:/Program Files/LLVM/bin/clangd.exe',
    '/usr/bin/clangd',
  })
  check_executable('clang', false, 'Treesitter CC env', {
    'C:/Program Files/LLVM/bin/clang.exe',
    '/usr/bin/clang',
    '/usr/local/opt/llvm/bin/clang',
  })
  check_executable('gcc', false, 'C compilation', { 'C:/Strawberry/c/bin/gcc.exe' })
  check_executable('g++', false, 'C++ compilation', { 'C:/Strawberry/c/bin/g++.exe' })
  check_executable('nasm', false, 'ASM compilation', { 'C:/Strawberry/c/bin/nasm.exe' })
  check_executable('pandoc', false, 'Markdown preview')
  check_executable('lazygit', false, 'choco install lazygit')
  if env.is_windows then
    check_executable('wsl', false, 'C/C++ compilation via WSL')
  end

  -- === LSP ===
  check_lsp_servers()

  -- === DIRECTORIES ===
  vim.health.start('Directories')
  if vim.env.TMP then
    check_directory(vim.env.TMP, 'TMP')
  else
    vim.health.error('TMP not set')
  end
  if vim.env.TEMP and vim.env.TEMP ~= vim.env.TMP then
    check_directory(vim.env.TEMP, 'TEMP')
  end
  check_directory(vim.fn.stdpath('data') .. '/nvim', 'Snacks lazygit dir')

  -- === LUA MODULES : CORE ===
  vim.health.start('Lua modules (core)')
  for _, mod in ipairs({
    'core.options',
    'core.keymaps',
    'core.autocmds',
    'core.statusline',
  }) do
    check_lua_module(mod, true)
  end

  -- === LUA MODULES : PLUGINS ===
  vim.health.start('Lua modules (plugins)')
  for _, mod in ipairs({
    'plugins.init',
    'plugins.ui',
    'plugins.diagnostics',
    'plugins.treesitter',
    'plugins.blink',
  }) do
    check_lua_module(mod, false)
  end

  -- === LUA MODULES : TOOLS & UTILS ===
  vim.health.start('Lua modules (tools & utils)')
  for _, mod in ipairs({
    'lsp',
    'lsp.clangd',
    'lsp.lua_ls',
    'tools.autosave',
    'tools.compiler',
    'tools.leap',
    'tools.pandoc',
    'utils.notify',
    'utils.safe',
    'utils.env',
    'utils.directory_history',
    'utils.health',
  }) do
    check_lua_module(mod, false)
  end

  -- === PLUGINS ===
  vim.health.start('Plugins loaded')
  for _, p in ipairs({
    'snacks',
    'blink.cmp',
    'nvim-treesitter',
    'gitsigns',
    'nvim-autopairs',
    'quicker',
    'leap',
    'tiny-inline-diagnostic',
  }) do
    -- Vérification non-intrusive : ne force pas le chargement
    local loaded = package.loaded[p] ~= nil
    local in_rtp = #vim.api.nvim_get_runtime_file(
          'lua/' .. p:gsub('%.', '/') .. '/init.lua',
          true
        )
        > 0
      or #vim.api.nvim_get_runtime_file('lua/' .. p:gsub('%.', '/') .. '.lua', true) > 0
      or #vim.api.nvim_get_runtime_file('plugin/' .. p:gsub('%.', '/') .. '.lua', true) > 0

    if loaded then
      vim.health.ok('✓ ' .. p .. ' (chargé)')
    elseif in_rtp then
      vim.health.ok('✓ ' .. p .. ' (disponible, lazy)')
    else
      vim.health.warn('✗ ' .. p .. ' (introuvable)')
    end
  end

  -- === THEME ===
  vim.health.start('Theme')
  if vim.g.colors_name then
    vim.health.ok('Active theme : ' .. vim.g.colors_name)
  else
    vim.health.warn('No theme loaded')
  end

  -- === DISK ROOTS ===
  vim.health.start('Disk roots')
  local roots = env.get_disk_roots()
  if #roots > 0 then
    vim.health.ok('Detected : ' .. table.concat(roots, ', '))
  else
    vim.health.error('No disk root detected')
  end
end

return M
