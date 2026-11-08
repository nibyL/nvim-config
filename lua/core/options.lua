-- ============================================================================
-- OPTIONS
-- ============================================================================

local env = require('utils.env')

-- ----------------------------------------------------------------------------
-- Environnement portable (Windows / Linux / macOS / WSL)
-- ----------------------------------------------------------------------------
local safe = require('utils.safe')
safe.call('core.options:env.setup', function()
  env.setup()
end)
env.ensure_snacks_dir() -- Fix bug snacks lazygit
-- ----------------------------------------------------------------------------
-- LEADER KEY (Doit être défini AVANT les plugins)
-- ----------------------------------------------------------------------------
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- ----------------------------------------------------------------------------
-- OPTIONS GÉNÉRALES
-- ----------------------------------------------------------------------------
vim.o.number = true
vim.o.relativenumber = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.list = true
vim.o.confirm = true
vim.o.updatetime = 300
vim.o.winborder = 'rounded'
vim.o.clipboard = 'unnamedplus'
vim.o.showmode = false
vim.o.background = 'dark'

vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.o.autoindent = true
vim.o.smartindent = true
vim.opt.keymodel = 'startsel,stopsel'
vim.opt.selectmode = 'mouse,key'

-- ----------------------------------------------------------------------------
-- APPARENCE DE BASE (Force le fond coloré même sans thème)
-- ----------------------------------------------------------------------------
local fallback_bg_main = '#121212'
local fallback_bg_float = '#040202'

vim.o.termguicolors = true

vim.api.nvim_set_hl(0, 'Normal', { bg = fallback_bg_main })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = fallback_bg_float })

vim.api.nvim_create_autocmd('ColorScheme', {
  desc = 'Forcer le fond coloré même avec le thème par défaut',
  callback = function()
    if vim.g.colors_name == nil or vim.g.colors_name == 'default' then
      vim.api.nvim_set_hl(0, 'Normal', { bg = fallback_bg_main })
      vim.api.nvim_set_hl(0, 'NormalFloat', { bg = fallback_bg_float })
    end
  end,
})
