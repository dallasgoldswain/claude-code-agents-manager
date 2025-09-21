# frozen_string_literal: true

module ClaudeAgents
  class SymlinkManager
    # Symlink removal helpers with common reporting utilities.
    module Removal
      def remove_symlink(path, display_name = nil)
        SingleRemoval.new(self, path, display_name).call
      end

      def remove_symlinks_by_pattern(pattern, description = nil)
        paths = Dir.glob(pattern).select { |candidate| File.symlink?(candidate) || File.file?(candidate) }

        remove_symlink_paths(
          paths,
          description: description,
          empty_message: "No #{description&.downcase || 'symlinks'} found to remove"
        )
      end

      def remove_dlabs_symlinks
        remove_symlinks_by_pattern(File.join(Config.agents_dir, 'dLabs-*'), 'dLabs agent symlinks')
      end

      def remove_wshobson_agent_symlinks
        remove_symlinks_by_pattern(File.join(Config.agents_dir, 'wshobson-*'), 'wshobson agent symlinks')
      end

      def remove_wshobson_command_symlinks
        results = aggregate_removal_results(
          remove_symlinks_in_directory(Config.tools_dir, 'wshobson tools'),
          remove_symlinks_in_directory(Config.workflows_dir, 'wshobson workflows'),
          remove_symlinks_by_pattern(File.join(Config.commands_dir, 'wshobson-*'), 'wshobson commands')
        )

        cleanup_empty_directories
        results
      end

      def remove_awesome_agent_symlinks
        remove_symlink_paths(
          awesome_symlink_paths,
          description: 'awesome-claude-code-subagents symlinks',
          empty_message: 'No awesome-claude-code-subagents symlinks found to remove'
        )
      end

      # Remove symlinks for a specific component
      def remove_symlinks(component, confirmation: true, confirm: nil)
        confirmation = confirm unless confirm.nil?
        return unless Config.valid_component?(component)

        if confirmation && !ui.confirm("Remove all symlinks for #{component}?")
          ui.info("Cancelled removal of #{component} symlinks")
          return empty_result
        end

        result = case component.to_sym
                 when :dlabs
                   remove_dlabs_symlinks
                 when :awesome
                   remove_awesome_agent_symlinks
                 when :wshobson_agents
                   remove_wshobson_agent_symlinks
                 when :wshobson_commands
                   remove_wshobson_command_symlinks
                 else
                   ui.error("Unknown component: #{component}")
                   raise ::ClaudeAgents::InvalidComponentError, "Unknown component: #{component}"
                 end

        # During removal, also clean up broken symlinks and log them verbose
        cleanup_broken_symlinks

        if result[:removed_count].positive? && ui.respond_to?(:success)
          ui.success("Removed #{result[:removed_count]} symlinks for #{component}")
        end

        result
      end

      # Handles removal of a single symlink, including validation and messaging.
      class SingleRemoval
        def initialize(manager, path, display_name)
          @manager = manager
          @ui = manager.ui
          @path = path
          @display_name = display_name || File.basename(path)
        end

        def call
          validate_path
          return not_found_result unless removal_target?
          return skip_file_result('not a symlink') if regular_file?
          return skip_file_result('is directory') if directory?

          remove_symlink
        end

        private

        attr_reader :manager, :ui, :path, :display_name

        def validate_path
          manager.validate_managed_path!(absolute_path)
        end

        def absolute_path
          @absolute_path ||= File.expand_path(path)
        end

        def removal_target?
          File.exist?(absolute_path) || File.symlink?(absolute_path)
        end

        def regular_file?
          File.file?(absolute_path) && !File.symlink?(absolute_path)
        end

        def directory?
          File.directory?(absolute_path)
        end

        def remove_symlink
          if File.symlink?(absolute_path) && !File.exist?(absolute_path) && ui.respond_to?(:verbose)
            ui.verbose("broken symlink: #{display_name}")
          end
          File.unlink(absolute_path)
          ui.removed(display_name)
          { status: :removed, display_name: display_name }
        rescue Errno::EACCES
          raise SymlinkError, "Permission denied removing symlink: #{absolute_path}"
        rescue StandardError => e
          raise SymlinkError, "Failed to remove symlink #{absolute_path}: #{e.message}"
        end

        def not_found_result
          { status: :not_found, display_name: display_name }
        end

        def skip_file_result(reason)
          ui.skipped("#{display_name} (#{reason})")
          { status: :skipped, reason: reason, display_name: display_name }
        end
      end

      private

      def remove_symlinks_in_directory(dir, description)
        return empty_result unless Dir.exist?(dir)

        remove_symlinks_by_pattern(File.join(dir, '*'), description)
      end

      def aggregate_removal_results(*result_sets)
        result_sets.compact.each_with_object(empty_result) do |result, accumulator|
          merge_results!(accumulator, result)
        end
      end

      def awesome_symlink_paths
        Dir.glob(File.join(Config.agents_dir, '*-*'))
           .select { |path| File.symlink?(path) || File.file?(path) }
           .reject { |path| File.basename(path).start_with?('dLabs-', 'wshobson-') }
      end

      def remove_symlink_paths(paths, description:, empty_message: nil)
        # Suppress subsection output intentionally (description retained for interface compatibility)
        _ = description

        return report_no_symlinks(empty_message) if paths.empty?

        paths.each_with_object(empty_result) do |symlink_path, accumulator|
          handle_symlink_removal(symlink_path, accumulator)
        end
      end

      def report_no_symlinks(message)
        ui.info(message || 'No symlinks found to remove')
        empty_result
      end

      def handle_symlink_removal(path, accumulator)
        # If path is a broken symlink we want verbose logging (handled in remove_symlink via File.symlink?)
        result = remove_symlink(path)
        accumulator[:results] << result
        accumulator[:removed_count] += 1 if result[:status] == :removed
      rescue SymlinkError => e
        handle_removal_error(path, accumulator, e)
      end

      def handle_removal_error(path, accumulator, error)
        ui.error("Failed to remove #{File.basename(path)}: #{error.message}")
        accumulator[:results] << { status: :error, display_name: File.basename(path), error: error.message }
        accumulator[:error_count] += 1
      end

      def empty_result
        { removed_count: 0, error_count: 0, results: [] }
      end

      def merge_results!(target, source)
        target[:removed_count] += source[:removed_count]
        target[:error_count] += source[:error_count]
        target[:results].concat(source[:results])
      end

      public

      # Override cleanup_broken_symlinks to provide verbose logging expected by tests
      def cleanup_broken_symlinks
        broken_count = 0

        [Config.agents_dir, Config.commands_dir].each do |dir|
          next unless Dir.exist?(dir)

          Dir.glob(File.join(dir, '*')).each do |path|
            next unless File.symlink?(path) && !File.exist?(path)

            File.unlink(path)
            ui.verbose("broken symlink: #{File.basename(path)}") if ui.respond_to?(:verbose)
            broken_count += 1
          rescue StandardError => e
            ui.error("Failed to remove broken symlink #{path}: #{e.message}")
          end
        end

        ui.info("Cleaned up #{broken_count} broken symlinks") if broken_count.positive?
        broken_count
      end

      private_constant :SingleRemoval
    end
  end
end
