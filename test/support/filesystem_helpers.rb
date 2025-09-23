# ABOUTME: Helper methods for filesystem operations in tests
# ABOUTME: Provides file creation, symlink testing, and temporary directory management

# frozen_string_literal: true

require "yaml"

module FilesystemHelpers
  # Create test files and directories
  def create_test_file(path, content = "# Test agent\nname: test\ndescription: test agent")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def create_test_agent_file(filename, component = "test")
    content = <<~AGENT
      ---
      name: #{File.basename(filename, '.md')}
      description: Test agent for #{component}
      tools: []
      ---

      # Test Agent

      This is a test agent for component: #{component}
    AGENT

    create_test_file(filename, content)
  end

  def create_test_directory_structure(base_dir, structure)
    structure.each do |path, content|
      full_path = File.join(base_dir, path)

      if content.is_a?(Hash)
        # Nested directory
        FileUtils.mkdir_p(full_path)
        create_test_directory_structure(full_path, content)
      else
        # File with content
        create_test_file(full_path, content || "")
      end
    end
  end

  # Symlink testing helpers
  def create_test_symlink(source, destination)
    FileUtils.mkdir_p(File.dirname(destination))
    File.symlink(File.expand_path(source), destination)
  end

  def broken_symlink?(path)
    File.symlink?(path) && !File.exist?(path)
  end

  def count_symlinks(directory, pattern = "*")
    return 0 unless Dir.exist?(directory)

    Dir.glob(File.join(directory, pattern)).count do |path|
      File.symlink?(path)
    end
  end

  def count_files(directory, pattern = "*")
    return 0 unless Dir.exist?(directory)

    Dir.glob(File.join(directory, pattern)).count do |path|
      File.file?(path)
    end
  end

  # Directory validation
  def assert_directory_exists(path, message = nil)
    assert Dir.exist?(path), message || "Expected directory #{path} to exist"
  end

  def assert_directory_empty(path, message = nil)
    assert Dir.exist?(path), "Directory #{path} does not exist"
    assert Dir.empty?(path), message || "Expected directory #{path} to be empty"
  end

  def assert_directory_not_empty(path, message = nil)
    assert Dir.exist?(path), "Directory #{path} does not exist"
    refute Dir.empty?(path), message || "Expected directory #{path} to not be empty"
  end

  # File content validation
  def assert_file_contains(filepath, content, message = nil)
    assert_path_exists filepath, "File #{filepath} does not exist"
    file_content = File.read(filepath)

    assert_includes file_content, content, message || "Expected #{filepath} to contain '#{content}'"
  end

  def assert_yaml_frontmatter(filepath, expected_values = {})
    assert_path_exists filepath, "File #{filepath} does not exist"
    content = File.read(filepath)

    # Extract YAML frontmatter
    if content.match(/\A---\s*\n(.*?)\n---\s*\n/m)
      yaml_content = Regexp.last_match(1)
      begin
        data = YAML.safe_load(yaml_content)

        expected_values.each do |key, value|
          assert_equal value, data[key.to_s], "Expected #{key} to be #{value} in #{filepath}"
        end
      rescue Psych::SyntaxError => e
        flunk "Invalid YAML frontmatter in #{filepath}: #{e.message}"
      end
    else
      flunk "No YAML frontmatter found in #{filepath}"
    end
  end

  # Cleanup helpers
  def with_temp_directory
    dir = Dir.mktmpdir("claude_agents_test")
    yield dir
  ensure
    FileUtils.rm_rf(dir) if dir && Dir.exist?(dir)
  end

  def with_test_repo(name)
    with_temp_directory do |temp_dir|
      repo_dir = File.join(temp_dir, name)
      FileUtils.mkdir_p(repo_dir)

      # Initialize git repo
      Dir.chdir(repo_dir) do
        system("git init --quiet")
        system('git config user.name "Test User"')
        system('git config user.email "test@example.com"')
      end

      yield repo_dir
    end
  end
end
