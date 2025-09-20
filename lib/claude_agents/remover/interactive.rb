# frozen_string_literal: true

module ClaudeAgents
  class Remover
    # Interactive workflows for selecting and removing components.
    module Interactive
      def interactive_remove
        show_removal_intro
        return unless ensure_components_available

        show_current_status
        components = prompt_components_to_remove
        return if components.empty?

        present_removal_plan(components)
        remove_components(components) if confirm_removal_plan?
      end

      def remove_all
        show_remove_all_intro
        return unless ensure_components_available

        return unless confirm_full_removal

        remove_components(installed_components)
      end

      private

      def installed_components
        Config.all_components.select { |component| ui.component_installed?(component) }
      end

      def show_removal_intro
        ui.title('Claude Code Agent Remover')
        ui.info('Select components to remove from your Claude Code installation.')
        ui.newline
      end

      def show_current_status
        ui.display_status
        ui.newline
      end

      def prompt_components_to_remove
        ui.removal_confirmation_menu
      end

      def present_removal_plan(components)
        ui.newline
        ui.section('Removal Plan')
        components.each do |component|
          info = Config.component_info(component)
          ui.highlight("• #{info[:name]} - #{info[:description]}")
        end
        ui.newline
        ui.warn('This will remove all symlinks for the selected components.')
      end

      def confirm_removal_plan?
        ui.confirm('Are you sure you want to proceed?')
      end

      def show_remove_all_intro
        ui.title('Remove All Claude Code Agents')
        ui.warn('This will remove ALL Claude Code agent installations.')
        ui.newline
        show_current_status
      end

      def confirm_full_removal
        return unless confirm_initial_warning

        confirm_final_warning
      end

      def confirm_initial_warning
        ui.error('⚠️  WARNING: This will remove ALL installed agent collections!')
        ui.newline
        ui.confirm('Are you absolutely sure you want to remove everything?')
      end

      def confirm_final_warning
        ui.newline
        ui.error('⚠️  FINAL WARNING: All agent symlinks will be deleted!')
        ui.confirm('Type YES to confirm complete removal', default: false)
      end

      def show_no_components_message
        ui.info('No Claude Code agents are currently installed.')
      end

      def ensure_components_available
        if installed_components.empty?
          show_no_components_message
          false
        else
          true
        end
      end
    end
  end
end
