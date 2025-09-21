# frozen_string_literal: true

require 'yaml'

module ClaudeAgents
  # Configuration management with validation and path handling
  class Config
    extend Directories
    extend Components
    extend Repositories
    extend SkipPatterns

    class << self
      # Delegate to Components module for backward compatibility
      def valid_component?(component)
        Components.valid_component?(component)
      end

      def all_components
        Components.all_components
      end

      # Configuration validation methods expected by tests
      def valid_component_config?(config)
        return false unless config.is_a?(Hash)

        required_keys = [:name, :description, :source_dir, :destination]
        required_keys.all? { |key| config.key?(key) }
      end

      def merge_with_defaults(user_config)
        defaults = {
          prefix: nil,
          processor: :default,
          count: 0
        }
        defaults.merge(user_config)
      end

      def load_from_file(file_path)
        return {} unless File.exist?(file_path)

        YAML.load_file(file_path) || {}
      rescue Psych::SyntaxError => e
        raise Error, "Invalid YAML in config file: #{e.message}"
      end

      # Directory helper that checks environment variables
      def base_dir
        ENV['CLAUDE_AGENTS_BASE_DIR'] || Directories.claude_dir
      end
    end
  end
end
