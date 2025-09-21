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

      def component_status
        Components.component_status
      end

      def component_info(component)
        Components.component_info(component)
      end

      def source_dir_for(component)
        Components.source_dir_for(component)
      end

      def destination_dir_for(component)
        Components.destination_dir_for(component)
      end

      def prefix_for(component)
        Components.prefix_for(component)
      end

      def component_exists?(component)
        Components.component_exists?(component)
      end

      def agents_dir
        Directories.agents_dir
      end

      def commands_dir
        Directories.commands_dir
      end

      def allowed_symlink_roots
        Directories.allowed_symlink_roots
      end

      def claude_dir
        Directories.claude_dir
      end

      def project_root
        Directories.project_root
      end

      def agents_source_dir
        Directories.agents_source_dir
      end

      def ensure_directories!
        Directories.ensure_directories!
      end

      # Configuration validation methods expected by tests
      def valid_component_config?(config)
        return false unless config.is_a?(Hash)

        required_keys = %i[name description source_dir destination]
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
