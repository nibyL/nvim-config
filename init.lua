-- ============================================================================
-- Neovim 0.12+ - Configuration personnelle
-- ============================================================================
--- @diagnostic disable: undefined-global
-- ============================================================================
-- 1. LEADER KEY
-- ============================================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- ============================================================================
-- 2. OPTIONS GÉNÉRALES
-- ============================================================================
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

vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.keymodel = 'startsel,stopsel'
vim.opt.selectmode = 'mouse,key'

-- Fond sombre
vim.api.nvim_set_hl(0, 'Normal', { bg = '#0f0f0f' })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = '#000000' })

-- Thème
-- vim.cmd.colorscheme('dark2026')

-- ----------------------------------------------------------------------------
-- STATUSLINE NATIVE
-- ----------------------------------------------------------------------------

vim.opt.laststatus = 3

-- Couleurs

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

-- Fonctions dynamiques

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

    return '%#' .. (groups[mode] or 'StatusModeNormal') .. '#'
        .. (names[mode] or ' NORMAL ')
        .. '%*'
end

local function status_diagnostics()
    local errors = #vim.diagnostic.get(0, {
        severity = vim.diagnostic.severity.ERROR,
    })

    local warnings = #vim.diagnostic.get(0, {
        severity = vim.diagnostic.severity.WARN,
    })

    local result = ''

    if errors > 0 then
        result = result
            .. '%#StatusDiagnosticError#'
            .. ' E:' .. errors
            .. '%*'
    end

    if warnings > 0 then
        result = result
            .. '%#StatusDiagnosticWarn#'
            .. ' W:' .. warnings
            .. '%*'
    end

    return result
end

local function status_filename()
    local filename = vim.fn.expand('%:t')

    if filename == '' then
        filename = '[No Name]'
    end

    local result =
        '%#StatusFile#'
        .. ' '
        .. filename
        .. ' '

    if vim.bo.modified then
        result =
            result
            .. '%#StatusModified#'
            .. '[+]'
            .. '%*'
    end

    if vim.bo.readonly then
        result =
            result
            .. ' RO'
    end

    return result .. '%*'
end

local function status_encoding()
    local encoding = vim.bo.fileencoding

    if encoding == '' then
        encoding = vim.o.encoding
    end

    return encoding
end

-- Statusline

_G.native_statusline = function()
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

vim.opt.statusline = '%{%v:lua.native_statusline()%}'

-- ============================================================================
-- 3. PLUGINS
-- ============================================================================

vim.cmd('packadd! nohlsearch')

vim.pack.add({
    -- LSP
    'https://github.com/neovim/nvim-lspconfig',

    -- Interface / outils
    'https://github.com/folke/snacks.nvim',
    'https://github.com/rachartier/tiny-inline-diagnostic.nvim',
    'https://github.com/stevearc/quicker.nvim',
    'https://github.com/lewis6991/gitsigns.nvim',
    'https://github.com/windwp/nvim-autopairs',
    'https://github.com/ggandor/leap.nvim',

    -- Syntaxe
    'https://github.com/nvim-treesitter/nvim-treesitter',

    -- Autocomplétion
    'https://github.com/saghen/blink.lib',
    'https://github.com/saghen/blink.cmp',

    -- Thème
    'https://github.com/D0nw0r/dark2026.nvim',
})

-- ============================================================================
-- 4. DIAGNOSTICS
-- ============================================================================

vim.diagnostic.config({
    virtual_text = false,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = '●',
            [vim.diagnostic.severity.WARN] = '●',
            [vim.diagnostic.severity.INFO] = '●',
            [vim.diagnostic.severity.HINT] = '●',
        },
    },
})

-- ============================================================================
-- 5. INITIALISATION DES PLUGINS
-- ============================================================================

require('nvim-autopairs').setup({})
require('quicker').setup({})
require('gitsigns').setup({})

local snacks = require('snacks')

snacks.setup({
    picker = {
        enabled = true,
    },
    explorer = {
        enabled = true,
    },
    lazygit = {
        enabled = true,
    },
})

require('tiny-inline-diagnostic').setup({
    options = {
        multilines = {
            enabled = true,
        },
    },
    preset = 'ghost',
})

