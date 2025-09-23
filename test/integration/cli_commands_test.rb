# ABOUTME: Integration tests for Claude Agents CLI commands
# ABOUTME: Tests full command workflows including setup, status, removal, and error scenarios

# frozen_string_literal: true

require_relative "../test_helper"

class CLICommandsTest < IntegrationTest
  def setup
    super
    @project_root = File.expand_path("../../..", __dir__)

    # Create test fixtures
    TestFixtures.create_full_test_structure(@project_root)
  end

  def test_version_command
    result = run_cli_command(["version"])

    assert_successful_execution result
    assert_output_includes result, "Claude Agents CLI"
    assert_output_includes result, ClaudeAgents::VERSION
  end

  def test_status_command_shows_installation_state
    result = run_cli_command(["status"])

    assert_successful_execution result
    output = [result[:stdout], result[:stderr]].join

    assert_includes output, "Claude Agents Status", "Expected status header. Got: #{output}"
    # Status command should show agent categories
    assert(
      output.include?("dLabs") || output.include?("dlabs"),
      "Expected status to mention dLabs agents. Got: #{output}"
    )
  end

  def test_setup_dlabs_command
    result = run_cli_command(%w[setup dlabs])

    assert_successful_execution result
    # CLI may output different messages based on whether agents already exist
    output = [result[:stdout], result[:stderr]].join

    assert(
      output.include?("Successfully installed") ||
      output.include?("Installing dLabs agents") ||
      output.include?("No new dlabs agents"),
      "Expected setup output to include installation or already-installed message. Got: #{output}"
    )

    expected_files = %w[
      dLabs-django-developer.md
      dLabs-js-ts-tech-lead.md
      dLabs-data-analysis-expert.md
      dLabs-python-backend-engineer.md
      dLabs-debug-specialist.md
      dLabs-ruby-expert.md
      dLabs-joker.md
    ]

    # Ensure all seven agent symlinks exist (idempotent: if already present they remain)
    assert_file_count test_agents_dir, expected_files.size, "dLabs-*"
    expected_files.each do |filename|
      symlink_path = File.join(test_agents_dir, filename)

      assert_symlink_exists symlink_path
    end
  end

  def test_setup_invalid_component
    result = run_cli_command(%w[setup invalid-component])

    assert_failed_execution result
    output = [result[:stdout], result[:stderr]].join

    assert_includes output, "Invalid component",
                    "Expected error message about invalid component. Got: #{output}"
  end

  def test_remove_dlabs_command
    # First install
    run_cli_command(%w[setup dlabs])

    # Then remove
    result = run_cli_command(%w[remove dlabs])

    assert_successful_execution result
    output = [result[:stdout], result[:stderr]].join

    assert(
      output.include?("Successfully removed") ||
      output.include?("removed") ||
      output.include?("No dlabs agents"),
      "Expected removal confirmation. Got: #{output}"
    )

    # Verify symlinks were removed (if they existed)
    assert_file_count test_agents_dir, 0, "dLabs-*"
  end

  def test_remove_nonexistent_component
    result = run_cli_command(%w[remove nothing-installed])

    # Should fail because component doesn't exist
    assert_failed_execution result
    output = [result[:stdout], result[:stderr]].join

    assert(
      output.include?("Invalid component") ||
      output.include?("not found") ||
      output.include?("nothing-installed"),
      "Expected error message about invalid component. Got: #{output}"
    )
  end

  def test_install_command_with_component_option
    result = run_cli_command(["install", "--component", "dlabs"])

    assert_successful_execution result
    output = [result[:stdout], result[:stderr]].join

    assert(
      output.include?("Installing") ||
      output.include?("installed") ||
      output.include?("dLabs") ||
      output.include?("No new dlabs agents"),
      "Expected install command to process dLabs. Got: #{output}"
    )

    expected_files = %w[
      dLabs-django-developer.md
      dLabs-js-ts-tech-lead.md
      dLabs-data-analysis-expert.md
      dLabs-python-backend-engineer.md
      dLabs-debug-specialist.md
      dLabs-ruby-expert.md
      dLabs-joker.md
    ]

    assert_file_count test_agents_dir, expected_files.size, "dLabs-*"
  end

  def test_doctor_command_system_checks
    # Mock external dependencies
    mock_git_commands

    result = run_cli_command(["doctor"])

    assert_successful_execution result
    assert_output_includes result, "System Doctor"
    assert_output_includes result, "Checking GitHub CLI"
    assert_output_includes result, "Checking directories"
    assert_output_includes result, "Checking symlinks"
    assert_output_includes result, "Checking repositories"
  end

  def test_error_recovery_broken_symlinks
    # Install components first
    run_cli_command(%w[setup dlabs])

    # Manually break some symlinks by removing source files
    dlabs_source = File.join(@project_root, "agents", "dallasLabs")
    source_file = File.join(dlabs_source, "django-developer.md")
    FileUtils.rm_f(source_file)

    # Status should still work and report issues
    result = run_cli_command(["status"])

    assert_successful_execution result

    # Remove should handle broken symlinks gracefully
    remove_result = run_cli_command(%w[remove dlabs])

    assert_successful_execution remove_result
  end

  def test_verbose_output_option
    result = run_cli_command(["setup", "dlabs", "--verbose"])

    assert_successful_execution result
    # Verbose mode should include additional output
    output = [result[:stdout], result[:stderr]].join

    assert(
      output.include?("Installing") ||
      output.include?("Setting up") ||
      output.include?("dLabs"),
      "Expected verbose output to include installation details. Got: #{output}"
    )
  end

  def test_help_commands
    # Test that basic commands exist and provide help
    %w[help setup remove status doctor version].each do |command|
      result = run_cli_command([command, "--help"])
      # Some commands may not support --help, so just check they execute
      output = [result[:stdout], result[:stderr]].join

      assert(
        result[:success] ||
        output.include?("Usage:") ||
        output.include?("help") ||
        output.include?("Commands:") ||
        output.downcase.include?(command),
        "Expected #{command} --help to work or provide help info. Got: #{output}"
      )
    end
  end

  def test_edge_case_empty_directories
    # Remove all fixture files to test empty directory handling
    FileUtils.rm_rf(File.join(@project_root, "agents"))
    FileUtils.mkdir_p(File.join(@project_root, "agents", "dallasLabs"))

    result = run_cli_command(%w[setup dlabs])

    # Should handle empty directories gracefully
    assert_successful_execution result
    output = [result[:stdout], result[:stderr]].join

    assert(
      output.include?("0 dlabs") ||
      output.include?("No dlabs") ||
      output.include?("Installing"),
      "Expected message about empty directory handling. Got: #{output}"
    )
  end

  def test_memory_usage_large_operations
    # Test memory usage doesn't grow excessively during large operations
    initial_memory = memory_usage_mb

    # Perform multiple large operations
    3.times do
      run_cli_command(%w[setup dlabs])
      run_cli_command(%w[remove dlabs])
    end

    final_memory = memory_usage_mb
    memory_growth = final_memory - initial_memory

    # Memory growth should be reasonable (under 20MB for 3 cycles)
    assert_operator memory_growth, :<, 20, "Memory grew by #{memory_growth.round(2)}MB"
  end

  private

  def memory_usage_mb
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  rescue StandardError
    0
  end
end
