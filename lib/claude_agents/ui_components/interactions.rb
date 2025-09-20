# frozen_string_literal: true

module ClaudeAgents
  module UIComponents
    # Interactive prompt helpers for confirmations and multi-selection menus.
    module Interactions
      def confirm(message, default: false)
        prompt.yes?(pastel.cyan(message.to_s), default: default)
      rescue TTY::Reader::InputInterrupt
        raise UserCancelledError, 'User cancelled operation'
      end

      def select(message, choices)
        prompt.select(pastel.cyan(message), choices)
      rescue TTY::Reader::InputInterrupt
        raise UserCancelledError, 'User cancelled operation'
      end

      def multiselect(message, choices)
        prompt.multi_select(pastel.cyan(message), choices)
      rescue TTY::Reader::InputInterrupt
        raise UserCancelledError, 'User cancelled operation'
      end

      def component_selection_menu
        choices = Config::COMPONENTS.map do |key, info|
          { name: component_choice_text(key, info), value: key }
        end

        multiselect('Select components to install:', choices)
      end

      def removal_confirmation_menu
        installed = Config.all_components.select { |component| component_installed?(component) }
        return [] if installed.empty?

        choices = installed.map do |component|
          info = Config.component_info(component)
          { name: "#{info[:name]} - #{info[:description]}", value: component }
        end

        multiselect('Select components to remove:', choices)
      end

      private

      def component_choice_text(key, info)
        status = component_selection_status(component_installed?(key))
        "#{info[:name]} - #{info[:description]} #{status}"
      end

      def component_selection_status(installed)
        installed ? pastel.green('[INSTALLED]') : pastel.dim('[NOT INSTALLED]')
      end
    end
  end
end
