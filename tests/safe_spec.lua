-- ============================================================================
-- SAFE TESTS
-- ============================================================================
if not _G.describe then
  return
end

describe('Safe module loader', function()
  local safe = require('utils.safe')

  before_each(function()
    safe._reset() -- On nettoie le registre avant chaque test
  end)

  it('loads an existing module without error', function()
    local mod = safe.require('utils.env', { optional = false })
    assert.is_not_nil(mod)
    assert.are.equal(0, vim.tbl_count(safe.get_failures()))
  end)

  it('registers a failure for a missing module', function()
    local mod = safe.require('module.inexistant.123', { optional = true })
    assert.is_nil(mod)

    local failures = safe.get_failures()
    assert.is_not_nil(failures['module.inexistant.123'])
    assert.is_true(failures['module.inexistant.123'].optional)
  end)

  it('is idempotent (does not duplicate failures)', function()
    safe.require('module.inexistant.123')
    safe.require('module.inexistant.123')
    assert.are.equal(1, vim.tbl_count(safe.get_failures()))
  end)
end)
