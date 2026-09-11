-- ============================================================================
-- COMPILATION / EXÉCUTION (C, C++, ASM) — Version optimisée
-- ============================================================================

local is_windows = vim.uv.os_uname().sysname:find('Windows') ~= nil

-- ==========================================================================
-- FONCTIONS AUXILIAIRES
-- ==========================================================================

-- Conversion d'un chemin Windows (C:\foo\bar) vers WSL (/mnt/c/foo/bar)
local function to_wsl(win_path)
  if not is_windows then return win_path end
  local path = win_path:gsub('\\', '/')
  path = path:gsub('^([A-Za-z]):', function(drive)
    return '/mnt/' .. drive:lower()
  end)
  return path
end

-- Échappement POSIX pour un chemin (gère espaces et apostrophes)
local function sh_escape(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

-- --------------------------------------------------------------------------
-- Terminal persistant (évite de recréer un buffer à chaque F5)
-- --------------------------------------------------------------------------
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

-- Envoie une commande (string) au shell WSL/Linux dans le terminal persistant
local function run_in_terminal(shell_cmd)
  local buf = open_terminal()

  local job = vim.b[buf].terminal_job_id
  if not job then
    local shell = is_windows and { "wsl.exe", "-e", "bash" } or { "bash" }
    vim.fn.jobstart(shell, { term = true, bufnr = buf })
  end

  vim.api.nvim_chan_send(vim.b[buf].terminal_job_id, shell_cmd .. "\r")
end

-- ==========================================================================
-- CONSTRUCTION DES COMMANDES
-- ==========================================================================

local function build_compile_command(target_file, target_exe, target_obj, ext)
  if ext == 'c' then
    return string.format("gcc %s -o %s -Wall -Wextra",
      sh_escape(target_file), sh_escape(target_exe)), "GCC"

  elseif ext == 'cpp' or ext == 'cc' or ext == 'cxx' then
    return string.format("g++ %s -o %s -Wall -Wextra",
      sh_escape(target_file), sh_escape(target_exe)), "G++"

  elseif ext == 'asm' or ext == 's' or ext == 'nasm' then
    return string.format(
      "nasm -f elf64 %s -o %s && ld %s -o %s",
      sh_escape(target_file), sh_escape(target_obj),
      sh_escape(target_obj),  sh_escape(target_exe)
    ), "NASM"
  end

  return nil, nil
end

-- ==========================================================================
-- FONCTION PRINCIPALE
-- ==========================================================================

local function compile_and_run(run_after)
  local file = vim.fn.expand('%:p')

  if file == '' then
    vim.notify('Aucun fichier à compiler', vim.log.levels.WARN, { title = 'Compilation' })
    return
  end

  local ext = vim.fn.expand('%:e'):lower()
  local target_file = to_wsl(file)
  local target_exe  = to_wsl(vim.fn.expand('%:p:r'))
  local target_obj  = to_wsl(vim.fn.expand('%:p:r') .. ".o")

  local compile_cmd, title = build_compile_command(target_file, target_exe, target_obj, ext)
  if not compile_cmd then
    vim.notify('Type non supporté: .' .. ext, vim.log.levels.WARN)
    return
  end

  vim.cmd('wall')

  -- Message de notification
  vim.notify(
    (run_after and 'Compilation + exécution' or 'Compilation')
      .. ' de ' .. vim.fn.expand('%:t') .. '...',
    vim.log.levels.INFO,
    { title = title .. (is_windows and ' (WSL)' or '') }
  )

  -- Commande finale : tout est groupé dans UN SEUL bash -c
  local final_cmd
  if run_after then
    final_cmd = compile_cmd
      .. " && " .. sh_escape(target_exe)
      .. " && echo -e '\\n--- [Terminé] ---'"
      .. " || echo -e '\\n--- [Échec] ---'"
  else
    final_cmd = compile_cmd
      .. " && echo -e '\\n--- [Compilation OK] ---'"
      .. " || echo -e '\\n--- [Échec compilation] ---'"
  end

  run_in_terminal(final_cmd)
end

-- ==========================================================================
-- RACCOURCIS
-- ==========================================================================
vim.keymap.set('n', '<F5>', function() compile_and_run(true) end,  { desc = 'Compiler & Exécuter' })
vim.keymap.set('n', '<F6>', function() compile_and_run(false) end, { desc = 'Compiler uniquement' })
