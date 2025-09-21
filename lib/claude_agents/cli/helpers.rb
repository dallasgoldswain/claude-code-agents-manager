# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    # Helper methods for CLI commands
    module Helpers
      private

      def configure_ui
        return unless options[:no_color]

        ui.pastel.enabled = false
      end

      def validate_component!(component)
        return if Config.valid_component?(component)

        available = Config.all_components.join(', ')
        raise ValidationError, "Invalid component: #{component}. Available: #{available}"
      end

      def handle_install_request(installer)
        if options[:component]
          validate_component!(options[:component])
          installer.install_component(options[:component])
        elsif options[:yes]
          installer.install_components(Config.all_components)
        else
          installer.interactive_install
        end
      end

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

      def report_setup_result(component, result)
        ui.newline
        if result[:created_links].positive?
          ui.success("Successfully installed #{result[:created_links]} #{component} agents")
        else
          ui.warn("No new #{component} agents were installed")
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