-- ============================================================================
-- 6. TREESITTER
-- ============================================================================

-- 1. Correctif Windows : Contourne le bug de l'espace dans "HP ELITE BOOK"
if vim.fn.has("win32") == 1 then
    local temp_dir = "C:\\Temp\\nvim"
    if vim.fn.isdirectory(temp_dir) == 0 then
        vim.fn.mkdir(temp_dir, "p")
    end
    vim.env.TMPDIR = temp_dir
    vim.env.TEMP = temp_dir
    vim.env.TMP = temp_dir
end

-- 2. Configuration officielle via le module de configuration Treesitter
local has_ts, ts_config = pcall(require, "nvim-treesitter.configs")
if has_ts then
    -- Configure l'ordre de priorité des compilateurs sous Windows
    require('nvim-treesitter.install').compilers = { 'gcc', 'clang' }

    ts_config.setup({
        -- Installe automatiquement ces parseurs s'ils sont manquants
        ensure_installed = {
            'c', 'cpp', 'lua', 'rust', 'javascript', 'typescript', 'html', 'css', 'json'
        },

        -- Synchronise l'installation au démarrage
        sync_install = false,
        auto_install = true,

        -- Active la coloration syntaxique Treesitter nativement
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        },

        -- Active l'indentation intelligente basée sur l'AST
        indent = {
            enable = true
        },
    })
end

-- 3. Autocommande pour le Folding (Pliage de code) Treesitter
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'c', 'cpp', 'lua', 'rust', 'javascript', 'typescript', 'html', 'css', 'json' },
    callback = function()
        -- Le surlignage démarre désormais via la table 'highlight' ci-dessus.
        -- On configure ici uniquement le pliage de code (folding).
        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.wo.foldmethod = 'expr'
        vim.wo.foldenable = false -- Évite que tout le code soit plié à l'ouverture
    end,
})


-- ============================================================================
-- 7. BLINK.CMP
-- ============================================================================

local blink = require('blink.cmp')

-- Construit la bibliothèque Rust uniquement si elle n'est pas disponible.
if not blink.library_available() then
    blink.build():pwait()
end

blink.setup({
    keymap = {
        -- Comportement proche de VS Code
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<Esc>'] = { 'cancel', 'fallback' },
        ['<C-Space>'] = { 'show', 'show_documentation', 'hide' },
    },

    completion = {
        accept = {
            auto_brackets = {
                enabled = true,
            },
        },
    },

    sources = {
        default = {
            'lsp',
            'path',
            'snippets',
            'buffer',
        },
    },

    fuzzy = {
        implementation = 'rust',
    },
})

-- ============================================================================
-- 8. LSP
-- ============================================================================

local capabilities = blink.get_lsp_capabilities()

-- --------------------------------------------------------------------------
-- clangd
-- --------------------------------------------------------------------------

vim.lsp.config('clangd', {
    capabilities = capabilities,

    filetypes = {
        'c',
        'cpp',
        'objc',
        'objcpp',
        'cuda',
    },

    cmd = {
        'clangd',
        '--query-driver=C:/Strawberry/c/bin/gcc.exe,C:/Strawberry/c/bin/g++.exe',
        '--background-index',
    },
})

vim.lsp.enable('clangd')

-- --------------------------------------------------------------------------
-- Autres serveurs LSP
-- --------------------------------------------------------------------------

local servers = {
    'lua_ls',
    'rust_analyzer',
    'html',
    'jinja_lsp',
    'emmet_ls',
    'ts_ls',
    'svelte',
    'nushell',
    'asm_lsp',
}

for _, server in ipairs(servers) do
    vim.lsp.config(server, {
        capabilities = capabilities,
    })

    vim.lsp.enable(server)
end

-- ============================================================================
-- 9. RACCOURCIS GÉNÉRAUX
-- ============================================================================

-- Terminal
vim.keymap.set(
    't',
    '<Esc>',
    '<C-\\><C-n>',
    { desc = 'Quitter le mode terminal' }
)

