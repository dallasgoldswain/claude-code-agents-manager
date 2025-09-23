# ABOUTME: Minitest configuration file for Claude Agents testing
# ABOUTME: Sets up test environment options, parallel execution, and reporting preferences

# frozen_string_literal: true

# Minitest configuration
require "minitest/autorun"
require "minitest/reporters"

# Use spec-style reporter with color
Minitest::Reporters.use! [
  Minitest::Reporters::SpecReporter.new(
    color: true,
    slow_count: 5, # Report 5 slowest tests
    detailed_skip: false
  )
]

# Test execution options
module Minitest
  def self.plugin_claude_agents_init(options)
    # Set random seed for reproducible test runs (removed slow test monitoring)
    self.seed = options[:seed] || 42
  end
end

# Environment setup
ENV["MINITEST_REPORTER"] = "SpecReporter"
ENV["MT_CPU"] = "4" # Parallel test execution with 4 processes
