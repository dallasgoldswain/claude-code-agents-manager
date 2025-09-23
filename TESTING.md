# Claude Agents CLI Testing Guide

## Overview

This project uses **Minitest** for comprehensive testing of the Claude Code agent management CLI. The testing strategy focuses on practical, efficient tests that cover core functionality without over-engineering.

## Testing Philosophy

- **Simple & Fast**: Tests should be easy to understand and quick to execute
- **TDD Approach**: Write tests before implementation
- **Real Data**: No mocking of external APIs - use real data and file operations
- **Performance Aware**: Monitor test execution time and memory usage
- **Comprehensive Coverage**: Unit, integration, and performance tests

## Test Architecture

### Directory Structure

```
test/
├── test_helper.rb                    # Central configuration and base classes
├── .minitest.rb                      # Minitest configuration
├── support/                          # Reusable test utilities
│   ├── filesystem_helpers.rb         # File operations, temp directories, assertions
│   ├── cli_helpers.rb                # CLI command testing utilities
│   └── test_fixtures.rb              # Test data generation and fixtures
├── unit/                             # Service class tests (70+ tests)
│   ├── config_test.rb                # Configuration management (25 tests)
│   ├── symlink_manager_test.rb       # Symlink operations (19 tests)
│   ├── file_processor_test.rb        # File processing (14 tests)
│   └── error_handling_test.rb        # Error scenarios (13 tests)
├── integration/                      # End-to-end tests (21+ tests)
│   └── cli_commands_test.rb          # Full CLI workflows
└── fixtures/                         # Generated test data structures
```

### Test Coverage Summary

| Test Suite | Tests | Coverage |
|------------|-------|----------|
| **Unit Tests** | 70+ | Core functionality |
| **Integration Tests** | 21+ | Complete workflows |
| **Performance Tests** | Embedded | Critical operations |
| **Error Handling** | 13+ | Edge cases & recovery |
| **Total** | 91+ tests | Comprehensive |

## Running Tests

### Using Rake (Recommended)

```bash
# Run all tests
rake test

# Run specific test suites
rake test:unit                         # Unit tests only
rake test:integration                  # Integration tests only
rake test:performance                  # Performance-focused tests

# Specialized test runs
rake test:coverage                     # Tests with coverage reporting
rake test:fast_fail                    # Stop on first failure with minimal output
rake test:failures_only                # Show only test failures
rake test:watch                        # Continuous testing (requires entr)

# Individual test execution
rake test:file[test/unit/config_test.rb]              # Run specific test file
rake test:method[ConfigTest,test_claude_dir]          # Run specific test method

# Test reporting and analysis
rake test:report                       # Generate detailed test report
rake dev:benchmark                     # Benchmark test execution time

# Development workflows
rake dev:setup                         # Setup development environment
rake dev:check                         # Full check (tests + linting)
rake dev:clean                         # Clean test artifacts
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
bin/test --seed 12345                 # Reproducible runs
```

### Direct Minitest Execution

```bash
# Run all tests
ruby -Itest:lib test/test_helper.rb

# Run specific test file
ruby -Itest:lib test/unit/config_test.rb

# Run with specific options
ruby -Itest:lib test/unit/config_test.rb --seed=42 --verbose --name=test_claude_dir
```

### CI/CD Integration

```bash
# Full CI pipeline locally
rake ci:local                          # Complete pipeline (clean, test, lint, performance)

# Quick CI check
rake ci:quick                          # Unit tests + linting only
```

## Test Categories

### Unit Tests (`test/unit/`) - 70+ Tests

Test individual service classes in isolation with comprehensive coverage:

#### **ConfigTest** (25 tests)
- Configuration management and path resolution
- Component validation and directory management
- Environment variable handling
- Cache management and reset functionality

#### **SymlinkManagerTest** (19 tests)
- Symlink creation, removal, and batch operations
- Performance testing with large datasets (100+ files)
- Error handling for broken symlinks and permissions
- Component-specific symlink patterns

#### **FileProcessorTest** (14 tests)
- File discovery, filtering, and mapping generation
- Category-based naming conventions
- Skip pattern filtering (JSON, hidden files, logs)
- Path generation with prefix handling

