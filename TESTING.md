# Claude Agents CLI Testing Guide

## Overview

This project uses **Minitest** for comprehensive testing of the Claude Code agent management CLI. The testing strategy focuses on practical, efficient tests that cover core functionality without over-engineering.

## Testing Philosophy

- **Simple & Fast**: Tests should be easy to understand and quick to execute
- **TDD Approach**: Write tests before implementation
- **Real Data**: No mocking of external APIs - use real data and file operations
- **Performance Aware**: Monitor test execution time and memory usage
- **Comprehensive Coverage**: Unit, integration, and performance tests

## Test Structure

```
test/
├── test_helper.rb              # Main test configuration
├── support/                    # Test utilities and helpers
│   ├── filesystem_helpers.rb   # File operations and fixtures
│   ├── cli_helpers.rb          # CLI command testing utilities
│   └── test_fixtures.rb        # Test data generation
├── unit/                       # Unit tests for service classes
│   ├── config_test.rb          # Configuration management
│   ├── symlink_manager_test.rb # Symlink operations
│   ├── file_processor_test.rb  # File discovery and processing
│   └── error_handling_test.rb  # Error scenarios and recovery
└── integration/                # Full workflow tests
    └── cli_commands_test.rb     # End-to-end CLI testing
```

## Running Tests

### Using Rake (Recommended)

```bash
# Run all tests
rake test

# Run specific test suites
rake test:unit
rake test:integration
rake test:performance

# Run with coverage
rake test:coverage

# Run specific test file
rake test:file[test/unit/config_test.rb]

# Run specific test method
rake test:method[ConfigTest,test_claude_dir_returns_expanded_path]

# Development workflows
rake dev:check          # Full check (tests + linting)
rake test:watch         # Continuous testing (requires entr)
rake dev:benchmark      # Performance benchmarking
```

### Using Custom Test Runner

```bash
# Run all tests
bin/test

# Run specific suites
bin/test --suite unit
bin/test --suite integration
bin/test --suite performance

# Run with options
bin/test --verbose --parallel
bin/test --seed 12345
```

### Direct Minitest Execution

```bash
# Run all tests
ruby -Itest:lib test/test_helper.rb

# Run specific test file
ruby -Itest:lib test/unit/config_test.rb

# Run with specific options
ruby -Itest:lib test/unit/config_test.rb --seed=42 --verbose
```

## Test Categories

### Unit Tests (`test/unit/`)

Test individual service classes in isolation:

- **ConfigTest**: Configuration management and path resolution
- **SymlinkManagerTest**: Symlink creation, removal, and batch operations
- **FileProcessorTest**: File discovery, filtering, and mapping generation
- **ErrorHandlingTest**: Exception handling and error recovery

**Key Features:**
- Isolated testing with mocked dependencies
- Fast execution (< 0.1s per test)
- Comprehensive edge case coverage
- Performance benchmarks for critical operations

### Integration Tests (`test/integration/`)

Test complete CLI workflows:

- **CLICommandsTest**: Full command execution and validation
- End-to-end installation and removal workflows
- Multi-component interactions
- System integration validation

**Key Features:**
- Real file system operations in temporary directories
- Complete CLI command execution
- Performance testing with realistic data sizes
- Error recovery and concurrent operation safety

### Performance Tests

Embedded within unit and integration tests:

- Memory usage monitoring
- Execution time benchmarks
- Large dataset handling
- Concurrent operation safety

## Test Helpers and Utilities

### TestHelpers Module

```ruby
# Automatic test environment setup
def setup
  setup_test_environment  # Creates isolated test directories
end

# Test directory accessors
test_claude_dir    # Temporary .claude directory
test_agents_dir    # Temporary agents directory
test_commands_dir  # Temporary commands directory
```

### FilesystemHelpers Module

```ruby
# File creation utilities
create_test_file(path, content)
create_test_agent_file(filename, component)
create_test_directory_structure(base_dir, structure)

# Symlink operations
create_test_symlink(source, destination)
assert_symlink_exists(path)
assert_symlink_points_to(symlink, target)

# Directory validation
assert_directory_exists(path)
assert_directory_empty(path)
assert_file_count(directory, expected_count, pattern)

# Temporary environments
with_temp_directory { |dir| ... }
with_test_repo(name) { |repo_dir| ... }
```

### CLIHelpers Module

```ruby
# Command execution
run_cli_command(['setup', 'dlabs'])
run_thor_command(CLI, :setup, ['dlabs'])

# Output validation
assert_output_includes(result, 'Success')
assert_successful_execution(result)
assert_command_succeeds(['version'])

# Interactive testing
simulate_user_input("y\nn\n") { ... }
capture_output { ... }
```

### Test Fixtures

```ruby
# Pre-built test structures
TestFixtures.create_dlabs_fixture(base_dir)
TestFixtures.create_wshobson_agents_fixture(base_dir)
TestFixtures.create_full_test_structure(base_dir)

# Agent content templates
TestFixtures::SAMPLE_AGENT_CONTENT
TestFixtures::DLABS_AGENT_CONTENT
```

