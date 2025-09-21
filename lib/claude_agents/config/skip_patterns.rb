# frozen_string_literal: true

module ClaudeAgents
  class Config
    # Convenience helpers for determining whether files should be skipped.
    module SkipPatterns
      DEFAULT = [
        '.git',
        '.DS_Store',
        '*.tmp',
        '*.swp',
        'README.md',
        'LICENSE',
        'CONTRIBUTING.md',
        'examples',
        'setup_*.sh',
        '.*'
      ].freeze

      @dynamic_patterns = []

      class << self
        attr_accessor :dynamic_patterns
      end

      def self.should_skip?(filename, patterns = all_patterns)
        patterns.any? do |pattern|
          File.fnmatch?(pattern, filename, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        end
      end

      def self.add_pattern(pattern)
        @dynamic_patterns << pattern unless @dynamic_patterns.include?(pattern)
      end

      def self.all_patterns
        DEFAULT + @dynamic_patterns
      end

      def self.patterns_for(component)
        case component.to_s
        when 'dlabs'
          all_patterns + ['*.example']
        when 'awesome'
          all_patterns + ['node_modules/*']
        else
          all_patterns
        end
      end

      def skip_file?(filename)
        self.class.should_skip?(filename)
      end
    end
  end
end
