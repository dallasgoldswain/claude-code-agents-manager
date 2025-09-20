# frozen_string_literal: true

module ClaudeAgents
  # Configuration management with validation and path handling
  class Config
    extend Directories
    extend Components
    extend Repositories
    extend SkipPatterns
  end
end
