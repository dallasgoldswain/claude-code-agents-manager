# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    module Doctor
      module Checks
        # Reports broken symlinks within managed directories.
        class SymlinksCheck < BaseCheck
          def call
            ui.subsection('Checking symlinks')

            broken_symlinks = collect_broken_symlinks([Config.agents_dir, Config.commands_dir])
            report_broken_symlinks(broken_symlinks)
          end

          private

          def collect_broken_symlinks(directories)
            directories.each_with_object([]) do |directory, memo|
              next unless Dir.exist?(directory)

              Dir.glob(File.join(directory, '**/*')).each do |path|
                memo << path if File.symlink?(path) && !File.exist?(path)
              end
            end
          end

          def report_broken_symlinks(broken_symlinks)
            if broken_symlinks.empty?
              ui.success('All symlinks are healthy')
            else
              ui.warn("Found #{broken_symlinks.length} broken symlinks:")
              broken_symlinks.each { |link| ui.dim("  • #{link}") }
            end
          end
        end
      end
    end
  end
end
