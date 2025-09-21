# frozen_string_literal: true

module ClaudeAgents
  class Installer
    # Repository management helpers for cloning and updating sources.
    module Repositories
      def ensure_repositories(components)
        repos_needed = components.map(&:to_sym).select { |component| Config.repository_for(component) }
        return if repos_needed.empty?

        ui.section('Repository Management')
        repos_needed.each { |component| manage_repository(component) }
      end

      # Method expected by tests
      def clone_repository_if_needed(component)
        repo_info = Config.repository_for(component.to_sym)
        return unless repo_info

        dir_name = repo_info[:dir]
        source_dir = File.join(Config.project_root, dir_name)

        return ui.info("Repository #{dir_name} already exists") if Dir.exist?(source_dir)

        clone_repository(repo_info[:url], dir_name)
      end

      # Dependency check methods expected by tests
      def check_git_available
        return true if system('git', '--version', out: File::NULL, err: File::NULL)

        raise DependencyError, 'Git is required but not available. Please install Git.'
      end

      def check_gh_available
        return true if system('gh', '--version', out: File::NULL, err: File::NULL)

        ui.warning('GitHub CLI is recommended but not required')
        false
      end

      private

      def manage_repository(component)
        repo_info = Config.repository_for(component)
        dir_name = repo_info[:dir]
        source_dir = File.join(Config.project_root, dir_name)

        if Dir.exist?(source_dir)
          update_repository(source_dir, dir_name)
        else
          clone_repository(repo_info[:url], dir_name)
        end
      end

      def clone_repository(repo_url, dir_name)
        target_path = File.join(Config.project_root, dir_name)
        spinner = ui.spinner("Cloning #{repo_url}...")
        spinner.auto_spin

        success = system('gh', 'repo', 'clone', repo_url, target_path, out: File::NULL, err: File::NULL)
        spinner.stop
        handle_clone_failure(repo_url) unless success

        ui.success("Successfully cloned #{repo_url}")
      end

      def update_repository(repo_path, repo_name = nil)
        repo_name ||= File.basename(repo_path)
        spinner = ui.spinner("Updating #{repo_name}...")
        spinner.auto_spin

        success = system('git', 'pull', chdir: repo_path, out: File::NULL, err: File::NULL)
        spinner.stop

        success ? ui.success("Successfully updated #{repo_name}") : warn_repository_update_failure(repo_name)
      end

      def handle_clone_failure(repo_url)
        raise RepositoryError, "Failed to clone repository: #{repo_url}. Please check your GitHub CLI setup."
      end

      def warn_repository_update_failure(repo_name)
        ui.warn("Failed to update #{repo_name}, continuing with existing version")
      end
    end
  end
end
