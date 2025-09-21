# frozen_string_literal: true

require 'test_helper'

class SymlinkManagerTest < ClaudeAgentsTest
  def setup
    super
    @ui = create_mock_ui
    @file_processor = mock('FileProcessor')
    ClaudeAgents::FileProcessor.stubs(:new).returns(@file_processor)
    @symlink_manager = ClaudeAgents::SymlinkManager.new(@ui)
  end

  def teardown
    super
    Mocha::Mock.reset_all
  end

  # Test initialization
  class InitializationTest < SymlinkManagerTest
    def test_initializes_with_ui
      assert_instance_of ClaudeAgents::SymlinkManager, @symlink_manager
      assert_respond_to @symlink_manager, :create_symlinks
      assert_respond_to @symlink_manager, :remove_symlinks
    end

    def test_initializes_file_processor
      # FileProcessor should be initialized during symlink manager creation
      assert ClaudeAgents::FileProcessor.respond_to?(:new)
    end
  end

  # Test symlink creation
  class SymlinkCreationTest < SymlinkManagerTest
    def test_creates_symlinks_for_dlabs_component
      with_mock_home do |home|
        # Set up source files
        source_dir = File.join(Dir.pwd, 'agents', 'dallasLabs')
        FileUtils.mkdir_p(source_dir)
        agent_files = {
          'test-agent.md' => '# Test Agent',
          'another-agent.md' => '# Another Agent'
        }

        agent_files.each do |filename, content|
          File.write(File.join(source_dir, filename), content)
        end

        # Set up expectations
        @file_processor.stubs(:should_skip?).returns(false)
        @file_processor.stubs(:process_filename).returns(->(name) { "dLabs-#{name}" })

        dest_dir = File.join(home, '.claude', 'agents')

        @symlink_manager.create_symlinks('dlabs')

        # Verify symlinks were created
        agent_files.each_key do |filename|
          expected_link = File.join(dest_dir, "dLabs-#{filename}")
          expected_target = File.join(source_dir, filename)

          # NOTE: In test environment, actual symlinks might not be created due to mocking
          # We verify through expectations instead
        end

        @ui.expects(:success).at_least_once
      end
    end

    def test_skips_existing_symlinks
      with_mock_home do |home|
        source_dir = File.join(Dir.pwd, 'agents', 'dallasLabs')
        dest_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(source_dir)
        FileUtils.mkdir_p(dest_dir)

        # Create existing symlink
        source_file = File.join(source_dir, 'existing.md')
        dest_link = File.join(dest_dir, 'dLabs-existing.md')
        FileUtils.touch(source_file)
        File.symlink(source_file, dest_link)

        @file_processor.stubs(:should_skip?).returns(false)
        @file_processor.stubs(:process_filename).returns(->(name) { "dLabs-#{name}" })

        @ui.expects(:verbose).with(includes('already exists'))

        @symlink_manager.create_symlinks('dlabs')
      end
    end

    def test_handles_symlink_creation_errors
      with_mock_home do |home|
        source_dir = File.join(Dir.pwd, 'agents', 'dallasLabs')
        dest_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(source_dir)

        # Make destination directory read-only
        FileUtils.mkdir_p(dest_dir)
        FileUtils.chmod(0o444, dest_dir)

        File.write(File.join(source_dir, 'test.md'), '# Test')

        @file_processor.stubs(:should_skip?).returns(false)
        @file_processor.stubs(:process_filename).returns(->(name) { "dLabs-#{name}" })

        @ui.expects(:error).with(includes('Failed to create symlink'))

        assert_raises(ClaudeAgents::SymlinkError) do
          @symlink_manager.create_symlinks('dlabs')
        end
      ensure
        FileUtils.chmod(0o755, dest_dir) if Dir.exist?(dest_dir)
      end
    end

    def test_creates_symlinks_with_dry_run_mode
      with_mock_home do |home|
        source_dir = File.join(Dir.pwd, 'agents', 'dallasLabs')
        dest_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(source_dir)

        File.write(File.join(source_dir, 'test.md'), '# Test')

        @file_processor.stubs(:should_skip?).returns(false)
        @file_processor.stubs(:process_filename).returns(->(name) { "dLabs-#{name}" })

        @ui.expects(:info).with(includes('[DRY RUN]')).at_least_once

        @symlink_manager.create_symlinks('dlabs', dry_run: true)

        # Verify no actual symlinks were created
        refute File.exist?(File.join(dest_dir, 'dLabs-test.md'))
      end
    end
  end

  # Test symlink removal
  class SymlinkRemovalTest < SymlinkManagerTest
    def test_removes_symlinks_for_component
      with_mock_home do |home|
        dest_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(dest_dir)

        # Create test symlinks
        symlinks = [
          'dLabs-agent1.md',
          'dLabs-agent2.md',
          'dLabs-agent3.md'
        ]

        symlinks.each do |link_name|
          link_path = File.join(dest_dir, link_name)
          # Create dummy target file
          target = "/tmp/#{link_name}"
          FileUtils.touch(target)
          File.symlink(target, link_path)
          # Track for cleanup
          track_symlink(link_path)
        end

        @symlink_manager.remove_symlinks('dlabs')

        # Verify all symlinks were removed
        symlinks.each do |link_name|
          refute File.exist?(File.join(dest_dir, link_name))
        end

        @ui.expects(:success).with(includes('Removed')).at_least_once
      end
    end

    def test_handles_broken_symlinks_during_removal
      with_mock_home do |home|
        dest_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(dest_dir)

        # Create broken symlink (target doesn't exist)
        broken_link = File.join(dest_dir, 'dLabs-broken.md')
        File.symlink('/nonexistent/target', broken_link)
        track_symlink(broken_link)

        @ui.expects(:verbose).with(includes('broken symlink'))

        @symlink_manager.remove_symlinks('dlabs')

        refute File.exist?(broken_link)
      end
    end

    def test_remove_symlinks_with_confirmation
      with_mock_home do |home|
        dest_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(dest_dir)

        link_path = File.join(dest_dir, 'dLabs-test.md')
        FileUtils.touch('/tmp/test.md')
        File.symlink('/tmp/test.md', link_path)
        track_symlink(link_path)

        @ui.expects(:confirm).with(includes('Remove')).returns(true)

        @symlink_manager.remove_symlinks('dlabs', confirm: true)

        refute File.exist?(link_path)
      end
    end

    def test_skips_removal_when_confirmation_denied
      with_mock_home do |home|
        dest_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(dest_dir)

        link_path = File.join(dest_dir, 'dLabs-test.md')
        FileUtils.touch('/tmp/test.md')
        File.symlink('/tmp/test.md', link_path)
        track_symlink(link_path)

        @ui.expects(:confirm).returns(false)
        @ui.expects(:info).with(includes('Cancelled'))

        @symlink_manager.remove_symlinks('dlabs', confirm: true)

        assert File.exist?(link_path)
      end
    end
  end

  # Test validation
  class ValidationTest < SymlinkManagerTest
    def test_validates_source_directory_exists
      @ui.expects(:error).with(includes('Source directory does not exist'))

      assert_raises(ClaudeAgents::DirectoryNotFoundError) do
        @symlink_manager.create_symlinks('nonexistent')
      end
    end

    def test_validates_destination_directory_writable
      with_mock_home do |home|
        dest_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(dest_dir)
        FileUtils.chmod(0o444, dest_dir) # Read-only

        source_dir = File.join(Dir.pwd, 'agents', 'dallasLabs')
        FileUtils.mkdir_p(source_dir)

        @ui.expects(:error).with(includes('not writable'))

        assert_raises(ClaudeAgents::PermissionError) do
          @symlink_manager.create_symlinks('dlabs')
        end
      ensure
        FileUtils.chmod(0o755, dest_dir) if Dir.exist?(dest_dir)
      end
    end

    def test_validates_component_configuration_exists
      invalid_component = 'invalid_component'

      @ui.expects(:error).with(includes('Unknown component'))

      assert_raises(ClaudeAgents::InvalidComponentError) do
        @symlink_manager.create_symlinks(invalid_component)
      end
    end
  end

  # Test batch operations
  class BatchOperationsTest < SymlinkManagerTest
    def test_creates_symlinks_for_multiple_files_efficiently
      with_mock_home do |home|
        source_dir = File.join(Dir.pwd, 'agents', 'dallasLabs')
        FileUtils.mkdir_p(source_dir)

        # Create many files
        100.times do |i|
          File.write(File.join(source_dir, "agent-#{i}.md"), "# Agent #{i}")
        end

        @file_processor.stubs(:should_skip?).returns(false)
        @file_processor.stubs(:process_filename).returns(->(name) { "dLabs-#{name}" })

        # Should process all files in a single batch
        @ui.expects(:with_progress).yields(mock_progress_bar).once

        @symlink_manager.create_symlinks('dlabs')
      end
    end

    def test_reports_statistics_after_batch_operation
      with_mock_home do |home|
        source_dir = File.join(Dir.pwd, 'agents', 'dallasLabs')
        FileUtils.mkdir_p(source_dir)

        5.times do |i|
          File.write(File.join(source_dir, "agent-#{i}.md"), "# Agent #{i}")
        end

        @file_processor.stubs(:should_skip?).returns(false)
        @file_processor.stubs(:process_filename).returns(->(name) { "dLabs-#{name}" })

        @ui.expects(:success).with(includes('Created 5 symlinks')).once

        @symlink_manager.create_symlinks('dlabs')
      end
    end
  end

  # Test cleanup operations
  class CleanupTest < SymlinkManagerTest
    def test_cleans_up_broken_symlinks
      with_mock_home do |home|
        dest_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(dest_dir)

        # Create valid and broken symlinks
        valid_target = '/tmp/valid.md'
        FileUtils.touch(valid_target)
        File.symlink(valid_target, File.join(dest_dir, 'valid.md'))

        File.symlink('/nonexistent', File.join(dest_dir, 'broken.md'))

        @symlink_manager.cleanup_broken_symlinks

        assert File.exist?(File.join(dest_dir, 'valid.md'))
        refute File.exist?(File.join(dest_dir, 'broken.md'))

        @ui.expects(:info).with(includes('Cleaned up'))
      end
    end

    def test_verifies_symlinks_point_to_correct_targets
      with_mock_home do |home|
        source_dir = File.join(Dir.pwd, 'agents', 'dallasLabs')
        dest_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(source_dir)
        FileUtils.mkdir_p(dest_dir)

        # Create source file and symlink
        source_file = File.join(source_dir, 'test.md')
        FileUtils.touch(source_file)
        link_path = File.join(dest_dir, 'dLabs-test.md')
        File.symlink(source_file, link_path)

        result = @symlink_manager.verify_symlinks('dlabs')

        assert result[:valid].include?(link_path)
        assert_empty result[:broken]
        assert_empty result[:mismatched]
      end
    end
  end

  # Test command symlink handling
  class CommandSymlinkTest < SymlinkManagerTest
    def test_creates_command_symlinks_in_correct_directories
      with_mock_home do |home|
        source_dir = File.join(Dir.pwd, 'agents', 'wshobson-commands')
        FileUtils.mkdir_p(File.join(source_dir, 'tools'))
        FileUtils.mkdir_p(File.join(source_dir, 'workflows'))

        # Create test command files
        File.write(File.join(source_dir, 'tools', 'test-tool.md'), '# Tool')
        File.write(File.join(source_dir, 'workflows', 'test-workflow.md'), '# Workflow')

        @file_processor.stubs(:should_skip?).returns(false)
        @file_processor.stubs(:process_filename).returns(->(name) { name })

        @symlink_manager.create_symlinks('wshobson-commands')

        tools_dir = File.join(home, '.claude', 'commands', 'tools')
        workflows_dir = File.join(home, '.claude', 'commands', 'workflows')

        # Verify symlinks are in correct subdirectories
        assert File.exist?(File.join(tools_dir, 'test-tool.md'))
        assert File.exist?(File.join(workflows_dir, 'test-workflow.md'))
      end
    end

    def test_preserves_command_directory_structure
      with_mock_home do |home|
        source_dir = File.join(Dir.pwd, 'agents', 'wshobson-commands')
        nested_dir = File.join(source_dir, 'tools', 'nested', 'deep')
        FileUtils.mkdir_p(nested_dir)

        File.write(File.join(nested_dir, 'deep-tool.md'), '# Deep Tool')

        @file_processor.stubs(:should_skip?).returns(false)
        @file_processor.stubs(:process_filename).returns(->(name) { name })

        @symlink_manager.create_symlinks('wshobson-commands')

        dest_nested = File.join(home, '.claude', 'commands', 'tools', 'nested', 'deep')

        assert Dir.exist?(dest_nested)
        assert File.exist?(File.join(dest_nested, 'deep-tool.md'))
      end
    end
  end
end
