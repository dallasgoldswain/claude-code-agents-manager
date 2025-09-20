# frozen_string_literal: true

module ClaudeAgents
  module UIComponents
    # Summary table helpers for installation and removal reporting.
    module Summaries
      INSTALLATION_HEADERS = ['Component', 'Status', 'Files Processed', 'Links Created', 'Skipped'].freeze
      REMOVAL_HEADERS = ['Component', 'Status', 'Files Removed', 'Errors'].freeze

      def display_installation_summary(results)
        display_summary('Installation Summary', installation_summary_rows(results))
      end

      def display_removal_summary(results)
        display_summary('Removal Summary', removal_summary_rows(results))
      end

      private

      def display_summary(title_text, rows)
        newline
        section(title_text)
        summary_table(rows)
      end

      def installation_summary_rows(results)
        build_summary_rows(INSTALLATION_HEADERS) do
          results.map { |component, result| installation_summary_row(component, result) }
        end
      end

      def installation_summary_row(component, result)
        info = Config.component_info(component)

        [
          info[:name],
          summary_status_label(result[:success]),
          result[:total_files].to_s,
          result[:created_links].to_s,
          result[:skipped_files].to_s
        ]
      end

      def removal_summary_rows(results)
        build_summary_rows(REMOVAL_HEADERS) do
          results.map { |component, result| removal_summary_row(component, result) }
        end
      end

      def removal_summary_row(component, result)
        info = Config.component_info(component)

        [
          info[:name],
          summary_status_label(result[:success]),
          result[:removed_count].to_s,
          result[:error_count].to_s
        ]
      end

      def summary_status_label(success)
        success ? pastel.green('✅ Success') : pastel.red('❌ Failed')
      end

      def build_summary_rows(headers)
        rows = [headers, :separator]
        rows.concat(Array(yield))
      end
    end
  end
end
