-- ============================================================================
-- HEALTH CHECK
-- ============================================================================
-- Rapport :checkhealth personnalisé.
-- ============================================================================

local M = {}
local env = require('utils.env')

-- ----------------------------------------------------------------------------
-- HELPERS
-- ----------------------------------------------------------------------------

local function check_executable(name, required, hint, candidates)
  local path = env.find_executable(name, candidates)

  -- Fallback Windows : utiliser where.exe
  if not path and env.is_windows then
    local result = vim.fn.system({ 'where.exe', name })
    if vim.v.shell_error == 0 and result ~= '' then
      -- Prendre la première ligne
      path = vim.split(result, '\n')[1]:gsub('\r', '')
    end
  end

  local found = path ~= nil
  local level = found and vim.health.ok
             or (required and vim.health.error or vim.health.warn)

  local msg = found and ('`' .. name .. '` found' .. (path and path ~= name and (' (' .. path .. ')') or ''))
                    or  ('`' .. name .. '` not found')

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
    local level = ok and vim.health.ok
        or (required and vim.health.error or vim.health.warn)
    level((ok and '✓ ' or '✗ ') .. name)
end

-- ----------------------------------------------------------------------------
-- MAIN CHECK
-- ----------------------------------------------------------------------------

function M.check()
    vim.health.start('Ma config Neovim')

    -- === ENVIRONNEMENT ===
    vim.health.start('Environment')
    vim.health.info('OS      : ' .. tostring(vim.uv.os_uname().sysname))
    vim.health.info('Neovim  : ' .. tostring(vim.version()))
    vim.health.info('Shell   : ' .. vim.o.shell)
    vim.health.info('Term    : ' .. (vim.env.TERM or 'unknown'))

    if env.is_wsl then
        vim.health.info('WSL     : detected')
    end

    -- === REQUIRED EXECUTABLES ===
    vim.health.start('Required executables')
    check_executable('git', true, 'Install Git : https://git-scm.com')
    check_executable('rg', true, 'choco install ripgrep')
    check_executable('fd', true, 'choco install fd')
    check_executable('pwsh', env.is_windows, 'choco install powershell-core', {
        'C:/Program Files/PowerShell/7/pwsh.exe',
        -- Windows Store PowerShell : utiliser glob pour trouver le vrai chemin
        vim.fn.glob(vim.fn.expand('$LOCALAPPDATA') .. '\\Microsoft\\WindowsApps\\Microsoft.PowerShellPreview_*\\pwsh.exe'),
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
    check_executable('gcc', false, 'C compilation')
    check_executable('g++', false, 'C++ compilation')
    check_executable('nasm', false, 'ASM compilation')
    check_executable('pandoc', false, 'Markdown preview')
    check_executable('lazygit', false, 'choco install lazygit')
    if env.is_windows then
        check_executable('wsl', false, 'C/C++ compilation via WSL')
    end

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
    -- Dossier snacks lazygit
    check_directory(vim.fn.stdpath('data') .. '/nvim', 'Snacks lazygit dir')

    -- === LUA MODULES : CORE ===
    vim.health.start('Lua modules (core)')
    for _, mod in ipairs({
        'core.options', 'core.keymaps', 'core.autocmds', 'core.statusline',
    }) do
        check_lua_module(mod, true)
    end

    -- === LUA MODULES : PLUGINS ===
    vim.health.start('Lua modules (plugins)')
    for _, mod in ipairs({
        'plugins.init', 'plugins.ui', 'plugins.diagnostics',
        'plugins.treesitter', 'plugins.blink',
    }) do
        check_lua_module(mod, false)
    end

    -- === LUA MODULES : TOOLS & UTILS ===
    vim.health.start('Lua modules (tools & utils)')
    for _, mod in ipairs({
        'lsp',
        'tools.autosave', 'tools.compiler', 'tools.leap',
        'utils.notify', 'utils.safe', 'utils.env',
        'utils.directory_history', 'utils.health',
    }) do
        check_lua_module(mod, false)
    end

    -- === PLUGINS ===
    vim.health.start('Plugins loaded')
    for _, p in ipairs({
        'snacks', 'blink.cmp', 'nvim-treesitter', 'gitsigns',
        'nvim-autopairs', 'quicker', 'leap',
        'tiny-inline-diagnostic',
    }) do
        check_lua_module(p, false)
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
