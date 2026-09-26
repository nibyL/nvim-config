-- ============================================================================
-- DÉTECTION D'ENVIRONNEMENT
-- ============================================================================
-- Détecte l'OS, le shell, les binaires disponibles, et configure
-- l'environnement (TMP, CC, PATH, shell) de manière portable.
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- DÉTECTION OS
-- ----------------------------------------------------------------------------
local uname = vim.uv.os_uname().sysname
M.os        = uname
M.is_windows = uname:find('Windows') ~= nil
M.is_linux   = uname == 'Linux'
M.is_macos   = uname == 'Darwin'
M.is_wsl     = false

if M.is_linux then
  local ok, lines = pcall(vim.fn.readfile, '/proc/version')
  if ok and lines and lines[1] then
    M.is_wsl = lines[1]:lower():find('microsoft') ~= nil
  end
end

-- ----------------------------------------------------------------------------
-- RECHERCHE D'EXÉCUTABLE
-- ----------------------------------------------------------------------------
--- Cherche un exécutable dans le PATH, puis dans une liste de candidats.
--- @param name string
--- @param candidates? string[]
--- @return string|nil
function M.find_executable(name, candidates)
  if vim.fn.executable(name) == 1 then return name end
  for _, path in ipairs(candidates or {}) do
    if vim.fn.executable(path) == 1 then return path end
  end
  return nil
end

-- ----------------------------------------------------------------------------
-- DOSSIER TEMPORAIRE PORTABLE
-- ----------------------------------------------------------------------------
function M.setup_tempdir()
  local base
  if M.is_windows then
    -- Chemin à la racine C:, sans espace (l'ancien chemin fonctionnait)
    base = 'C:\\Temp\\NvimTemp'
  else
    base = '/tmp/nvim-' .. (vim.env.USER or 'user')
  end

  local nvim_dir = base .. (M.is_windows and '\\nvim' or '/nvim')

  vim.fn.mkdir(base, 'p')
  vim.fn.mkdir(nvim_dir, 'p')

  vim.env.TMP  = base
  vim.env.TEMP = base

  M.tempdir = base
  return base
end


function M.ensure_snacks_dir()
  local dir = vim.fn.stdpath('data') .. '/nvim'
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
  return dir
end

-- ----------------------------------------------------------------------------
-- COMPILATEUR CLANG (Treesitter)
-- ----------------------------------------------------------------------------
function M.setup_clang()
  local clang = M.find_executable('clang', {
    'C:/Program Files/LLVM/bin/clang.exe',
    '/usr/bin/clang',
    '/usr/local/opt/llvm/bin/clang',
  })

  if clang then
    vim.env.CC = clang
    M.clang = clang
  end
  return clang
end

-- ----------------------------------------------------------------------------
-- PATH ADDITIONNEL (Chocolatey, Scoop, Homebrew…)
-- ----------------------------------------------------------------------------
function M.setup_path()
  local extras = {}

  if M.is_windows then
    extras = {
      'C:\\ProgramData\\chocolatey\\bin',
      vim.fn.expand('$USERPROFILE') .. '\\scoop\\shims',
      vim.fn.expand('$LOCALAPPDATA') .. '\\Microsoft\\WindowsApps',
    }
  elseif M.is_macos then
    extras = {
      '/opt/homebrew/bin',
      '/usr/local/bin',
    }
  end

  local sep = M.is_windows and ';' or ':'
  for _, path in ipairs(extras) do
    if vim.fn.isdirectory(path) == 1 then
      vim.env.PATH = path .. sep .. vim.env.PATH
    end
  end
end

-- ----------------------------------------------------------------------------
-- SHELL
-- ----------------------------------------------------------------------------
function M.setup_shell()
  if M.is_windows then
    -- Chercher pwsh avec where.exe (détecte WindowsApps)
    local pwsh
    local result = vim.fn.system({ 'where.exe', 'pwsh' })
    if vim.v.shell_error == 0 and result ~= '' then
      pwsh = vim.split(result, '\n')[1]:gsub('\r', '')
    end

    if pwsh then
      vim.o.shell = pwsh
    else
      vim.o.shell = 'powershell'
    end
    vim.o.shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command'
  else
    vim.o.shell = vim.env.SHELL or 'bash'
  end
end

-- ----------------------------------------------------------------------------
-- RACINES DISQUE (pour pickers sur C:/, D:/, etc.)
-- ----------------------------------------------------------------------------
--- Renvoie une liste de racines valides pour la recherche disque.
--- @return string[]
function M.get_disk_roots()
  local candidates

  if M.is_windows then
    candidates = { 'C:/', 'D:/', 'E:/', 'F:/' }
  else
    candidates = { '/' }
  end

  return vim.tbl_filter(function(p)
    return vim.fn.isdirectory(p) == 1
  end, candidates)
end

-- ----------------------------------------------------------------------------
-- SETUP COMPLET (appelé depuis core/options.lua)
-- ----------------------------------------------------------------------------
function M.setup()
  M.setup_tempdir()
  M.setup_clang()
  M.setup_path()
  M.setup_shell()
end

return M
