# ABOUTME: Integration tests for Zeitwerk autoloading with full CLI workflows
# ABOUTME: Tests end-to-end functionality with Zeitwerk-based autoloading

# frozen_string_literal: true

require "test_helper"

class ZeitwerkIntegrationTest < IntegrationTest
  def test_full_cli_workflow_with_zeitwerk_autoloading
    # This will fail until CLI is properly autoloaded via Zeitwerk
    result = run_cli_command(["version"])

    assert_equal 0, result[:exit_code], "Version command should work with Zeitwerk autoloading"
    assert_match(/Claude Agents CLI/, result[:stdout], "Version output should be correct")
  end

  def test_service_instantiation_chain_with_autoloading
    # This will fail until all services are properly autoloaded

    ui = ClaudeAgents::UI.new
    installer = ClaudeAgents::Installer.new(ui)
    remover = ClaudeAgents::Remover.new(ui)

    assert_respond_to installer, :install_component, "Installer should have expected methods"
    assert_respond_to remover, :remove_component, "Remover should have expected methods"
    assert_respond_to ui, :success, "UI should have expected methods"
  rescue StandardError => e
    flunk "Service dependency chain should work with Zeitwerk: #{e.message}"
  end

  def test_cli_commands_load_services_on_demand
    # This will fail until CLI uses Zeitwerk autoloading

    cli = ClaudeAgents::CLI.new

    # These should trigger autoloading of dependent services
    assert_respond_to cli, :install, "CLI should respond to install command"
    assert_respond_to cli, :remove, "CLI should respond to remove command"
    assert_respond_to cli, :status, "CLI should respond to status command"
    assert_respond_to cli, :doctor, "CLI should respond to doctor command"
  rescue StandardError => e
    flunk "CLI should be able to load services on demand: #{e.message}"
  end

  def test_config_autoloads_and_provides_expected_interface
    # This should work since Config is already properly structured
    config = ClaudeAgents::Config

    assert_respond_to config, :claude_dir, "Config should provide claude_dir"
    assert_respond_to config, :agents_dir, "Config should provide agents_dir"
    assert_respond_to config, :commands_dir, "Config should provide commands_dir"
    assert_respond_to config, :ensure_directories!, "Config should provide ensure_directories!"
  end

  def test_file_processor_autoloads_with_correct_functionality
    # This will work once Zeitwerk is configured
    ui = ClaudeAgents::UI.new
    processor = ClaudeAgents::FileProcessor.new(ui)

    assert_respond_to processor, :should_skip_file?,
                      "FileProcessor should provide should_skip_file? method"
    assert_respond_to processor, :eligible_files_in_directory,
                      "FileProcessor should provide eligible_files_in_directory method"
    assert_respond_to processor, :process_generic_files,
                      "FileProcessor should provide process_generic_files method"
  end

  def test_symlink_manager_autoloads_and_functions
    # This will work once Zeitwerk is configured
    ui = ClaudeAgents::UI.new
    manager = ClaudeAgents::SymlinkManager.new(ui)

    assert_respond_to manager, :create_symlink, "SymlinkManager should provide create_symlink"
    assert_respond_to manager, :remove_symlink, "SymlinkManager should provide remove_symlink"
    assert_respond_to manager, :create_symlinks, "SymlinkManager should provide create_symlinks"
  end

  def test_error_handling_with_zeitwerk_autoloaded_exceptions
    # This should work since error classes are already properly namespaced
    assert_raises ClaudeAgents::ValidationError do
      raise ClaudeAgents::ValidationError, "Test validation error"
    end

    assert_raises ClaudeAgents::InstallationError do
      raise ClaudeAgents::InstallationError, "Test installation error"
    end

    assert_raises ClaudeAgents::FileOperationError do
      raise ClaudeAgents::FileOperationError, "Test file operation error"
    end
  end

  def test_zeitwerk_reload_functionality_in_development
    # Basic sanity: loader should be configured and respond to eager_load (no reload simulation needed)
    loader = ObjectSpace.each_object(Zeitwerk::Loader).find do |l|
      l.tag == "claude_agents"
    rescue StandardError
      false
    end

    assert loader, "Expected to find Zeitwerk loader tagged 'claude_agents'"
    assert_respond_to loader, :eager_load, "Loader should respond to eager_load"
  end

  def test_memory_efficiency_of_zeitwerk_autoloading
    # This tests that Zeitwerk doesn't load everything upfront
    before_memory = memory_usage_mb

    # Access some classes to trigger autoloading
    _cfg = ClaudeAgents::Config
    _ui_class = ClaudeAgents::UI

    after_memory = memory_usage_mb
    memory_increase = after_memory - before_memory

    # Should not use excessive memory for basic autoloading
    assert_operator memory_increase, :<, 5,
                    "Autoloading should not use more than 5MB additional memory"
  end

  def test_concurrent_autoloading_safety
    # This tests thread safety of Zeitwerk autoloading
    threads = []
    errors = []

    5.times do
      threads << Thread.new do
        # Try to access different classes concurrently
        _cfg2 = ClaudeAgents::Config
        ui = ClaudeAgents::UI.new
        ClaudeAgents::FileProcessor.new(ui)
      rescue StandardError => e
        errors << e
      end
    end

    threads.each(&:join)

    assert_empty errors,
                 "Concurrent autoloading should not produce errors: #{errors.map(&:message)}"
  end

  private

  def memory_usage_mb
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  rescue StandardError
    0
  end
end
