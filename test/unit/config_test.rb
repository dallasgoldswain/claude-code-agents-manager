# frozen_string_literal: true

require 'test_helper'

class ConfigTest < ClaudeAgentsTest
  # Test Directories module
  class DirectoriesTest < ConfigTest
    def test_base_directory_uses_home_env
      original_home = ENV['HOME']
      ENV['HOME'] = '/test/home'

      assert_equal '/test/home/.claude', ClaudeAgents::Config::Directories.base_dir
    ensure
      ENV['HOME'] = original_home
    end

    def test_agents_directory_path
      with_mock_home do |home|
        expected = File.join(home, '.claude', 'agents')
        assert_equal expected, ClaudeAgents::Config::Directories.agents_dir
      end
    end

    def test_commands_directory_paths
      with_mock_home do |home|
        base = File.join(home, '.claude', 'commands')

        assert_equal base, ClaudeAgents::Config::Directories.commands_dir
        assert_equal File.join(base, 'tools'), ClaudeAgents::Config::Directories.tools_dir
        assert_equal File.join(base, 'workflows'), ClaudeAgents::Config::Directories.workflows_dir
      end
    end

    def test_all_directories_returns_complete_list
      dirs = ClaudeAgents::Config::Directories.all_directories

      assert_instance_of Array, dirs
      assert dirs.include?(ClaudeAgents::Config::Directories.agents_dir)
      assert dirs.include?(ClaudeAgents::Config::Directories.tools_dir)
      assert dirs.include?(ClaudeAgents::Config::Directories.workflows_dir)
    end

    def test_directory_exists_check
      with_mock_home do |home|
        agents_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(agents_dir)

        assert ClaudeAgents::Config::Directories.directory_exists?(agents_dir)
        refute ClaudeAgents::Config::Directories.directory_exists?('/nonexistent')
      end
    end

    def test_ensure_directories_creates_all_required
      with_mock_home do |home|
        ClaudeAgents::Config::Directories.ensure_directories!

        assert Dir.exist?(File.join(home, '.claude', 'agents'))
        assert Dir.exist?(File.join(home, '.claude', 'commands', 'tools'))
        assert Dir.exist?(File.join(home, '.claude', 'commands', 'workflows'))
      end
    end
  end

  # Test Components module
  class ComponentsTest < ConfigTest
    def test_dlabs_component_configuration
      config = ClaudeAgents::Config::Components::DLABS

      assert_equal 'dlabs', config[:name]
      assert_equal 'agents/dallasLabs', config[:source_dir]
      assert_match(/\.claude\/agents$/, config[:dest_dir])
      assert_equal 'dLabs-', config[:prefix]
    end

    def test_wshobson_agents_configuration
      config = ClaudeAgents::Config::Components::WSHOBSON_AGENTS

      assert_equal 'wshobson-agents', config[:name]
      assert_equal 'agents/wshobson-agents', config[:source_dir]
      assert_match(/\.claude\/agents$/, config[:dest_dir])
      assert_equal 'wshobson-', config[:prefix]
    end

    def test_wshobson_commands_configuration
      config = ClaudeAgents::Config::Components::WSHOBSON_COMMANDS

      assert_equal 'wshobson-commands', config[:name]
      assert_equal 'agents/wshobson-commands', config[:source_dir]
      assert_match(/\.claude\/commands$/, config[:dest_dir])
      assert_nil config[:prefix]  # Commands don't use prefixes
    end

    def test_awesome_agents_configuration
      config = ClaudeAgents::Config::Components::AWESOME

      assert_equal 'awesome', config[:name]
      assert_equal 'agents/awesome-claude-code-subagents', config[:source_dir]
      assert_match(/\.claude\/agents$/, config[:dest_dir])
      assert_nil config[:prefix]  # Uses category prefixes instead
    end

    def test_all_components_array
      all = ClaudeAgents::Config::Components::ALL

      assert_instance_of Array, all
      assert_equal 4, all.length
      assert all.any? { |c| c[:name] == 'dlabs' }
      assert all.any? { |c| c[:name] == 'wshobson-agents' }
    end

    def test_find_component_by_name
      component = ClaudeAgents::Config::Components.find_by_name('dlabs')

      assert_equal 'dlabs', component[:name]
      assert_equal ClaudeAgents::Config::Components::DLABS, component
    end

    def test_find_component_returns_nil_for_invalid_name
      component = ClaudeAgents::Config::Components.find_by_name('invalid')

      assert_nil component
    end

    def test_component_names_list
      names = ClaudeAgents::Config::Components.component_names

      assert_instance_of Array, names
      assert names.include?('dlabs')
      assert names.include?('wshobson-agents')
      assert names.include?('wshobson-commands')
      assert names.include?('awesome')
    end

    def test_valid_component_check
      assert ClaudeAgents::Config::Components.valid_component?('dlabs')
      assert ClaudeAgents::Config::Components.valid_component?('wshobson-agents')
      refute ClaudeAgents::Config::Components.valid_component?('invalid')
    end
  end

  # Test Repositories module
  class RepositoriesTest < ConfigTest
    def test_wshobson_agents_repository_config
      config = ClaudeAgents::Config::Repositories::WSHOBSON_AGENTS

      assert_equal 'https://github.com/wshobson/claude-engineer-agents.git', config['url']
      assert_equal 'agents/wshobson-agents', config['local_path']
      assert_equal 'main', config['branch']
    end

    def test_wshobson_commands_repository_config
      config = ClaudeAgents::Config::Repositories::WSHOBSON_COMMANDS

      assert_equal 'https://github.com/wshobson/claude-engineer-commands.git', config['url']
      assert_equal 'agents/wshobson-commands', config['local_path']
      assert_equal 'main', config['branch']
    end

    def test_awesome_agents_repository_config
      config = ClaudeAgents::Config::Repositories::AWESOME_AGENTS

      assert_equal 'https://github.com/VoltaireNoir/awesome-claude-code-subagents.git', config['url']
      assert_equal 'agents/awesome-claude-code-subagents', config['local_path']
      assert_equal 'main', config['branch']
    end

    def test_all_repositories_hash
      all = ClaudeAgents::Config::Repositories::ALL

      assert_instance_of Hash, all
      assert_equal 3, all.keys.length
      assert all.key?('wshobson-agents')
      assert all.key?('wshobson-commands')
      assert all.key?('awesome')
    end

    def test_find_repository_by_name
      repo = ClaudeAgents::Config::Repositories.find_by_name('wshobson-agents')

      assert_equal ClaudeAgents::Config::Repositories::WSHOBSON_AGENTS, repo
      assert_equal 'https://github.com/wshobson/claude-engineer-agents.git', repo['url']
    end

    def test_repository_exists_check
      assert ClaudeAgents::Config::Repositories.repository_exists?('wshobson-agents')
      refute ClaudeAgents::Config::Repositories.repository_exists?('nonexistent')
    end

    def test_clone_url_retrieval
      url = ClaudeAgents::Config::Repositories.clone_url('wshobson-agents')

      assert_equal 'https://github.com/wshobson/claude-engineer-agents.git', url
    end

    def test_local_path_retrieval
      path = ClaudeAgents::Config::Repositories.local_path('awesome')

      assert_equal 'agents/awesome-claude-code-subagents', path
    end
  end

  # Test SkipPatterns module
  class SkipPatternsTest < ConfigTest
    def test_default_skip_patterns
      patterns = ClaudeAgents::Config::SkipPatterns::DEFAULT

      assert patterns.include?('.git')
      assert patterns.include?('.DS_Store')
      assert patterns.include?('*.tmp')
      assert patterns.include?('*.swp')
      assert patterns.include?('README.md')
      assert patterns.include?('LICENSE')
    end

    def test_should_skip_file_with_matching_pattern
      assert ClaudeAgents::Config::SkipPatterns.should_skip?('.git/config')
      assert ClaudeAgents::Config::SkipPatterns.should_skip?('.DS_Store')
      assert ClaudeAgents::Config::SkipPatterns.should_skip?('test.tmp')
      assert ClaudeAgents::Config::SkipPatterns.should_skip?('README.md')
    end

    def test_should_not_skip_valid_files
      refute ClaudeAgents::Config::SkipPatterns.should_skip?('agent.md')
      refute ClaudeAgents::Config::SkipPatterns.should_skip?('tool.yaml')
      refute ClaudeAgents::Config::SkipPatterns.should_skip?('workflow.json')
    end

    def test_custom_skip_patterns
      custom_patterns = ['*.custom', 'skip_me/*']

      assert ClaudeAgents::Config::SkipPatterns.should_skip?('test.custom', custom_patterns)
      assert ClaudeAgents::Config::SkipPatterns.should_skip?('skip_me/file.txt', custom_patterns)
      refute ClaudeAgents::Config::SkipPatterns.should_skip?('keep.txt', custom_patterns)
    end

    def test_skip_patterns_with_glob_matching
      patterns = ['**/*.test', '**/node_modules/*']

      assert ClaudeAgents::Config::SkipPatterns.should_skip?('src/deep/file.test', patterns)
      assert ClaudeAgents::Config::SkipPatterns.should_skip?('project/node_modules/package.json', patterns)
      refute ClaudeAgents::Config::SkipPatterns.should_skip?('src/main.js', patterns)
    end

    def test_add_skip_pattern
      original_count = ClaudeAgents::Config::SkipPatterns::DEFAULT.length

      ClaudeAgents::Config::SkipPatterns.add_pattern('*.new')

      assert ClaudeAgents::Config::SkipPatterns.should_skip?('test.new')
    ensure
      # Reset patterns
      ClaudeAgents::Config::SkipPatterns::DEFAULT.delete('*.new')
    end

    def test_component_specific_skip_patterns
      dlabs_patterns = ClaudeAgents::Config::SkipPatterns.patterns_for('dlabs')
      awesome_patterns = ClaudeAgents::Config::SkipPatterns.patterns_for('awesome')

      # Each component might have specific patterns
      assert_instance_of Array, dlabs_patterns
      assert_instance_of Array, awesome_patterns
    end
  end

  # Test Config main module
  class ConfigMainTest < ConfigTest
    def test_version_constant
      assert defined?(ClaudeAgents::VERSION)
      assert_match(/^\d+\.\d+\.\d+/, ClaudeAgents::VERSION)
    end

    def test_config_load_from_file
      config_file = create_fixture_file('config.yml', <<~YAML)
        components:
          custom:
            name: custom
            source_dir: custom/agents
            dest_dir: ~/.claude/custom
            prefix: custom-
      YAML

      config = ClaudeAgents::Config.load_from_file(config_file)

      assert config[:components][:custom]
      assert_equal 'custom', config[:components][:custom][:name]
    ensure
      File.delete(config_file) if File.exist?(config_file)
    end

    def test_config_validation
      valid_config = {
        name: 'test',
        source_dir: 'test/source',
        dest_dir: 'test/dest'
      }

      invalid_config = {
        name: 'test'
        # Missing required fields
      }

      assert ClaudeAgents::Config.valid_component_config?(valid_config)
      refute ClaudeAgents::Config.valid_component_config?(invalid_config)
    end

    def test_environment_variable_override
      original_home = ENV['HOME']
      ENV['CLAUDE_HOME'] = '/custom/claude/home'

      base_dir = ClaudeAgents::Config::Directories.base_dir

      # Should prefer CLAUDE_HOME if set
      assert_equal '/custom/claude/home/.claude', base_dir
    ensure
      ENV.delete('CLAUDE_HOME')
      ENV['HOME'] = original_home
    end

    def test_config_merge_with_defaults
      custom_config = {
        prefix: 'custom-'
      }

      default_config = {
        name: 'default',
        prefix: 'default-',
        source_dir: 'default/source'
      }

      merged = ClaudeAgents::Config.merge_with_defaults(custom_config, default_config)

      assert_equal 'custom-', merged[:prefix]  # Custom overrides default
      assert_equal 'default', merged[:name]    # Default preserved
      assert_equal 'default/source', merged[:source_dir]  # Default preserved
    end
  end

  # Test configuration persistence
  class ConfigPersistenceTest < ConfigTest
    def test_saves_configuration_to_file
      with_temp_dir do |dir|
        config_file = File.join(dir, 'config.yml')

        config = {
          version: ClaudeAgents::VERSION,
          components: ClaudeAgents::Config::Components::ALL
        }

        ClaudeAgents::Config.save_to_file(config, config_file)

        assert File.exist?(config_file)
        loaded = YAML.load_file(config_file)
        assert_equal ClaudeAgents::VERSION, loaded['version']
      end
    end

    def test_migrates_old_configuration_format
      old_config = {
        'agents' => {
          'dlabs' => 'agents/dallasLabs'
        }
      }

      migrated = ClaudeAgents::Config.migrate_config(old_config)

      assert migrated[:components]
      refute migrated['agents']  # Old format removed
    end

    def test_backs_up_config_before_modification
      with_temp_dir do |dir|
        config_file = File.join(dir, 'config.yml')
        File.write(config_file, 'original: true')

        ClaudeAgents::Config.backup_config(config_file)

        backup_file = "#{config_file}.backup"
        assert File.exist?(backup_file)
        assert_equal 'original: true', File.read(backup_file)
      end
    end
  end
end