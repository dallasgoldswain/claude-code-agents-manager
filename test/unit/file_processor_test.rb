# ABOUTME: Unit tests for ClaudeAgents::FileProcessor class
# ABOUTME: Tests file discovery, filtering, naming conventions, and mapping generation

# frozen_string_literal: true

require_relative "../test_helper"

class FileProcessorTest < ClaudeAgentsTest
  def setup
    super
    @ui = create_test_ui
    @file_processor = ClaudeAgents::FileProcessor.new(@ui)
  end

  def test_process_component_files_dlabs
    with_temp_directory do |temp_dir|
      # Create test structure
      dlabs_dir = TestFixtures.create_dlabs_fixture(temp_dir)

      # Mock Config methods
      ClaudeAgents::Config.stubs(:source_dir_for).with(:dlabs).returns(dlabs_dir)
      ClaudeAgents::Config.stubs(:destination_dir_for).with(:dlabs).returns(test_agents_dir)
      ClaudeAgents::Config.stubs(:prefix_for).with(:dlabs).returns("dLabs-")

      result = @file_processor.get_file_mappings_for_component(:dlabs)

      assert_equal 5, result.length

      # Check that all files are mapped correctly
      result.each do |mapping|
        assert mapping[:source].end_with?(".md")
        assert mapping[:destination].start_with?(test_agents_dir)
        assert mapping[:destination].include?("dLabs-")
        assert_equal File.basename(mapping[:destination]), mapping[:display_name]
      end
    end
  end

  def test_process_component_files_awesome_with_categories
    with_temp_directory do |temp_dir|
      # Create test structure
      awesome_dir = TestFixtures.create_awesome_agents_fixture(temp_dir)

      # Mock Config methods
      ClaudeAgents::Config.stubs(:source_dir_for).with(:awesome).returns(awesome_dir)
      ClaudeAgents::Config.stubs(:destination_dir_for).with(:awesome).returns(test_agents_dir)
      ClaudeAgents::Config.stubs(:prefix_for).with(:awesome).returns(nil)

      result = @file_processor.get_file_mappings_for_component(:awesome)

      assert_equal 6, result.length # 2 files per category × 3 categories

      # Check category-based naming
      frontend_files = result.select { |m| m[:display_name].start_with?("frontend-") }
      backend_files = result.select { |m| m[:display_name].start_with?("backend-") }
      devops_files = result.select { |m| m[:display_name].start_with?("devops-") }

      assert_equal 2, frontend_files.length
      assert_equal 2, backend_files.length
      assert_equal 2, devops_files.length
    end
  end

  def test_process_component_files_wshobson_commands
    with_temp_directory do |temp_dir|
      # Create test structure
      commands_dir = TestFixtures.create_wshobson_commands_fixture(temp_dir)

      # Mock Config methods
      ClaudeAgents::Config.stubs(:source_dir_for).with(:wshobson_commands).returns(commands_dir)
      ClaudeAgents::Config.stubs(:destination_dir_for).with(:wshobson_commands).returns(test_commands_dir)
      ClaudeAgents::Config.stubs(:prefix_for).with(:wshobson_commands).returns(nil)

      result = @file_processor.get_file_mappings_for_component(:wshobson_commands)

      assert_equal 5, result.length # 3 tools + 2 workflows

      # Check that tools go to tools directory
      tools_mappings = result.select { |m| m[:destination].include?("/tools/") }
      workflows_mappings = result.select { |m| m[:destination].include?("/workflows/") }

      assert_equal 3, tools_mappings.length
      assert_equal 2, workflows_mappings.length
    end
  end

  def test_process_component_files_filters_skip_patterns
    with_temp_directory do |temp_dir|
      source_dir = File.join(temp_dir, "test_source")
      FileUtils.mkdir_p(source_dir)

      # Create files that should be skipped
      create_test_file(File.join(source_dir, "README.md"))
      create_test_file(File.join(source_dir, "LICENSE"))
      create_test_file(File.join(source_dir, ".gitignore"))
      create_test_file(File.join(source_dir, "setup_test.sh"))

      # Create files that should be included
      create_test_agent_file(File.join(source_dir, "valid-agent.md"))

      # Mock Config methods
      ClaudeAgents::Config.stubs(:valid_component?).with(:test).returns(true)
      ClaudeAgents::Config.stubs(:source_dir_for).with(:test).returns(source_dir)
      ClaudeAgents::Config.stubs(:destination_dir_for).with(:test).returns(test_agents_dir)
      ClaudeAgents::Config.stubs(:prefix_for).with(:test).returns("test-")

      result = @file_processor.get_file_mappings_for_component(:test)

      assert_equal 1, result.length
      assert result.first[:display_name] == "test-valid-agent.md"
    end
  end

  def test_process_component_files_invalid_component
    error = assert_raises(ClaudeAgents::ValidationError) do
      @file_processor.get_file_mappings_for_component(:nonexistent)
    end

    assert_includes error.message, "Invalid component"
  end

  def test_process_component_files_missing_source_directory
    # Mock Config to return non-existent directory
    ClaudeAgents::Config.stubs(:valid_component?).with(:test).returns(true)
    ClaudeAgents::Config.stubs(:source_dir_for).with(:test).returns("/nonexistent/path")

    error = assert_raises(ClaudeAgents::FileOperationError) do
      @file_processor.get_file_mappings_for_component(:test)
    end

    assert_includes error.message, "Source directory for test does not exist"
  end

  def test_find_markdown_files_recursive
    with_temp_directory do |temp_dir|
      # Create nested structure
      create_test_file(File.join(temp_dir, "top-level.md"))
      create_test_file(File.join(temp_dir, "category1", "agent1.md"))
      create_test_file(File.join(temp_dir, "category1", "agent2.md"))
      create_test_file(File.join(temp_dir, "category2", "deep", "agent3.md"))

      # Non-markdown files should be ignored
      create_test_file(File.join(temp_dir, "config.json"))
      create_test_file(File.join(temp_dir, "script.sh"))

      files = @file_processor.send(:find_markdown_files, temp_dir)

      assert_equal 4, files.length
      files.each { |file| assert file.end_with?(".md") }
    end
  end

  def test_generate_destination_path_with_prefix
    destination_dir = "/test/destination"
    relative_path = "category/agent.md"
    prefix = "test-"

    result = @file_processor.send(:generate_destination_path, destination_dir, relative_path,
                                  prefix)

    expected = File.join(destination_dir, "test-agent.md")
    assert_equal expected, result
  end

  def test_generate_destination_path_without_prefix
    destination_dir = "/test/destination"
    relative_path = "category/agent.md"

    result = @file_processor.send(:generate_destination_path, destination_dir, relative_path, nil)

    expected = File.join(destination_dir, "category-agent.md")
    assert_equal expected, result
  end

  def test_generate_destination_path_commands_structure
    # Mock Config for commands destination
    ClaudeAgents::Config.stubs(:tools_dir).returns("/test/commands/tools")
    ClaudeAgents::Config.stubs(:workflows_dir).returns("/test/commands/workflows")

    destination_dir = "/test/commands"

    # Tools directory
    tools_path = @file_processor.send(:generate_destination_path, destination_dir,
                                      "tools/test-tool.md", nil)
    expected_tools = "/test/commands/tools/test-tool.md"
    assert_equal expected_tools, tools_path

    # Workflows directory
    workflows_path = @file_processor.send(:generate_destination_path, destination_dir,
                                          "workflows/test-workflow.md", nil)
    expected_workflows = "/test/commands/workflows/test-workflow.md"
    assert_equal expected_workflows, workflows_path
  end

  def test_generate_display_name_with_prefix
    filename = "agent.md"
    prefix = "test-"

    result = @file_processor.send(:generate_display_name, filename, prefix)

    assert_equal "test-agent.md", result
  end

  def test_generate_display_name_without_prefix
    filename = "category-agent.md"

    result = @file_processor.send(:generate_display_name, filename, nil)

    assert_equal "category-agent.md", result
  end

  def test_performance_large_directory_scan
    with_temp_directory do |temp_dir|
      # Create many files
      100.times do |i|
        category_dir = File.join(temp_dir, "category#{i / 10}")
        FileUtils.mkdir_p(category_dir)
        create_test_agent_file(File.join(category_dir, "agent#{i}.md"))
      end

      # Mock Config methods
      ClaudeAgents::Config.stubs(:valid_component?).with(:test).returns(true)
      ClaudeAgents::Config.stubs(:source_dir_for).with(:test).returns(temp_dir)
      ClaudeAgents::Config.stubs(:destination_dir_for).with(:test).returns(test_agents_dir)
      ClaudeAgents::Config.stubs(:prefix_for).with(:test).returns("test-")

      # Should complete in under 1 second
      assert_performance_under(1.0) do
        @file_processor.get_file_mappings_for_component(:test)
      end
    end
  end

  def test_error_handling_permission_denied
    with_temp_directory do |temp_dir|
      source_dir = File.join(temp_dir, "source")
      FileUtils.mkdir_p(source_dir)

      # Mock Config methods
      ClaudeAgents::Config.stubs(:valid_component?).with(:test).returns(true)
      ClaudeAgents::Config.stubs(:source_dir_for).with(:test).returns(source_dir)

      # Mock Dir.glob to simulate permission denied error
      Dir.stubs(:glob).raises(Errno::EACCES.new("Permission denied"))

      error = assert_raises(ClaudeAgents::FileOperationError) do
        @file_processor.get_file_mappings_for_component(:test)
      end

      assert_includes error.message, "Permission denied"
    end
  end
end
