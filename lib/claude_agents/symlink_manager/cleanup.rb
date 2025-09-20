# frozen_string_literal: true

module ClaudeAgents
  class SymlinkManager
    # Directory housekeeping helpers for empty symlink targets.
    module Cleanup
      def cleanup_empty_directories
        cleanup_directory(Config.tools_dir)
        cleanup_directory(Config.workflows_dir)
        cleanup_directory(Config.commands_dir, label: 'commands')
      end

      private

      def cleanup_directory(dir, label: File.basename(dir))
        return unless Dir.exist?(dir) && Dir.empty?(dir)

        Dir.rmdir(dir)
        ui.removed("empty #{label} directory")
      rescue SystemCallError => e
        ui.warn("Could not remove empty #{label} directory: #{e.message}")
      end
    end
  end
end
