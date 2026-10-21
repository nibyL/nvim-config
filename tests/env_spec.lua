-- ============================================================================
-- ENV TESTS
-- ============================================================================
if not _G.describe then
  return
end

describe('Environment utils', function()
  local env = require('utils.env')

  it('detects the current OS correctly', function()
    local uname = vim.uv.os_uname().sysname
    if uname:find('Windows') then
      assert.is_true(env.is_windows)
      assert.is_false(env.is_linux)
    elseif uname == 'Linux' then
      assert.is_true(env.is_linux)
      assert.is_false(env.is_windows)
    end
  end)

  it('finds a known executable (git)', function()
    local path = env.find_executable('git')
    assert.is_not_nil(path, 'git should be found')
  end)

  it('returns nil for a non-existent executable', function()
    local path = env.find_executable('this_binary_does_not_exist_12345')
    assert.is_nil(path)
  end)

  it('returns at least one valid disk root', function()
    local roots = env.get_disk_roots()
    assert.is_true(#roots > 0)
    for _, root in ipairs(roots) do
      assert.is_true(vim.fn.isdirectory(root) == 1, 'Root must be a directory: ' .. root)
    end
  end)
end)
