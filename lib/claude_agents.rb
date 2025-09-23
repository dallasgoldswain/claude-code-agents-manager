# frozen_string_literal: true

require "zeitwerk"
require "thor"
require "pastel"
require "tty-prompt"
require "tty-spinner"
require "tty-progressbar"
require "tty-table"
require "tty-box"
require "fileutils"
require "pathname"

module ClaudeAgents
  # Version information
  VERSION = "0.4.1"

  # Global configuration
  CONFIG = {
    claude_dir: File.expand_path("~/.claude"),
    agents_dir: File.expand_path("~/.claude/agents"),
    commands_dir: File.expand_path("~/.claude/commands"),
    source_dirs: {
      dlabs: "dallasLabs"
    },
    prefixes: {
      dlabs: "dLabs-"
    },
    skip_patterns: [
      /^readme/i,
      /^license/i,
      /^contributing/i,
      /^examples/i,
      /^setup_.*\.sh$/,
      /^\./, # Hidden files
      /\.json$/, # JSON configuration files
      /\.txt$/, # Text files
      /\.log$/ # Log files
    ]
  }.freeze
end

# Setup Zeitwerk loader
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect("ui" => "UI", "cli" => "CLI")
loader.ignore("#{__dir__}/claude_agents/errors.rb")
loader.setup
loader.eager_load if ENV["CLAUDE_AGENTS_EAGER_LOAD"] == "true"

# Manually require error classes since they don't follow Zeitwerk conventions
require_relative "claude_agents/errors"
