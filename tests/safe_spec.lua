-- ============================================================================
-- SAFE TESTS
-- ============================================================================
if not _G.describe then
  return
end

describe('Safe module loader', function()
  local safe = require('utils.safe')

  before_each(function()
    safe._reset()
  end)

  it('loads an existing module without error', function()
    local mod = safe.require('utils.env', { mode = 'warn' })
    assert.is_not_nil(mod)
    assert.are.equal(0, vim.tbl_count(safe.get_failures()))
  end)

  it('rejects an invalid mode', function()
    assert.has_error(function()
      safe.require('utils.env', { mode = 'n_importe_quoi' })
    end)
  end)

  it("registers a 'warn' failure for a missing module", function()
    local mod = safe.require('module.inexistant.warn', { mode = 'warn' })
    assert.is_nil(mod)
    local failures = safe.get_failures()
    assert.is_not_nil(failures['module.inexistant.warn'])
    assert.are.equal('warn', failures['module.inexistant.warn'].mode)
  end)

  it("registers an 'optional' failure with the right mode", function()
    safe.require('module.inexistant.opt', { mode = 'optional' })
    assert.are.equal('optional', safe.get_failures()['module.inexistant.opt'].mode)
  end)

  it("defaults to 'warn' when opts is nil", function()
    safe.require('module.inexistant.default')
    assert.are.equal('warn', safe.get_failures()['module.inexistant.default'].mode)
  end)

  it('is idempotent (does not duplicate failures)', function()
    safe.require('module.inexistant.dup', { mode = 'warn' })
    safe.require('module.inexistant.dup', { mode = 'warn' })
    assert.are.equal(1, vim.tbl_count(safe.get_failures()))
  end)

  it('safe.call records setup failures', function()
    local ok = safe.call('test.setup', function()
      error('boom')
    end)
    assert.is_false(ok)
    assert.is_not_nil(safe.get_setup_failures()['test.setup'])
  end)

  it('safe.call returns true on success', function()
    local ok = safe.call('test.ok', function()
      return 42
    end)
    assert.is_true(ok)
    assert.is_nil(safe.get_setup_failures()['test.ok'])
  end)
end)
