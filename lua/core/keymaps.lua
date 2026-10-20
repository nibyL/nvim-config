-- ============================================================================
-- RACCOURCIS GÉNÉRAUX
-- ============================================================================

-- ============================================================================
-- TERMINAL
-- ============================================================================

-- TERMINAL SNACKS (Terminal flottant ultra-moderne avec PowerShell 7.7)
vim.keymap.set({ 'n', 't' }, '<leader>tt', function()
  require('snacks').terminal.toggle('pwsh', {
    win = {
      position = 'bottom', -- Place le terminal en bas comme VS Code
      height = 0.4, -- Prend 40% de la hauteur de l'écran
    },
  })
end, { desc = 'Ouvrir/Masquer le terminal PowerShell (Bas)' })

-- ============================================================================
-- NAVIGATION ENTRE LES FENÊTRES
-- ============================================================================

for _, dir in ipairs({ 'h', 'j', 'k', 'l' }) do
  -- Mode Normal
  vim.keymap.set('n', '<A-' .. dir .. '>', '<C-w>' .. dir, { desc = 'Fenêtre ' .. dir })

  -- Mode Insertion
  vim.keymap.set('i', '<A-' .. dir .. '>', '<C-o><C-w>' .. dir, { desc = 'Fenêtre ' .. dir })

  -- Mode Terminal
  vim.keymap.set('t', '<A-' .. dir .. '>', '<C-\\><C-n><C-w>' .. dir, { desc = 'Fenêtre ' .. dir })
end

-- ============================================================================
-- SÉLECTEUR DE THÈME VISUEL (Espace + t + h)
-- ============================================================================

local state_file = vim.fn.stdpath('data') .. '/theme_state'

vim.keymap.set('n', '<leader>th', function()
  require('snacks').picker.colorschemes({
    confirm = function(picker, item)
      local theme = item.text

      picker:close()
      picker.preview.state.colorscheme = nil

      vim.schedule(function()
        vim.cmd.colorscheme(theme)
        vim.fn.writefile({ theme }, state_file)

        -- Notification de confirmation
        vim.notify('Thème appliqué : ' .. theme, vim.log.levels.INFO, { title = 'Thème' })
      end)
    end,
  })
end, { desc = 'Sélecteur de thème' })

-- ============================================================================
-- GESTION DES DOSSIERS ET FICHIERS (Recherche, formatage, sélecteur)
-- ============================================================================

-- Ctrl+A : sélectionner tout le fichier
vim.keymap.set('n', '<C-a>', 'ggVG', {
  desc = 'Sélectionner tout le fichier',
})

vim.keymap.set('i', '<C-a>', '<Esc>ggVG', {
  desc = 'Sélectionner tout le fichier',
})

vim.keymap.set({ 'v', 'x', 's' }, '<C-a>', 'ggVG', {
  desc = 'Sélectionner tout le fichier',
})
--Recherche de dossiers dans l'historique des dossiers ouverts
vim.keymap.set('n', '<leader>fd', function()
  require('utils.directory_history').pick()
end, {
  desc = 'Historique des dossiers visités',
})

--Recherche de fichiers dans le projet courant et l'historique des fichiers ouverts
vim.keymap.set('n', '<leader>ff', function()
  local root = vim.fn.getcwd()

  require('snacks').picker({
    title = '📂 Dossier courant + 🌍 Historique Global',

    multi = {
      {
        source = 'files',
        cwd = root,
      },
      {
        source = 'recent',
      },
    },

    transform = function(item, ctx)
      return require('snacks.picker.transform').unique_file(item, ctx)
    end,
  })
end, { desc = 'Fichiers (Dossier + Historique)' })

-- Recherche de texte dans tout le projet (grep)
vim.keymap.set('n', '<leader>sg', function()
  local root = vim.fs.root(0, '.git') or vim.fn.getcwd()
  require('snacks').picker.grep({
    cwd = root,
  })
end, { desc = 'Chercher du texte dans le projet' })

-- Sélecteur de buffers ouverts (quand vous avez 10+ fichiers)
vim.keymap.set('n', '<leader>fb', function()
  require('snacks').picker.buffers()
end, { desc = 'Changer de buffer ouvert' })

