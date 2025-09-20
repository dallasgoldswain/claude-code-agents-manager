# frozen_string_literal: true

module ClaudeAgents
  class Config
    # Convenience helpers for determining whether files should be skipped.
    module SkipPatterns
      SKIP_PATTERNS = [
        /^readme/i,
        /^license/i,
        /^contributing/i,
        /^examples/i,
        /^setup_.*\.sh$/,
        /^\./
      ].freeze

      def skip_file?(filename)
        SKIP_PATTERNS.any? { |pattern| filename.match?(pattern) }
      end
    end
  end
end
