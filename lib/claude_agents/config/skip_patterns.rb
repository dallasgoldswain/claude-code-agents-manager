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
      ]

      def self.should_skip?(filename, patterns = DEFAULT)
        patterns.any? do |pattern|
          File.fnmatch?(pattern, filename, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        end
      end

      def self.add_pattern(pattern)
        DEFAULT << pattern unless DEFAULT.include?(pattern)
      end

      def self.patterns_for(component)
        case component.to_s
        when 'dlabs'
          DEFAULT + ['*.example']
        when 'awesome'
          DEFAULT + ['node_modules/*']
        else
          DEFAULT
        end
      end

      def skip_file?(filename)
        self.class.should_skip?(filename)
      end
    end
  end
end
