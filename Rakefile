# ABOUTME: Rake tasks for testing, linting, and development workflows
# ABOUTME: Provides test execution, linting, and development utilities

# frozen_string_literal: true

require "rake/testtask"
require "rubocop/rake_task"

# Default task
task default: %i[test rubocop]

# Test tasks
namespace :test do
  desc "Run all tests"
  Rake::TestTask.new(:all) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.test_files = FileList["test/**/*_test.rb"]
    t.verbose = true
  end

  desc "Run unit tests only"
  Rake::TestTask.new(:unit) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.test_files = FileList["test/unit/**/*_test.rb"]
    t.verbose = true
  end

  desc "Run integration tests only"
  Rake::TestTask.new(:integration) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.test_files = FileList["test/integration/**/*_test.rb"]
    t.verbose = true
  end

  desc "Run tests with coverage reporting"
  task :coverage do
    puts "Running tests with coverage..."
    ENV["COVERAGE"] = "true"
    Rake::Task["test:all"].invoke
  end

  desc "Run tests and generate detailed report"
  task :report do
    puts "Generating test report..."

    start_time = Time.now

    # Run tests with detailed output
    system "ruby -Itest:lib test/test_helper.rb"

    end_time = Time.now
    duration = end_time - start_time

    puts "\n#{'=' * 50}"
    puts "TEST EXECUTION SUMMARY"
    puts "=" * 50
    puts "Duration: #{duration.round(2)} seconds"
    puts "Timestamp: #{Time.now}"

    # Get test file count
    unit_tests = Dir["test/unit/**/*_test.rb"].length
    integration_tests = Dir["test/integration/**/*_test.rb"].length

    puts "Unit test files: #{unit_tests}"
    puts "Integration test files: #{integration_tests}"
    puts "Total test files: #{unit_tests + integration_tests}"
    puts "=" * 50
  end

  desc "Run tests in watch mode (requires entr)"
  task :watch do
    puts "Starting test watch mode..."
    puts "Tests will re-run when files change. Press Ctrl+C to stop."

    system 'find lib test -name "*.rb" | entr -c rake test:all'
  end

  desc "Run tests showing only failures"
  task :failures_only do
    puts "Running tests (failures only output)..."
    # Use a subshell so the env var doesn't leak to subsequent tasks in this process
    system({ "FAILURES_ONLY" => "1" }, "rake test:all")
  end

  desc "Fast fail (stop on first failure) with minimal, colorized, project-only backtrace"
  task :fast_fail do
    puts "Running tests with fast-fail (color, failures-only style, project backtrace)..."
    env = {
      "FAIL_FAST" => "1",
      "FAILURES_ONLY" => "1",
      "PROJECT_BT" => "1",
      # Force color even in some CI/non-tty contexts; user can disable with NO_COLOR=1
      "FORCE_COLOR" => "1"
    }
    system(env, "rake test:all")
  end

  desc "Run specific test file"
  task :file, [:filename] do |_t, args|
    filename = args[:filename]
    unless filename
      puts "Usage: rake test:file[path/to/test_file.rb]"
      exit 1
    end

    unless File.exist?(filename)
      puts "Test file not found: #{filename}"
      exit 1
    end

    system "ruby -Itest:lib #{filename}"
  end

  desc "Run specific test method"
  task :method, [:class_name, :method_name] do |_t, args|
    class_name = args[:class_name]
    method_name = args[:method_name]

    unless class_name && method_name
      puts "Usage: rake test:method[TestClassName,test_method_name]"
      exit 1
    end

    system "ruby -Itest:lib -e \"
      require_relative 'test/test_helper'
      require_relative 'test/unit/#{class_name.downcase.gsub('test', '')}_test.rb'
      #{class_name}.new('#{method_name}').run
    \""
  end
end

# Alias for convenience
task test: "test:all"

# Linting tasks
RuboCop::RakeTask.new do |task|
  task.patterns = ["lib/**/*.rb", "test/**/*.rb", "bin/*"]
  task.formatters = ["simple"]
  task.fail_on_error = true
