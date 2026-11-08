-- ============================================================================
-- HEALTH CHECK
-- ============================================================================

local M = {}
local env = require('utils.env')

-- ----------------------------------------------------------------------------
-- HELPERS
-- ----------------------------------------------------------------------------

local function check_executable(name, required, hint, candidates)
  local path = env.find_executable(name, candidates)

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

  vim.health.info('Loader Lua : activé au démarrage (init.lua)')

  if #vim.api.nvim_list_uis() == 0 then
    vim.health.info('Mode headless détecté — notifications silencieuses')
  end
end

-- ----------------------------------------------------------------------------
-- SECTION : FAILED MODULES
-- ----------------------------------------------------------------------------

local function check_failed_modules()
  vim.health.start('Failed modules')

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
-- SECTION : LAZY LOADING & PERFORMANCE
-- ----------------------------------------------------------------------------

local function check_lazy_loading()
  vim.health.start('Lazy Loading & Performance')

  -- P1-3 : Remplacement de vim.v.startuptime (qui n'existe pas)
  local t = vim.g._config_load_ms
  if t then
    if t < 300 then
      vim.health.ok(('Chargement : %.0f ms (Excellent)'):format(t))
    elseif t < 600 then
      vim.health.ok(('Chargement : %.0f ms (Bon)'):format(t))
    else
      vim.health.warn(('Chargement lent : %.0f ms'):format(t))
    end
  else
    vim.health.info('Temps de chargement : non mesuré')
  end

  -- Déclencheurs lazy
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
    vim.health.info('Lazy loading : aucun déclencheur en attente')
  end
end

-- ----------------------------------------------------------------------------
-- SECTION : LSP SERVERS (utilise le registre)
-- ----------------------------------------------------------------------------

local function check_lsp_servers()
  vim.health.start('LSP servers (activés dans lsp/init.lua)')

  local ok, registry = pcall(require, 'lsp.registry')
  if not ok then
    vim.health.error('lsp.registry introuvable')
    return
  end

  local missing = {}

  for _, srv in ipairs(registry) do
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
          .. '  → Désactivez-les dans lsp/registry.lua ou installez-les.',
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
    vim.health.warn('nvim-pack-lock.json introuvable')
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
-- MAIN CHECK
-- ----------------------------------------------------------------------------

function M.check()
  vim.health.start('Ma config Neovim')

  check_environment()
  check_version_guard()
  check_failed_modules()
  check_lockfile()
  check_lazy_loading()

  -- === REQUIRED EXECUTABLES ===
  vim.health.start('Required executables')
  check_executable('git', true, 'Install Git : https://git-scm.com')
  check_executable('rg', true, 'choco install ripgrep')
  check_executable('fd', true, 'choco install fd')
  check_executable('pwsh', env.is_windows, 'choco install powershell-core', {
    'C:/Program Files/PowerShell/7/pwsh.exe',
  })

  -- === OPTIONAL EXECUTABLES ===
  vim.health.start('Optional executables')
  check_executable('clangd', false, 'LSP for C/C++ : choco install llvm', {
    'C:/Program Files/LLVM/bin/clangd.exe',
    '/usr/bin/clangd',
  })
  check_executable('clang', false, 'Treesitter CC env', {
    'C:/Program Files/LLVM/bin/clang.exe',
  })
  check_executable('gcc', false, 'C compilation')
  check_executable('g++', false, 'C++ compilation')
  check_executable('nasm', false, 'ASM compilation')
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
  check_directory(vim.fn.stdpath('data') .. '/nvim', 'Snacks lazygit dir')

  -- === LUA MODULES ===
  vim.health.start('Lua modules')
  for _, mod in ipairs({
    'core.options',
    'core.keymaps',
    'core.autocmds',
    'core.statusline',
    'core.on_demand',
    'plugins.init',
    'plugins.ui',
    'plugins.diagnostics',
    'plugins.treesitter',
    'plugins.blink',
    'lsp',
    'lsp.registry',
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
    local loaded = package.loaded[p] ~= nil
    if loaded then
      vim.health.ok('✓ ' .. p .. ' (chargé)')
    else
      vim.health.info('⏳ ' .. p .. ' (en attente ou non installé)')
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
