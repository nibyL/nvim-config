-- ============================================================================
-- AUTOCMDS TESTS
-- ============================================================================
if not _G.describe then return end
describe('Autocmds', function()
  it('TextYankPost is registered', function()
    local autocmds = vim.api.nvim_get_autocmds({ event = 'TextYankPost' })
    assert.is_true(#autocmds > 0, 'TextYankPost autocmd not registered')
  end)

  it('BufEnter is registered for filetype detection', function()
    local autocmds = vim.api.nvim_get_autocmds({ event = 'BufEnter' })
    assert.is_true(#autocmds > 0, 'BufEnter autocmd not registered')
  end)

  it('ColorScheme autocmd is registered', function()
    local autocmds = vim.api.nvim_get_autocmds({ event = 'ColorScheme' })
    assert.is_true(#autocmds > 0, 'ColorScheme autocmd not registered')
  end)
end)

describe('Options', function()
  it('number is enabled', function()
    assert.is_true(vim.o.number)
  end)

  it('relativenumber is enabled', function()
    assert.is_true(vim.o.relativenumber)
  end)

  it('expandtab is enabled', function()
    assert.is_true(vim.o.expandtab)
  end)

  it('shiftwidth is 4', function()
    assert.are.equal(4, vim.o.shiftwidth)
  end)

  it('tabstop is 4', function()
    assert.are.equal(4, vim.o.tabstop)
  end)

  it('termguicolors is enabled', function()
    assert.is_true(vim.o.termguicolors)
  end)

  it('clipboard is set to unnamedplus', function()
    assert.are.equal('unnamedplus', vim.o.clipboard)
  end)
end)

describe('Utils modules', function()
  it('utils.safe loads', function()
    local ok = pcall(require, 'utils.safe')
    assert.is_true(ok)
  end)

  it('utils.notify loads', function()
    local ok = pcall(require, 'utils.notify')
    assert.is_true(ok)
  end)

  it('utils.env loads', function()
    local ok = pcall(require, 'utils.env')
    assert.is_true(ok)
  end)

it('utils.env detects current OS', function()
    local env = require('utils.env')
    local uname = vim.uv.os_uname().sysname
    if uname:find('Windows') then
        assert.is_true(env.is_windows, 'Windows should be detected')
    elseif uname == 'Linux' then
        assert.is_true(env.is_linux, 'Linux should be detected')
    elseif uname == 'Darwin' then
        assert.is_true(env.is_macos, 'macOS should be detected')
    end
end)

  it('utils.env.get_disk_roots returns at least one root', function()
    local env = require('utils.env')
    local roots = env.get_disk_roots()
    assert.is_true(#roots > 0, 'At least one disk root expected')
  end)
end)
