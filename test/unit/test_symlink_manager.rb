# frozen_string_literal: true

require_relative '../test_helper'

# Test suite for the SymlinkManager service class
# Tests symlink creation, removal, and file processing operations
class TestSymlinkManager < ClaudeAgentsTest
  def setup
    super
    @ui = create_mock_ui
    @config = sample_config_component
    @symlink_manager = ClaudeAgents::SymlinkManager.new(@config, @ui)
  end

  # Test symlink manager initialization
  def test_symlink_manager_initialization
    assert_instance_of ClaudeAgents::SymlinkManager, @symlink_manager
    assert_equal @config, @symlink_manager.config
    assert_equal @ui, @symlink_manager.ui
  end

  # Test create_symlinks with valid configuration
  def test_create_symlinks_basic_functionality
    with_temp_dir do |temp_dir|
      # Set up test directories and files
      source_dir = File.join(temp_dir, 'source')
      dest_dir = File.join(temp_dir, 'dest')
      FileUtils.mkdir_p(source_dir)
      FileUtils.mkdir_p(dest_dir)

      # Create test files
      test_file = File.join(source_dir, 'test-agent.md')
      File.write(test_file, "# Test Agent\nTest content")

      # Update config with actual paths
      config = @config.merge(
        source_dir: source_dir,
        dest_dir: dest_dir
      )

      # Create symlink manager with updated config
      manager = ClaudeAgents::SymlinkManager.new(config, @ui)

      result = manager.create_symlinks

      assert result, 'Should successfully create symlinks'

      # Verify symlink was created
      expected_link = File.join(dest_dir, "#{@config[:prefix]}test-agent.md")

      assert File.symlink?(expected_link), 'Should create symlink'
      assert_equal test_file, File.readlink(expected_link), 'Symlink should point to source file'
    end
  end

  # Test create_symlinks with missing source directory
  def test_create_symlinks_missing_source_directory
    config = @config.merge(source_dir: '/nonexistent/path')
    manager = ClaudeAgents::SymlinkManager.new(config, @ui)

    assert_raises ClaudeAgents::FileProcessingError do
      manager.create_symlinks
    end
  end

  # Test create_symlinks with file skip patterns
  def test_create_symlinks_with_skip_patterns
    with_temp_dir do |temp_dir|
      source_dir = File.join(temp_dir, 'source')
      dest_dir = File.join(temp_dir, 'dest')
      FileUtils.mkdir_p(source_dir)
      FileUtils.mkdir_p(dest_dir)

      # Create files that should be skipped and included
      File.write(File.join(source_dir, 'agent.md'), 'Valid agent')
      File.write(File.join(source_dir, 'temp.tmp'), 'Temp file')
      File.write(File.join(source_dir, '.hidden'), 'Hidden file')

      config = @config.merge(
        source_dir: source_dir,
        dest_dir: dest_dir,
        skip_patterns: ['*.tmp', '.*']
      )

      manager = ClaudeAgents::SymlinkManager.new(config, @ui)
      result = manager.create_symlinks

      assert result, 'Should complete successfully'

      # Check that only valid file was symlinked
      assert File.symlink?(File.join(dest_dir, "#{@config[:prefix]}agent.md")),
             'Should create symlink for valid file'
      refute_path_exists File.join(dest_dir, "#{@config[:prefix]}temp.tmp"),
                         'Should skip .tmp files'
      refute_path_exists File.join(dest_dir, "#{@config[:prefix]}.hidden"),
                         'Should skip hidden files'
    end
  end

  # Test create_symlinks with existing symlinks (update scenario)
  def test_create_symlinks_with_existing_symlinks
    with_temp_dir do |temp_dir|
      source_dir = File.join(temp_dir, 'source')
      dest_dir = File.join(temp_dir, 'dest')
      FileUtils.mkdir_p([source_dir, dest_dir])

      # Create source file
      source_file = File.join(source_dir, 'agent.md')
      File.write(source_file, 'Agent content')

      # Create existing symlink pointing elsewhere
      dest_link = File.join(dest_dir, "#{@config[:prefix]}agent.md")
      old_target = File.join(temp_dir, 'old_target.md')
      File.write(old_target, 'Old content')
      File.symlink(old_target, dest_link)

      assert File.symlink?(dest_link), 'Symlink should exist initially'
      assert_equal old_target, File.readlink(dest_link), 'Should point to old target'

      config = @config.merge(source_dir: source_dir, dest_dir: dest_dir)
      manager = ClaudeAgents::SymlinkManager.new(config, @ui)

      result = manager.create_symlinks

      assert result, 'Should complete successfully'
      assert File.symlink?(dest_link), 'Symlink should still exist'
      assert_equal source_file, File.readlink(dest_link), 'Should point to new target'
    end
  end

  # Test remove_symlinks functionality
  def test_remove_symlinks
    with_temp_dir do |temp_dir|
      source_dir = File.join(temp_dir, 'source')
      dest_dir = File.join(temp_dir, 'dest')
      FileUtils.mkdir_p([source_dir, dest_dir])

      # Create source files and symlinks
      source_file = File.join(source_dir, 'agent.md')
      File.write(source_file, 'Content')

      dest_link = File.join(dest_dir, "#{@config[:prefix]}agent.md")
      File.symlink(source_file, dest_link)

      # Also create a non-symlink file to ensure it's not removed
      regular_file = File.join(dest_dir, 'regular.md')
      File.write(regular_file, 'Regular file')

      assert File.symlink?(dest_link), 'Symlink should exist'
      assert_path_exists regular_file, 'Regular file should exist'

      config = @config.merge(source_dir: source_dir, dest_dir: dest_dir)
      manager = ClaudeAgents::SymlinkManager.new(config, @ui)

      result = manager.remove_symlinks

      assert result, 'Should complete successfully'
      refute_path_exists dest_link, 'Symlink should be removed'
      assert_path_exists regular_file, 'Regular file should remain'
    end
  end

  # Test file processing integration
  def test_file_processing_integration
    with_temp_dir do |temp_dir|
      source_dir = File.join(temp_dir, 'source')
      dest_dir = File.join(temp_dir, 'dest')
      FileUtils.mkdir_p([source_dir, dest_dir])

      # Create files with different extensions
      File.write(File.join(source_dir, 'agent.md'), 'Markdown agent')
      File.write(File.join(source_dir, 'tool.yaml'), 'YAML tool')
      File.write(File.join(source_dir, 'README.txt'), 'Text file')

      config = @config.merge(source_dir: source_dir, dest_dir: dest_dir)
      manager = ClaudeAgents::SymlinkManager.new(config, @ui)

      # Mock file processor to track processed files
      mock_processor = mock('FileProcessor')
      mock_processor.expects(:process_file).times(3).returns(true)
      ClaudeAgents::FileProcessor.expects(:new).times(3).returns(mock_processor)

      result = manager.create_symlinks

      assert result, 'Should process all files successfully'
    end
  end

  # Test error handling in symlink creation
  def test_create_symlinks_error_handling
    with_temp_dir do |temp_dir|
      source_dir = File.join(temp_dir, 'source')
      dest_dir = '/root/forbidden' # Directory we can't write to
      FileUtils.mkdir_p(source_dir)

      File.write(File.join(source_dir, 'agent.md'), 'Content')

      config = @config.merge(source_dir: source_dir, dest_dir: dest_dir)
      manager = ClaudeAgents::SymlinkManager.new(config, @ui)

      # Should handle permission errors gracefully
      assert_raises ClaudeAgents::FileProcessingError do
        manager.create_symlinks
      end
    end
  end

  # Test progress tracking during operations
  def test_progress_tracking
    with_temp_dir do |temp_dir|
      source_dir = File.join(temp_dir, 'source')
      dest_dir = File.join(temp_dir, 'dest')
      FileUtils.mkdir_p([source_dir, dest_dir])

      # Create multiple files to track progress
      5.times do |i|
        File.write(File.join(source_dir, "agent#{i}.md"), "Agent #{i}")
      end

      config = @config.merge(source_dir: source_dir, dest_dir: dest_dir)
      manager = ClaudeAgents::SymlinkManager.new(config, @ui)

      # Verify progress tracking is called
      progress_bar = mock_progress_bar
      progress_bar.expects(:advance).times(5)
      @ui.expects(:with_progress).yields(progress_bar).returns(true)

      result = manager.create_symlinks

      assert result, 'Should complete with progress tracking'
    end
  end

  # Test destination directory creation
  def test_destination_directory_creation
    with_temp_dir do |temp_dir|
      source_dir = File.join(temp_dir, 'source')
      dest_dir = File.join(temp_dir, 'nonexistent', 'dest')
      FileUtils.mkdir_p(source_dir)

      File.write(File.join(source_dir, 'agent.md'), 'Content')

      config = @config.merge(source_dir: source_dir, dest_dir: dest_dir)
      manager = ClaudeAgents::SymlinkManager.new(config, @ui)

      result = manager.create_symlinks

      assert result, 'Should create destination directory and complete'
      assert Dir.exist?(dest_dir), 'Should create destination directory'
      assert File.symlink?(File.join(dest_dir, "#{@config[:prefix]}agent.md")),
             'Should create symlink in new directory'
    end
  end

  # Test symlink validation
  def test_symlink_validation
    with_temp_dir do |temp_dir|
      source_dir = File.join(temp_dir, 'source')
      dest_dir = File.join(temp_dir, 'dest')
      FileUtils.mkdir_p([source_dir, dest_dir])

      source_file = File.join(source_dir, 'agent.md')
      File.write(source_file, 'Content')

      config = @config.merge(source_dir: source_dir, dest_dir: dest_dir)
      manager = ClaudeAgents::SymlinkManager.new(config, @ui)

      # Create symlinks
      manager.create_symlinks

      dest_link = File.join(dest_dir, "#{@config[:prefix]}agent.md")

      # Verify symlink properties
      assert File.symlink?(dest_link), 'Should be a symlink'
      assert_path_exists dest_link, 'Symlink target should exist'
      assert_equal File.expand_path(source_file), File.expand_path(File.readlink(dest_link)),
                   'Symlink should point to correct target'
    end
  end
end
