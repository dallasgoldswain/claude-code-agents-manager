# frozen_string_literal: true

require 'rake/testtask'

# Default task runs all tests
task default: :test

# Main test task - runs all tests
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = false
  t.verbose = true
end

# Run only unit tests
Rake::TestTask.new(:unit) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/unit/**/*_test.rb']
  t.warning = false
  t.verbose = true
end

# Run only integration tests
Rake::TestTask.new(:integration) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/integration/**/*_test.rb']
  t.warning = false
  t.verbose = true
end

# Run tests with coverage report
desc 'Run tests with coverage report'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['test'].invoke
end

# Run specific test file
desc 'Run a specific test file (use TEST=path/to/test.rb)'
task :test_file do
  test_file = ENV['TEST']
  unless test_file
    puts 'Please specify a test file with TEST=path/to/test.rb'
    exit 1
  end

  ruby "-Ilib:test #{test_file}"
end

# Run tests matching a pattern
desc 'Run tests matching a pattern (use PATTERN=pattern)'
task :test_pattern do
  pattern = ENV['PATTERN']
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
  Rake::Task['test'].invoke
end

# Watch for changes and run tests (requires rerun gem)
desc 'Watch files and run tests on changes'
task :watch do
  begin
    require 'rerun'
    exec "rerun -c -x -- rake test"
  rescue LoadError
    puts 'Please install the rerun gem: gem install rerun'
    exit 1
  end
end

# Generate test documentation
desc 'Generate test documentation'
task :test_docs do
  system 'yard doc --plugin minitest test/**/*_test.rb'
end