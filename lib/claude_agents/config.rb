# frozen_string_literal: true

module ClaudeAgents
  # Configuration management with validation and path handling
  class Config
    REPOSITORIES = {
      awesome: {
        url: 'VoltAgent/awesome-claude-code-subagents',
        dir: 'agents/awesome-claude-code-subagents',
        description: '116 industry-standard agents'
      },
      wshobson_agents: {
        url: 'wshobson/agents',
        dir: 'agents/wshobson-agents',
        description: '82 production-ready agents'
      },
      wshobson_commands: {
        url: 'wshobson/commands',
        dir: 'agents/wshobson-commands',
        description: '56 workflow tools'
      }
    }.freeze

    COMPONENTS = {
      dlabs: {
        name: 'dLabs agents',
        description: 'Local specialized agents',
        count: 5,
        source_dir: 'agents/dallasLabs',
        prefix: 'dLabs-',
        destination: :agents,
        processor: :prefixed
      },
      awesome: {
        name: 'awesome-claude-code-subagents',
        description: '116 industry-standard agents',
        count: 116,
        source_dir: 'agents/awesome-claude-code-subagents',
        prefix: nil, # Category-based
        destination: :agents,
        processor: :awesome
      },
      wshobson_agents: {
        name: 'wshobson agents',
        description: '82 production-ready agents',
        count: 82,
        source_dir: 'agents/wshobson-agents',
        prefix: 'wshobson-',
        destination: :agents,
        processor: :prefixed
      },
      wshobson_commands: {
        name: 'wshobson commands',
        description: '56 workflow tools',
        count: 56,
        source_dir: 'agents/wshobson-commands',
        prefix: nil,
        destination: :commands,
        processor: :wshobson_commands
      }
    }.freeze

    SKIP_PATTERNS = [
      /^readme/i,
      /^license/i,
      /^contributing/i,
      /^examples/i,
      /^setup_.*\.sh$/,
      /^\./
    ].freeze

    class << self
      def claude_dir
        @claude_dir ||= File.expand_path('~/.claude')
      end

      def agents_dir
        @agents_dir ||= File.join(claude_dir, 'agents')
      end

      def commands_dir
        @commands_dir ||= File.join(claude_dir, 'commands')
      end

      def tools_dir
        @tools_dir ||= File.join(commands_dir, 'tools')
      end

      def workflows_dir
        @workflows_dir ||= File.join(commands_dir, 'workflows')
      end

      def project_root
        @project_root ||= File.expand_path('../..', __dir__)
      end

      def agents_source_dir
        @agents_source_dir ||= File.join(project_root, 'agents')
      end

      def source_dir_for(component)
        component_config = COMPONENTS[component.to_sym]
        return nil unless component_config

        File.join(project_root, component_config[:source_dir])
      end

      def destination_dir_for(component)
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
        COMPONENTS.dig(component.to_sym, :prefix)
      end

      def component_exists?(component)
        COMPONENTS.key?(component.to_sym)
      end

      def repository_for(component)
        REPOSITORIES[component.to_sym]
      end

      def ensure_directories!
        [claude_dir, agents_dir, commands_dir, tools_dir, workflows_dir, agents_source_dir].each do |dir|
          FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        end
      end

      def skip_file?(filename)
        SKIP_PATTERNS.any? { |pattern| filename.match?(pattern) }
      end

      def valid_component?(component)
        COMPONENTS.key?(component.to_sym)
      end

      def all_components
        COMPONENTS.keys
      end

      def component_info(component)
        COMPONENTS[component.to_sym]
      end

      def allowed_symlink_roots
        [agents_dir, commands_dir, tools_dir, workflows_dir].map { |dir| File.expand_path(dir) }.uniq
      end
    end
  end
end
