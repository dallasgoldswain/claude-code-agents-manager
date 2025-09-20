# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    module Doctor
      module Checks
        # Verifies the GitHub CLI is installed and authenticated.
        class GithubCliCheck < BaseCheck
          def call
            ui.subsection('Checking GitHub CLI')
            ensure_installed
            report_authentication_status
          end

          private

          def ensure_installed
            return if system('which gh > /dev/null 2>&1')

            ui.error('GitHub CLI is not installed. Please install it from https://cli.github.com/')
            raise ValidationError, 'GitHub CLI is required for repository management'
          end

          def report_authentication_status
            if system('gh auth status > /dev/null 2>&1')
              ui.success('GitHub CLI is authenticated')
            else
              ui.warn('GitHub CLI is not authenticated. Run "gh auth login" to authenticate.')
            end
          end
        end
      end
    end
  end
end
