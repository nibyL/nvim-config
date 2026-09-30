-- ============================================================================
-- UI & OUTILS
-- ============================================================================

-- ============================================================================
-- AUTOPAIRS
-- ============================================================================

require('nvim-autopairs').setup({})

-- ============================================================================
-- QUICKFIX / LOCATION LIST
-- ============================================================================

require('quicker').setup({})

-- ============================================================================
-- GITSIGNS
-- ============================================================================

require('gitsigns').setup({})

-- ============================================================================
-- SNACKS
-- ============================================================================

require('snacks').setup({
  terminal = {
    enabled = true,
    cmd = 'pwsh',
    win = {
      keys = {
        -- Raccourci d'origine pour passer en mode normal reste intact
        term_normal = { '<Esc>', '<C-\\><C-n>', mode = 't', desc = 'Quitter le mode terminal' },
      },
    },
  },

  picker = {
    enabled = true,
    hidden = true,
    ignored = true,

    sources = {
      hybrid = {
        name = 'hybrid',
        title = '📂 Projet + 🌍 Historique Global',
        multi = {
          {
            source = 'files',
            cwd = function()
              return vim.fs.root(0, '.git') or vim.fn.getcwd()
            end,
          },
          { source = 'recent' },
        },
        transform = function(item, ctx)
          return require('snacks.picker.transform').unique_file(item, ctx)
        end,
      },
    },
  },
})

-- ============================================================================
-- SNACKS + :RESTART
-- ============================================================================

vim.api.nvim_create_autocmd('ExitPre', {
  desc = 'Préparer Snacks avant :restart',
  callback = function()
    if not vim.v.exitreason:match('^restart') then
      return
    end

    local snacks = require('snacks')

    for _, term in ipairs(snacks.terminal.list()) do
      if term.augroup then
        for _, ac in
          ipairs(vim.api.nvim_get_autocmds({
            group = term.augroup,
            event = 'ExitPre',
          }))
        do
          pcall(vim.api.nvim_del_autocmd, ac.id)
        end
      end
    end
  end,
})

-- ============================================================================
-- THÈME PERSISTANT
-- ============================================================================

local state_file = vim.fn.stdpath('data') .. '/theme_state'
local my_theme = 'dark2026'

local saved_theme = my_theme
if vim.fn.filereadable(state_file) == 1 then
  local ok, lines = pcall(vim.fn.readfile, state_file)
  if ok and lines and lines[1] and lines[1] ~= '' then
    saved_theme = lines[1]
  end
end

local ok_theme, err_theme = pcall(vim.cmd.colorscheme, saved_theme)
if not ok_theme then
  vim.notify(
    'Thème "' .. saved_theme .. '" introuvable, fallback habamax.\n' .. tostring(err_theme),
    vim.log.levels.WARN,
    { title = 'Thème' }
  )
  pcall(vim.cmd.colorscheme, 'habamax')
end
