# frozen_string_literal: true

# Test helper for claude-agents test suite
# Provides common test setup, utilities, and mocking strategies

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'
  add_group 'CLI', 'lib/claude_agents/cli'
  add_group 'Services', ['lib/claude_agents/installer', 'lib/claude_agents/remover',
                         'lib/claude_agents/symlink_manager', 'lib/claude_agents/file_processor']
  add_group 'Config', 'lib/claude_agents/config'
  add_group 'UI', 'lib/claude_agents/ui'
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'claude_agents'

require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/focus'
require 'mocha/minitest'
require 'webmock/minitest'
require 'fakefs/safe'
require 'pathname'
require 'tempfile'
require 'stringio'
require 'open3'

# Load cleanup verification
require_relative 'support/cleanup_verification'

# Use a more detailed reporter for better test output
Minitest::Reporters.use! [
  Minitest::Reporters::SpecReporter.new(color: true)
]

# Base test class with common utilities
class ClaudeAgentsTest < Minitest::Test
  # Track resources created during tests for cleanup
  def setup
    super
    @temp_dirs = []
    @temp_files = []
    @created_symlinks = []
    @mock_homes = []
  end

  def teardown
    # Clean up all tracked resources
    cleanup_test_artifacts
    super
  end

  # Capture stdout/stderr for testing CLI output
  def capture_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    [$stdout.string, $stderr.string]
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  # Create a temporary directory for testing
  def with_temp_dir
    Dir.mktmpdir('claude_agents_test') do |dir|
      @temp_dirs << dir
      Dir.chdir(dir) do
        yield dir
      end
    end
  end

  # Mock home directory for testing
  def with_mock_home
    original_home = ENV['HOME']
    temp_home = Dir.mktmpdir('mock_home')
    @mock_homes << temp_home
    ENV['HOME'] = temp_home

    # Create expected .claude directories
    FileUtils.mkdir_p(File.join(temp_home, '.claude', 'agents'))
    FileUtils.mkdir_p(File.join(temp_home, '.claude', 'commands', 'tools'))
    FileUtils.mkdir_p(File.join(temp_home, '.claude', 'commands', 'workflows'))

    yield temp_home
  ensure
    ENV['HOME'] = original_home
    # NOTE: cleanup happens in teardown to ensure it's always called
  end

  # Create a mock git repository
  def setup_mock_git_repo(path, files = {})
    FileUtils.mkdir_p(path)
    FileUtils.mkdir_p(File.join(path, '.git'))
    @temp_dirs << path

    files.each do |file_path, content|
      full_path = File.join(path, file_path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
      @temp_files << full_path
    end

    path
  end

  # Mock TTY prompt responses
  def mock_tty_prompt(responses = {})
    prompt = mock('TTY::Prompt')
    responses.each do |method, response|
      prompt.stubs(method).returns(response)
    end
    TTY::Prompt.stubs(:new).returns(prompt)
    prompt
  end

  # Mock UI with test-friendly behavior
  def create_mock_ui
    ui = mock('UI')
    ui.stubs(:say).returns(nil)
    ui.stubs(:success).returns(nil)
    ui.stubs(:error).returns(nil)
    ui.stubs(:warning).returns(nil)
    ui.stubs(:info).returns(nil)
    ui.stubs(:verbose).returns(nil)
    ui.stubs(:with_spinner).yields.returns(true)
    ui.stubs(:with_progress).yields(mock_progress_bar).returns(true)
    ui.stubs(:confirm).returns(true)
    ui.stubs(:ask).returns('')
    ui.stubs(:select).returns(nil)
    ui.stubs(:multi_select).returns([])
    ui.stubs(:display_status).returns(nil)
    ui
  end

  # Mock progress bar for testing
  def mock_progress_bar
    progress = mock('ProgressBar')
    progress.stubs(:advance).returns(nil)
    progress.stubs(:finish).returns(nil)
    progress.stubs(:update).returns(nil)
    progress
  end

  # Assert that a file exists with optional content check
  def assert_file_exists(path, content = nil)
    assert File.exist?(path), "Expected file #{path} to exist"
    return unless content

    actual_content = File.read(path)
    if content.is_a?(Regexp)
      assert_match content, actual_content, "File content doesn't match expected pattern"
    else
      assert_equal content, actual_content, "File content doesn't match"
    end
  end

  # Assert that a symlink exists and points to expected target
  def assert_symlink_exists(link_path, target_path = nil)
    assert File.symlink?(link_path), "Expected #{link_path} to be a symlink"
    return unless target_path

    actual_target = File.readlink(link_path)
    assert_equal target_path, actual_target, "Symlink target doesn't match"
  end

  # Helper to create fixture files for testing
  def create_fixture_file(name, content)
    fixture_dir = File.join(__dir__, 'fixtures')
    FileUtils.mkdir_p(fixture_dir)
    path = File.join(fixture_dir, name)
    File.write(path, content)
    @temp_files << path
    path
  end

  # Mock system calls (git, gh, etc.)
  def stub_system_command(command, success: true, output: '')
    Open3.stubs(:capture3).with(command).returns([output, '', success ? 0 : 1])

    # Also stub backticks and system
    self.class.any_instance.stubs(:`).with(command).returns(output)
    self.class.any_instance.stubs(:system).with(command).returns(success)
  end

  # Track symlinks created during tests
  def track_symlink(link_path)
    @created_symlinks << link_path if File.symlink?(link_path)
  end

  # Helper to create tracked symlinks
  def create_test_symlink(target, link_path)
    FileUtils.mkdir_p(File.dirname(link_path))
    File.symlink(target, link_path)
    @created_symlinks << link_path
    link_path
  end

  private

  # Clean up all test artifacts
  def cleanup_test_artifacts
    cleanup_symlinks
    cleanup_temp_files
    cleanup_mock_homes
    cleanup_temp_dirs
  end

  # Remove all tracked symlinks
  def cleanup_symlinks
    @created_symlinks.each do |link|
      File.unlink(link) if File.symlink?(link)
    rescue Errno::ENOENT
      # Already removed, ignore
    rescue StandardError => e
      warn "Failed to remove symlink #{link}: #{e.message}"
    end
    @created_symlinks.clear
  end

  # Remove all tracked temporary files
  def cleanup_temp_files
    @temp_files.each do |file|
      File.delete(file) if File.exist?(file)
    rescue StandardError => e
      warn "Failed to remove temp file #{file}: #{e.message}"
    end
    @temp_files.clear
  end

  # Clean up mock home directories
  def cleanup_mock_homes
    @mock_homes.each do |dir|
      FileUtils.rm_rf(dir) if Dir.exist?(dir)
    rescue StandardError => e
      warn "Failed to remove mock home #{dir}: #{e.message}"
    end
    @mock_homes.clear
  end

  # Clean up tracked temporary directories
  def cleanup_temp_dirs
    @temp_dirs.each do |dir|
      FileUtils.rm_rf(dir) if Dir.exist?(dir)
    rescue StandardError => e
      warn "Failed to remove temp dir #{dir}: #{e.message}"
    end
    @temp_dirs.clear
  end
end

# Test helper module for CLI testing with Thor
module CLITestHelper
  def setup
    super
    @cli = ClaudeAgents::CLI.new
    @original_stdout = $stdout
    @original_stderr = $stderr
  end

  def teardown
    super
    $stdout = @original_stdout
    $stderr = @original_stderr
  end

  # Run a CLI command and capture output
  def run_command(command, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    arguments = args.flatten
    capture_output do
      @cli.invoke(command, arguments, options)
    rescue SystemExit => e
      # Capture exit codes
      @exit_code = e.status
    end
  end

  # Assert that a command outputs specific text
  def assert_command_output(command, args, expected_output)
    stdout, _stderr = run_command(command, *args)
    if expected_output.is_a?(Regexp)
      assert_match expected_output, stdout
    else
      assert_includes stdout, expected_output
    end
  end

  # Assert that a command exits with specific code
  def assert_command_exit_code(command, args, expected_code)
    run_command(command, *args)
    assert_equal expected_code, @exit_code
  end
end

# Test data factory for creating consistent test objects
module TestDataFactory
  def sample_agent_file(name = 'test-agent')
    {
      'name' => name,
      'description' => 'A test agent for testing',
      'tools' => %w[tool1 tool2],
      'content' => "# #{name}\n\nTest agent instructions."
    }
  end

  def sample_config_component
    {
      name: 'test_component',
      source_dir: '/tmp/test_source',
      dest_dir: '/tmp/test_dest',
      prefix: 'test-',
      skip_patterns: ['*.tmp', '.git']
    }
  end

  def sample_repository_config
    {
      'test_repo' => {
        'url' => 'https://github.com/test/repo.git',
        'local_path' => 'agents/test-repo',
        'branch' => 'main'
      }
    }
  end
end

# Include helpers in base test class
class ClaudeAgentsTest
  include TestDataFactory
end

# Global cleanup hook to ensure no artifacts are left behind
at_exit do
  # Clean up any remaining test artifacts
  test_fixture_dir = File.join(__dir__, 'fixtures')
  if Dir.exist?(test_fixture_dir)
    begin
      FileUtils.rm_rf(test_fixture_dir)
    rescue StandardError => e
      warn "Failed to clean up fixtures directory: #{e.message}"
    end
  end

  # Clean up any temp directories that might have been missed
  Dir.glob('/tmp/claude_agents_test*').each do |dir|
    FileUtils.rm_rf(dir)
  rescue StandardError => e
    warn "Failed to clean up temp directory #{dir}: #{e.message}"
  end

  # Clean up any mock home directories
  Dir.glob('/tmp/mock_home*').each do |dir|
    FileUtils.rm_rf(dir)
  rescue StandardError => e
    warn "Failed to clean up mock home #{dir}: #{e.message}"
  end
end
