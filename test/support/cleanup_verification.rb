# frozen_string_literal: true

# Cleanup verification helper for minitest
# Verifies that test artifacts are properly cleaned up after test runs

module CleanupVerification
  class << self
    # Run verification after all tests complete
    def verify_cleanup!
      puts "\n🧹 Verifying test cleanup..."

      issues = []
      issues.concat(check_temp_directories)
      issues.concat(check_fixture_files)
      issues.concat(check_test_symlinks)

      if issues.empty?
        puts '✅ All test artifacts have been cleaned up properly!'
      else
        puts "❌ Found #{issues.length} cleanup issues:"
        issues.each { |issue| puts "  - #{issue}" }
        exit(1) if ENV['CI'] # Fail CI builds if cleanup is incomplete
      end
    end

    private

    # Check for leftover temporary directories
    def check_temp_directories
      issues = []

      temp_patterns = [
        '/tmp/claude_agents_test*',
        '/tmp/mock_home*'
      ]

      temp_patterns.each do |pattern|
        leftover_dirs = Dir.glob(pattern)
        leftover_dirs.each do |dir|
          issues << "Leftover temp directory: #{dir}"
        end
      end

      issues
    end

    # Check for leftover fixture files
    def check_fixture_files
      issues = []

      fixture_dir = File.join(__dir__, '..', 'fixtures')
      if Dir.exist?(fixture_dir)
        fixture_files = Dir.glob("#{fixture_dir}/**/*").select { |f| File.file?(f) }
        fixture_files.each do |file|
          issues << "Leftover fixture file: #{file}"
        end
      end

      issues
    end

    # Check for leftover symlinks in test directories
    def check_test_symlinks
      issues = []

      test_dir = File.join(__dir__, '..')
      test_symlinks = Dir.glob("#{test_dir}/**/*").select { |f| File.symlink?(f) }
      test_symlinks.each do |symlink|
        issues << "Leftover test symlink: #{symlink}"
      end

      issues
    end
  end
end

# Register cleanup verification to run at program exit
at_exit do
  # Only run verification if tests were actually run
  CleanupVerification.verify_cleanup! if defined?(Minitest) && ENV.fetch('SKIP_CLEANUP_VERIFICATION', 'false') != 'true'
end
