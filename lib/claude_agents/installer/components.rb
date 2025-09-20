# frozen_string_literal: true

module ClaudeAgents
  class Installer
    # Component-level installation routines and summarisation helpers.
    module Components
      def install_component(component, ensure_repo: true)
        key = component.to_sym
        info = component_info_for(key)
        present_component_header(info)
        ensure_repositories([key]) if ensure_repo
        ensure_component_preconditions(key)

        mappings = file_processor.get_file_mappings_for_component(key)
        return no_files_result(info) if mappings.empty?

        success_result(symlink_manager.create_symlinks(mappings))
      rescue ValidationError, RepositoryError, SymlinkError => e
        report_component_error(e)
      end

      def install_components(components)
        return handle_no_components_selected if components.empty?

        present_batch_header
        Config.ensure_directories!
        ensure_repositories(components)
        results = build_component_results(components)
        present_batch_summary(results)
      end

      private

      def component_info_for(component)
        info = Config.component_info(component)
        raise ValidationError, "Unknown component: #{component}" unless info

        info
      end

      def present_component_header(info)
        ui.section("Installing #{info[:name]}")
      end

      def success_result(result)
        result.merge(success: true)
      end

      def report_component_error(error)
        ui.error(error.message)
        component_error_result(error)
      end

      def component_error_result(error)
        {
          success: false,
          error: error.message,
          total_files: 0,
          created_links: 0,
          skipped_files: 0,
          results: []
        }
      end

      def no_files_result(info)
        ui.warn("No files found to install for #{info[:name]}")
        success_result(total_files: 0, created_links: 0, skipped_files: 0, results: [])
      end

      def handle_no_components_selected
        ui.info('No components selected. Exiting.')
        {}
      end

      def present_batch_header
        ui.newline
        ui.section('Installing Components')
      end

      def build_component_results(components)
        components.each_with_object({}) do |component, memo|
          memo[component.to_sym] = install_component_with_handling(component)
          ui.newline
        end
      end

      def present_batch_summary(results)
        ui.display_installation_summary(results)
        ui.newline
        ui.success('Installation completed!')
      end

      def install_component_with_handling(component)
        install_component(component, ensure_repo: false)
      rescue StandardError => e
        ui.error("Failed to install #{component}: #{e.message}")
        component_error_result(e)
      end

      def ensure_component_preconditions(component)
        case component
        when :wshobson_commands
          FileUtils.mkdir_p(Config.tools_dir)
          FileUtils.mkdir_p(Config.workflows_dir)
        end
      end
    end
  end
end