-- Navigation entre fenêtres
for _, dir in ipairs({ 'h', 'j', 'k', 'l' }) do
    vim.keymap.set(
        'n',
        '<A-' .. dir .. '>',
        '<C-w>' .. dir,
        { desc = 'Fenêtre ' .. dir }
    )

    vim.keymap.set(
        'i',
        '<A-' .. dir .. '>',
        '<C-o><C-w>' .. dir,
        { desc = 'Fenêtre ' .. dir }
    )

    vim.keymap.set(
        't',
        '<A-' .. dir .. '>',
        '<C-\\><C-n><C-w>' .. dir,
        { desc = 'Fenêtre ' .. dir }
    )
end

-- ============================================================================
-- 10. AUTOCOMMANDES
-- ============================================================================

-- Highlight temporaire lors d'un yank
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Surligner le texte copié',
    callback = function()
        vim.hl.on_yank()
    end,
})

-- ============================================================================
-- 11. SAUVEGARDE AUTOMATIQUE
-- ============================================================================

local autosave_group = vim.api.nvim_create_augroup(
    'AutosaveGroup',
    { clear = true }
)

local save_timers = {}

local function safe_save(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    if not vim.bo[buf].modified then
        return
    end

    if vim.bo[buf].buftype ~= '' then
        return
    end

    local filename = vim.api.nvim_buf_get_name(buf)

    if filename == '' then
        return
    end

    local dir = vim.fn.fnamemodify(filename, ':h')

    if vim.fn.isdirectory(dir) ~= 1 then
        return
    end

    vim.api.nvim_buf_call(buf, function()
        vim.cmd('silent! update')
    end)
end

-- Sauvegarde une seconde après la dernière modification
vim.api.nvim_create_autocmd(
    { 'TextChanged', 'TextChangedI' },
    {
        group = autosave_group,
        desc = 'Sauvegarde automatique après inactivité',
        callback = function()
            local buf = vim.api.nvim_get_current_buf()

            if save_timers[buf] then
                save_timers[buf]:stop()
                save_timers[buf] = nil
            end

            save_timers[buf] = vim.defer_fn(function()
                safe_save(buf)
                save_timers[buf] = nil
            end, 1000)
        end,
    }
)

-- Sauvegarde immédiate quand Neovim perd le focus
vim.api.nvim_create_autocmd('FocusLost', {
    group = autosave_group,
    desc = 'Sauvegarde à la perte de focus',
    callback = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            safe_save(buf)
        end
    end,
})

-- Nettoyage des timers
vim.api.nvim_create_autocmd('VimLeavePre', {
    group = autosave_group,
    desc = 'Nettoyage des timers',
    callback = function()
        for buf, timer in pairs(save_timers) do
            if timer then
                timer:stop()
            end
            save_timers[buf] = nil
        end
    end,
})

-- ============================================================================
-- 12. SNACKS / LSP
-- ============================================================================

vim.keymap.set(
    'n',
    '<leader>ff',
    snacks.picker.files,
    { desc = 'Rechercher un fichier' }
)

vim.keymap.set(
    'n',
    '<leader>fg',
    snacks.picker.grep,
    { desc = 'Rechercher dans les fichiers' }
)

vim.keymap.set(
    'n',
    '<leader>fb',
    snacks.picker.buffers,
    { desc = 'Buffers ouverts' }
)

vim.keymap.set(
    'n',
    '<leader>fd',
    snacks.picker.diagnostics,
    { desc = 'Diagnostics du workspace' }
)

vim.keymap.set(
    'n',
    '<leader>fs',
    snacks.picker.lsp_symbols,
    { desc = 'Symboles du fichier' }
)

vim.keymap.set(
    'n',
    '<leader>fS',
    snacks.picker.lsp_workspace_symbols,
    { desc = 'Symboles du workspace' }
)

vim.keymap.set(
    'n',
    '<leader>fe',
    function()
        snacks.explorer()
    end,
    { desc = 'Explorateur de fichiers' }
)

vim.keymap.set(
    'n',
    '<leader>lg',
    function()
        snacks.lazygit()
    end,
    { desc = 'Ouvrir LazyGit' }
)

-- Navigation LSP
vim.keymap.set(
    'n',
    'gd',
    snacks.picker.lsp_definitions,
    { desc = 'Aller à la définition' }
)

vim.keymap.set(
    'n',
    'gr',
    snacks.picker.lsp_references,
    { desc = 'Afficher les références' }
)

vim.keymap.set(
    'n',
    'K',
    vim.lsp.buf.hover,
    { desc = 'Documentation' }
)

vim.keymap.set(
    'n',
    '<leader>rn',
    vim.lsp.buf.rename,
    { desc = 'Renommer le symbole' }
)

vim.keymap.set(
    { 'n', 'v' },
    '<leader>ca',
    vim.lsp.buf.code_action,
    { desc = 'Action de code' }
)

-- Formatage
vim.keymap.set(
    'n',
    '<leader>fm',
    function()
        vim.lsp.buf.format({ async = true })
    end,
    { desc = 'Formater le code' }
)

-- Afficher le diagnostic courant
vim.keymap.set(
    'n',
    '<leader>d',
    vim.diagnostic.open_float,
    { desc = 'Afficher le diagnostic' }
)

-- ============================================================================
-- 13. LEAP
-- ============================================================================

vim.keymap.set(
    { 'n', 'x', 'o' },
    's',
    function()
        require('leap').leap({})
    end,
    { desc = 'Leap dans la fenêtre actuelle' }
)

vim.keymap.set(
    'n',
    'S',
    function()
        require('leap').leap({
            target_windows = require('leap.util').get_enterable_targets(),
        })
    end,
    { desc = 'Leap vers une autre fenêtre' }
)

-- ============================================================================
-- 14. COMPILATION / EXÉCUTION C ET C++
-- ============================================================================

local function compile_and_run(run_after)
    local file = vim.fn.expand('%:p')

    if file == '' then
        vim.notify(
            'Aucun fichier à compiler',
            vim.log.levels.WARN
        )
        return
    end

    local ext = vim.fn.expand('%:e'):lower()
    local exe = vim.fn.expand('%:p:r') .. '.exe'

    local compiler

    if ext == 'c' then
        compiler = 'gcc'
    elseif ext == 'cpp' or ext == 'cc' or ext == 'cxx' then
        compiler = 'g++'
    else
        vim.notify(
            'Type de fichier non supporté : .' .. ext,
            vim.log.levels.WARN
        )
        return
    end

    vim.cmd('write')

    vim.notify(
        'Compilation de ' .. vim.fn.expand('%:t') .. '...',
        vim.log.levels.INFO
    )

    vim.system(
        {
            compiler,
            file,
            '-o',
            exe,
            '-Wall',
            '-Wextra',
        },
        { text = true },
        function(result)
            vim.schedule(function()
                if result.code ~= 0 then
                    local stderr = vim.trim(result.stderr or '')

                    vim.notify(
                        'Erreur de compilation\n\n' .. stderr,
                        vim.log.levels.ERROR,
                        {
                            title = compiler,
                        }
                    )

                    -- Quickfix avec les erreurs GCC
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

                vim.notify(
                    'Compilation réussie',
                    vim.log.levels.INFO
                )

                if not run_after then
                    return
                end

                -- Terminal intégré
                vim.cmd('botright 12split')

                local buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_win_set_buf(
                    vim.api.nvim_get_current_win(),
                    buf
                )

                vim.fn.termopen({ exe }, {
                    on_exit = function()
                        vim.schedule(function()
                            if vim.api.nvim_buf_is_valid(buf) then
                                vim.bo[buf].buflisted = false
                            end
                        end)
                    end,
                })

                vim.cmd('startinsert')
            end)
        end
    )
end

-- F5 : compiler + exécuter
vim.keymap.set(
    'n',
    '<F5>',
    function()
        compile_and_run(true)
    end,
    { desc = 'Compiler et exécuter C/C++' }
)

-- F6 : compiler uniquement
vim.keymap.set(
    'n',
    '<F6>',
    function()
        compile_and_run(false)
    end,
    { desc = 'Compiler C/C++' }
)

-- ============================================================================
-- 15. NOTIFICATION
-- ============================================================================

vim.notify(
    'Configuration chargée avec succès !',
    vim.log.levels.INFO
)
