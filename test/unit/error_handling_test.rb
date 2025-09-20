# frozen_string_literal: true

require 'test_helper'

class ErrorHandlingTest < ClaudeAgentsTest
  def setup
    super
    @ui = create_mock_ui
  end

  # Test custom error classes
  class CustomErrorClassesTest < ErrorHandlingTest
    def test_user_cancelled_error
      error = ClaudeAgents::UserCancelledError.new('Operation cancelled by user')

      assert_instance_of ClaudeAgents::UserCancelledError, error
      assert_equal 'Operation cancelled by user', error.message
      assert_kind_of StandardError, error
    end

    def test_installation_error
      error = ClaudeAgents::InstallationError.new('Failed to install component')

      assert_instance_of ClaudeAgents::InstallationError, error
      assert_equal 'Failed to install component', error.message
    end

    def test_symlink_error
      error = ClaudeAgents::SymlinkError.new('Failed to create symlink')

      assert_instance_of ClaudeAgents::SymlinkError, error
      assert_equal 'Failed to create symlink', error.message
    end

    def test_configuration_error
      error = ClaudeAgents::ConfigurationError.new('Invalid configuration')

      assert_instance_of ClaudeAgents::ConfigurationError, error
      assert_equal 'Invalid configuration', error.message
    end

    def test_dependency_error
      error = ClaudeAgents::DependencyError.new('Missing dependency: git')

      assert_instance_of ClaudeAgents::DependencyError, error
      assert_equal 'Missing dependency: git', error.message
    end

    def test_permission_error
      error = ClaudeAgents::PermissionError.new('Permission denied')

      assert_instance_of ClaudeAgents::PermissionError, error
      assert_equal 'Permission denied', error.message
    end

    def test_directory_not_found_error
      error = ClaudeAgents::DirectoryNotFoundError.new('/path/not/found')

      assert_instance_of ClaudeAgents::DirectoryNotFoundError, error
      assert_equal '/path/not/found', error.message
    end

    def test_invalid_component_error
      error = ClaudeAgents::InvalidComponentError.new('unknown_component')

      assert_instance_of ClaudeAgents::InvalidComponentError, error
      assert_equal 'unknown_component', error.message
    end
  end

  # Test ErrorHandler module
  class ErrorHandlerTest < ErrorHandlingTest
    def test_handles_user_cancelled_error
      error = ClaudeAgents::UserCancelledError.new('User cancelled')

      @ui.expects(:warning).with('Operation cancelled by user')

      ClaudeAgents::ErrorHandler.handle_error(error, @ui)
    end

    def test_handles_installation_error
      error = ClaudeAgents::InstallationError.new('Installation failed')

      @ui.expects(:error).with(includes('Installation failed'))
      @ui.expects(:info).with(includes('Try running'))

      ClaudeAgents::ErrorHandler.handle_error(error, @ui)
    end

    def test_handles_permission_error
      error = ClaudeAgents::PermissionError.new('/usr/local/bin')

      @ui.expects(:error).with(includes('Permission denied'))
      @ui.expects(:info).with(includes('sudo'))

      ClaudeAgents::ErrorHandler.handle_error(error, @ui)
    end

    def test_handles_dependency_error
      error = ClaudeAgents::DependencyError.new('git not found')

      @ui.expects(:error).with(includes('Missing dependency'))
      @ui.expects(:info).with(includes('install'))

      ClaudeAgents::ErrorHandler.handle_error(error, @ui)
    end

    def test_handles_interrupt_signal
      error = Interrupt.new

      @ui.expects(:warning).with(includes('Interrupted'))

      assert_raises(SystemExit) do
        ClaudeAgents::ErrorHandler.handle_error(error, @ui)
      end
    end

    def test_handles_system_exit
      error = SystemExit.new(1)

      # SystemExit should be re-raised without additional handling
      assert_raises(SystemExit) do
        ClaudeAgents::ErrorHandler.handle_error(error, @ui)
      end
    end

    def test_handles_generic_standard_error
      error = StandardError.new('Something went wrong')

      @ui.expects(:error).with(includes('Something went wrong'))
      @ui.expects(:verbose).with(includes('Backtrace'))

      ClaudeAgents::ErrorHandler.handle_error(error, @ui)
    end

    def test_shows_backtrace_in_verbose_mode
      error = StandardError.new('Error with trace')
      error.set_backtrace(['line1', 'line2', 'line3'])

      @ui.instance_variable_set(:@verbose, true)
      @ui.expects(:error).once
      @ui.expects(:verbose).with(includes('line1')).once

      ClaudeAgents::ErrorHandler.handle_error(error, @ui)
    end

    def test_handles_errno_exceptions
      error = Errno::ENOENT.new('No such file or directory')

      @ui.expects(:error).with(includes('File not found'))
      @ui.expects(:info).with(includes('Check the path'))

      ClaudeAgents::ErrorHandler.handle_error(error, @ui)
    end

    def test_handles_network_errors
      error = SocketError.new('getaddrinfo: nodename nor servname provided')

      @ui.expects(:error).with(includes('Network error'))
      @ui.expects(:info).with(includes('Check your internet connection'))

      ClaudeAgents::ErrorHandler.handle_error(error, @ui)
    end

    def test_provides_context_specific_suggestions
      git_error = ClaudeAgents::DependencyError.new('git command not found')

      @ui.expects(:error).once
      @ui.expects(:info).with(includes('brew install git')).once if RUBY_PLATFORM =~ /darwin/
      @ui.expects(:info).with(includes('apt-get install git')).once if RUBY_PLATFORM =~ /linux/

      ClaudeAgents::ErrorHandler.handle_error(git_error, @ui)
    end
  end

  # Test error recovery strategies
  class ErrorRecoveryTest < ErrorHandlingTest
    def test_retries_on_transient_errors
      attempts = 0
      max_retries = 3

      operation = lambda do
        attempts += 1
        raise SocketError, 'Connection timeout' if attempts < max_retries
        'success'
      end

      result = ClaudeAgents::ErrorHandler.with_retry(max_retries: max_retries, &operation)

      assert_equal 'success', result
      assert_equal max_retries, attempts
    end

    def test_stops_retrying_after_max_attempts
      max_retries = 3
      attempts = 0

      operation = lambda do
        attempts += 1
        raise SocketError, 'Persistent error'
      end

      assert_raises(SocketError) do
        ClaudeAgents::ErrorHandler.with_retry(max_retries: max_retries, &operation)
      end

      assert_equal max_retries + 1, attempts
    end

    def test_exponential_backoff_between_retries
      start_time = Time.now
      attempts = 0

      operation = lambda do
        attempts += 1
        raise SocketError, 'Retry me' if attempts < 3
        'done'
      end

      ClaudeAgents::ErrorHandler.with_retry(
        max_retries: 3,
        backoff: :exponential,
        &operation
      )

      elapsed = Time.now - start_time
      # With exponential backoff: 1s, 2s, 4s = at least 3s total
      assert elapsed >= 3, 'Expected exponential backoff delays'
    end

    def test_graceful_degradation
      primary_source = -> { raise StandardError, 'Primary failed' }
      fallback_source = -> { 'fallback_data' }

      result = ClaudeAgents::ErrorHandler.with_fallback(
        primary: primary_source,
        fallback: fallback_source
      )

      assert_equal 'fallback_data', result
    end
  end

  # Test error logging
  class ErrorLoggingTest < ErrorHandlingTest
    def test_logs_errors_to_file
      with_temp_dir do |dir|
        log_file = File.join(dir, 'error.log')
        ClaudeAgents::ErrorHandler.configure(log_file: log_file)

        error = StandardError.new('Test error for logging')
        ClaudeAgents::ErrorHandler.log_error(error)

        assert File.exist?(log_file)
        log_content = File.read(log_file)
        assert_includes log_content, 'Test error for logging'
        assert_includes log_content, Time.now.strftime('%Y-%m-%d')
      end
    end

    def test_rotates_log_files
      with_temp_dir do |dir|
        log_file = File.join(dir, 'error.log')
        ClaudeAgents::ErrorHandler.configure(
          log_file: log_file,
          max_log_size: 100, # 100 bytes
          log_rotation: 3
        )

        # Generate enough errors to trigger rotation
        10.times do |i|
          error = StandardError.new("Error number #{i} with long message")
          ClaudeAgents::ErrorHandler.log_error(error)
        end

        # Check for rotated log files
        assert File.exist?(log_file)
        assert File.exist?("#{log_file}.1") || File.exist?("#{log_file}.2")
      end
    end

    def test_sanitizes_sensitive_information
      error = StandardError.new('Failed to authenticate with password: secret123')

      sanitized = ClaudeAgents::ErrorHandler.sanitize_message(error.message)

      assert_includes sanitized, 'Failed to authenticate'
      refute_includes sanitized, 'secret123'
      assert_includes sanitized, '[REDACTED]'
    end
  end

  # Test error aggregation
  class ErrorAggregationTest < ErrorHandlingTest
    def test_aggregates_multiple_errors
      errors = []

      3.times do |i|
        begin
          raise StandardError, "Error #{i}"
        rescue StandardError => e
          errors << e
        end
      end

      aggregated = ClaudeAgents::ErrorHandler.aggregate_errors(errors)

      assert_instance_of ClaudeAgents::AggregateError, aggregated
      assert_equal 3, aggregated.errors.count
      assert_includes aggregated.message, 'Multiple errors occurred'
    end

    def test_groups_errors_by_type
      errors = [
        ClaudeAgents::PermissionError.new('Permission 1'),
        ClaudeAgents::PermissionError.new('Permission 2'),
        ClaudeAgents::InstallationError.new('Install failed'),
        StandardError.new('Generic error')
      ]

      grouped = ClaudeAgents::ErrorHandler.group_errors(errors)

      assert_equal 2, grouped[ClaudeAgents::PermissionError].count
      assert_equal 1, grouped[ClaudeAgents::InstallationError].count
      assert_equal 1, grouped[StandardError].count
    end

    def test_summarizes_error_collection
      errors = 10.times.map { |i| StandardError.new("Error #{i}") }

      summary = ClaudeAgents::ErrorHandler.summarize_errors(errors)

      assert_includes summary, '10 errors occurred'
      assert_includes summary, 'StandardError'
      assert summary.length < 500, 'Summary should be concise'
    end
  end

  # Test validation errors
  class ValidationErrorTest < ErrorHandlingTest
    def test_validates_required_fields
      config = { name: 'test' }  # Missing required fields

      errors = ClaudeAgents::ErrorHandler.validate_config(config)

      assert errors.any? { |e| e.message.include?('source_dir is required') }
      assert errors.any? { |e| e.message.include?('dest_dir is required') }
    end

    def test_validates_data_types
      config = {
        name: 123,  # Should be string
        source_dir: 'valid',
        dest_dir: 'valid'
      }

      errors = ClaudeAgents::ErrorHandler.validate_config(config)

      assert errors.any? { |e| e.message.include?('name must be a string') }
    end

    def test_validates_path_existence
      config = {
        name: 'test',
        source_dir: '/nonexistent/path',
        dest_dir: '/tmp'
      }

      errors = ClaudeAgents::ErrorHandler.validate_config(config)

      assert errors.any? { |e| e.message.include?('source_dir does not exist') }
    end

    def test_collects_all_validation_errors
      config = {}  # Completely invalid

      errors = ClaudeAgents::ErrorHandler.validate_config(config)

      assert errors.count >= 3  # At least name, source_dir, dest_dir errors
      errors.each do |error|
        assert_instance_of ClaudeAgents::ValidationError, error
      end
    end
  end

  # Test error context
  class ErrorContextTest < ErrorHandlingTest
    def test_adds_context_to_errors
      original_error = StandardError.new('Original error')

      wrapped_error = ClaudeAgents::ErrorHandler.wrap_with_context(
        original_error,
        component: 'installer',
        operation: 'clone_repository',
        details: { repo: 'test-repo' }
      )

      assert_instance_of ClaudeAgents::ContextualError, wrapped_error
      assert_equal original_error, wrapped_error.cause
      assert_equal 'installer', wrapped_error.context[:component]
      assert_equal 'clone_repository', wrapped_error.context[:operation]
      assert_equal 'test-repo', wrapped_error.context[:details][:repo]
    end

    def test_preserves_error_chain
      level1 = StandardError.new('Level 1')
      level2 = ClaudeAgents::InstallationError.new('Level 2')
      level2.set_backtrace(caller)

      begin
        begin
          raise level1
        rescue StandardError
          raise level2
        end
      rescue ClaudeAgents::InstallationError => e
        chain = ClaudeAgents::ErrorHandler.extract_error_chain(e)

        assert_equal 2, chain.length
        assert_equal 'Level 2', chain[0].message
        assert_equal 'Level 1', chain[1].message
      end
    end

    def test_formats_error_with_context
      error = ClaudeAgents::ContextualError.new(
        'Operation failed',
        component: 'symlink_manager',
        file: 'test.md',
        line: 42
      )

      formatted = ClaudeAgents::ErrorHandler.format_with_context(error)

      assert_includes formatted, 'Operation failed'
      assert_includes formatted, 'Component: symlink_manager'
      assert_includes formatted, 'File: test.md'
      assert_includes formatted, 'Line: 42'
    end
  end
end