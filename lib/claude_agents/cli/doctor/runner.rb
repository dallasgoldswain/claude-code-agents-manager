# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    module Doctor
      # Executes system health checks and reports outcomes to the UI.
      class Runner
        def initialize(user_interface)
          @ui = user_interface
        end

        def call
          ui.title('Claude Agents System Doctor')
          conclude(execute_checks)
        end

        private

        attr_reader :ui

        def execute_checks
          doctor_checks.map { |check| perform_check(check) }.all?
        end

        def doctor_checks
          [
            Checks::GithubCliCheck.new(ui),
            Checks::DirectoriesCheck.new(ui),
            Checks::SymlinksCheck.new(ui),
            Checks::RepositoriesCheck.new(ui)
          ]
        end

        def perform_check(check)
          check.call
          true
        rescue StandardError => e
          ui.error("Check failed: #{e.message}")
          false
        end

        def conclude(all_passed)
          ui.newline
          if all_passed
            ui.success('All system checks passed! 🎉')
          else
            ui.error('Some system checks failed. Please review the output above.')
            exit 1
          end
        end
      end
    end
  end
end
