# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    # CLI commands for installing a single component without prompts.
    module SetupCommands
      def self.included(base)
        configure_setup_command(base)
      end

      def self.configure_setup_command(base)
        base.desc 'setup COMPONENT', setup_description
        base.long_desc(setup_long_description)
      end

      def self.setup_description
        'Setup specific component (dlabs, wshobson-agents, wshobson-commands, awesome)'
      end

      def self.setup_long_description
        <<~DESC
          Setup a specific component without interactive prompts.

          Available components:
          • dlabs - dLabs agents (local specialized agents)
          • wshobson-agents - wshobson production-ready agents
          • wshobson-commands - wshobson workflow tools and commands
          • awesome - awesome-claude-code-subagents collection

          This command will create symlinks for the specified component only.
          Use 'install' for full interactive setup including repository management.
        DESC
      end

      def setup(component)
        configure_ui
        validate_component!(component)

        installer = Installer.new(ui)
        result = installer.install_component(component)
        report_setup_result(component, result)
      rescue StandardError => e
        ErrorHandler.handle_error(e, ui)
      end

      private

      def report_setup_result(component, result)
        ui.newline
        if result[:created_links].positive?
          ui.success("Successfully installed #{result[:created_links]} #{component} agents")
        else
          ui.warn("No new #{component} agents were installed")
        end
      end
    end
  end
end
