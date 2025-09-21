# frozen_string_literal: true

require_relative '../test_helper'

class TestConfig < ClaudeAgentsTest
  def setup
    super
    clear_cached_paths
  end

  def teardown
    super
    clear_cached_paths
  end

  def test_project_root_points_to_repository
    project_root = ClaudeAgents::Config.project_root

    assert File.exist?(File.join(project_root, 'Gemfile'))
    assert project_root.end_with?('claude-agents')
  end

  def test_agents_dir_resides_in_home_directory
    with_mock_home do |home|
      expected = File.join(home, '.claude', 'agents')
      assert_equal expected, ClaudeAgents::Config.agents_dir
    end
  end

  def test_base_dir_prefers_environment_override
    with_temp_dir do |dir|
      begin
        ENV['CLAUDE_AGENTS_BASE_DIR'] = dir
        assert_equal dir, ClaudeAgents::Config.base_dir
      ensure
        ENV.delete('CLAUDE_AGENTS_BASE_DIR')
      end
    end
  end

  def test_all_components_returns_symbol_keys
    components = ClaudeAgents::Config.all_components
    expected = %i[dlabs awesome wshobson_agents wshobson_commands]

    assert_equal expected.sort, components.sort
    components.each { |component| assert_kind_of Symbol, component }
  end

  def test_valid_component_accepts_strings_and_symbols
    assert ClaudeAgents::Config.valid_component?('dlabs')
    assert ClaudeAgents::Config.valid_component?(:awesome)
    refute ClaudeAgents::Config.valid_component?('missing')
  end

  def test_component_info_returns_registered_metadata
    info = ClaudeAgents::Config.component_info(:dlabs)

    refute_nil info
    assert_equal 'dLabs agents', info[:name]
    assert_equal 'agents/dallasLabs', info[:source_dir]
    assert_equal :agents, info[:destination]
    assert_equal :prefixed, info[:processor]
  end

  def test_component_info_returns_nil_for_unknown_component
    assert_nil ClaudeAgents::Config.component_info(:unknown)
  end

  def test_valid_component_config_requires_expected_keys
    valid = {
      name: 'custom',
      description: 'Custom component',
      source_dir: 'custom/source',
      destination: :agents
    }
    invalid = { name: 'custom', source_dir: 'custom/source' }

    assert ClaudeAgents::Config.valid_component_config?(valid)
    refute ClaudeAgents::Config.valid_component_config?(invalid)
  end

  def test_merge_with_defaults_fills_missing_attributes
    merged = ClaudeAgents::Config.merge_with_defaults(prefix: 'custom-')

    assert_equal 'custom-', merged[:prefix]
    assert_equal :default, merged[:processor]
    assert_equal 0, merged[:count]
  end

  def test_load_from_file_handles_missing_file
    with_temp_dir do |dir|
      path = File.join(dir, 'missing.yml')
      assert_equal({}, ClaudeAgents::Config.load_from_file(path))
    end
  end

  def test_load_from_file_parses_yaml_content
    with_temp_dir do |dir|
      path = File.join(dir, 'config.yml')
      File.write(path, "prefix: demo\nprocessor: awesome\n")

      config = ClaudeAgents::Config.load_from_file(path)

      assert_equal 'demo', config['prefix']
      assert_equal 'awesome', config['processor']
    end
  end

  private

  def clear_cached_paths
    %i[@claude_dir @agents_dir @commands_dir @tools_dir @workflows_dir @project_root @agents_source_dir].each do |ivar|
      ClaudeAgents::Config.instance_variable_set(ivar, nil)
    end
  end
end
