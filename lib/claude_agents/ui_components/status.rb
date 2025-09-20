# frozen_string_literal: true

module ClaudeAgents
  module UIComponents
    # Status utilities for checking installations and formatting status tables.
    module Status
      COMPONENT_INSTALL_CHECKS = {
        dlabs: -> { Dir.glob(File.join(Config.agents_dir, 'dLabs-*')).any? },
        wshobson_agents: -> { Dir.glob(File.join(Config.agents_dir, 'wshobson-*')).any? },
        wshobson_commands: -> { Dir.exist?(Config.tools_dir) || Dir.exist?(Config.workflows_dir) },
        awesome: lambda do
          Dir.glob(File.join(Config.agents_dir, '*-*'))
             .reject { |path| File.basename(path).start_with?('dLabs-', 'wshobson-') }
             .any?
        end
      }.freeze

      FILE_COUNT_CALCULATORS = {
        dlabs: -> { Dir.glob(File.join(Config.agents_dir, 'dLabs-*')).length },
        wshobson_agents: -> { Dir.glob(File.join(Config.agents_dir, 'wshobson-*')).length },
        wshobson_commands: -> { Dir.glob(File.join(Config.commands_dir, '**/*')).length },
        awesome: lambda do
          Dir.glob(File.join(Config.agents_dir, '*-*'))
             .reject { |path| File.basename(path).start_with?('dLabs-', 'wshobson-') }
             .length
        end
      }.freeze

      def display_status
        title('Claude Agents Status')
        summary_table(status_data)
      end

      def status_data
        build_rows(['Component', 'Status', 'Installed Files']) do
          Config.all_components.map { |component| status_row(component) }
        end
      end

      def status_row(component)
        info = Config.component_info(component)
        installed = component_installed?(component)

        [
          info[:name],
          status_label(installed),
          installed_file_count(component, installed).to_s
        ]
      end

      def status_label(installed)
        installed ? pastel.green('✅ Installed') : pastel.dim('⭕ Not Installed')
      end

      def installed_file_count(component, installed)
        return 0 unless installed

        calculator = FILE_COUNT_CALCULATORS[normalize_component(component)]
        calculator ? calculator.call : 0
      end

      def component_installed?(component)
        checker = COMPONENT_INSTALL_CHECKS[normalize_component(component)]
        checker ? checker.call : false
      end

      private

      def build_rows(headers)
        rows = [headers, :separator]
        rows.concat(Array(yield))
      end

      def normalize_component(component)
        component.respond_to?(:to_sym) ? component.to_sym : component
      end
    end
  end
end
