# frozen_string_literal: true

module ClaudeAgents
  # Configuration management with validation and path handling
  class Config
    # External repositories removed in dLabs-only mode
    REPOSITORIES = {}.freeze

    COMPONENTS = {
      dlabs: {
        name: "dLabs agents",
        description: "Local specialized agents",
        # NOTE: Count reflects current number of dLabs agent markdown files.
        count: 7,
        source_dir: "agents/dallasLabs/agents",
        prefix: "dLabs-",
        destination: :agents
      }
    }.freeze

    # Fallback skip patterns used when the top-level ClaudeAgents::CONFIG
    # constant is unavailable (defensive for test isolation scenarios).
    # This keeps unit tests (e.g. Config.skip_file?) functioning without
    # triggering a NameError when referencing the global configuration.
    DEFAULT_SKIP_PATTERNS = [
      /^readme/i,
      /^license/i,
      /^contributing/i,
      /^examples/i,
      /^setup_.*\.sh$/,
      /^\./,      # Hidden files
      /\.json$/,  # JSON configuration files
      /\.txt$/,   # Text files
      /\.log$/    # Log files
    ].freeze

    class << self
      def claude_dir
        @claude_dir ||= File.expand_path(ENV["CLAUDE_DIR"] || "~/.claude")
      end

      def agents_dir
        @agents_dir ||= File.join(claude_dir, "agents")
      end

      def commands_dir
        @commands_dir ||= File.join(claude_dir, "commands")
      end

      def tools_dir
        @tools_dir ||= File.join(commands_dir, "tools")
      end

      def workflows_dir
        @workflows_dir ||= File.join(commands_dir, "workflows")
      end

      def project_root
        @project_root ||= File.expand_path("../..", __dir__)
      end

      def agents_source_dir
        @agents_source_dir ||= File.join(project_root, "agents")
      end

      def source_dir_for(component)
        return nil if component.nil?

        component_config = COMPONENTS[component.to_sym]
        return nil unless component_config

        File.join(project_root, component_config[:source_dir])
      end

      def destination_dir_for(component)
        return nil if component.nil?

        component_config = COMPONENTS[component.to_sym]
        return nil unless component_config

        case component_config[:destination]
        when :agents
          agents_dir
        when :commands
          commands_dir
        else
          raise ValidationError, "Unknown destination type: #{component_config[:destination]}"
        end
      end

      def prefix_for(component)
        return nil if component.nil?

        COMPONENTS.dig(component.to_sym, :prefix)
      end

      def component_exists?(component)
        return false if component.nil?

        COMPONENTS.key?(component.to_sym)
      end

      def repository_for(component)
        return nil if component.nil?

        REPOSITORIES[component.to_sym]
      end

      def ensure_directories!
        [claude_dir, agents_dir, commands_dir, tools_dir, workflows_dir,
         agents_source_dir].each do |dir|
          FileUtils.mkdir_p(dir)
        end
      end

      def skip_file?(filename)
        patterns = if defined?(ClaudeAgents) &&
                      ClaudeAgents.const_defined?(:CONFIG) &&
                      ClaudeAgents::CONFIG[:skip_patterns]
                     ClaudeAgents::CONFIG[:skip_patterns]
                   else
                     DEFAULT_SKIP_PATTERNS
                   end

        patterns.any? { |pattern| filename.match?(pattern) }
      end

      def valid_component?(component)
        return false if component.nil?

        COMPONENTS.key?(component.to_sym)
      end

      def all_components
        COMPONENTS.keys
      end

      def component_info(component)
        raise ValidationError, "Component cannot be nil" if component.nil?

        info = COMPONENTS[component.to_sym]
        raise ValidationError, "Unknown component: #{component}" unless info

        info
      end

      # Reset cached directory paths (for testing)
      def reset_cache!
        @claude_dir = nil
        @agents_dir = nil
        @commands_dir = nil
        @tools_dir = nil
        @workflows_dir = nil
        @agents_source_dir = nil
      end
    end
  end
end
