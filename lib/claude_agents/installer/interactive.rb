# frozen_string_literal: true

module ClaudeAgents
  class Installer
    # Interactive workflow for selecting and installing components.
    module Interactive
      def interactive_install
        show_install_intro
        return unless ensure_installation_can_proceed?

        components = ui.component_selection_menu
        return handle_no_components_selected if components.empty?

        present_install_plan(components)
        install_components(components) if confirm_install_plan?
      end

      private

      def show_install_intro
        ui.title('Claude Code Agent Installer')
        ui.info('Welcome to the interactive Claude Code agent installer!')
        ui.newline
      end

      def ensure_installation_can_proceed?
        check_and_offer_removal
        true
      end

      def present_install_plan(components)
        ui.newline
        ui.section('Installation Plan')
        components.each do |component|
          info = Config.component_info(component)
          ui.highlight("• #{info[:name]} - #{info[:description]}")
        end
        ui.newline
      end

      def confirm_install_plan?
        ui.confirm('Proceed with installation?')
      end

      def check_and_offer_removal
        existing = installed_components
        return if existing.empty?

        present_existing_install_warning
        selected = prompt_removal_components
        return if selected.empty?

        Remover.new(ui).remove_components(selected)
        ui.newline
      end

      def installed_components
        Config.all_components.select { |component| ui.component_installed?(component) }
      end

      def present_existing_install_warning
        ui.warn('Existing agent installations detected.')
        ui.newline
      end

      def prompt_removal_components
        return [] unless ui.confirm('Would you like to remove existing installations first?')

        ui.removal_confirmation_menu
      end
    end
  end
end
