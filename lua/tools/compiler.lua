-- ============================================================================
-- COMPILATION / EXÉCUTION (Natif Windows, WSL, ou Python)
-- ============================================================================
local env = require('utils.env')
local is_windows = env.is_windows

-- ==========================================================================
-- FONCTIONS AUXILIAIRES
-- ==========================================================================

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

local function sh_escape(s, force_win)
  if is_windows and force_win then
    return '"' .. tostring(s):gsub('"', '\\"') .. '"'
  else
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
  end
end

-- ==========================================================================
-- DÉTECTION DES COMPILATEURS
-- ==========================================================================

local function get_c_compiler()
  if is_windows then
    if vim.fn.executable('gcc') == 1 then
      return 'gcc', false
    end
    if vim.fn.executable('wsl') == 1 then
      return 'gcc', true
    end
  else
    if vim.fn.executable('gcc') == 1 then
      return 'gcc', false
    end
  end
  return nil, false
end

local function get_cpp_compiler()
  if is_windows then
    if vim.fn.executable('g++') == 1 then
      return 'g++', false
    end
    if vim.fn.executable('wsl') == 1 then
      return 'g++', true
    end
  else
    if vim.fn.executable('g++') == 1 then
      return 'g++', false
    end
  end
  return nil, false
end

-- ==========================================================================
-- CONSTRUCTION DES COMMANDES
-- ==========================================================================
local function build_compile_command(target_file, target_exe, target_obj, ext)
  if ext == 'c' then
    local bin, use_wsl = get_c_compiler()
    if not bin then
      return nil, nil, false
    end
    return string.format(
      '%s %s -o %s -Wall -Wextra',
      bin,
      sh_escape(target_file, not use_wsl),
      sh_escape(target_exe, not use_wsl)
    ),
      'GCC',
      not use_wsl
  elseif ext == 'cpp' or ext == 'cc' or ext == 'cxx' then
    local bin, use_wsl = get_cpp_compiler()
    if not bin then
      return nil, nil, false
    end
    return string.format(
      '%s %s -o %s -Wall -Wextra',
      bin,
      sh_escape(target_file, not use_wsl),
      sh_escape(target_exe, not use_wsl)
    ),
      'G++',
      not use_wsl
  elseif ext == 'asm' or ext == 's' or ext == 'nasm' then
    -- On force WSL pour l'ASM car nasm -f elf64 est spécifique à Linux
    if is_windows and vim.fn.executable('wsl') == 1 then
      -- 'rm -f' supprime les anciens fichiers pour éviter l'erreur "unable to open output"
      return string.format(
        'rm -f %s %s && nasm -f elf64 %s -o %s && ld %s -o %s',
        sh_escape(target_obj),
        sh_escape(target_exe),
        sh_escape(target_file),
        sh_escape(target_obj),
        sh_escape(target_obj),
        sh_escape(target_exe)
      ),
        'NASM (WSL)',
        false
    end
    -- Fallback natif (si nasm est installé sous Windows)
    if vim.fn.executable('nasm') == 1 then
      return string.format(
        'nasm -f win64 %s -o %s',
        sh_escape(target_file, true),
        sh_escape(target_obj, true)
      ),
        'NASM (Windows)',
        true
    end
    return nil, nil, false
  elseif ext == 'py' then
    if vim.fn.executable('python') == 1 or vim.fn.executable('python3') == 1 then
      return string.format('python %s', sh_escape(target_file, true)), 'Python', true
    end
    return nil, nil, false
  end
  return nil, nil, false
end

-- ==========================================================================
-- GESTION DU TERMINAL
-- ==========================================================================
local function execute_in_terminal(cmd)
  local snacks = require('snacks')

  -- 1. On cherche d'abord une fenêtre qui affiche déjà un terminal
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == 'terminal' then
      local job_id = vim.b[buf].terminal_job_id
      if job_id then
        -- On utilise CE terminal
        vim.api.nvim_chan_send(job_id, cmd .. '\r')
        -- On donne le focus à cette fenêtre spécifique
        vim.api.nvim_set_current_win(win)
        vim.cmd('startinsert')
        return true
      end
    end
  end

  -- 2. Si aucun terminal n'est visible, on en ouvre un nouveau (pwsh)
  local term_win = snacks.terminal.open('pwsh', {
    win = { position = 'bottom', height = 0.4 },
  })

  if term_win and term_win.buf and vim.api.nvim_buf_is_valid(term_win.buf) then
    local job_id = vim.b[term_win.buf].terminal_job_id
    if job_id then
      vim.api.nvim_chan_send(job_id, cmd .. '\r')
      return true
    end
  end

  return false
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

  local is_python = (ext == 'py')
  local use_wsl = false

  if ext == 'c' then
    local _, w = get_c_compiler()
    use_wsl = w
  elseif ext == 'cpp' or ext == 'cc' or ext == 'cxx' then
    local _, w = get_cpp_compiler()
    use_wsl = w
  elseif ext == 'asm' or ext == 's' or ext == 'nasm' then
    -- On force WSL si dispo (comme dans build_compile_command)
    use_wsl = is_windows and vim.fn.executable('wsl') == 1
  end

  local target_file = (is_python or not use_wsl) and file or to_wsl(file)
  local target_exe = (is_python or not use_wsl) and vim.fn.expand('%:p:r')
    or to_wsl(vim.fn.expand('%:p:r'))
  local target_obj = (is_python or not use_wsl) and (vim.fn.expand('%:p:r') .. '.o')
    or to_wsl(vim.fn.expand('%:p:r') .. '.o')

  local compile_cmd, title, is_native =
    build_compile_command(target_file, target_exe, target_obj, ext)

  if not compile_cmd then
    vim.notify(
      'Compilateur introuvable pour .' .. ext .. '. Installez GCC/G++ (natif ou WSL).',
      vim.log.levels.ERROR
    )
    return
  end

  vim.cmd('wall')
  vim.notify(
    (run_after and 'Exécution' or 'Compilation') .. ' de ' .. vim.fn.expand('%:t') .. '...',
    vim.log.levels.INFO,
    { title = title }
  )

  local final_cmd
  if is_native then
    -- Mode natif Windows
    if run_after then
      final_cmd = compile_cmd
        .. ' ; if ($LASTEXITCODE -eq 0) { cmd.exe /c "'
        .. target_exe
        .. '" } ; Write-Host "`n--- [Terminé] ---"'
    else
      final_cmd = compile_cmd .. ' ; Write-Host "`n--- [Compilation terminée] ---"'
    end
  else
    -- Mode WSL ou Python natif direct
    if is_python then
      final_cmd = compile_cmd .. "; Write-Host '`n--- [Terminé] ---'"
    else
      local wsl_body
      if run_after then
        wsl_body = compile_cmd
          .. ' && '
          .. sh_escape(target_exe)
          .. " && echo -e '\\n--- [Terminé] ---' || echo -e '\\n--- [Échec] ---'"
      else
        wsl_body = compile_cmd
          .. " && echo -e '\\n--- [Compilation OK] ---' || echo -e '\\n--- [Échec compilation] ---'"
      end
      local escaped_body = wsl_body:gsub('"', '\\"')
      final_cmd = 'wsl.exe bash -c "' .. escaped_body .. '"'
    end
  end

  if not execute_in_terminal(final_cmd) then
    vim.notify('Impossible de trouver ou créer un terminal', vim.log.levels.ERROR)
  end
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
