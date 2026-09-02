-- ============================================================================
-- COMPILATION / EXÉCUTION C ET C++
-- ============================================================================

-- ============================================================================
-- DÉTECTION DU SYSTÈME
-- ============================================================================

local is_windows = vim.uv.os_uname().sysname:find('Windows') ~= nil

-- ============================================================================
-- COMPILATION
-- ============================================================================

local function compile_and_run(run_after)
  local file = vim.fn.expand('%:p')

  -- Aucun fichier ouvert
  if file == '' then
    vim.notify(
      'Aucun fichier à compiler',
      vim.log.levels.WARN,
      { title = 'Compilation' }
    )
    return
  end

  local ext = vim.fn.expand('%:e'):lower()

  -- Détermine le compilateur
  local compiler

  if ext == 'c' then
    compiler = 'gcc'
  elseif ext == 'cpp' or ext == 'cc' or ext == 'cxx' then
    compiler = 'g++'
  else
    vim.notify(
      'Type de fichier non supporté : .' .. ext,
      vim.log.levels.WARN,
      { title = 'Compilation' }
    )
    return
  end

  -- Nom de l'exécutable
  local exe_ext = is_windows and '.exe' or ''
  local exe = vim.fn.expand('%:p:r') .. exe_ext

  -- Sauvegarde avant compilation
  vim.cmd('write')

  vim.notify(
    'Compilation de ' .. vim.fn.expand('%:t') .. '...',
    vim.log.levels.INFO,
    { title = compiler }
  )

  -- ==========================================================================
  -- COMPILATION ASYNCHRONE
  -- ==========================================================================

  vim.system(
    {
      compiler,
      file,
      '-o',
      exe,
      '-Wall',
      '-Wextra',
    },
    {
      text = true,
    },
    function(result)
      vim.schedule(function()

        -- ====================================================================
        -- ERREUR
        -- ====================================================================

        if result.code ~= 0 then
          local stderr = vim.trim(result.stderr or '')

          if stderr == '' then
            stderr = 'Erreur de compilation inconnue.'
          end

          vim.notify(
            stderr,
            vim.log.levels.ERROR,
            { title = 'Erreur ' .. compiler }
          )

          -- Envoyer les erreurs dans QuickFix
          vim.fn.setqflist({}, 'r', {
            title = 'Compilation ' .. compiler,
            lines = vim.split(
              stderr,
              '\n',
              { trimempty = true }
            ),
          })

          vim.cmd('copen')

          return
        end

        -- ====================================================================
        -- SUCCÈS
        -- ====================================================================

        vim.notify(
          'Compilation réussie',
          vim.log.levels.INFO,
          { title = compiler }
        )

        -- F6 : compilation uniquement
        if not run_after then
          return
        end

        -- ====================================================================
        -- TERMINAL INTÉGRÉ
        -- ====================================================================

        vim.cmd('botright 12split')

        local buf = vim.api.nvim_create_buf(false, true)

        vim.api.nvim_win_set_buf(
          vim.api.nvim_get_current_win(),
          buf
        )

        -- Lancer le programme
        vim.fn.termopen({ exe }, {
          on_exit = function()
            vim.schedule(function()
              if vim.api.nvim_buf_is_valid(buf) then
                vim.bo[buf].buflisted = false
              end
            end)
          end,
        })

        -- Entrée directement dans le terminal
        vim.cmd('startinsert')
      end)
    end
  )
end

-- ============================================================================
-- F5 : COMPILER + EXÉCUTER
-- ============================================================================

vim.keymap.set(
  'n',
  '<F5>',
  function()
    compile_and_run(true)
  end,
  {
    desc = 'Compiler et exécuter C/C++',
  }
)

-- ============================================================================
-- F6 : COMPILER UNIQUEMENT
-- ============================================================================

vim.keymap.set(
  'n',
  '<F6>',
  function()
    compile_and_run(false)
  end,
  {
    desc = 'Compiler C/C++',
  }
)
