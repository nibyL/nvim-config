-- ============================================================================
-- CHARGEMENT SÉCURISÉ DE MODULES
-- ============================================================================
-- Contrat strict :
--   mode = 'fatal'    → échec : message + cq (Neovim refuse de démarrer)
--   mode = 'warn'     → échec : notify ERROR + registre (démarrage dégradé)
--   mode = 'optional' → échec : notify WARN  + registre (confort)
--
-- Défaut (sans opts) : 'warn'. Un module requis doit être fatal explicitement.
-- Registre consommé par utils.health via get_failures() / get_setup_failures().
-- ============================================================================

local M = {}

local VALID_MODES = { fatal = true, warn = true, optional = true }
local DEFAULT_MODE = 'warn'

-- Registres module-level (closures, pas vim.g qui ne préserve pas les tables)
local load_failures = {}
local setup_failures = {}

local function record_load_failure(name, err, mode)
    if load_failures[name] then
        return -- idempotent
    end
    load_failures[name] = {
        error = tostring(err),
        mode = mode,
        timestamp = os.time(),
    }
end

local function emit(msg, level, title)
    -- Silence total en headless (CI, scripts)
    if #vim.api.nvim_list_uis() == 0 then
        return
    end

    local ok, notify = pcall(require, 'utils.notify')
    if ok and notify then
        if level >= vim.log.levels.ERROR then
            notify.error(msg, title)
        else
            notify.warn(msg, title)
        end
    else
        vim.notify(msg, level, { title = title })
    end
end

-- ----------------------------------------------------------------------------
-- API PUBLIQUE
-- ----------------------------------------------------------------------------

--- Charge un module avec contrat strict.
--- @param module_name string
--- @param opts? { mode?: 'fatal'|'warn'|'optional' }
--- @return table|nil
function M.require(module_name, opts)
    opts = opts or {}
    local mode = opts.mode or DEFAULT_MODE

    if not VALID_MODES[mode] then
        error(
            ('safe.require: mode invalide "%s" (attendu: fatal|warn|optional)'):format(tostring(mode)),
            2
        )
    end

    local ok, result = pcall(require, module_name)
    if ok then
        return result
    end

    record_load_failure(module_name, result, mode)

    if mode == 'fatal' then
        local msg = ('ERREUR FATALE : module requis "%s"\n%s'):format(module_name, tostring(result))

        -- 1. Écrire dans stderr (visible même quand l'UI Neovim se ferme instantanément)
        io.stderr:write('\n════════════════════════════════════════════════════════\n')
        io.stderr:write(' ' .. msg .. '\n')
        io.stderr:write('════════════════════════════════════════════════════════\n')
        io.stderr:write(' La configuration ne peut pas démarrer.\n\n')
        io.stderr:flush()

        -- 2. Écrire dans un fichier de log persistant
        local log = vim.fn.stdpath('log') .. '/startup.log'
        pcall(vim.fn.writefile, {
            ('[%s] FATAL %s'):format(os.date('%Y-%m-%d %H:%M:%S'), module_name),
            tostring(result),
            '',
        }, log, 'a')

        -- 3. Message dans l'UI Neovim (pour les terminaux qui le capturent)
        vim.api.nvim_echo({
            { '════════════════════════════════════════════════════════\n', 'ErrorMsg' },
            { (' ERREUR FATALE : module requis "%s"\n'):format(module_name), 'ErrorMsg' },
            { '════════════════════════════════════════════════════════\n', 'ErrorMsg' },
            { tostring(result) .. '\n', 'WarningMsg' },
            { '\n' },
            { ' Log : ' .. log .. '\n', 'Comment' },
            { ' La configuration ne peut pas démarrer.\n', 'Comment' },
        }, true, {})

        -- 4. Pause de 2s pour laisser le temps de lire (sauf si headless)
        if #vim.api.nvim_list_uis() > 0 then
            vim.cmd('sleep 2')
        end

        vim.cmd('cq')
        return nil
    end

    local label = mode == 'warn' and 'Module requis indisponible' or 'Module optionnel indisponible'
    local level = mode == 'warn' and vim.log.levels.ERROR or vim.log.levels.WARN
    emit(('%s : %s\n%s'):format(label, module_name, tostring(result)), level, 'Chargement')
    return nil
end

--- Exécute une fonction (typiquement un .setup()) en isolant l'erreur.
--- Enregistre l'échec dans setup_failures pour :checkhealth monprofil.
--- @param name string Identifiant lisible (ex: 'plugins.ui:snacks')
--- @param fn function
--- @return boolean ok
function M.call(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        setup_failures[name] = {
            error = tostring(err),
            timestamp = os.time(),
        }
        emit(('Échec de %s :\n%s'):format(name, tostring(err)), vim.log.levels.ERROR, 'Setup')
    end
    return ok
end

--- @return table<string, {error:string, mode:string, timestamp:number}>
function M.get_failures()
    return load_failures
end

--- @return table<string, {error:string, timestamp:number}>
function M.get_setup_failures()
    return setup_failures
end

--- Vide les registres (tests uniquement).
function M._reset()
    load_failures = {}
    setup_failures = {}
end

return M
