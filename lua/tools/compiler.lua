-- ============================================================================
-- COMPILATION / EXÉCUTION (C, C++, ASM via WSL | Python via Windows)
-- ============================================================================
local is_windows = vim.uv.os_uname().sysname:find('Windows') ~= nil

-- ==========================================================================
-- FONCTIONS AUXILIAIRES
-- ==========================================================================

-- Conversion d'un chemin Windows (C:\foo\bar) vers WSL (/mnt/c/foo/bar)
local function to_wsl(win_path)
  if not is_windows then
    return win_path
  end
  local path = win_path:gsub('\\', '/')
  path = path:gsub('^([A-Za-z]):', function(drive)
    return '/mnt/' .. drive:lower()
  end)
  return path
end

-- Échappement pour un chemin (gère espaces et apostrophes)
local function sh_escape(s, force_win)
  if is_windows and force_win then
    -- Échappement sécurisé pour les chaînes de caractères Windows entre guillemets
    return '"' .. tostring(s):gsub('"', '\\"') .. '"'
  else
    -- Échappement POSIX classique pour Linux/WSL
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
  end
end

-- Terminal persistant
local term_buf = nil

local function open_terminal()
  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == term_buf then
        vim.api.nvim_set_current_win(win)
        return term_buf
      end
    end
    vim.cmd('botright 15split')
    vim.api.nvim_win_set_buf(0, term_buf)
    return term_buf
  end
  vim.cmd('botright 15split | enew')
  term_buf = vim.api.nvim_get_current_buf()
  return term_buf
end

-- Lance la commande dans le bon interpréteur (WSL Bash ou Windows Power Shell)
local function run_in_terminal(shell_cmd, use_windows_native)
  local buf = open_terminal()
  local job = vim.b[buf].terminal_job_id

  if not job then
    local shell
    if use_windows_native then
      -- On utilise PowerShell 7 (pwsh) ou Windows PowerShell si l'extension est Python
      shell = { vim.o.shell }
    else
      -- On utilise WSL pour le C/C++/ASM
      shell = is_windows and { 'wsl.exe', '-e', 'bash' } or { 'bash' }
    end
    vim.fn.jobstart(shell, { term = true, bufnr = buf })
  end

  vim.api.nvim_chan_send(vim.b[buf].terminal_job_id, shell_cmd .. '\r')
end

-- ==========================================================================
-- CONSTRUCTION DES COMMANDES
-- ==========================================================================
local function build_compile_command(target_file, target_exe, target_obj, ext)
  if ext == 'c' then
    return string.format(
      'gcc %s -o %s -Wall -Wextra',
      sh_escape(target_file),
      sh_escape(target_exe)
    ),
      'GCC',
      false
  elseif ext == 'cpp' or ext == 'cc' or ext == 'cxx' then
    return string.format(
      'g++ %s -o %s -Wall -Wextra',
      sh_escape(target_file),
      sh_escape(target_exe)
    ),
      'G++',
      false
  elseif ext == 'asm' or ext == 's' or ext == 'nasm' then
    return string.format(
      'nasm -f elf64 %s -o %s && ld %s -o %s',
      sh_escape(target_file),
      sh_escape(target_obj),
      sh_escape(target_obj),
      sh_escape(target_exe)
    ),
      'NASM',
      false
    --bloc d'exécution natif Windows pour Python
  elseif ext == 'py' then
    return string.format('python %s', sh_escape(target_file, true)), 'Python (Windows)', true
  end
  return nil, nil, false
end

-- ==========================================================================
-- FONCTION PRINCIPALE
-- ==========================================================================
local function compile_and_run(run_after)
  local file = vim.fn.expand('%:p')
  if file == '' then
    vim.notify('Aucun fichier à exécuter', vim.log.levels.WARN, { title = 'Exécution' })
    return
  end

  local ext = vim.fn.expand('%:e'):lower()

  -- Préparation des chemins selon la cible
  local target_file = (ext == 'py') and file or to_wsl(file)
  local target_exe = to_wsl(vim.fn.expand('%:p:r'))
  local target_obj = to_wsl(vim.fn.expand('%:p:r') .. '.o')

  local compile_cmd, title, use_windows_native =
    build_compile_command(target_file, target_exe, target_obj, ext)

  if not compile_cmd then
    vim.notify('Type non supporté: .' .. ext, vim.log.levels.WARN)
    return
  end

  vim.cmd('wall')

  -- Notification
  vim.notify(
    (run_after and 'Exécution' or 'Compilation') .. ' de ' .. vim.fn.expand('%:t') .. '...',
    vim.log.levels.INFO,
    { title = title }
  )

  -- Construction de la chaîne finale de commande
  local final_cmd
  if use_windows_native then
    -- Syntaxe d'enchaînement propre à PowerShell pour Python
    final_cmd = compile_cmd .. "; Write-Host '`n--- [Terminé] ---'"
  else
    -- Syntaxe POSIX pour Bash (C/C++/ASM dans WSL)
    if run_after then
      final_cmd = compile_cmd
        .. ' && '
        .. sh_escape(target_exe)
        .. " && echo -e '\\n--- [Terminé] ---' || echo -e '\\n--- [Échec] ---'"
    else
      final_cmd = compile_cmd
        .. " && echo -e '\\n--- [Compilation OK] ---' || echo -e '\\n--- [Échec compilation] ---'"
    end
  end

  run_in_terminal(final_cmd, use_windows_native)
end

-- ==========================================================================
-- RACCOURCIS
-- ==========================================================================
vim.keymap.set('n', '<F5>', function()
  compile_and_run(true)
end, { desc = 'Compiler & Exécuter' })
vim.keymap.set('n', '<F6>', function()
  compile_and_run(false)
end, { desc = 'Compiler uniquement' })
