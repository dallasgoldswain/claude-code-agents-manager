# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    module Doctor
      module Checks
        # Validates repository presence and the dLabs directory.
        class RepositoriesCheck < BaseCheck
          def call
            ui.subsection('Checking repositories')

            Config::REPOSITORIES.each_value { |repo| report_repository_status(repo) }
            report_dlabs_directory_status
          end

          private

          def report_repository_status(repo_info)
            repo_path = File.join(Config.project_root, repo_info[:dir])

            if !Dir.exist?(repo_path)
              ui.info("#{repo_info[:dir]} repository not cloned")
            elsif Dir.exist?(File.join(repo_path, '.git'))
              ui.success("#{repo_info[:dir]} repository is available")
            else
              ui.warn("#{repo_info[:dir]} directory exists but is not a git repository")
            end
          end

          def report_dlabs_directory_status
            dlabs_path = File.join(Config.project_root, 'agents', 'dallasLabs')
            if Dir.exist?(dlabs_path)
              ui.success('dallasLabs directory is available')
            else
              ui.error('dallasLabs directory not found')
            end
          end
        end
      end
    end
  end
end