#### **ErrorHandlingTest** (13 tests)
- Exception handling and error recovery scenarios
- Edge case validation (nil inputs, malformed data)
- Memory leak detection and cleanup
- Concurrent operation error handling

**Key Features:**
- Isolated testing with temporary directories
- Fast execution (< 0.1s per test)
- Comprehensive edge case coverage
- Performance benchmarks for critical operations
- Memory usage monitoring

### Integration Tests (`test/integration/`) - 21+ Tests

Test complete CLI workflows with real file system operations:

#### **CLICommandsTest** (21 tests)
- Complete installation and removal workflows
- Multi-component interactions and dependencies
- System integration validation with external tools
- Performance testing with realistic data sizes
- Error recovery and concurrent operation safety
- CLI argument parsing and validation
- Environment variable handling in CLI context

**Key Features:**
- Real file system operations in isolated test environments
- Complete CLI command execution with environment isolation
- Performance testing with large datasets
- Error recovery scenarios and edge case handling
- Memory usage monitoring for large operations

### Performance Tests

Embedded within unit and integration tests with specific performance criteria:

- **Execution time benchmarks**: Critical operations < 1s
- **Memory usage monitoring**: Large operations < 50MB growth
- **Large dataset handling**: 100+ files processed efficiently
- **Concurrent operation safety**: Thread-safe operations validated
- **Performance regression detection**: Automated benchmarking

## Test Helpers and Utilities

### TestHelpers Module

Core testing infrastructure with automatic environment setup:

```ruby
# Automatic test environment setup
def setup
  setup_test_environment    # Creates isolated test directories
  ClaudeAgents::Config.reset_cache!  # Ensures clean config state
end

# Test directory accessors
test_claude_dir    # Temporary .claude directory
test_agents_dir    # Temporary agents directory
test_commands_dir  # Temporary commands directory
```

### FilesystemHelpers Module

Comprehensive file system testing utilities:

```ruby
# File creation utilities
create_test_file(path, content)
create_test_agent_file(filename, component)
create_test_directory_structure(base_dir, structure)

# Symlink testing and validation
create_test_symlink(source, destination)
assert_symlink_exists(path)
assert_symlink_points_to(symlink, target)
count_symlinks(directory, pattern)

# Directory validation and assertions
assert_directory_exists(path)
assert_directory_empty(path)
assert_file_count(directory, expected_count, pattern)

# Temporary environments with automatic cleanup
with_temp_directory { |dir| ... }
with_test_repo(name) { |repo_dir| ... }
```

### CLIHelpers Module

CLI command testing with environment isolation:

```ruby
# Command execution with environment isolation
run_cli_command(['setup', 'dlabs'])          # Real CLI execution
run_thor_command(CLI, :setup, ['dlabs'])     # Direct Thor command

# Output validation and assertions
assert_output_includes(result, 'Success')
assert_successful_execution(result)
assert_failed_execution(result)
assert_command_succeeds(['version'])

# Interactive testing simulation
simulate_user_input("y\nn\n") { ... }
capture_output { ... }

# Environment variable mocking
with_env('CLAUDE_DIR' => '/tmp/test') { ... }
```

### PerformanceHelpers Module

Performance testing and benchmarking utilities:

```ruby
# Performance assertions with thresholds
assert_performance_under(1.0) do
  # Operation should complete in under 1 second
  perform_large_operation
end

assert_memory_usage_under(50) do
  # Memory growth should be under 50MB
  process_large_dataset
end

# Benchmarking utilities
benchmark_execution { operation }
monitor_memory_usage { operation }
```

### Test Fixtures

Pre-built test data structures for consistent testing:

```ruby
# Component-specific test structures
TestFixtures.create_dlabs_fixture(base_dir)           # 5 agent files
TestFixtures.create_wshobson_agents_fixture(base_dir) # Sample wshobson agents
TestFixtures.create_awesome_agents_fixture(base_dir)  # Category-based structure
TestFixtures.create_full_test_structure(base_dir)     # Complete test environment

# Agent content templates with realistic YAML frontmatter
TestFixtures::SAMPLE_AGENT_CONTENT
TestFixtures::DLABS_AGENT_CONTENT
TestFixtures::AWESOME_AGENT_CONTENT
```

## Advanced Testing Features

### Mocking and Stubbing with Mocha

