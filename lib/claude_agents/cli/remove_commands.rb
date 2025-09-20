# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    # CLI commands for removing installed components.
    module RemoveCommands
      def self.included(base)
        configure_remove_command(base)
        configure_remove_options(base)
      end

      def self.configure_remove_command(base)
        base.desc 'remove [COMPONENT]', remove_description
        base.long_desc(remove_long_description)
      end

      def self.remove_description
        'Remove installed agents'
      end

      def self.remove_long_description
        <<~DESC
          Remove installed Claude Code agents. If no component is specified,
          launches an interactive removal tool.

          Available components:
          • dlabs - Remove dLabs agents
          • wshobson-agents - Remove wshobson agents
          • wshobson-commands - Remove wshobson commands
          • awesome - Remove awesome-claude-code-subagents
          • all - Remove everything (use with caution!)

          The removal process:
          • Only removes symlinks (source files are preserved)
          • Cleans up empty directories
          • Provides detailed feedback on what was removed
        DESC
      end

      def self.configure_remove_options(base)
        base.option :force, type: :boolean, aliases: '-f', desc: 'Skip confirmation prompts'
      end

      def remove(component = nil)
        configure_ui
        remover = Remover.new(ui)
        handle_remove_component(remover, component)
      rescue StandardError => e
        ErrorHandler.handle_error(e, ui)
      end

      private

      def handle_remove_component(remover, component)
        case component
        when nil
          remover.interactive_remove
        when 'all'
          remover.remove_all
        else
          validate_component!(component)
          summarize_component_removal(component, remover.remove_component(component))
        end
      end

      def summarize_component_removal(component, result)
        ui.newline
        if result[:removed_count].positive?
          ui.success("Successfully removed #{result[:removed_count]} #{component} agents")
        else
          ui.info("No #{component} agents were found to remove")
        end
      end
    end
  end
end
