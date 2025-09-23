# ABOUTME: Unit tests for ClaudeAgents::SymlinkManager class
# ABOUTME: Tests symlink creation, removal, and batch operations with error handling

# frozen_string_literal: true

require_relative "../test_helper"

class SymlinkManagerTest < ClaudeAgentsTest
  def setup
    super
    @ui = create_test_ui
    @symlink_manager = ClaudeAgents::SymlinkManager.new(@ui)
  end

  def test_create_symlink_success
    with_temp_directory do |temp_dir|
      source = create_test_file(File.join(temp_dir, "source.md"))
      destination = File.join(temp_dir, "destination.md")

      result = @symlink_manager.create_symlink(source, destination)

      assert_equal :created, result[:status]
      assert_equal "destination.md", result[:display_name]
      assert_symlink_exists destination
      assert_symlink_points_to destination, source
    end
  end

  def test_create_symlink_creates_destination_directory
    with_temp_directory do |temp_dir|
      source = create_test_file(File.join(temp_dir, "source.md"))
      destination = File.join(temp_dir, "nested", "deep", "destination.md")

      @symlink_manager.create_symlink(source, destination)

      assert_directory_exists File.dirname(destination)
      assert_symlink_exists destination
    end
  end

  def test_create_symlink_skips_existing_file
    with_temp_directory do |temp_dir|
      source = create_test_file(File.join(temp_dir, "source.md"))
      destination = create_test_file(File.join(temp_dir, "existing.md"))

      result = @symlink_manager.create_symlink(source, destination)

      assert_equal :skipped, result[:status]
      assert_equal "already exists", result[:reason]
    end
  end

  def test_create_symlink_skips_existing_symlink
    with_temp_directory do |temp_dir|
      source = create_test_file(File.join(temp_dir, "source.md"))
      destination = File.join(temp_dir, "existing_link.md")
      create_test_symlink(source, destination)

      result = @symlink_manager.create_symlink(source, destination)

      assert_equal :skipped, result[:status]
      assert_equal "already exists", result[:reason]
    end
  end

  def test_create_symlink_fails_with_nonexistent_source
    with_temp_directory do |temp_dir|
      source = File.join(temp_dir, "nonexistent.md")
      destination = File.join(temp_dir, "destination.md")

      error = assert_raises(ClaudeAgents::SymlinkError) do
        @symlink_manager.create_symlink(source, destination)
      end

      assert_includes error.message, "Source file does not exist"
    end
  end

  def test_remove_symlink_success
    with_temp_directory do |temp_dir|
      source = create_test_file(File.join(temp_dir, "source.md"))
      symlink_path = File.join(temp_dir, "symlink.md")
      create_test_symlink(source, symlink_path)

      result = @symlink_manager.remove_symlink(symlink_path)

      assert_equal :removed, result[:status]
      assert_equal "symlink.md", result[:display_name]
      refute_path_exists symlink_path
    end
  end

  def test_remove_symlink_not_found
    with_temp_directory do |temp_dir|
      nonexistent_path = File.join(temp_dir, "nonexistent.md")

      result = @symlink_manager.remove_symlink(nonexistent_path)

      assert_equal :not_found, result[:status]
    end
  end

  def test_remove_symlink_skips_regular_file
    with_temp_directory do |temp_dir|
      file_path = create_test_file(File.join(temp_dir, "regular.md"))

      result = @symlink_manager.remove_symlink(file_path)

      assert_equal :skipped, result[:status]
      assert_equal "not a symlink", result[:reason]
      assert_path_exists file_path
    end
  end

  def test_remove_symlink_skips_directory
    with_temp_directory do |temp_dir|
      dir_path = File.join(temp_dir, "directory")
      FileUtils.mkdir_p(dir_path)

      result = @symlink_manager.remove_symlink(dir_path)

      assert_equal :skipped, result[:status]
      assert_equal "is directory", result[:reason]
      assert Dir.exist?(dir_path)
    end
  end

  def test_create_symlinks_batch_operation
    with_temp_directory do |temp_dir|
      # Create source files
      sources = (1..3).map do |i|
        create_test_file(File.join(temp_dir, "source#{i}.md"))
      end

      # Prepare mappings
      mappings = sources.map.with_index do |source, i|
        {
          source: source,
          destination: File.join(temp_dir, "dest#{i + 1}.md"),
          display_name: "dest#{i + 1}.md"
        }
      end

      result = @symlink_manager.create_symlinks(mappings, show_progress: false)

      assert_equal 3, result[:total_files]
      assert_equal 3, result[:created_links]
      assert_equal 0, result[:skipped_files]

      # Verify all symlinks created
      mappings.each do |mapping|
        assert_symlink_exists mapping[:destination]
        assert_symlink_points_to mapping[:destination], mapping[:source]
      end
    end
  end

  def test_create_symlinks_handles_mixed_results
    with_temp_directory do |temp_dir|
      # Create sources
      source1 = create_test_file(File.join(temp_dir, "source1.md"))
      source2 = create_test_file(File.join(temp_dir, "source2.md"))

      # Create an existing destination
      existing_dest = create_test_file(File.join(temp_dir, "existing.md"))

      mappings = [
        {
          source: source1,
          destination: File.join(temp_dir, "new1.md"),
          display_name: "new1.md"
        },
        {
          source: source2,
          destination: existing_dest,
          display_name: "existing.md"
        }
      ]

      result = @symlink_manager.create_symlinks(mappings, show_progress: false)

      assert_equal 2, result[:total_files]
      assert_equal 1, result[:created_links]
      assert_equal 1, result[:skipped_files]
    end
  end

  def test_create_symlinks_empty_mappings
    result = @symlink_manager.create_symlinks([], show_progress: false)

    assert_equal 0, result[:total_files]
    assert_equal 0, result[:created_links]
    assert_equal 0, result[:skipped_files]
    assert_empty result[:results]
  end

  def test_remove_symlinks_by_pattern
    with_temp_directory do |temp_dir|
      # Create source files and symlinks
      (1..3).each do |i|
        source = create_test_file(File.join(temp_dir, "source#{i}.md"))
        symlink = File.join(temp_dir, "test-link#{i}.md")
        create_test_symlink(source, symlink)
      end

      pattern = File.join(temp_dir, "test-link*.md")
      result = @symlink_manager.remove_symlinks_by_pattern(pattern, "test symlinks")

      assert_equal 3, result[:removed_count]
      assert_equal 0, result[:error_count]

      # Verify symlinks are removed
      refute_path_exists File.join(temp_dir, "test-link1.md")
      refute_path_exists File.join(temp_dir, "test-link2.md")
      refute_path_exists File.join(temp_dir, "test-link3.md")
    end
  end

  def test_remove_symlinks_by_pattern_no_matches
    with_temp_directory do |temp_dir|
      pattern = File.join(temp_dir, "nonexistent*.md")
      result = @symlink_manager.remove_symlinks_by_pattern(pattern, "test symlinks")

      assert_equal 0, result[:removed_count]
      assert_equal 0, result[:error_count]
    end
  end

  def test_remove_dlabs_symlinks
    # Mock Config methods
    ClaudeAgents::Config.stubs(:agents_dir).returns(test_agents_dir)

    # Create test symlinks
    source = create_test_file(File.join(test_agents_dir, "../source.md"))
    create_test_symlink(source, File.join(test_agents_dir, "dLabs-test1.md"))
    create_test_symlink(source, File.join(test_agents_dir, "dLabs-test2.md"))

    result = @symlink_manager.remove_dlabs_symlinks

    assert_equal 2, result[:removed_count]
  end
end
