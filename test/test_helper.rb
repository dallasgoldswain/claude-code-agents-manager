# ABOUTME: Main test configuration and helper methods for Minitest
# ABOUTME: Sets up testing environment with mocks, fixtures, and custom assertions

# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "minitest/reporters"
require "mocha/minitest"
require "fileutils"
require "tempfile"
require "tmpdir"
require "benchmark"

# Reporter selection:
# Default: SpecReporter (detailed per-test output)
# FAILURES_ONLY=1: Custom reporter that only prints failing tests + summary

if ENV["FAILURES_ONLY"] == "1"
  # Define minimal reporter only once to avoid constant redefinition noise when files are loaded
  unless defined?(ClaudeAgentsFailuresOnlyReporter)
    class ClaudeAgentsFailuresOnlyReporter < Minitest::StatisticsReporter
      def initialize(io = $stdout, options = {})
        super
        @failed = []
        @project_root = File.expand_path("..", __dir__)
      end

      def record(result)
        super
        @failed << result unless result.passed?

        # When failing fast, print the failure immediately (so user gets context before exit)
        return unless ENV["FAIL_FAST"] == "1" && !result.passed?

        print_failure_block(result, index: @failed.size)
      end

      def report
        return if count.zero?

        unless @failed.empty?
          io.puts "\nFailed tests (#{@failed.size}):"
          @failed.each_with_index { |r, i| print_failure_block(r, index: i + 1) }
        end

        summary_color = failures.zero? && errors.zero? ? "32" : "31" # green if all good else red
        parts = []
        parts << color("#{count} tests", summary_color)
        parts << color("#{assertions} assertions", "36")
        parts << color("#{failures} failures", failures.zero? ? "32" : "31;1")
        parts << color("#{errors} errors", errors.zero? ? "32" : "31;1")
        parts << color("#{skips} skips", skips.zero? ? "90" : "33")
        io.puts "\n" + parts.join(", ")
      end

      private

      def print_failure_block(result, index: 1)
        failure = result.failure
        name_line = "#{result.klass}##{result.name}"
        header = color("FAIL #{index}: #{name_line}", "31;1") # bold red
        separator = color("-" * [name_line.length + 8, 70].min, "31") # red
        io.puts "\n#{separator}\n#{header}\n#{separator}"
        if failure
          io.puts color(failure.message, "91") # bright red message
          bt = Array(failure.backtrace)
          bt = bt.select { |ln| ln.start_with?(@project_root) } if ENV["PROJECT_BT"] == "1"
          bt = bt.first(10)
          unless bt.empty?
            io.puts color("  Backtrace (top #{bt.size}):", "90") # dim label
            bt.each { |ln| io.puts color("    #{ln}", "90") }
          end
        else
          io.puts color("(No failure object captured)", "90")
        end
      end

      def color(str, code)
        force = ENV["FORCE_COLOR"] == "1" || ENV["CLICOLOR_FORCE"] == "1" || ENV["COLOR"] == "1"
        return str if ENV["NO_COLOR"] || (!$stdout.isatty && !force)

        "\e[#{code}m#{str}\e[0m"
      end
    end
  end

  Minitest::Reporters.use! ClaudeAgentsFailuresOnlyReporter.new
else
  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
end

# Fail-fast support: abort test run after first failure if FAIL_FAST=1
if ENV["FAIL_FAST"] == "1"
  module Minitest
    class Test
      alias _original_run run
      def run
        result = _original_run
        # If this test failed or errored, abort immediately.
        unless passed?
          unless ENV["FAILURES_ONLY"] == "1"
            # When not using failures-only reporter, emit a concise failure block now.
            failure = self.failure
            name_line = "#{self.class}##{name}"
            project_root = File.expand_path("..", __dir__)
            separator = color("-" * [name_line.length + 8, 70].min, "31")
            puts "\n#{separator}\n#{color("FAIL 1: #{name_line}", '31;1')}\n#{separator}"
            if failure
              puts color(failure.message, "91")
              bt = Array(failure.backtrace)
              bt = bt.select { |ln| ln.start_with?(project_root) } if ENV["PROJECT_BT"] == "1"
              bt = bt.first(10)
              unless bt.empty?
                puts color("  Backtrace (top #{bt.size}):", "90")
                bt.each { |ln| puts color("    #{ln}", "90") }
              end
            end
          end
          puts color("\nAborting test run (FAIL_FAST=1).", "33")
          exit 1
        end
        result
      end

      private

      def color(str, code)
        force = ENV["FORCE_COLOR"] == "1" || ENV["CLICOLOR_FORCE"] == "1" || ENV["COLOR"] == "1"
        return str if ENV["NO_COLOR"] || (!$stdout.isatty && !force)

        "\e[#{code}m#{str}\e[0m"
      end
    end
  end
end

# Load the main application
require "claude_agents"

# Test support modules
require_relative "support/test_fixtures"
require_relative "support/filesystem_helpers"
require_relative "support/cli_helpers"

