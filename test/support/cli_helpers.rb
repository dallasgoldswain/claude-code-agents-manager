# ABOUTME: Helper methods for testing CLI commands and Thor interactions
# ABOUTME: Provides command execution, output capture, and CLI assertion helpers

# frozen_string_literal: true

require "open3"
require "stringio"

module CLIHelpers
  # Execute CLI commands in test environment
  def run_cli_command(args, env: {})
    # Prepare environment
    test_env = {
      "CLAUDE_DIR" => test_claude_dir,
      "BUNDLE_GEMFILE" => File.expand_path("../../Gemfile", __dir__)
    }.merge(env)

    cli_path = File.expand_path("../../bin/claude-agents", __dir__)
    cmd = "#{cli_path} #{args.join(' ')}"

    stdout, stderr, status = Open3.capture3(test_env, cmd)

    {
      stdout: stdout,
      stderr: stderr,
      exit_code: status.exitstatus,
      success: status.success?
    }
  end

  # Mock Thor command execution for unit testing
  def run_thor_command(command_class, command_name, args = [], options = {})
    # Capture output
    old_stdout = $stdout
    old_stderr = $stderr
    stdout = StringIO.new
    stderr = StringIO.new

    begin
      $stdout = stdout
      $stderr = stderr

      # Create instance with test UI
      instance = command_class.new([], options)
      instance.instance_variable_set(:@ui, create_test_ui)

      # Execute command
      instance.invoke(command_name, args)

      {
        stdout: stdout.string,
        stderr: stderr.string,
        success: true
      }
    rescue SystemExit => e
      {
        stdout: stdout.string,
        stderr: stderr.string,
        exit_code: e.status,
        success: e.status.zero?
      }
    rescue StandardError => e
      {
        stdout: stdout.string,
        stderr: stderr.string,
        error: e,
        success: false
      }
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end
  end

  # Assertion helpers for CLI output
  def assert_output_includes(result, text, message = nil)
    output = [result[:stdout], result[:stderr]].join
    assert_includes output, text, message || "Expected output to include '#{text}'"
  end

  def assert_output_matches(result, pattern, message = nil)
    output = [result[:stdout], result[:stderr]].join
    assert_match pattern, output, message || "Expected output to match #{pattern}"
  end

  def assert_successful_execution(result, message = nil)
    assert result[:success], message || "Command failed: #{result[:stderr]}"
  end

  def assert_failed_execution(result, message = nil)
    refute result[:success], message || "Command should have failed but succeeded"
  end

  # CLI integration test helpers
  def simulate_user_input(input)
    old_stdin = $stdin
    $stdin = StringIO.new(input)
    yield
  ensure
    $stdin = old_stdin
  end

  def capture_output
    old_stdout = $stdout
    old_stderr = $stderr
    stdout = StringIO.new
    stderr = StringIO.new

    begin
      $stdout = stdout
      $stderr = stderr
      yield
      {
        stdout: stdout.string,
        stderr: stderr.string
      }
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end
  end

  # Mock external commands
  def mock_system_command(command, return_value: true)
    # Store original method if not already stored
    @original_system = Object.method(:system) unless defined?(@original_system)

    # Mock the system command
    Object.define_singleton_method(:system) do |cmd|
      if cmd.include?(command)
        return_value
      else
        @original_system.call(cmd)
      end
    end
  end

  def restore_system_command
    return unless defined?(@original_system)

    Object.define_singleton_method(:system, @original_system)
  end

  def mock_git_commands
    mock_system_command("git", return_value: true)
    mock_system_command("gh", return_value: true)
  end
end
