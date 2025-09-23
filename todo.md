# ABOUTME: Tests for the global CONFIG constant and Zeitwerk autoload baseline

# ABOUTME: Ensures configuration structure, values, and immutability contract remain stable

Integrate Zeitwerk for autoloading in the CLI tool

- Analyze current project structure and autoloading patterns
- Research Zeitwerk integration best practices for CLI tools
- Write failing tests for Zeitwerk autoloading behavior
- Add Zeitwerk gem to Gemfile with proper versioning
- Configure Zeitwerk loader in main module
- Refactor existing require statements to use autoloading
- Implement proper file naming conventions for Zeitwerk
- Add integration tests for autoloading across service classes
- Performance test autoloading vs manual requires
- Run full test suite to ensure no regressions
- Optimize Zeitwerk configuration for CLI startup performance
- Document Zeitwerk integration and conventions

```ruby
# frozen_string_literal: true

require_relative "../test/test_helper"
require "claude_agents"

class ClaudeAgentsConfigTest < Minitest::Test
  def setup
    @config = ClaudeAgents::CONFIG
  end

  def test_config_constant_exists_and_frozen
    assert_kind_of Hash, @config
    assert @config.frozen?, "CONFIG should be frozen to prevent mutation"
  end

  def test_required_top_level_keys_present
    expected_keys = %i[
      claude_dir
      agents_dir
      commands_dir
      source_dirs
      prefixes
      skip_patterns
    ]
    expected_keys.each do |k|
      assert @config.key?(k), "Expected CONFIG to include key #{k}"
    end
  end

  def test_path_values_are_expanded
    assert_equal File.expand_path("~/.claude"), @config[:claude_dir]
    assert_equal File.expand_path("~/.claude/agents"), @config[:agents_dir]
    assert_equal File.expand_path("~/.claude/commands"), @config[:commands_dir]
  end

  def test_source_dirs_structure
    source_dirs = @config[:source_dirs]
    assert_kind_of Hash, source_dirs

    %i[dlabs wshobson_agents wshobson_commands awesome].each do |k|
      assert source_dirs.key?(k), "Expected source_dirs to include #{k}"
      assert_kind_of String, source_dirs[k], "source_dirs[#{k}] should be a String"
    end

    assert_equal "dallasLabs", source_dirs[:dlabs]
    assert_equal "wshobson-agents", source_dirs[:wshobson_agents]
    assert_equal "wshobson-commands", source_dirs[:wshobson_commands]
    assert_equal "awesome-claude-code-subagents", source_dirs[:awesome]
  end

  def test_prefixes_structure
    prefixes = @config[:prefixes]
    assert_kind_of Hash, prefixes

    assert_equal "dLabs-", prefixes[:dlabs]
    assert_equal "wshobson-", prefixes[:wshobson_agents]
    assert_equal "wshobson-", prefixes[:wshobson_commands]
    assert_nil prefixes[:awesome], "awesome should have nil prefix (category-based)"
  end

  def test_skip_patterns_are_expected_regexes
    patterns = @config[:skip_patterns]
    assert_kind_of Array, patterns
    assert patterns.all? { |p| p.is_a?(Regexp) }, "All skip patterns must be Regexp instances"

    expected = [
      /^readme/i,
      /^license/i,
      /^contributing/i,
      /^examples/i,
      /^setup_.*\.sh$/,
      /^\./,
      /\.json$/,
      /\.txt$/,
      /\.log$/
    ]

    # Compare pattern source + options (case-insensitive ones)
    actual_descriptors = patterns.map { |r| [r.source, r.options] }
    expected_descriptors = expected.map { |r| [r.source, r.options] }

    assert_equal expected_descriptors, actual_descriptors,
                 "Skip patterns differ.\nExpected: #{expected_descriptors}\nActual:   #{actual_descriptors}"
  end

  def test_top_level_mutation_is_prevented
    assert_raises(FrozenError) { @config[:claude_dir] = "/tmp/alt" }
  end

  def test_version_constant_autoloaded
    assert ClaudeAgents.const_defined?(:VERSION), "VERSION should be defined"
    assert_match(/\A\d+\.\d+\.\d+\z/, ClaudeAgents::VERSION)
  end

  def test_config_contract_snapshot
    # Lightweight snapshot to catch accidental structural edits
    snapshot = {
      keys: @config.keys.sort,
      source_dir_keys: @config[:source_dirs].keys.sort,
      prefix_keys: @config[:prefixes].keys.sort,
      skip_pattern_count: @config[:skip_patterns].size
    }
    expected = {
      keys: %i[agents_dir claude_dir commands_dir prefixes skip_patterns source_dirs].sort,
      source_dir_keys: %i[awesome dlabs wshobson_agents wshobson_commands].sort,
      prefix_keys: %i[awesome dlabs wshobson_agents wshobson_commands].sort,
      skip_pattern_count: 9
    }
    assert_equal expected, snapshot
  end
end
```

# TODO (Zeitwerk usage & maintenance plan)

1. Add unit test ensuring each new service class (Installer, Remover, etc.) autoloads: assert defined?(ClaudeAgents::Installer)

2. Enforce filename/classname parity: add a rake task using Zeitwerk::Loader.new.tap(&:check!)

3. When adding a constant with irregular inflection, extend loader.inflector in claude_agents.rb (add matching test)

4. Prohibit manual requires except for exceptions (errors.rb) – add linter or grep-based test

5. Add a test that setting CLAUDE_AGENTS_EAGER_LOAD=true eager_loads without errors

6. Document workflow in CONTRIBUTING: "create file under lib/claude_agents/, camel-cased class name"

7. Before releasing, run loader.reload; loader.eager_load in a smoke test to catch autoload edge cases

8. If introducing namespaces (e.g., ClaudeAgents::Services), mirror directory tree exactly

9. Avoid circular requires: prefer small, dependency-light service objects

10. Periodically run zeitwerk:check (custom rake task) in CI to validate autoload map
