-- ============================================================================
-- HISTORIQUE DES DOSSIERS VISITÉS
-- ============================================================================

local MAX_HISTORY = 100
local HISTORY_FILE = vim.fs.joinpath(vim.fn.stdpath('state'), 'directory_history')
local history = {}

-- Charger l'historique
if vim.fn.filereadable(HISTORY_FILE) == 1 then
  for _, dir in ipairs(vim.fn.readfile(HISTORY_FILE)) do
    dir = vim.fs.normalize(dir)
    if dir ~= '' and vim.fn.isdirectory(dir) == 1 and not vim.tbl_contains(history, dir) then
      table.insert(history, dir)
    end

    if #history >= MAX_HISTORY then
      break
    end
  end
end

-- Ajouter le dossier en tête
local function add(dir)
  dir = vim.fs.normalize(vim.fn.fnamemodify(dir, ':p'))

  history = vim.tbl_filter(function(v)
    return v ~= dir
  end, history)

  table.insert(history, 1, dir)

  if #history > MAX_HISTORY then
    table.remove(history)
  end

  vim.fn.writefile(history, HISTORY_FILE, 's')
end

add(vim.fn.getcwd())

vim.api.nvim_create_autocmd('DirChanged', {
  group = vim.api.nvim_create_augroup('DirectoryHistory', { clear = true }),
  desc = 'Enregistrer les dossiers visités',
  callback = function()
    add(vim.fn.getcwd())
  end,
})

-- Picker
local function pick()
  local items = {}

  for _, dir in ipairs(history) do
    if vim.fn.isdirectory(dir) == 1 then
      items[#items + 1] = {
        text = dir,
        file = dir,
      }
    end
  end

  require('snacks').picker({
    title = 'Dossiers visités',
    items = items,
    format = 'file',
    confirm = function(picker, item)
      picker:close()
      if item and item.file then
        vim.cmd('cd ' .. vim.fn.fnameescape(item.file))
      end
    end,
  })
end

return { pick = pick }