Strategic mocking for external dependencies:

```ruby
# Configuration method mocking
ClaudeAgents::Config.stubs(:valid_component?).with(:test).returns(true)
ClaudeAgents::Config.stubs(:source_dir_for).with(:test).returns('/tmp/source')

# External command mocking
system.stubs(:exec).returns(true)
Dir.stubs(:glob).raises(Errno::EACCES.new("Permission denied"))

# UI component mocking for headless testing
ui = create_test_ui                    # Non-interactive UI mock
ui.expects(:info).with("message")      # Expectation verification
```

### Error Testing Scenarios

Comprehensive error condition validation:

```ruby
# Permission denied scenarios
File.chmod(0o000, restricted_dir)
error = assert_raises(ClaudeAgents::FileOperationError) { operation }

# Network failure simulation
mock_git_commands(failure: true)

# Memory leak detection
assert_memory_cleanup_on_errors

# Edge case validation
assert_validation_edge_cases          # nil, empty, malformed inputs
```

### Performance Monitoring

Built-in performance tracking and regression detection:

```ruby
# Execution time benchmarking
def test_performance_large_operation
  assert_performance_under(1.0) do
    @processor.get_file_mappings_for_component(:awesome)
  end
end

# Memory usage tracking
def test_memory_usage_large_dataset
  before_objects = ObjectSpace.count_objects

  100.times { create_large_operation }

  GC.start
  after_objects = ObjectSpace.count_objects
  object_growth = after_objects[:T_DATA] - before_objects[:T_DATA]

  assert object_growth < 1000, "Memory leak detected: #{object_growth} objects"
end

# Concurrent operation safety
def test_concurrent_operations
  threads = 5.times.map do
    Thread.new { perform_thread_safe_operation }
  end

  results = threads.map(&:value)
  assert results.all?(&:success?)
end
```

## Development Workflow

### Test-Driven Development

Follow TDD principles with comprehensive test coverage:

1. **Write failing test** that defines desired functionality
2. **Implement minimal code** to make test pass
3. **Refactor code** while keeping tests green
4. **Add edge cases** and error handling tests
5. **Performance tests** for critical operations

### Continuous Testing

Multiple options for continuous feedback:

```bash
# Watch mode (requires entr)
rake test:watch

# Quick feedback loop
rake test:unit            # Fast unit tests only

# Full validation
rake dev:check           # Tests + linting + coverage
```

### Performance Tracking

Monitor and benchmark performance over time:

```bash
# Performance benchmarking
rake dev:benchmark        # Benchmark test execution times

# Performance-specific tests
rake test:performance     # Run performance-focused tests

# Memory profiling
rake test:coverage        # Include memory usage tracking
```

## Writing New Tests

### Unit Test Template

```ruby
require_relative '../test_helper'

class NewComponentTest < ClaudeAgentsTest
  def setup
    super
    @component = ClaudeAgents::NewComponent.new
  end

  def test_basic_functionality
    # Arrange
    input = create_test_input

    # Act
    result = @component.process(input)

    # Assert
    assert_equal expected_value, result
    assert_instance_of Hash, result
  end

  def test_error_handling_invalid_input
    # Test specific error conditions
    error = assert_raises(ClaudeAgents::ValidationError) do
      @component.process(invalid_input)
    end

    assert_includes error.message, 'expected error description'
  end

  def test_performance_large_input
    # Performance testing with realistic thresholds
    assert_performance_under(0.1) do
      @component.process(create_large_input)
    end
  end

  def test_edge_cases
    # Test boundary conditions
    assert_nil @component.process(nil)
    assert_empty @component.process('')
    assert_equal [], @component.process([])
  end

  private

  def create_test_input
    # Helper for creating realistic test data
  end
end
```

### Integration Test Template

