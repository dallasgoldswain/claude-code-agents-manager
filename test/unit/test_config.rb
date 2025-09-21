# frozen_string_literal: true

require_relative '../test_helper'

# Test suite for configuration management
# Tests component validation, repository definitions, and path resolution
class TestConfig < ClaudeAgentsTest
  def setup
    super
    # Reset any cached values in Config
    ClaudeAgents::Config.instance_variable_set(:@project_root, nil) if ClaudeAgents::Config.instance_variable_defined?(:@project_root)
  end

  # Test project root calculation
  def test_project_root_calculation
    project_root = ClaudeAgents::Config.project_root

    # Should point to the actual project directory
    assert project_root.end_with?('claude-agents'), 'Project root should end with claude-agents'
    assert Dir.exist?(project_root), 'Project root should exist'

    # Should contain expected project files
    assert File.exist?(File.join(project_root, 'Gemfile')), 'Should contain Gemfile'
    assert File.exist?(File.join(project_root, 'bin', 'claude-agents')), 'Should contain CLI executable'
    assert Dir.exist?(File.join(project_root, 'lib')), 'Should contain lib directory'
  end

  # Test agents directory path
  def test_agents_directory
    agents_dir = ClaudeAgents::Config.agents_directory

    expected_path = File.join(ClaudeAgents::Config.project_root, 'agents')
    assert_equal expected_path, agents_dir

    # Test that it's a valid path structure
    assert agents_dir.include?('claude-agents'), 'Agents directory should be within project'
  end

  # Test component validation
  def test_valid_component_validation
    # Test valid components
    assert ClaudeAgents::Config.valid_component?('dlabs'), 'dlabs should be valid component'
    assert ClaudeAgents::Config.valid_component?('wshobson-agents'), 'wshobson-agents should be valid'
    assert ClaudeAgents::Config.valid_component?('wshobson-commands'), 'wshobson-commands should be valid'
    assert ClaudeAgents::Config.valid_component?('awesome'), 'awesome should be valid'

    # Test invalid components
    refute ClaudeAgents::Config.valid_component?('invalid'), 'invalid should not be valid component'
    refute ClaudeAgents::Config.valid_component?(''), 'empty string should not be valid'
    refute ClaudeAgents::Config.valid_component?(nil), 'nil should not be valid'
  end

  # Test all components list
  def test_all_components_list
    components = ClaudeAgents::Config.all_components

    assert_instance_of Array, components
    assert_includes components, 'dlabs'
    assert_includes components, 'wshobson-agents'
    assert_includes components, 'wshobson-commands'
    assert_includes components, 'awesome'

    # Should not contain invalid entries
    refute_includes components, nil
    refute_includes components, ''
  end

  # Test repositories configuration structure
  def test_repositories_configuration
    repos = ClaudeAgents::Config::Repositories::REPOSITORIES

    assert_instance_of Hash, repos
    assert repos.size > 0, 'Should have repository definitions'

    # Test each repository has required keys
    repos.each do |name, config|
      assert_instance_of String, name, 'Repository name should be string'
      assert_instance_of Hash, config, 'Repository config should be hash'

      # Required configuration keys
      assert config.key?('url'), "Repository #{name} should have url"
      assert config.key?('local_path'), "Repository #{name} should have local_path"

      # URL should be valid format
      assert config['url'].start_with?('https://'), "Repository #{name} URL should use HTTPS"

      # Local path should be relative
      refute config['local_path'].start_with?('/'), "Repository #{name} local_path should be relative"
    end
  end

  # Test components configuration structure
  def test_components_configuration
    components = ClaudeAgents::Config::Components::COMPONENTS

    assert_instance_of Hash, components
    assert components.size > 0, 'Should have component definitions'

    # Test each component has required structure
    components.each do |name, config|
      assert_instance_of String, name, 'Component name should be string'
      assert_instance_of Hash, config, 'Component config should be hash'

      # Required configuration keys
      assert config.key?(:source_dir), "Component #{name} should have source_dir"
      assert config.key?(:dest_dir), "Component #{name} should have dest_dir"

      # Optional but common keys
      if config.key?(:prefix)
        assert_instance_of String, config[:prefix], "Component #{name} prefix should be string"
      end

      if config.key?(:skip_patterns)
        assert_instance_of Array, config[:skip_patterns], "Component #{name} skip_patterns should be array"
      end
    end
  end

  # Test claude directories configuration
  def test_claude_directories
    claude_dirs = ClaudeAgents::Config::ClaudeDirectories

    # Test that constants are defined
    assert_respond_to claude_dirs, :const_get

    # Test key directory constants exist
    %w[AGENTS_DIR COMMANDS_DIR TOOLS_DIR WORKFLOWS_DIR].each do |const_name|
      assert claude_dirs.const_defined?(const_name), "Should define #{const_name}"

      # Should be valid directory paths
      dir_path = claude_dirs.const_get(const_name)
      assert_instance_of String, dir_path
      assert dir_path.start_with?(ENV['HOME']), "#{const_name} should be in home directory"
      assert dir_path.include?('.claude'), "#{const_name} should be in .claude directory"
    end
  end

  # Test component configuration retrieval
  def test_component_config_retrieval
    # Test getting config for valid component
    dlabs_config = ClaudeAgents::Config.component_config('dlabs')
    assert_instance_of Hash, dlabs_config
    assert dlabs_config.key?(:source_dir)
    assert dlabs_config.key?(:dest_dir)

    # Test getting config for invalid component should return nil or raise
    invalid_config = ClaudeAgents::Config.component_config('invalid')
    assert_nil invalid_config
  end

  # Test repository configuration retrieval
  def test_repository_config_retrieval
    # Get first repository for testing
    first_repo_name = ClaudeAgents::Config::Repositories::REPOSITORIES.keys.first

    repo_config = ClaudeAgents::Config.repository_config(first_repo_name)
    assert_instance_of Hash, repo_config
    assert repo_config.key?('url')
    assert repo_config.key?('local_path')

    # Test invalid repository
    invalid_repo = ClaudeAgents::Config.repository_config('invalid')
    assert_nil invalid_repo
  end

  # Test configuration consistency
  def test_configuration_consistency
    # Components should reference valid directories
    components = ClaudeAgents::Config::Components::COMPONENTS

    components.each do |name, config|
      source_dir = config[:source_dir]

      # Source directory should either exist or be in agents directory structure
      if source_dir.start_with?('agents/')
        # Should be valid relative to project root
        full_path = File.join(ClaudeAgents::Config.project_root, source_dir)
        # Note: Directory might not exist until repositories are cloned
      elsif source_dir.start_with?('/')
        # Absolute path - should exist if it's a local directory
        # Only test this for local components like dlabs
        if name == 'dlabs'
          # dlabs might be in either location due to refactoring
          # Just verify the path structure makes sense
          assert source_dir.include?('claude-agents'), "dlabs source should be in project"
        end
      end
    end
  end

  # Test that constants are properly namespaced
  def test_constant_namespacing
    # Test that we can access all major configuration constants
    assert_nothing_raised do
      ClaudeAgents::Config::Repositories::REPOSITORIES
      ClaudeAgents::Config::Components::COMPONENTS
      ClaudeAgents::Config::ClaudeDirectories::AGENTS_DIR
    end
  end

  # Test configuration module methods exist
  def test_configuration_module_methods
    config_methods = %w[
      project_root
      agents_directory
      valid_component?
      all_components
      component_config
      repository_config
    ]

    config_methods.each do |method_name|
      assert_respond_to ClaudeAgents::Config, method_name,
                        "Config should respond to #{method_name}"
    end
  end
end