-- Explorateur de fichiers latéral (pour voir l'arborescence)
vim.keymap.set('n', '<leader>e', function()
  local explorer = require('snacks').explorer
  if explorer.win and explorer.win:is_valid() then
    explorer.close()
  else
    explorer.open()
  end
end, { desc = 'Explorateur de fichiers (toggle)' })

-- Navigation ultra-rapide (une seule main, pas besoin de quitter la ligne de base)
vim.keymap.set('n', 'L', ':bnext<CR>', { desc = 'Buffer suivant' })
vim.keymap.set('n', 'H', ':bprevious<CR>', { desc = 'Buffer précédent' })

-- Formatage via LSP
vim.keymap.set('n', '<leader>fm', function()
  vim.lsp.buf.format({ async = true })
end, { desc = 'Formater le code' })

-- Recherche de fichiers sur tout le disque (racines détectées dynamiquement)
vim.keymap.set('n', '<leader>fR', function()
  local roots = require('utils.env').get_disk_roots()
  if #roots == 0 then
    vim.notify('Aucune racine disque trouvée', vim.log.levels.WARN)
    return
  end

  require('snacks').picker.files({
    dirs = roots,
    find_command = {
      'fd',
      '-tf',
      '-E',
      '.git',
      '-E',
      'node_modules',
      '-E',
      '*.exe',
      '-E',
      '*.dll',
    },
  })
end, { desc = 'Recherche fichiers (disques)' })

-- Recherche de dossiers sur tout le disque (racines détectées dynamiquement)
vim.keymap.set('n', '<leader>fD', function()
  local roots = require('utils.env').get_disk_roots()
  if #roots == 0 then
    vim.notify('Aucune racine disque trouvée', vim.log.levels.WARN)
    return
  end

  local all_items = {}
  local pending = #roots

  -- Options fd communes
  local fd_args = {
    '--type',
    'd',
    '--color',
    'never',
    '--exclude',
    '.git',
    '--exclude',
    'node_modules',
    '--exclude',
    'AppData',
    '--exclude',
    'Windows',
    '--exclude',
    'Program Files',
    '--exclude',
    'Program Files (x86)',
    '--exclude',
    '$Recycle.Bin',
    '--exclude',
    'System Volume Information',
    '--exclude',
    'DumpStack.log',
    '--exclude',
    'pagefile.sys',
    '--exclude',
    'hiberfil.sys',
    '--exclude',
    'swapfile.sys',
    '.',
  }

  -- Lance fd en parallèle sur chaque disque
  for _, root in ipairs(roots) do
    local r = root
    vim.fn.jobstart(vim.list_extend({ 'fd' }, fd_args), {
      cwd = r,
      stdout_buffered = true,
      on_stdout = function(_, data)
        if not data then
          return
        end
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(all_items, {
              text = line,
              file = vim.fs.joinpath(r, line),
            })
          end
        end
      end,
      on_exit = function()
        pending = pending - 1
        if pending == 0 then
          -- Tous les fd sont finis → ouvre le picker
          vim.schedule(function()
            if #all_items == 0 then
              vim.notify('Aucun dossier trouvé', vim.log.levels.WARN)
              return
            end

            require('snacks').picker({
              title = 'Dossiers (' .. table.concat(roots, ', ') .. ')',
              items = all_items,
              format = 'file',
              confirm = function(picker, item)
                picker:close()
                if item and item.file then
                  vim.cmd('cd ' .. vim.fn.fnameescape(item.file))
                end
              end,
            })
          end)
        end
      end,
    })
  end
end, { desc = 'Changer dossier (tous disques)' })

-- Fermer la fenêtre active (mode Normal ET mode Terminal)
vim.keymap.set({ 'n', 't' }, '<leader>q', function()
  local buf = vim.api.nvim_get_current_buf()
  local mode = vim.api.nvim_get_mode().mode

  -- Sortir du mode terminal si nécessaire
  if mode == 't' then
    vim.cmd('stopinsert')
  end

  -- Buffer terminal : envoyer `exit` et LAISSER NEOVIM nettoyer
  if vim.bo[buf].buftype == 'terminal' then
    local job_id = vim.b[buf].terminal_job_id
    if job_id then
      vim.api.nvim_chan_send(job_id, 'exit\r')
    end
    -- Ne PAS forcer la fermeture : Neovim fermera le buffer
    -- automatiquement quand le shell quittera (TermClose)
    return
  end

  -- Buffer normal : fermer proprement
  local wins = vim.api.nvim_tabpage_list_wins(0)
  if #wins > 1 then
    vim.cmd('close')
  else
    vim.cmd('bd')
  end
end, { desc = 'Fermer le buffer ou le terminal proprement' })

-- ============================================================================
-- LAZYGIT (Interface Git visuelle)
-- ============================================================================
vim.keymap.set('n', '<leader>lg', function()
  require('snacks').lazygit()
end, { desc = 'Ouvrir Lazygit' })

-- ============================================================================
-- RACCOURCIS POUR LES COMMENTAIRES (Natif Neovim 0.10+)
-- ============================================================================

vim.keymap.set('n', '<leader>/', 'gcc', { remap = true, desc = 'Commenter la ligne' })
vim.keymap.set('v', '<leader>/', 'gc', { remap = true, desc = 'Commenter la sélection' })