module TestHelpers
  # Test environment configuration
  def setup
    super
    setup_test_environment
  end

  def teardown
    cleanup_test_environment
    super
  end

  # Create a test UI instance that captures output
  def create_test_ui
    ui = ClaudeAgents::UI.new

    # Mock TTY methods to work in test environment
    ui.define_singleton_method(:puts) { |msg| $stdout.puts(msg) }
    ui.define_singleton_method(:print) { |msg| $stdout.print(msg) }

    # Mock interactive prompts
    prompt = Object.new
    prompt.define_singleton_method(:multi_select) { |_, choices:| choices.map { |c| c[:value] } }
    prompt.define_singleton_method(:select) { |_, choices| choices.first }
    prompt.define_singleton_method(:yes?) { |_| true }

    ui.define_singleton_method(:prompt) { prompt }

    # Mock UI output methods to prevent TTY dependencies
    %w[success info warn error linked removed skipped].each do |method|
      ui.define_singleton_method(method) { |msg| puts "[#{method.upcase}] #{msg}" }
    end

    # Mock progress methods
    ui.define_singleton_method(:progress_bar) do |_title, _total|
      progress = Object.new
      progress.define_singleton_method(:advance) {}
      progress.define_singleton_method(:finish) {}
      progress
    end

    ui.define_singleton_method(:title) { |msg| puts "=== #{msg} ===" }
    ui.define_singleton_method(:subsection) { |msg| puts "--- #{msg} ---" }
    ui.define_singleton_method(:newline) { puts }
    ui.define_singleton_method(:dim) { |msg| puts msg }

    ui
  end

  private

  def setup_test_environment
    # Create temporary test directory
    @test_dir = Dir.mktmpdir("claude_agents_test")
    @original_claude_dir = ClaudeAgents::Config.instance_variable_get(:@claude_dir)

    # Override paths to use test directory
    ClaudeAgents::Config.instance_variable_set(:@claude_dir, @test_dir)
    ClaudeAgents::Config.instance_variable_set(:@agents_dir, File.join(@test_dir, "agents"))
    ClaudeAgents::Config.instance_variable_set(:@commands_dir, File.join(@test_dir, "commands"))
    ClaudeAgents::Config.instance_variable_set(:@tools_dir,
                                               File.join(@test_dir, "commands", "tools"))
    ClaudeAgents::Config.instance_variable_set(:@workflows_dir,
                                               File.join(@test_dir, "commands", "workflows"))

    # Create test directories
    ClaudeAgents::Config.ensure_directories!
  end

  def cleanup_test_environment
    # Restore original paths
    ClaudeAgents::Config.instance_variable_set(:@claude_dir, @original_claude_dir)
    ClaudeAgents::Config.instance_variable_set(:@agents_dir, nil)
    ClaudeAgents::Config.instance_variable_set(:@commands_dir, nil)
    ClaudeAgents::Config.instance_variable_set(:@tools_dir, nil)
    ClaudeAgents::Config.instance_variable_set(:@workflows_dir, nil)

    # Clean up test directory
    FileUtils.rm_rf(@test_dir) if @test_dir && Dir.exist?(@test_dir)
  end

  # Test directory accessors
  def test_claude_dir
    @test_dir
  end

  def test_agents_dir
    File.join(@test_dir, "agents")
  end

  def test_commands_dir
    File.join(@test_dir, "commands")
  end

  def test_tools_dir
    File.join(@test_dir, "commands", "tools")
  end

  def test_workflows_dir
    File.join(@test_dir, "commands", "workflows")
  end
end

# Performance testing helpers
module PerformanceHelpers
  def assert_performance_under(threshold, &)
    time = Benchmark.realtime(&)
    assert time < threshold, "Expected execution under #{threshold}s, but took #{time.round(3)}s"
  end

  def assert_memory_usage_under(threshold_mb)
    before = memory_usage_mb
    yield
    after = memory_usage_mb
    usage = after - before

    assert usage < threshold_mb,
           "Expected memory usage under #{threshold_mb}MB, but used #{usage.round(2)}MB"
  end

  private

  def memory_usage_mb
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  rescue StandardError
    0
  end
end

# Custom assertions for CLI testing
module CLIAssertions
  def assert_command_succeeds(command_args, message = nil)
    result = run_cli_command(command_args)
    assert_equal 0, result[:exit_code], message || "Command failed: #{result[:stderr]}"
    result
  end

  def assert_command_fails(command_args, message = nil)
    result = run_cli_command(command_args)
    refute_equal 0, result[:exit_code], message || "Command should have failed but succeeded"
    result
  end

  def assert_symlink_exists(path, message = nil)
    assert File.symlink?(path), message || "Expected symlink at #{path}"
  end

  def assert_symlink_points_to(symlink_path, target_path, message = nil)
    assert File.symlink?(symlink_path), "Expected #{symlink_path} to be a symlink"
    actual_target = File.readlink(symlink_path)
    expected_target = File.expand_path(target_path)
    assert_equal expected_target, actual_target,
                 message || "Expected symlink to point to #{expected_target}, but points to #{actual_target}"
  end

  def assert_file_count(directory, expected_count, pattern = "*", message = nil)
    files = Dir.glob(File.join(directory, pattern))
    actual_count = files.length
    assert_equal expected_count, actual_count,
                 message || "Expected #{expected_count} files in #{directory}, found #{actual_count}"
  end
end

# Base test class for unit tests
class ClaudeAgentsTest < Minitest::Test
  include TestHelpers
  include PerformanceHelpers
  include CLIAssertions
  include FilesystemHelpers
end

# Base test class for integration tests
class IntegrationTest < Minitest::Test
  include TestHelpers
  include PerformanceHelpers
  include CLIAssertions
  include FilesystemHelpers
  include CLIHelpers
end
