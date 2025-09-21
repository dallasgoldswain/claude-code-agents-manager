# frozen_string_literal: true

module ClaudeAgents
  class Config
    # Component metadata and helpers for installation/removal logic.
    module Components
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
          prefix: nil,
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

      # Alias for all components list for tests
      ALL = COMPONENTS.keys.freeze

      module_function

      def component_exists?(component)
        COMPONENTS.key?(component.to_sym)
      end

      def valid_component?(component)
        component_exists?(component)
      end

      def all_components
        COMPONENTS.keys
      end

      def component_info(component)
        COMPONENTS[component.to_sym]
      end

      def prefix_for(component)
        COMPONENTS.dig(component.to_sym, :prefix)
      end

      def source_dir_for(component)
        info = component_info(component)
        return unless info

        File.join(project_root, info[:source_dir])
      end

      def destination_dir_for(component)
        info = component_info(component)
        return unless info

        case info[:destination]
        when :agents
          agents_dir
        when :commands
          commands_dir
        else
          raise ValidationError, "Unknown destination type: #{info[:destination]}"
        end
      end

      def project_root
        # Get the root directory of the project (where this gem's source code lives)
        File.expand_path('../../..', __dir__)
      end

      def agents_dir
        # This would typically come from the Directories module
        File.join(Dir.home, '.claude', 'agents')
      end

      def commands_dir
        # This would typically come from the Directories module
        File.join(Dir.home, '.claude', 'commands')
      end

      def component_status
        all_components.map do |component|
          destination_dir = destination_dir_for(component)
          installed = destination_dir && Dir.exist?(destination_dir)
          symlinks = installed ? count_symlinks_for_component(component) : 0

          {
            name: component.to_s,
            installed: installed,
            symlinks: symlinks
          }
        end
      end

      def count_symlinks_for_component(component)
        destination_dir = destination_dir_for(component)
        return 0 unless destination_dir && Dir.exist?(destination_dir)

        Dir.glob(File.join(destination_dir, '*')).count { |file| File.symlink?(file) }
      end
    end
  end
end