```ruby
require_relative '../test_helper'

class NewFeatureIntegrationTest < IntegrationTest
  def test_complete_workflow
    # Setup realistic test environment
    TestFixtures.create_full_test_structure(@project_root)

    # Execute complete command workflow
    result = run_cli_command(['new-command', '--option', 'value'])

    # Validate successful execution
    assert_successful_execution result
    assert_output_includes result, 'Success: Operation completed'

    # Verify filesystem changes
    assert_file_count test_agents_dir, expected_count, "pattern-*"
    assert_symlink_exists expected_symlink_path

    # Test cleanup and removal
    cleanup_result = run_cli_command(['remove', 'new-feature'])
    assert_successful_execution cleanup_result
    assert_file_count test_agents_dir, 0, "pattern-*"
  end

  def test_error_recovery_scenarios
    # Test error conditions and recovery
    result = run_cli_command(['new-command', '--invalid-option'])

    assert_failed_execution result
    assert_output_includes result, 'Error: Invalid option'

    # Verify system remains in clean state
    assert_directory_empty test_agents_dir
  end

  def test_performance_with_large_dataset
    # Create large realistic test dataset
    create_large_test_structure(100)

    assert_performance_under(5.0) do
      result = run_cli_command(['process-all'])
      assert_successful_execution result
    end
  end
end
```

## Best Practices

### Test Organization

1. **One test per behavior**: Each test method verifies one specific behavior
2. **Descriptive names**: Use clear, intention-revealing test method names
3. **Arrange-Act-Assert**: Structure tests with clear setup, execution, and validation
4. **Independent tests**: Tests should not depend on each other's state

### Test Data Management

1. **Use fixtures**: Create reusable test data with `TestFixtures`
2. **Realistic data**: Use representative file structures and content
3. **Edge cases**: Test boundary conditions and error scenarios
4. **Cleanup**: Always clean up temporary files and directories automatically

### Error Testing Strategy

1. **Test failure modes**: Verify proper error handling and recovery
2. **Validate error messages**: Ensure error messages are helpful and actionable
3. **Test edge cases**: Handle malformed input and system failures gracefully
4. **Performance impact**: Ensure errors don't cause memory leaks or performance degradation

### Performance Testing Guidelines

1. **Set realistic thresholds**: Define acceptable performance limits based on usage
2. **Monitor trends**: Track performance over time to detect regressions
3. **Test realistic scenarios**: Use representative data sizes and operations
4. **Memory awareness**: Monitor memory usage patterns and prevent leaks

## Troubleshooting

### Common Issues

1. **Test environment isolation**: Ensure tests don't interfere with each other
2. **Temporary file cleanup**: Always clean up test artifacts automatically
3. **Path resolution**: Use absolute paths in test assertions for consistency
4. **Timing issues**: Add appropriate waits for file operations if needed
5. **Permission errors**: Ensure test directories have proper permissions

### Performance Issues

1. **Slow tests**: Use profiling and benchmarking to identify bottlenecks
2. **Memory growth**: Monitor object allocation and garbage collection
3. **File I/O optimization**: Minimize unnecessary file operations
4. **Parallel execution**: Use `MT_CPU` environment variable for parallel test execution

### Debugging Tests

```bash
# Verbose output for debugging
rake test TESTOPTS="--verbose"
bin/test --verbose

# Run specific failing test
rake test:method[TestClass,test_method_name]

# Debug with specific seed for reproducibility
bin/test --seed 12345

# Profile slow tests
rake dev:benchmark | grep "Slow test"
```

## Current Test Status

### Test Metrics

- **Total Tests**: 91+ tests across unit and integration suites
- **Execution Time**: < 30 seconds for full suite
- **Memory Usage**: Monitored and optimized for large operations
- **Coverage**: Comprehensive coverage of core functionality

### Test Distribution

```
Unit Tests (70+ tests):
├── ConfigTest (25 tests)           ✅ Configuration management
├── SymlinkManagerTest (19 tests)   ✅ Symlink operations
├── FileProcessorTest (14 tests)    ✅ File processing
└── ErrorHandlingTest (13 tests)    ✅ Error scenarios

Integration Tests (21+ tests):
└── CLICommandsTest (21 tests)      ✅ Complete workflows

Performance Tests:
└── Embedded throughout all suites  ✅ Critical operations
```

### Quality Metrics

- **Fast execution**: Individual tests complete in < 0.1s
- **Memory efficient**: Large operations stay under 50MB growth
- **Error resilient**: Comprehensive error condition coverage
- **CI ready**: Full automation with parallel execution support

This comprehensive testing strategy provides confidence in the Claude Agents CLI functionality while maintaining excellent performance and developer experience. The test suite serves as both validation and living documentation of the system's capabilities.