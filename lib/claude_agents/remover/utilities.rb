# frozen_string_literal: true

module ClaudeAgents
  class Remover
    # Utility helpers for cleanup and post-removal verification.
    module Utilities
      def cleanup_empty_directories
        ui.subsection('Cleaning up empty directories')
        directories.each { |dir| attempt_directory_removal(dir) }
      end

      def verify_removal(component)
        !ui.component_installed?(component.to_sym)
      end

      private

      def directories
        [
          Config.tools_dir,
          Config.workflows_dir,
          Config.commands_dir,
          Config.agents_dir
        ]
      end

      def attempt_directory_removal(dir)
        return unless Dir.exist?(dir) && Dir.empty?(dir)

        Dir.rmdir(dir)
        ui.removed("empty directory: #{File.basename(dir)}")
      rescue SystemCallError => e
        ui.warn("Could not remove directory #{dir}: #{e.message}")
      end
    end
  end
end
