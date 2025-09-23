# frozen_string_literal: true

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
  class Error < StandardError; end
  class InstallationError < Error; end
  class RemovalError < Error; end
  class FileOperationError < Error; end
  class ValidationError < Error; end

  # Version information
  VERSION = "0.3.0"

  # Global configuration
  CONFIG = {
    claude_dir: File.expand_path("~/.claude"),
    agents_dir: File.expand_path("~/.claude/agents"),
    commands_dir: File.expand_path("~/.claude/commands"),
    source_dirs: {
      dlabs: "dallasLabs",
      wshobson_agents: "wshobson-agents",
      wshobson_commands: "wshobson-commands",
      awesome: "awesome-claude-code-subagents"
    },
    prefixes: {
      dlabs: "dLabs-",
      wshobson_agents: "wshobson-",
      wshobson_commands: nil,
      awesome: nil # Category-based prefixes
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

# Load all components
require_relative "claude_agents/errors"
require_relative "claude_agents/config"
require_relative "claude_agents/ui"
require_relative "claude_agents/file_processor"
require_relative "claude_agents/symlink_manager"
require_relative "claude_agents/installer"
require_relative "claude_agents/remover"
require_relative "claude_agents_cli"
