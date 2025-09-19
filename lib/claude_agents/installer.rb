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

      # Ensure repositories are available
      ensure_repositories(selected_components)

      # Perform installations
      install_components(selected_components)
    end

    # Install specific components
    def install_component(component)
      ui.section("Installing #{Config.component_info(component)[:name]}")

      case component.to_sym
      when :dlabs
        install_dlabs_agents
      when :wshobson_agents
        install_wshobson_agents
      when :wshobson_commands
        install_wshobson_commands
      when :awesome
        install_awesome_agents
      else
        raise ValidationError, "Unknown component: #{component}"
      end
    end

    # Install multiple components with summary
    def install_components(components)
      ui.newline
      ui.section('Installing Components')

      Config.ensure_directories!
      results = {}

      components.each do |component|
        begin
          results[component] = install_component(component)
          results[component][:success] = true
        rescue StandardError => e
          ui.error("Failed to install #{component}: #{e.message}")
          results[component] = {
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
      repos_needed = components.select { |comp| Config.repository_for(comp) }
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

      command = "gh repo clone #{repo_url} #{target_path}"

      spinner = ui.spinner("Cloning #{repo_url}...")
      spinner.auto_spin

      success = system(command, out: File::NULL, err: File::NULL)
      spinner.stop

      if success
        ui.success("Successfully cloned #{repo_url}")
      else
        raise RepositoryError, "Failed to clone repository: #{repo_url}. Please check your GitHub CLI setup."
      end
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

    # Component installation methods
    def install_dlabs_agents
      ui.subsection('Setting up dLabs agents')

      file_mappings = file_processor.get_file_mappings_for_component(:dlabs)

      if file_mappings.empty?
        ui.warn('No dLabs agent files found to install')
        return { total_files: 0, created_links: 0, skipped_files: 0 }
      end

      symlink_manager.create_symlinks(file_mappings)
    end

    def install_wshobson_agents
      ui.subsection('Setting up wshobson agents')

      # Ensure repository exists
      source_dir = Config.source_dir_for(:wshobson_agents)
      unless Dir.exist?(source_dir)
        ui.error("wshobson-agents repository not found. Please run the interactive installer.")
        return { total_files: 0, created_links: 0, skipped_files: 0 }
      end

      file_mappings = file_processor.get_file_mappings_for_component(:wshobson_agents)

      if file_mappings.empty?
        ui.warn('No wshobson agent files found to install')
        return { total_files: 0, created_links: 0, skipped_files: 0 }
      end

      symlink_manager.create_symlinks(file_mappings)
    end

    def install_wshobson_commands
      ui.subsection('Setting up wshobson commands')

      # Ensure repository exists
      source_dir = Config.source_dir_for(:wshobson_commands)
      unless Dir.exist?(source_dir)
        ui.error("wshobson-commands repository not found. Please run the interactive installer.")
        return { total_files: 0, created_links: 0, skipped_files: 0 }
      end

      # Ensure command directories exist
      FileUtils.mkdir_p(Config.tools_dir)
      FileUtils.mkdir_p(Config.workflows_dir)

      file_mappings = file_processor.get_file_mappings_for_component(:wshobson_commands)

      if file_mappings.empty?
        ui.warn('No wshobson command files found to install')
        return { total_files: 0, created_links: 0, skipped_files: 0 }
      end

      symlink_manager.create_symlinks(file_mappings)
    end

    def install_awesome_agents
      ui.subsection('Setting up awesome-claude-code-subagents')

      # Ensure repository exists
      source_dir = Config.source_dir_for(:awesome)
      unless Dir.exist?(source_dir)
        ui.error("awesome-claude-code-subagents repository not found. Please run the interactive installer.")
        return { total_files: 0, created_links: 0, skipped_files: 0 }
      end

      file_mappings = file_processor.get_file_mappings_for_component(:awesome)

      if file_mappings.empty?
        ui.warn('No awesome agent files found to install')
        return { total_files: 0, created_links: 0, skipped_files: 0 }
      end

      symlink_manager.create_symlinks(file_mappings)
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