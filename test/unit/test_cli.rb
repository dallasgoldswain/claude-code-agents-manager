# frozen_string_literal: true

require_relative '../test_helper'

# Test suite for the main CLI interface
# Focuses on command registration, basic functionality, and error handling
class TestCLI < ClaudeAgentsTest
  include CLITestHelper

  def setup
    super
    @cli = ClaudeAgents::CLI.new
  end

  # Test basic CLI initialization and structure
  def test_cli_initialization
    assert_instance_of ClaudeAgents::CLI, @cli
    assert_respond_to @cli, :ui
    assert_instance_of ClaudeAgents::UI, @cli.ui
  end

  # Test Thor command registration - ensuring all commands are available
  def test_all_commands_registered
    expected_commands = %w[doctor status version install setup remove]

    # Get registered Thor commands
    registered_commands = @cli.class.commands.keys

    expected_commands.each do |command|
      assert_includes registered_commands, command, "Command '#{command}' should be registered"
    end
  end

  # Test version command output
  def test_version_command_output
    stdout, _stderr = run_command(:version)

    assert_includes stdout, "Claude Agents CLI v#{ClaudeAgents::VERSION}"
    assert_includes stdout, 'A comprehensive management system'
    assert_includes stdout, 'Components:'
    assert_includes stdout, 'dLabs agents'
    assert_includes stdout, 'wshobson agents'
    assert_includes stdout, 'GitHub:'
  end

  # Test help command shows all available commands
  def test_help_command_shows_all_commands
    stdout, _stderr = run_command(:help)

    %w[doctor status version install setup remove].each do |command|
      assert_includes stdout, command, "Help should include '#{command}' command"
    end
  end

  # Test doctor command basic functionality (without full health checks)
  def test_doctor_command_executes
    # Mock the doctor runner to avoid external dependencies
    mock_runner = mock('Doctor::Runner')
    mock_runner.expects(:call).returns(true)
    ClaudeAgents::CLI::Doctor::Runner.expects(:new).returns(mock_runner)

    stdout, stderr = run_command(:doctor)

    # Should not crash and should execute runner
    assert_empty stderr
  end

  # Test status command basic functionality
  def test_status_command_executes
    # Mock the UI instance that will be created (setup already creates one instance)
    mock_ui = mock('UI')
    mock_ui.expects(:display_status).returns(nil)

    # We need to allow UI.new to be called twice - once in setup, once in run_command
    ClaudeAgents::UI.stubs(:new).returns(mock_ui)

    stdout, stderr = run_command(:status)

    # Should not crash
    assert_empty stderr
  end

  # Test invalid command handling
  def test_invalid_command_shows_help
    # Try to invoke a non-existent command
    # Thor invocation of non-existent commands causes RuntimeError about missing Thor class
    error = assert_raises(RuntimeError) do
      @cli.invoke(:nonexistent_command, [])
    end
    assert_match(/Missing Thor class/, error.message)
  end

  # Test setup command with valid component
  def test_setup_command_with_valid_component
    # Mock the installer
    mock_installer = mock('Installer')
    mock_installer.expects(:install_component).with('dlabs').returns({created_links: 5})
    ClaudeAgents::Installer.expects(:new).returns(mock_installer)

    # Mock component validation
    ClaudeAgents::Config.expects(:valid_component?).with('dlabs').returns(true)

    stdout, stderr = run_command(:setup, 'dlabs')

    # Should execute without errors
    assert_empty stderr
  end

  # Test setup command with invalid component
  def test_setup_command_with_invalid_component
    # Mock component validation to return false
    ClaudeAgents::Config.expects(:valid_component?).with('invalid').returns(false)
    ClaudeAgents::Config.expects(:all_components).returns(['dlabs', 'wshobson_agents'])

    stdout, stderr = run_command(:setup, 'invalid')

    # Should show error about invalid component
    combined_output = stdout + stderr
    assert_match(/Invalid component/, combined_output)
  end

  # Test remove command basic functionality
  def test_remove_command_executes
    # Mock the remover - when no argument is passed, it calls interactive_remove
    mock_remover = mock('Remover')
    mock_remover.expects(:interactive_remove).returns(true)
    ClaudeAgents::Remover.expects(:new).returns(mock_remover)

    stdout, stderr = run_command(:remove)

    # Should execute without crashing
    assert_empty stderr
  end

  # Test install command basic functionality
  def test_install_command_executes
    # Mock the installer - when no options are passed, it calls interactive_install
    mock_installer = mock('Installer')
    mock_installer.expects(:interactive_install).returns({})
    ClaudeAgents::Installer.expects(:new).returns(mock_installer)

    stdout, stderr = run_command(:install)

    # Should execute without crashing
    assert_empty stderr
  end

  # Test error handling in commands
  def test_command_error_handling
    # Mock an error in the doctor command
    ClaudeAgents::CLI::Doctor::Runner.expects(:new).raises(StandardError.new('Test error'))
    ClaudeAgents::ErrorHandler.expects(:handle_error).with(
      instance_of(StandardError),
      instance_of(ClaudeAgents::UI)
    )

    stdout, stderr = run_command(:doctor)

    # Error should be handled gracefully
  end

  # Test exit_on_failure? method exists (fixes Thor deprecation)
  def test_exit_on_failure_method_exists
    assert_respond_to ClaudeAgents::CLI, :exit_on_failure?
    assert_equal true, ClaudeAgents::CLI.exit_on_failure?
  end

  # Test CLI options are properly configured
  def test_cli_options_configured
    options = @cli.class.class_options

    assert_includes options.keys, :verbose
    assert_includes options.keys, :no_color

    # Test verbose option
    verbose_option = options[:verbose]
    assert_equal :boolean, verbose_option.type
    assert_includes verbose_option.aliases, '-v'

    # Test no_color option
    no_color_option = options[:no_color]
    assert_equal :boolean, no_color_option.type
  end

  private

  # Override run_command to handle Thor specifics
  def run_command(command, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    arguments = args.flatten

    capture_output do
      begin
        # Create fresh CLI instance to avoid state pollution
        cli = ClaudeAgents::CLI.new
        cli.invoke(command, arguments, options)
      rescue SystemExit => e
        @exit_code = e.status
      rescue Thor::Error => e
        # Thor errors should be captured in stderr
        $stderr.puts e.message
      end
    end
  end
end