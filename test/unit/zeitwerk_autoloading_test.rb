# ABOUTME: Tests for Zeitwerk autoloading behavior and configuration
# ABOUTME: Ensures proper autoloading of ClaudeAgents service classes without explicit requires

# frozen_string_literal: true

require "test_helper"

class ZeitwerkAutoloadingTest < ClaudeAgentsTest
  def test_zeitwerk_is_available
    assert defined?(Zeitwerk), "Zeitwerk gem should be available"
  end

  def test_zeitwerk_loader_is_configured_for_claude_agents
    # Check that a loader exists for this gem
    loaders_collection = Zeitwerk::Registry.loaders
    # Registry.loaders returns a Zeitwerk::Registry::Loaders, check it has items
    assert_predicate loaders_collection.instance_variable_get(:@loaders), :any?,
                     "Zeitwerk loader should be configured for ClaudeAgents gem"
  end

  def test_zeitwerk_inflector_configured_for_ui_and_cli
    # Check that the inflector is properly configured
    loaders_collection = Zeitwerk::Registry.loaders
    loader = loaders_collection.instance_variable_get(:@loaders).first

    assert_equal "UI", loader.inflector.camelize("ui", nil), "UI should be properly inflected"
    assert_equal "CLI", loader.inflector.camelize("cli", nil), "CLI should be properly inflected"
  end

  def test_all_service_classes_autoload_without_explicit_requires
    # This will fail until we move CLI file and configure autoloading
    expected_classes = %w[
      ClaudeAgents::Config
      ClaudeAgents::UI
      ClaudeAgents::FileProcessor
      ClaudeAgents::SymlinkManager
      ClaudeAgents::Installer
      ClaudeAgents::Remover
      ClaudeAgents::CLI
    ]

    expected_classes.each do |class_name|
      assert Object.const_defined?(class_name),
             "#{class_name} should be autoloaded without explicit require"
      actual_class = Object.const_get(class_name)

      assert_kind_of Class, actual_class, "#{class_name} should be a class"
    end
  end

  def test_error_classes_autoload_properly
    # This should work since errors.rb is already properly namespaced
    error_classes = %w[
      ClaudeAgents::Error
      ClaudeAgents::InstallationError
      ClaudeAgents::RemovalError
      ClaudeAgents::FileOperationError
      ClaudeAgents::ValidationError
      ClaudeAgents::RepositoryError
      ClaudeAgents::SymlinkError
      ClaudeAgents::UserCancelledError
    ]

    error_classes.each do |class_name|
      assert Object.const_defined?(class_name), "#{class_name} should be autoloaded"
      error_class = Object.const_get(class_name)

      assert_operator error_class, :<, StandardError,
                      "#{class_name} should inherit from StandardError"
    end
  end

  def test_no_manual_requires_in_main_module
    # Check that most service classes don't need manual requires (errors is exception)
    main_file = File.read(File.expand_path("../../lib/claude_agents.rb", __dir__))

    # Should not contain manual require_relative statements for autoloaded service classes
    forbidden_requires = [
      'require_relative "claude_agents/config"',
      'require_relative "claude_agents/ui"',
      'require_relative "claude_agents/file_processor"',
      'require_relative "claude_agents/symlink_manager"',
      'require_relative "claude_agents/installer"',
      'require_relative "claude_agents/remover"',
      'require_relative "claude_agents_cli"'
    ]

    forbidden_requires.each do |forbidden_require|
      refute_includes main_file, forbidden_require,
                      "Main module should not contain manual require: #{forbidden_require}"
    end

    # Errors is manually required due to Zeitwerk convention conflict
    assert_includes main_file, 'require_relative "claude_agents/errors"',
                    "Errors should be manually required due to naming convention conflict"
  end

  def test_cli_file_is_in_correct_location_for_zeitwerk
    # This will fail until we move claude_agents_cli.rb to claude_agents/cli.rb
    expected_cli_path = File.expand_path("../../lib/claude_agents/cli.rb", __dir__)
    old_cli_path = File.expand_path("../../lib/claude_agents_cli.rb", __dir__)

    assert_path_exists expected_cli_path,
                       "CLI file should be at lib/claude_agents/cli.rb for Zeitwerk"
    refute_path_exists old_cli_path, "Old CLI file should be moved from lib/claude_agents_cli.rb"
  end

  def test_zeitwerk_loader_setup_and_eager_load_configuration
    # Check that the loader is properly set up
    loader = Zeitwerk::Registry.loaders.instance_variable_get(:@loaders).first

    # Should be set up but not necessarily eager loaded in tests
    assert_predicate loader.dirs, :any?, "Zeitwerk loader should have directories configured"

    # Eager loading should be controlled by environment variable
    skip unless ENV["CLAUDE_AGENTS_EAGER_LOAD"] == "true"

    # In eager load mode, everything should be loaded
    assert Object.const_defined?("ClaudeAgents::Config"), "Config should be loaded in eager mode"
    assert Object.const_defined?("ClaudeAgents::CLI"), "CLI should be loaded in eager mode"
  end

  def test_zeitwerk_autoloading_works_on_demand
    # This will fail until Zeitwerk is properly configured
    # Test that classes are available without explicit requires
    ui_class = ClaudeAgents::UI

    assert_kind_of Class, ui_class, "UI class should be autoloaded on demand"
    assert_equal ClaudeAgents::UI, ui_class, "Autoloaded class should be correct"

    # Test that multiple classes can be loaded
    config_class = ClaudeAgents::Config

    assert_kind_of Module, config_class, "Config should be autoloaded on demand"
  end

  def test_no_circular_dependencies_with_zeitwerk
    # This should pass with current clean architecture

    # Access multiple classes that depend on each other
    installer = ClaudeAgents::Installer.new(ClaudeAgents::UI.new)
    remover = ClaudeAgents::Remover.new(ClaudeAgents::UI.new)

    assert_respond_to installer, :install_component
    assert_respond_to remover, :remove_component
  rescue StandardError => e
    flunk "Zeitwerk autoloading should not create circular dependencies: #{e.message}"
  end
end
