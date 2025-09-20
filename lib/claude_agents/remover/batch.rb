# frozen_string_literal: true

module ClaudeAgents
  class Remover
    # Batch removal orchestration with summary reporting.
    module Batch
      def remove_components(components)
        return handle_no_components_selected if components.empty?

        present_batch_header
        results = build_removal_results(components)
        present_batch_summary(results)
      end

      private

      def present_batch_header
        ui.newline
        ui.section('Removing Components')
      end

      def build_removal_results(components)
        components.each_with_object({}) do |component, memo|
          key, result = process_component_removal(component)
          memo[key] = result
        end
      end

      def present_batch_summary(results)
        ui.display_removal_summary(results)
        ui.newline
        ui.success('Removal completed!')
      end

      def remove_component_with_handling(component)
        remove_component(component).merge(success: true)
      rescue StandardError => e
        ui.error("Failed to remove #{component}: #{e.message}")
        { success: false, error: e.message, removed_count: 0, error_count: 1 }
      end

      def process_component_removal(component)
        result = remove_component_with_handling(component)
        ui.newline
        [component, result]
      end

      def handle_no_components_selected
        ui.info('No components selected for removal.')
        {}
      end
    end
  end
end
