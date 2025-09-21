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

      def verify_symlinks(_component = nil)
        categorized = { valid: [], broken: [], mismatched: [] }

        [Config.agents_dir, Config.commands_dir].each do |dir|
          next unless Dir.exist?(dir)

          Dir.glob(File.join(dir, '*')).each do |path|
            next unless File.symlink?(path)

            target = File.readlink(path)
            if File.exist?(target)
              categorized[:valid] << path
            else
              categorized[:broken] << path
            end
          end
        end

        categorized
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
