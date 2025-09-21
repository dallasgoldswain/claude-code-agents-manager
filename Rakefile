# frozen_string_literal: true

require 'rake/testtask'

# Load RuboCop if available
begin
  require 'rubocop/rake_task'
  RUBOCOP_AVAILABLE = true
rescue LoadError
  RUBOCOP_AVAILABLE = false
end

# Default task runs tests and linting
if RUBOCOP_AVAILABLE
  task default: %i[test rubocop]
else
  task default: :test
end

# Main test task - runs all tests
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb', 'test/**/test_*.rb']
  t.warning = false
  t.verbose = true
end

# Ensure cleanup after test runs
task :test do
  Rake::Task[:cleanup_test_artifacts].invoke
end

# Separate tasks for different test types
namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = FileList['test/unit/**/*_test.rb', 'test/unit/**/test_*.rb']
    t.warning = false
    t.verbose = true
  end

  task :unit do
    Rake::Task[:cleanup_test_artifacts].invoke
  end

  Rake::TestTask.new(:integration) do |t|
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = FileList['test/integration/**/*_test.rb', 'test/integration/**/test_*.rb']
    t.warning = false
    t.verbose = true
  end

  task :integration do
    Rake::Task[:cleanup_test_artifacts].invoke
  end

  # Run tests with coverage report
  desc 'Run tests with coverage report'
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task['test'].invoke
  end
end

# RuboCop linting (if available)
RuboCop::RakeTask.new if RUBOCOP_AVAILABLE

# Run specific test file
desc 'Run a specific test file (use TEST=path/to/test.rb)'
task :test_file do
  test_file = ENV.fetch('TEST', nil)
  unless test_file
    puts 'Please specify a test file with TEST=path/to/test.rb'
    exit 1
  end

  ruby "-Ilib:test #{test_file}"
end

# Run tests matching a pattern
desc 'Run tests matching a pattern (use PATTERN=pattern)'
task :test_pattern do
  pattern = ENV.fetch('PATTERN', nil)
  unless pattern
    puts 'Please specify a pattern with PATTERN=pattern'
    exit 1
  end

  ruby "-Ilib:test -e 'ARGV.each{|f| require f}' test/**/*_test.rb -n '/#{pattern}/'"
end

# CI-friendly test task with proper exit codes
desc 'Run tests for CI environment'
task :ci do
  ENV['CI'] = 'true'
  ENV['COVERAGE'] = 'true'
  begin
    Rake::Task['test'].invoke
  ensure
    # Always cleanup in CI, regardless of test outcome
    Rake::Task[:force_cleanup].invoke
  end
end

# Watch for changes and run tests (requires rerun gem)
desc 'Watch files and run tests on changes'
task :watch do
  require 'rerun'
  exec 'rerun -c -x -- rake test'
rescue LoadError
  puts 'Please install the rerun gem: gem install rerun'
  exit 1
end

# Generate test documentation
desc 'Generate test documentation'
task :test_docs do
  system 'yard doc --plugin minitest test/**/*_test.rb'
end

# Cleanup test artifacts
desc 'Clean up test artifacts and temporary files'
task :cleanup_test_artifacts do
  puts 'Cleaning up test artifacts...'

  # Clean up test fixtures directory
  fixtures_dir = File.join(__dir__, 'test', 'fixtures')
  if Dir.exist?(fixtures_dir)
    FileUtils.rm_rf(fixtures_dir)
    puts "Removed fixtures directory: #{fixtures_dir}"
  end

  # Clean up temporary directories created by tests
  temp_patterns = [
    '/tmp/claude_agents_test*',
    '/tmp/mock_home*'
  ]

  temp_patterns.each do |pattern|
    Dir.glob(pattern).each do |dir|
      next unless Dir.exist?(dir)

      begin
        FileUtils.rm_rf(dir)
        puts "Removed temp directory: #{dir}"
      rescue StandardError => e
        puts "Warning: Failed to remove #{dir}: #{e.message}"
      end
    end
  end

  # Clean up any symlinks that might be left in test directories
  test_dir = File.join(__dir__, 'test')
  Dir.glob("#{test_dir}/**/*").each do |path|
    next unless File.symlink?(path)

    begin
      File.unlink(path)
      puts "Removed test symlink: #{path}"
    rescue StandardError => e
      puts "Warning: Failed to remove symlink #{path}: #{e.message}"
    end
  end

  puts 'Test artifact cleanup completed.'
end

# Force cleanup - more aggressive cleanup for CI environments
desc 'Force cleanup of all test artifacts (for CI)'
task :force_cleanup do
  puts 'Performing force cleanup...'

  # All the regular cleanup
  Rake::Task[:cleanup_test_artifacts].invoke

  # Additional aggressive cleanup for CI
  coverage_dir = File.join(__dir__, 'coverage')
  if Dir.exist?(coverage_dir) && ENV['CI']
    # Only remove coverage in CI to avoid losing local reports
    FileUtils.rm_rf(coverage_dir)
    puts "Removed coverage directory in CI: #{coverage_dir}"
  end

  puts 'Force cleanup completed.'
end

# Verify that cleanup is working properly
desc 'Verify cleanup - check for leftover test artifacts'
task :verify_cleanup do
  puts 'Verifying test cleanup...'

  require_relative 'test/support/cleanup_verification'
  CleanupVerification.verify_cleanup!
end
