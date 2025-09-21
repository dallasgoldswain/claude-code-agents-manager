# frozen_string_literal: true

require 'test_helper'

class ConfigTest < ClaudeAgentsTest
  def setup
    super
    reset_config_cache
  end

  def teardown
    super
    reset_config_cache
  end

  private

  def reset_config_cache
    %i[@claude_dir @agents_dir @commands_dir @tools_dir @workflows_dir @project_root @agents_source_dir].each do |ivar|
      ClaudeAgents::Config.instance_variable_set(ivar, nil)
    end
  end

  class DirectoriesTest < ConfigTest
    def test_claude_dir_defaults_to_home
      with_mock_home do |home|
        expected = File.expand_path(File.join(home, '.claude'))

        assert_equal expected, ClaudeAgents::Config.claude_dir
      end
    end

    def test_agents_and_commands_subdirectories
      with_mock_home do |home|
        assert_equal File.join(home, '.claude', 'agents'), ClaudeAgents::Config.agents_dir
        assert_equal File.join(home, '.claude', 'commands'), ClaudeAgents::Config.commands_dir
        assert_equal File.join(home, '.claude', 'commands', 'tools'), ClaudeAgents::Config.tools_dir
        assert_equal File.join(home, '.claude', 'commands', 'workflows'), ClaudeAgents::Config.workflows_dir
      end
    end

    def test_agents_source_dir_points_into_project
      source_dir = ClaudeAgents::Config.agents_source_dir

      assert source_dir.end_with?('claude-agents/agents')
      assert Dir.exist?(source_dir), 'Agents source directory should exist inside the project'
    end

    def test_ensure_directories_creates_expected_structure
      with_mock_home do |home|
        FileUtils.rm_rf(File.join(home, '.claude'))

        ClaudeAgents::Config.ensure_directories!

        assert Dir.exist?(File.join(home, '.claude', 'agents'))
        assert Dir.exist?(File.join(home, '.claude', 'commands', 'tools'))
        assert Dir.exist?(File.join(home, '.claude', 'commands', 'workflows'))
      end
    end

    def test_allowed_symlink_roots_cover_agent_and_command_paths
      with_mock_home do |home|
        roots = ClaudeAgents::Config.allowed_symlink_roots
        expected = [
          File.join(home, '.claude', 'agents'),
          File.join(home, '.claude', 'commands'),
          File.join(home, '.claude', 'commands', 'tools'),
          File.join(home, '.claude', 'commands', 'workflows')
        ].map { |path| File.expand_path(path) }

        assert_equal expected.sort, roots.sort
      end
    end
  end

  class ComponentsTest < ConfigTest
    def test_component_exists_and_valid_component_helpers
      assert ClaudeAgents::Config.component_exists?(:dlabs)
      assert ClaudeAgents::Config.component_exists?('awesome')
      refute ClaudeAgents::Config.component_exists?(:missing)

      assert ClaudeAgents::Config.valid_component?(:wshobson_agents)
      refute ClaudeAgents::Config.valid_component?('invalid')
    end

    def test_all_components_lists_registered_keys
      components = ClaudeAgents::Config.all_components

      assert_equal %i[dlabs awesome wshobson_agents wshobson_commands].sort, components.sort
    end

    def test_component_info_retrieves_component_metadata
      info = ClaudeAgents::Config.component_info(:wshobson_commands)

      assert_equal 'wshobson commands', info[:name]
      assert_equal '56 workflow tools', info[:description]
      assert_equal 'agents/wshobson-commands', info[:source_dir]
      assert_equal :commands, info[:destination]
    end

    def test_source_dir_for_returns_absolute_path
      path = ClaudeAgents::Config.source_dir_for(:awesome)

      assert path.end_with?('agents/awesome-claude-code-subagents')
      assert path.start_with?(ClaudeAgents::Config.project_root)
    end

    def test_destination_dir_for_commands_component
      with_mock_home do |home|
        commands_dir = ClaudeAgents::Config.destination_dir_for(:wshobson_commands)

        assert_equal File.join(home, '.claude', 'commands'), commands_dir
      end
    end

    def test_prefix_for_handles_components_without_prefix
      assert_equal 'dLabs-', ClaudeAgents::Config.prefix_for(:dlabs)
      assert_nil ClaudeAgents::Config.prefix_for(:awesome)
    end
  end

  class RepositoriesTest < ConfigTest
    def test_repository_for_returns_metadata
      repo = ClaudeAgents::Config::Repositories.repository_for(:awesome)

      assert_equal 'VoltAgent/awesome-claude-code-subagents', repo[:url]
      assert_equal 'agents/awesome-claude-code-subagents', repo[:dir]
      assert_equal '116 industry-standard agents', repo[:description]
    end

    def test_repository_for_unknown_component_returns_nil
      assert_nil ClaudeAgents::Config::Repositories.repository_for(:missing)
    end
  end

  class SkipPatternsTest < ConfigTest
    def test_default_patterns_cover_common_files
      patterns = ClaudeAgents::Config::SkipPatterns::DEFAULT

      assert_includes patterns, '.git'
      assert_includes patterns, '.DS_Store'
      assert_includes patterns, 'README.md'
    end

    def test_should_skip_matches_patterns
      assert ClaudeAgents::Config::SkipPatterns.should_skip?('.git/config')
      assert ClaudeAgents::Config::SkipPatterns.should_skip?('folder/.DS_Store')
      refute ClaudeAgents::Config::SkipPatterns.should_skip?('agents/agent.md')
    end

    def test_patterns_for_adds_component_specific_entries
      awesome_patterns = ClaudeAgents::Config::SkipPatterns.patterns_for(:awesome)
      dlabs_patterns = ClaudeAgents::Config::SkipPatterns.patterns_for(:dlabs)

      assert_includes awesome_patterns, 'node_modules/*'
      assert_includes dlabs_patterns, '*.example'
    end

    def test_add_pattern_appends_and_skip_file_uses_updated_patterns
      ClaudeAgents::Config::SkipPatterns.add_pattern('*.custom')

      assert ClaudeAgents::Config.skip_file?('notes.custom')
    ensure
      ClaudeAgents::Config::SkipPatterns::DEFAULT.delete('*.custom')
    end
  end
end
