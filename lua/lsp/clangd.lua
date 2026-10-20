-- ============================================================================
-- LSP : clangd
-- ============================================================================

local env = require('utils.env')

-- Construction de la liste des compilateurs pour --query-driver
local drivers = env.get_query_driver()

-- CORRECTION CRITIQUE POUR WINDOWS :
-- clangd en mode LSP est très strict sur les chemins passés dans --query-driver.
-- Les extensions en majuscules (.EXE) font échouer la résolution.
local query_driver_args = {}
for _, d in ipairs(drivers) do
    -- On force l'extension en minuscules
    local normalized = d:gsub('%.EXE$', '.exe')
    table.insert(query_driver_args, normalized)
end

-- Construction de la commande clangd
local cmd = { 'clangd', '--background-index' }

if #query_driver_args > 0 then
    local qd_str = table.concat(query_driver_args, ',')
    -- Ajout de l'argument
    table.insert(cmd, '--query-driver=' .. qd_str)

    -- Optionnel : log pour vérifier ce que clangd reçoit exactement
    if vim.g.debug_mode then
        vim.notify('clangd cmd : ' .. table.concat(cmd, ' '), vim.log.levels.INFO)
    end
end

return {
    cmd = cmd,

    filetypes = {
        'c',
        'cpp',
        'objc',
        'objcpp',
        'cuda',
    },
}
