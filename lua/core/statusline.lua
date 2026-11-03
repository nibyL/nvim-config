-- ============================================================================
-- STATUSLINE NATIVE
-- ============================================================================

vim.opt.laststatus = 3

-- ============================================================================
-- COULEURS (Encapsulées pour éviter l'écrasement par le thème)
-- ============================================================================

local function apply_statusline_colors()
  vim.api.nvim_set_hl(0, 'StatusLine', {
    fg = '#cdd6f4',
    bg = '#1e1e2e',
  })

  vim.api.nvim_set_hl(0, 'StatusLineNC', {
    fg = '#6c7086',
    bg = '#181825',
  })

  vim.api.nvim_set_hl(0, 'StatusModeNormal', {
    fg = '#11111b',
    bg = '#a6e3a1',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusModeInsert', {
    fg = '#11111b',
    bg = '#89b4fa',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusModeVisual', {
    fg = '#11111b',
    bg = '#cba6f7',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusModeCommand', {
    fg = '#11111b',
    bg = '#f9e2af',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusModeReplace', {
    fg = '#11111b',
    bg = '#f38ba8',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusModeTerminal', {
    fg = '#11111b',
    bg = '#94e2d5',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusFile', {
    fg = '#cdd6f4',
    bg = '#313244',
  })

  vim.api.nvim_set_hl(0, 'StatusModified', {
    fg = '#f9e2af',
    bg = '#313244',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusDiagnosticError', {
    fg = '#f38ba8',
    bg = '#1e1e2e',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusDiagnosticWarn', {
    fg = '#f9e2af',
    bg = '#1e1e2e',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusInfo', {
    fg = '#bac2de',
    bg = '#1e1e2e',
  })
end

-- 1. Appliquer les couleurs immédiatement au chargement
apply_statusline_colors()

-- 2. LA MAGIE : Réappliquer les couleurs à chaque fois qu'un thème est chargé
-- C'est ce qui règle définitivement le bug d'écrasement au démarrage !
vim.api.nvim_create_autocmd('ColorScheme', {
  desc = 'Réappliquer les couleurs de la statusline après un changement de thème',
  callback = apply_statusline_colors,
})

-- ============================================================================
-- MODE
-- ============================================================================

local function status_mode()
  local mode = vim.api.nvim_get_mode().mode

  local names = {
    n = ' NORMAL ',
    i = ' INSERT ',
    v = ' VISUAL ',
    V = ' V-LINE ',
    ['\22'] = ' V-BLOCK ',
    c = ' COMMAND ',
    R = ' REPLACE ',
    t = ' TERMINAL ',
    s = ' SELECT ',
    S = ' S-LINE ',
  }

  local groups = {
    n = 'StatusModeNormal',
    i = 'StatusModeInsert',
    v = 'StatusModeVisual',
    V = 'StatusModeVisual',
    ['\22'] = 'StatusModeVisual',
    c = 'StatusModeCommand',
    R = 'StatusModeReplace',
    t = 'StatusModeTerminal',
    s = 'StatusModeVisual',
    S = 'StatusModeVisual',
  }

  return '%#' .. (groups[mode] or 'StatusModeNormal') .. '#' .. (names[mode] or ' NORMAL ') .. '%*'
end

-- ============================================================================
-- DIAGNOSTICS (Optimisé : 0 allocation de tableau, appel C natif)
-- ============================================================================

local function status_diagnostics()
  -- Récupération directe et instantanée des comptes
  local counts = vim.diagnostic.count(0)
  local errors = counts[vim.diagnostic.severity.ERROR] or 0
  local warnings = counts[vim.diagnostic.severity.WARN] or 0

  local result = ''

  if errors > 0 then
    result = result .. '%#StatusDiagnosticError# E:' .. errors .. '%*'
  end

  if warnings > 0 then
    result = result .. '%#StatusDiagnosticWarn# W:' .. warnings .. '%*'
  end

  return result
end

-- ============================================================================
-- FICHIER
-- ============================================================================

local function status_filename()
  local filename = vim.fn.expand('%:t')

  if filename == '' then
    filename = '[No Name]'
  end

  local result = '%#StatusFile#' .. ' ' .. filename .. ' '

  if vim.bo.modified then
    result = result .. '%#StatusModified#' .. '[+]' .. '%*'
  end

  if vim.bo.readonly then
    result = result .. ' RO'
  end

  return result .. '%*'
end

-- ============================================================================
-- ENCODAGE
-- ============================================================================

local function status_encoding()
  local encoding = vim.bo.fileencoding

  if encoding == '' then
    encoding = vim.o.encoding
  end

  return encoding
end

-- ============================================================================
-- STATUSLINE
-- ============================================================================

local function render_statusline()
  return table.concat({
    status_mode(),
    status_filename(),

    '%=',

    status_diagnostics(),

    '%#StatusInfo#',
    ' ',
    vim.bo.filetype ~= '' and vim.bo.filetype or 'text',
    ' │ ',
    status_encoding(),
    ' [',
    vim.bo.fileformat,
    '] ',
    '%l:%c',
    ' │ ',
    '%p%% ',
    '%*',
  })
end

-- On expose la fonction via vim.g pour que `%{%v:lua...%}` puisse l'appeler
vim.g.Statusline = render_statusline
vim.opt.statusline = '%{%v:lua.vim.g.Statusline()%}'
