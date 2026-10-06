-- ============================================================================
-- KEYMAPS TESTS
-- ============================================================================

describe('Keymaps', function()
  it('leader key is space', function()
    assert.are.equal(' ', vim.g.mapleader)
  end)

  it('maplocalleader is space', function()
    assert.are.equal(' ', vim.g.maplocalleader)
  end)

  it('Alt+h/j/k/l are mapped in normal mode', function()
    for _, dir in ipairs({ 'h', 'j', 'k', 'l' }) do
      local map = vim.fn.maparg('<A-' .. dir .. '>', 'n')
      assert.is_not_equal('', map, 'Missing keymap: <A-' .. dir .. '>')
    end
  end)

  it('Alt+h/j/k/l are mapped in insert mode', function()
    for _, dir in ipairs({ 'h', 'j', 'k', 'l' }) do
      local map = vim.fn.maparg('<A-' .. dir .. '>', 'i')
      assert.is_not_equal('', map, 'Missing keymap: <A-' .. dir .. '> (insert)')
    end
  end)

  it('Alt+h/j/k/l are mapped in terminal mode', function()
    for _, dir in ipairs({ 'h', 'j', 'k', 'l' }) do
      local map = vim.fn.maparg('<A-' .. dir .. '>', 't')
      assert.is_not_equal('', map, 'Missing keymap: <A-' .. dir .. '> (terminal)')
    end
  end)

  it('<leader>q is mapped', function()
    local map = vim.fn.maparg('<leader>q', 'n')
    assert.is_not_equal('', map, 'Missing keymap: <leader>q')
  end)

  it('<leader>e is mapped (explorer)', function()
    local map = vim.fn.maparg('<leader>e', 'n')
    assert.is_not_equal('', map, 'Missing keymap: <leader>e')
  end)

  it('<leader>fm is mapped (format)', function()
    local map = vim.fn.maparg('<leader>fm', 'n')
    assert.is_not_equal('', map, 'Missing keymap: <leader>fm')
  end)

  it('L and H are mapped for buffer navigation', function()
    assert.is_not_equal('', vim.fn.maparg('L', 'n'), 'Missing keymap: L')
    assert.is_not_equal('', vim.fn.maparg('H', 'n'), 'Missing keymap: H')
  end)

it('s and S are mapped for leap (if installed)', function()
    if vim.fn.isdirectory(vim.fn.stdpath('data') .. '/site/pack/core/opt/leap.nvim') == 1 then
        assert.is_not_equal('', vim.fn.maparg('s', 'n'), 'Missing keymap: s')
        assert.is_not_equal('', vim.fn.maparg('S', 'n'), 'Missing keymap: S')
    end
end)

  it('<leader>/ is mapped for comments', function()
    local map_n = vim.fn.maparg('<leader>/', 'n')
    local map_v = vim.fn.maparg('<leader>/', 'v')
    assert.is_not_equal('', map_n, 'Missing keymap: <leader>/ (normal)')
    assert.is_not_equal('', map_v, 'Missing keymap: <leader>/ (visual)')
  end)

  it('<C-a> is mapped for select all', function()
    local map_n = vim.fn.maparg('<C-a>', 'n')
    local map_i = vim.fn.maparg('<C-a>', 'i')
    assert.is_not_equal('', map_n, 'Missing keymap: <C-a> (normal)')
    assert.is_not_equal('', map_i, 'Missing keymap: <C-a> (insert)')
  end)

  it('F5 and F6 are mapped for compilation', function()
    assert.is_not_equal('', vim.fn.maparg('<F5>', 'n'), 'Missing keymap: F5')
    assert.is_not_equal('', vim.fn.maparg('<F6>', 'n'), 'Missing keymap: F6')
  end)
end)
