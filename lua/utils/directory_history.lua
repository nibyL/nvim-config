-- ============================================================================
-- HISTORIQUE DES DOSSIERS VISITÉS (Version Ultra-Compacte)
-- ============================================================================

local MAX_HISTORY = 100
local HISTORY_FILE = vim.fs.joinpath(vim.fn.stdpath("state"), "directory_history")
local history = {}

-- LECTURE
if vim.fn.filereadable(HISTORY_FILE) == 1 then
    for _, dir in ipairs(vim.fn.readfile(HISTORY_FILE)) do
        if dir ~= "" and vim.fn.isdirectory(dir) == 1 and #history < MAX_HISTORY then
            table.insert(history, dir)
        end
    end
end

-- AJOUT + ÉCRITURE SÛRE
local function add_directory_to_history(dir)
    dir = vim.fn.fnamemodify(dir, ":p")
    
    -- Filtrer les doublons et reconstruire la table proprement
    history = vim.tbl_filter(function(v) return v ~= dir end, history)
    table.insert(history, 1, dir)
    if #history > MAX_HISTORY then table.remove(history) end

    local ok, err = pcall(vim.fn.writefile, history, HISTORY_FILE, "s")
    if not ok then
        vim.notify("Erreur sauvegarde historique : " .. tostring(err), vim.log.levels.ERROR, { title = "Directory History" })
    end
end

-- SURVEILLANCE & DÉMARRAGE
add_directory_to_history(vim.fn.getcwd())

vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("DirectoryHistory", { clear = true }),
    desc = "Enregistrer les dossiers visités",
    callback = function() add_directory_to_history(vim.fn.getcwd()) end,
})

-- PICKER SNACKS
local function pick()
    local items = {}

    for _, dir in ipairs(history) do
        if vim.fn.isdirectory(dir) == 1 then
            items[#items + 1] = { text = dir, file = dir }
        end
    end

    require("snacks").picker({
        title = "Dossiers visités",
        items = items,
        confirm = function(picker, item)
            picker:close()
            if item and item.file then
                vim.cmd("cd " .. vim.fn.fnameescape(item.file))
                vim.notify(
                    "Workspace ➔ " .. item.file,
                    vim.log.levels.INFO,
                    { title = "CD" }
                )
            end
        end,
    })
end

return { pick = pick }
