# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    module Doctor
      module Checks
        # Ensures managed directories exist and are writable.
        class DirectoriesCheck < BaseCheck
          def call
            ui.subsection('Checking directories')
            directories.each { |dir| report_directory_status(dir) }
          end

          private

          def directories
            [Config.claude_dir, Config.agents_dir, Config.commands_dir]
          end

          def report_directory_status(dir)
            unless Dir.exist?(dir)
              ui.info("#{dir} does not exist (will be created when needed)")
              return
            end

            if File.writable?(dir)
              ui.success("#{dir} exists and is writable")
            else
              ui.error("#{dir} exists but is not writable")
              raise ValidationError, "Directory permission error: #{dir}"
            end
          end
        end
      end
    end
  end
end
