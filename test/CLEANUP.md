# Test Cleanup System

The minitest suite has been enhanced with comprehensive cleanup mechanisms to ensure no test artifacts are left behind after test runs.

## Features

### Automatic Cleanup

- **Test Helper Tracking**: The `ClaudeAgentsTest` base class now tracks all created resources:
  - Temporary directories (`@temp_dirs`)
  - Temporary files (`@temp_files`)
  - Created symlinks (`@created_symlinks`)
  - Mock home directories (`@mock_homes`)

- **Teardown Cleanup**: All tracked resources are automatically cleaned up in the `teardown` method

- **At-Exit Cleanup**: Global cleanup hook ensures any missed artifacts are removed when tests complete

### Manual Cleanup Tasks

- `rake cleanup_test_artifacts` - Removes test fixtures, temp directories, and stray symlinks
- `rake force_cleanup` - Aggressive cleanup for CI environments (includes coverage reports)
- `rake verify_cleanup` - Verifies that no test artifacts remain

### Verification System

The `CleanupVerification` module automatically runs after test completion to ensure:

- No leftover temporary directories in `/tmp/claude_agents_test*` or `/tmp/mock_home*`
- No leftover fixture files in `test/fixtures/`
- No stray symlinks in test directories

In CI environments, failed cleanup verification will cause the build to fail.

## Usage

### In Test Files

```ruby
class MyTest < ClaudeAgentsTest
  def test_something
    # Create tracked temporary directory
    with_temp_dir do |dir|
      # work with temp dir - automatically cleaned up
    end

    # Create tracked symlinks
    link_path = create_test_symlink('/target/file', '/link/path')
    # automatically tracked and cleaned up

    # Create tracked fixture
    fixture = create_fixture_file('test.txt', 'content')
    # automatically tracked and cleaned up
  end
end
```

### Manual Cleanup

```bash
# Clean up after running tests
rake cleanup_test_artifacts

# Verify cleanup worked
rake verify_cleanup

# Force cleanup (useful in CI)
rake force_cleanup
```

## Environment Variables

- `CI=true` - Enables stricter cleanup verification (fails builds on incomplete cleanup)
- `SKIP_CLEANUP_VERIFICATION=true` - Disables automatic cleanup verification
