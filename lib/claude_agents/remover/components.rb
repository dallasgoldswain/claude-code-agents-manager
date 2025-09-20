# frozen_string_literal: true

module ClaudeAgents
  class Remover
    # Component-level removal operations delegating to the SymlinkManager.
    module Components
      def remove_component(component)
        info = Config.component_info(component)
        ui.section("Removing #{info[:name]}")
        remove_component_by_key(component.to_sym)
      end

      private

      def remove_component_by_key(component)
        removal_handler_for(component).call
      end

      def remove_dlabs_agents
        remove_with_presence_check(:dlabs, 'dLabs agents') do
          symlink_manager.remove_dlabs_symlinks
        end
      end

      def remove_wshobson_agents
        remove_with_presence_check(:wshobson_agents, 'wshobson agents') do
          symlink_manager.remove_wshobson_agent_symlinks
        end
      end

      def remove_wshobson_commands
        remove_with_presence_check(:wshobson_commands, 'wshobson commands') do
          symlink_manager.remove_wshobson_command_symlinks
        end
      end

      def remove_awesome_agents
        remove_with_presence_check(:awesome, 'awesome-claude-code-subagents') do
          symlink_manager.remove_awesome_agent_symlinks
        end
      end

      def remove_with_presence_check(component, label)
        ui.subsection("Removing #{label}")

        unless ui.component_installed?(component)
          ui.info("No #{label} found to remove")
          return { removed_count: 0, error_count: 0 }
        end

        yield
      end

      def removal_handler_for(component)
        {
          dlabs: method(:remove_dlabs_agents),
          wshobson_agents: method(:remove_wshobson_agents),
          wshobson_commands: method(:remove_wshobson_commands),
          awesome: method(:remove_awesome_agents)
        }.fetch(component) do
          raise ValidationError, "Unknown component: #{component}"
        end
      end
    end
  end
end
