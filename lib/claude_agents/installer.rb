# frozen_string_literal: true

module ClaudeAgents
  # Installation service with repository management and interactive setup
  class Installer
    attr_reader :ui, :file_processor, :symlink_manager

    def initialize(ui)
      @ui = ui
      @file_processor = FileProcessor.new(ui)
      @symlink_manager = SymlinkManager.new(ui)
    end

    # Interactive installation with component selection
    def interactive_install
      ui.title('Claude Code Agent Installer')
      ui.info('Welcome to the interactive Claude Code agent installer!')
      ui.newline

      # Check for existing installations and offer removal
      check_and_offer_removal

      # Component selection
      selected_components = ui.component_selection_menu

      if selected_components.empty?
        ui.info('No components selected. Exiting.')
        return
      end

      ui.newline
      ui.section('Installation Plan')
      selected_components.each do |component|
        info = Config.component_info(component)
        ui.highlight("• #{info[:name]} - #{info[:description]}")
      end

      ui.newline
      return unless ui.confirm('Proceed with installation?')

      # Perform installations
      install_components(selected_components)
    end

    # Install specific components
    def install_component(component, ensure_repo: true)
      component = component.to_sym
      info = Config.component_info(component)
      raise ValidationError, "Unknown component: #{component}" unless info

      ui.section("Installing #{info[:name]}")

      ensure_repositories([component]) if ensure_repo
      ensure_component_preconditions(component)

      file_mappings = file_processor.get_file_mappings_for_component(component)

      if file_mappings.empty?
        ui.warn("No files found to install for #{info[:name]}")
        return { total_files: 0, created_links: 0, skipped_files: 0, success: true }
      end

      result = symlink_manager.create_symlinks(file_mappings)
      result[:success] = true
      result
    rescue ValidationError, RepositoryError, SymlinkError => e
      ui.error(e.message)
      {
        success: false,
        error: e.message,
        total_files: 0,
        created_links: 0,
        skipped_files: 0
      }
    end

    # Install multiple components with summary
    def install_components(components)
      ui.newline
      ui.section('Installing Components')

      Config.ensure_directories!
      ensure_repositories(components)
      results = {}

      components.each do |component|
        component_sym = component.to_sym
        begin
          results[component_sym] = install_component(component_sym, ensure_repo: false)
        rescue StandardError => e
          ui.error("Failed to install #{component}: #{e.message}")
          results[component_sym] = {
            success: false,
            error: e.message,
            total_files: 0,
            created_links: 0,
            skipped_files: 0
          }
        end
        ui.newline
      end

      ui.display_installation_summary(results)
      ui.newline
      ui.success('Installation completed!')
    end

    private

    # Repository management
    def ensure_repositories(components)
      repos_needed = components.map(&:to_sym).select { |comp| Config.repository_for(comp) }
      return if repos_needed.empty?

      ui.section('Repository Management')

      repos_needed.each do |component|
        repo_info = Config.repository_for(component)
        source_dir = File.join(Config.project_root, repo_info[:dir])

        if Dir.exist?(source_dir)
          ui.info("Repository #{repo_info[:dir]} exists, updating...")
          update_repository(source_dir, repo_info[:dir])
        else
          ui.info("Cloning #{repo_info[:dir]}...")
          clone_repository(repo_info[:url], repo_info[:dir])
        end
      end
    end

    def clone_repository(repo_url, dir_name)
      target_path = File.join(Config.project_root, dir_name)

      spinner = ui.spinner("Cloning #{repo_url}...")
      spinner.auto_spin

      success = system('gh', 'repo', 'clone', repo_url, target_path, out: File::NULL, err: File::NULL)
      spinner.stop

      unless success
        raise RepositoryError, "Failed to clone repository: #{repo_url}. Please check your GitHub CLI setup."
      end

      ui.success("Successfully cloned #{repo_url}")
    end

    def update_repository(repo_path, repo_name)
      spinner = ui.spinner("Updating #{repo_name}...")
      spinner.auto_spin

      success = system('git', 'pull', chdir: repo_path, out: File::NULL, err: File::NULL)
      spinner.stop

      if success
        ui.success("Successfully updated #{repo_name}")
      else
        ui.warn("Failed to update #{repo_name}, continuing with existing version")
      end
    end

    def ensure_component_preconditions(component)
      case component
      when :wshobson_commands
        FileUtils.mkdir_p(Config.tools_dir)
        FileUtils.mkdir_p(Config.workflows_dir)
      end
    end

    # Cleanup and removal checking
    def check_and_offer_removal
      installed_components = Config.all_components.select { |comp| ui.component_installed?(comp) }

      return if installed_components.empty?

      ui.warn('Existing agent installations detected.')
      ui.newline

      return unless ui.confirm('Would you like to remove existing installations first?')

      components_to_remove = ui.removal_confirmation_menu

      return if components_to_remove.empty?

      remover = Remover.new(ui)
      remover.remove_components(components_to_remove)
      ui.newline
    end
  end
end