end

namespace :rubocop do
  desc "Auto-correct RuboCop offenses"
  RuboCop::RakeTask.new(:autocorrect) do |task|
    task.patterns = ["lib/**/*.rb", "test/**/*.rb", "bin/*"]
    task.options = ["--autocorrect"]
  end

  desc "Auto-correct RuboCop offenses (including unsafe corrections)"
  RuboCop::RakeTask.new(:autocorrect_all) do |task|
    task.patterns = ["lib/**/*.rb", "test/**/*.rb", "bin/*"]
    task.options = ["--autocorrect-all"]
  end
end

# Development tasks
namespace :dev do
  desc "Setup development environment"
  task :setup do
    puts "Setting up development environment..."

    # Install gems
    system "bundle install"

    # Create test directories if they don't exist
    %w[test/unit test/integration test/fixtures test/support].each do |dir|
      FileUtils.mkdir_p(dir)
    end

    puts "Development environment ready!"
    puts 'Run "rake test" to run all tests'
    puts 'Run "rake test:watch" for continuous testing'
  end

  desc "Clean up test artifacts"
  task :clean do
    puts "Cleaning up test artifacts..."

    # Remove temporary test files
    FileUtils.rm_rf("tmp/test_*")
    FileUtils.rm_rf("coverage")

    # Clean up any symlinks in test directories
    Dir.glob("test/**/*").each do |path|
      File.unlink(path) if File.symlink?(path)
    end

    puts "Cleanup complete!"
  end

  desc "Run full development check (tests + linting)"
  task :check do
    puts "Running full development check..."

    # Run tests
    Rake::Task["test:all"].invoke

    # Run linting
    Rake::Task["rubocop"].invoke

    puts "\n✅ All checks passed! Ready for commit."
  rescue SystemExit => e
    puts "\n❌ Checks failed. Please fix issues before committing."
    exit e.status
  end
end

# Documentation tasks
namespace :doc do
  desc "Generate test documentation"
  task :tests do
    puts "Generating test documentation..."

    output = []
    output << "# Test Suite Documentation\n"
    output << "Generated: #{Time.now}\n\n"

    # Unit tests
    output << "## Unit Tests\n"
    Dir["test/unit/**/*_test.rb"].each do |file|
      class_name = File.basename(file, "_test.rb").split("_").map(&:capitalize).join
      output << "- **#{class_name}**: #{file}\n"
    end

    # Integration tests
    output << "\n## Integration Tests\n"
    Dir["test/integration/**/*_test.rb"].each do |file|
      class_name = File.basename(file, "_test.rb").split("_").map(&:capitalize).join
      output << "- **#{class_name}**: #{file}\n"
    end

    # Test methods count
    total_methods = 0
    Dir["test/**/*_test.rb"].each do |file|
      content = File.read(file)
      methods = content.scan(/def test_\w+/).length
      total_methods += methods
    end

    output << "\n## Statistics\n"
    output << "- Total test methods: #{total_methods}\n"
    output << "- Unit test files: #{Dir['test/unit/**/*_test.rb'].length}\n"
    output << "- Integration test files: #{Dir['test/integration/**/*_test.rb'].length}\n"

    File.write("TEST_DOCUMENTATION.md", output.join)
    puts "Test documentation saved to TEST_DOCUMENTATION.md"
  end
end

# CI tasks
namespace :ci do
  desc "Run CI pipeline locally"
  task :local do
    puts "Running CI pipeline locally..."

    tasks = %w[
      dev:clean
      test:all
      rubocop
    ]

    tasks.each do |task|
      puts "\n=== Running #{task} ==="
      Rake::Task[task].invoke
    end

    puts "\n✅ CI pipeline completed successfully!"
  end

  desc "Quick CI check (fast tests only)"
  task :quick do
    puts "Running quick CI check..."

    Rake::Task["test:unit"].invoke
    Rake::Task["rubocop"].invoke

    puts "\n✅ Quick check completed!"
  end
end
