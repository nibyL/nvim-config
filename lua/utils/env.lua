-- ============================================================================
-- DÉTECTION D'ENVIRONNEMENT
-- ============================================================================
-- Détecte l'OS, le shell, les binaires disponibles, et configure
-- l'environnement (TMP, CC, PATH, shell) de manière portable.
--
-- RÈGLE ABSOLUE : aucun autre fichier de la config ne doit contenir
-- de chemin OS-spécifique. Tout passe par env.*
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
  if vim.fn.executable(name) == 1 then
    return name
  end
  for _, path in ipairs(candidates or {}) do
    if path and path ~= '' and vim.fn.executable(path) == 1 then
      return path
    end
  end
  return nil
end

-- ----------------------------------------------------------------------------
-- DÉTECTION LLVM (WinGet, Program Files, Homebrew, apt)
-- ----------------------------------------------------------------------------
--- Détecte le dossier bin/ de LLVM selon la plateforme.
--- Utile pour clangd, clang, clang-format, clang-tidy.
--- @return string|nil
function M.detect_llvm_bin()
  if M.is_windows then
    -- 1. WinGet (chemin versionné, change à chaque mise à jour majeure)
    local winget_glob = vim.fn.expand('$LOCALAPPDATA')
      .. '\\Microsoft\\WinGet\\Packages\\LLVM.clangd_*\\clangd_*\\bin'
    local winget_matches = vim.fn.glob(winget_glob, false, true)
    if #winget_matches > 0 then
      -- Le glob peut retourner plusieurs versions, on prend la plus récente
      table.sort(winget_matches)
      return winget_matches[#winget_matches]
    end

    -- 2. Installation classique
    local program_files = 'C:\\Program Files\\LLVM\\bin'
    if vim.fn.isdirectory(program_files) == 1 then
      return program_files
    end
  elseif M.is_macos then
    for _, p in ipairs({
      '/opt/homebrew/opt/llvm/bin',
      '/usr/local/opt/llvm/bin',
    }) do
      if vim.fn.isdirectory(p) == 1 then
        return p
      end
    end
  else
    if vim.fn.isdirectory('/usr/bin') == 1 and vim.fn.executable('clangd') == 1 then
      return '/usr/bin'
    end
  end
  return nil
end

-- ----------------------------------------------------------------------------
-- CANDIDATS POUR BINAIRES LSP
-- ----------------------------------------------------------------------------
--- Retourne les chemins candidats pour un binaire LSP connu.
--- Évite de dupliquer les chemins dans health.lua et lsp/init.lua.
--- @param name string  -- 'clangd', 'clang', 'clang-format', etc.
--- @return string[]
function M.get_lsp_candidates(name)
  local llvm_bin = M.detect_llvm_bin()
  local candidates = {}

  if llvm_bin then
    local sep = M.is_windows and '\\' or '/'
    local ext = M.is_windows and '.exe' or ''
    table.insert(candidates, llvm_bin .. sep .. name .. ext)
  end

  -- Candidats additionnels selon le binaire
  if name == 'clangd' and not M.is_windows then
    table.insert(candidates, '/usr/bin/clangd')
  end

  return candidates
end

-- ----------------------------------------------------------------------------
-- COMMANDE D'OUVERTURE DE FICHIER
-- ----------------------------------------------------------------------------
--- Retourne la commande pour ouvrir un fichier dans l'application par défaut.
--- @return string[]
function M.get_explorer_cmd()
  if M.is_windows then
    return { 'explorer.exe' }
  elseif M.is_macos then
    return { 'open' }
  else
    return { 'xdg-open' }
  end
end

-- ----------------------------------------------------------------------------
-- COMMANDE SHELL WSL
-- ----------------------------------------------------------------------------
--- Retourne la commande shell pour compiler en C/C++/ASM.
--- Sous Windows : WSL si disponible, sinon bash natif (Git Bash, MSYS2).
--- Ailleurs : bash (ou $SHELL).
--- @return string[]
function M.get_wsl_cmd()
  if M.is_windows then
    if vim.fn.executable('wsl.exe') == 1 then
      return { 'wsl.exe', '-e', 'bash' }
    end
    -- Fallback : Git Bash / MSYS2 bash
    if vim.fn.executable('bash') == 1 then
      return { 'bash' }
    end
    return { 'cmd.exe' }
  else
    return { vim.env.SHELL or 'bash' }
  end
end

-- ----------------------------------------------------------------------------
-- QUERY DRIVER POUR CLANGD
-- ----------------------------------------------------------------------------
--- Retourne la liste des compilateurs C/C++ détectés, à passer à clangd
--- via --query-driver=... pour qu'il puisse résoudre les includes système.
--- @return string[]
function M.get_query_driver()
  local drivers = {}

  if M.is_windows then
    -- Candidats connus sur Windows (Strawberry Perl, MSYS2, MinGW)
    local candidates = {
      { 'gcc', { 'C:/Strawberry/c/bin/gcc.exe', 'C:/msys64/mingw64/bin/gcc.exe' } },
      { 'g++', { 'C:/Strawberry/c/bin/g++.exe', 'C:/msys64/mingw64/bin/g++.exe' } },
    }
    for _, entry in ipairs(candidates) do
      local found = M.find_executable(entry[1], entry[2])
      if found then
        -- On renvoie toujours un chemin absolu (clangd l'exige)
        if found == entry[1] then
          -- Trouvé via le PATH : on résout le chemin complet
          local resolved = vim.fn.exepath(found)
          if resolved ~= '' then
            table.insert(drivers, resolved)
          end
        else
          table.insert(drivers, found)
        end
      end
    end
  else
    for _, name in ipairs({ 'gcc', 'g++', 'clang', 'clang++' }) do
      local found = M.find_executable(name)
      if found then
        table.insert(drivers, vim.fn.exepath(found))
      end
    end
  end

  return drivers
end

-- ----------------------------------------------------------------------------
-- DOSSIER TEMPORAIRE PORTABLE
-- ----------------------------------------------------------------------------
function M.setup_tempdir()
  local base
  if M.is_windows then
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
  local candidates = M.get_lsp_candidates('clang')
  -- Ajoute des candidats génériques
  for _, p in ipairs({
    'C:/Program Files/LLVM/bin/clang.exe',
    '/usr/bin/clang',
    '/usr/local/opt/llvm/bin/clang',
  }) do
    table.insert(candidates, p)
  end

  local clang = M.find_executable('clang', candidates)
  if clang then
    vim.env.CC = clang
    M.clang = clang
  end
  return clang
end

-- ----------------------------------------------------------------------------
-- PATH ADDITIONNEL (Chocolatey, Scoop, Homebrew, WinGet)
-- ----------------------------------------------------------------------------
function M.setup_path()
  local extras = {}

  if M.is_windows then
    extras = {
      'C:\\ProgramData\\chocolatey\\bin',
      vim.fn.expand('$USERPROFILE') .. '\\scoop\\shims',
      vim.fn.expand('$LOCALAPPDATA') .. '\\Microsoft\\WindowsApps',
    }
    -- Ajout du bin LLVM détecté (WinGet ou Program Files)
    local llvm_bin = M.detect_llvm_bin()
    if llvm_bin then
      table.insert(extras, llvm_bin)
    end
  elseif M.is_macos then
    extras = { '/opt/homebrew/bin', '/usr/local/bin' }
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
    vim.o.shell        = 'cmd.exe'
    vim.o.shellcmdflag = '/c'
    vim.o.shellredir   = '2>&1 > %s'
    vim.o.shellpipe    = '2>&1 > %s'
    vim.o.shellquote   = ''
    vim.o.shellxquote  = ''
  else
    vim.o.shell = vim.env.SHELL or 'bash'
  end
end

-- ----------------------------------------------------------------------------
-- RACINES DISQUE (pour pickers sur C:/, D:/, etc.)
-- ----------------------------------------------------------------------------
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
