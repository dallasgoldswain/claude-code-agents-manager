# ABOUTME: Unit tests for ClaudeAgents::Config class
# ABOUTME: Tests configuration management, path resolution, and component validation

# frozen_string_literal: true

require_relative "../test_helper"

class ConfigTest < ClaudeAgentsTest
  def test_claude_dir_returns_expanded_path
    expected = File.expand_path("~/.claude")
    # Reset instance variables to test fresh
    ClaudeAgents::Config.instance_variable_set(:@claude_dir, nil)

    assert_equal expected, ClaudeAgents::Config.claude_dir
  end

  def test_agents_dir_builds_from_claude_dir
    expected = File.join(ClaudeAgents::Config.claude_dir, "agents")
    assert_equal expected, ClaudeAgents::Config.agents_dir
  end

  def test_commands_dir_builds_from_claude_dir
    expected = File.join(ClaudeAgents::Config.claude_dir, "commands")
    assert_equal expected, ClaudeAgents::Config.commands_dir
  end

  def test_tools_dir_builds_from_commands_dir
    expected = File.join(ClaudeAgents::Config.commands_dir, "tools")
    assert_equal expected, ClaudeAgents::Config.tools_dir
  end

  def test_workflows_dir_builds_from_commands_dir
    expected = File.join(ClaudeAgents::Config.commands_dir, "workflows")
    assert_equal expected, ClaudeAgents::Config.workflows_dir
  end

  def test_project_root_returns_correct_path
    # Project root should be the claude-agents directory
    expected = File.expand_path("../..", __dir__)
    ClaudeAgents::Config.instance_variable_set(:@project_root, nil)

    assert_equal expected, ClaudeAgents::Config.project_root
  end

  def test_source_dir_for_valid_component
    result = ClaudeAgents::Config.source_dir_for(:dlabs)
    expected = File.join(ClaudeAgents::Config.project_root, "agents/dallasLabs")

    assert_equal expected, result
  end

  def test_source_dir_for_invalid_component
    result = ClaudeAgents::Config.source_dir_for(:nonexistent)
    assert_nil result
  end

  def test_destination_dir_for_agents_component
    result = ClaudeAgents::Config.destination_dir_for(:dlabs)
    assert_equal ClaudeAgents::Config.agents_dir, result
  end

  def test_destination_dir_for_commands_component
    result = ClaudeAgents::Config.destination_dir_for(:wshobson_commands)
    assert_equal ClaudeAgents::Config.commands_dir, result
  end

  def test_destination_dir_for_invalid_component
    result = ClaudeAgents::Config.destination_dir_for(:nonexistent)
    assert_nil result
  end

  def test_prefix_for_component_with_prefix
    result = ClaudeAgents::Config.prefix_for(:dlabs)
    assert_equal "dLabs-", result
  end

  def test_prefix_for_component_without_prefix
    result = ClaudeAgents::Config.prefix_for(:awesome)
    assert_nil result
  end

  def test_component_exists_with_valid_component
    assert ClaudeAgents::Config.component_exists?(:dlabs)
    assert ClaudeAgents::Config.component_exists?("dlabs")
  end

  def test_component_exists_with_invalid_component
    refute ClaudeAgents::Config.component_exists?(:nonexistent)
    refute ClaudeAgents::Config.component_exists?("nonexistent")
  end

  def test_repository_for_valid_component
    result = ClaudeAgents::Config.repository_for(:awesome)
    expected = {
      url: "VoltAgent/awesome-claude-code-subagents",
      dir: "agents/awesome-claude-code-subagents",
      description: "116 industry-standard agents"
    }

    assert_equal expected, result
  end

  def test_repository_for_invalid_component
    result = ClaudeAgents::Config.repository_for(:nonexistent)
    assert_nil result
  end

  def test_ensure_directories_creates_missing_directories
    with_temp_directory do |temp_dir|
      # Override paths to use temp directory
      ClaudeAgents::Config.instance_variable_set(:@claude_dir, temp_dir)
      ClaudeAgents::Config.instance_variable_set(:@agents_dir, nil)
      ClaudeAgents::Config.instance_variable_set(:@commands_dir, nil)
      ClaudeAgents::Config.instance_variable_set(:@tools_dir, nil)
      ClaudeAgents::Config.instance_variable_set(:@workflows_dir, nil)
      ClaudeAgents::Config.instance_variable_set(:@agents_source_dir, nil)

      ClaudeAgents::Config.ensure_directories!

      assert_directory_exists ClaudeAgents::Config.claude_dir
      assert_directory_exists ClaudeAgents::Config.agents_dir
      assert_directory_exists ClaudeAgents::Config.commands_dir
      assert_directory_exists ClaudeAgents::Config.tools_dir
      assert_directory_exists ClaudeAgents::Config.workflows_dir
    end
  end

  def test_skip_file_with_matching_patterns
    skip_files = [
      "README.md",
      "LICENSE",
      "CONTRIBUTING.md",
      "setup_test.sh",
      ".gitignore",
      ".hidden"
    ]

    skip_files.each do |filename|
      assert ClaudeAgents::Config.skip_file?(filename),
             "Expected #{filename} to be skipped"
    end
  end

  def test_skip_file_with_non_matching_patterns
    keep_files = [
      "agent.md",
      "test-agent.md",
      "important-tool.md"
    ]

    keep_files.each do |filename|
      refute ClaudeAgents::Config.skip_file?(filename),
             "Expected #{filename} to not be skipped"
    end
  end

  def test_valid_component_with_valid_components
    valid_components = %i[dlabs awesome wshobson_agents wshobson_commands]

    valid_components.each do |component|
      assert ClaudeAgents::Config.valid_component?(component),
             "Expected #{component} to be valid"
    end
  end

  def test_valid_component_with_invalid_component
    refute ClaudeAgents::Config.valid_component?(:invalid)
  end

  def test_all_components_returns_all_keys
    expected = %i[dlabs awesome wshobson_agents wshobson_commands]
    result = ClaudeAgents::Config.all_components

    assert_equal expected.sort, result.sort
  end

  def test_component_info_returns_correct_structure
    info = ClaudeAgents::Config.component_info(:dlabs)

    assert_equal "dLabs agents", info[:name]
    assert_equal "Local specialized agents", info[:description]
    assert_equal 5, info[:count]
    assert_equal "agents/dallasLabs", info[:source_dir]
    assert_equal "dLabs-", info[:prefix]
    assert_equal :agents, info[:destination]
  end

  def test_component_info_with_invalid_component
    error = assert_raises(ClaudeAgents::ValidationError) do
      ClaudeAgents::Config.component_info(:nonexistent)
    end
    assert_includes error.message, "Unknown component"
  end
end