## Performance Guidelines

### Test Execution Time

- **Unit tests**: < 0.1s each
- **Integration tests**: < 1s each
- **Full suite**: < 30s total
- **Performance tests**: Clearly marked and monitored

### Memory Usage

- Monitor memory growth during large operations
- Clean up temporary files and directories
- Use lazy enumeration for large datasets
- Force garbage collection in memory-sensitive tests

### Benchmarking

```ruby
def test_performance_large_operation
  assert_performance_under(1.0) do
    # Operation should complete in under 1 second
    perform_large_operation
  end
end

def test_memory_usage
  assert_memory_usage_under(50) do # Under 50MB
    # Memory-intensive operation
    process_large_dataset
  end
end
```

## Best Practices

### Test Organization

1. **One test per behavior**: Each test method should verify one specific behavior
2. **Descriptive names**: Use clear, descriptive test method names
3. **Arrange-Act-Assert**: Structure tests with clear setup, execution, and validation
4. **Independent tests**: Tests should not depend on each other

### Test Data

1. **Use fixtures**: Create reusable test data with `TestFixtures`
2. **Realistic data**: Use representative file structures and content
3. **Edge cases**: Test boundary conditions and error scenarios
4. **Cleanup**: Always clean up temporary files and directories

### Error Testing

1. **Test failure modes**: Verify proper error handling and recovery
2. **Validate error messages**: Ensure error messages are helpful
3. **Test edge cases**: Handle malformed input and system failures
4. **Performance degradation**: Ensure errors don't cause memory leaks

### Performance Testing

1. **Set thresholds**: Define acceptable performance limits
2. **Monitor trends**: Track performance over time
3. **Test realistic scenarios**: Use representative data sizes
4. **Memory awareness**: Monitor memory usage patterns

## Continuous Integration

### Local CI Pipeline

```bash
# Full CI check
rake ci:local

# Quick check (fast tests only)
rake ci:quick

# Development workflow
rake dev:setup    # Setup environment
rake dev:check    # Full check
rake dev:clean    # Cleanup artifacts
```

### Test Coverage

- Target: 90%+ code coverage
- Critical paths: 100% coverage
- Error handling: Comprehensive coverage
- CLI commands: Full integration coverage

## Debugging Tests

### Verbose Output

```bash
# Enable verbose test output
rake test TESTOPTS="--verbose"
bin/test --verbose

# Debug specific test
ruby -Itest:lib test/unit/config_test.rb --name=test_claude_dir_returns_expanded_path --verbose
```

### Test Isolation

```bash
# Run single test method
rake test:method[ConfigTest,test_claude_dir_returns_expanded_path]

# Run with specific seed for reproducibility
bin/test --seed 12345
```

### Performance Debugging

```bash
# Run performance benchmarks
rake dev:benchmark

# Profile memory usage
rake test:performance

# Monitor slow tests
rake test TESTOPTS="--verbose" | grep "Slow test"
```

## Writing New Tests

### Template for Unit Test

```ruby
class NewComponentTest < ClaudeAgentsTest
  def setup
    super
    @component = NewComponent.new
  end

  def test_basic_functionality
    # Arrange
    input = create_test_input

    # Act
    result = @component.process(input)

    # Assert
    assert_equal expected_value, result
  end

  def test_error_handling
    error = assert_raises(ClaudeAgents::ValidationError) do
      @component.process(invalid_input)
    end

    assert_includes error.message, 'expected error text'
  end

  def test_performance
    assert_performance_under(0.1) do
      @component.process(large_input)
    end
  end
end
```

### Template for Integration Test

```ruby
class NewFeatureIntegrationTest < IntegrationTest
  def test_complete_workflow
    # Setup test environment
    setup_test_fixtures

    # Execute command
    result = run_cli_command(['new-command', 'args'])

    # Validate results
    assert_successful_execution result
    assert_output_includes result, 'Success message'

    # Verify filesystem changes
    assert_file_count test_target_dir, expected_count
    assert_symlink_exists expected_symlink_path
  end
end
```

## Troubleshooting

### Common Issues

1. **Test environment isolation**: Ensure tests don't interfere with each other
2. **Temporary file cleanup**: Always clean up test artifacts
3. **Path resolution**: Use absolute paths in test assertions
4. **Timing issues**: Add appropriate waits for file operations
5. **Permission errors**: Ensure test directories have proper permissions

### Performance Issues

1. **Slow tests**: Use profiling to identify bottlenecks
2. **Memory growth**: Monitor object allocation and cleanup
3. **File I/O**: Minimize unnecessary file operations
4. **Parallel execution**: Use `MT_CPU` for parallel test execution

This testing strategy provides comprehensive coverage while maintaining simplicity and performance. The test suite serves as both validation and documentation of the Claude Agents CLI functionality.