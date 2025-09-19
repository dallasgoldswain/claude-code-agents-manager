# frozen_string_literal: true

module ClaudeAgents
  # Removal service for safe cleanup of symlinks and installations
  class Remover
    attr_reader :ui, :symlink_manager

    def initialize(ui)
      @ui = ui
      @symlink_manager = SymlinkManager.new(ui)
    end

    # Interactive removal with component selection
    def interactive_remove
      ui.title('Claude Code Agent Remover')
      ui.info('Select components to remove from your Claude Code installation.')
      ui.newline

      # Check what's currently installed
      installed_components = Config.all_components.select { |comp| ui.component_installed?(comp) }

      if installed_components.empty?
        ui.info('No Claude Code agents are currently installed.')
        return
      end

      # Show current status
      ui.display_status
      ui.newline

      # Component selection for removal
      components_to_remove = ui.removal_confirmation_menu

      if components_to_remove.empty?
        ui.info('No components selected for removal.')
        return
      end

      ui.newline
      ui.section('Removal Plan')
      components_to_remove.each do |component|
        info = Config.component_info(component)
        ui.highlight("• #{info[:name]} - #{info[:description]}")
      end

      ui.newline
      ui.warn('This will remove all symlinks for the selected components.')
      return unless ui.confirm('Are you sure you want to proceed?')

      # Perform removals
      remove_components(components_to_remove)
    end

    # Remove specific component
    def remove_component(component)
      ui.section("Removing #{Config.component_info(component)[:name]}")

      case component.to_sym
      when :dlabs
        remove_dlabs_agents
      when :wshobson_agents
        remove_wshobson_agents
      when :wshobson_commands
        remove_wshobson_commands
      when :awesome
        remove_awesome_agents
      else
        raise ValidationError, "Unknown component: #{component}"
      end
    end

    # Remove multiple components with summary
    def remove_components(components)
      ui.newline
      ui.section('Removing Components')

      results = {}

      components.each do |component|
        begin
          results[component] = remove_component(component)
          results[component][:success] = true
        rescue StandardError => e
          ui.error("Failed to remove #{component}: #{e.message}")
          results[component] = {
            success: false,
            error: e.message,
            removed_count: 0,
            error_count: 1
          }
        end
        ui.newline
      end

      ui.display_removal_summary(results)
      ui.newline
      ui.success('Removal completed!')
    end

    # Remove all installed components
    def remove_all
      ui.title('Remove All Claude Code Agents')
      ui.warn('This will remove ALL Claude Code agent installations.')
      ui.newline

      # Show current status
      ui.display_status
      ui.newline

      installed_components = Config.all_components.select { |comp| ui.component_installed?(comp) }

      if installed_components.empty?
        ui.info('No Claude Code agents are currently installed.')
        return
      end

      ui.error('⚠️  WARNING: This will remove ALL installed agent collections!')
      ui.newline
      return unless ui.confirm('Are you absolutely sure you want to remove everything?')

      # Confirm again for safety
      ui.newline
      ui.error('⚠️  FINAL WARNING: All agent symlinks will be deleted!')
      return unless ui.confirm('Type YES to confirm complete removal', default: false)

      remove_components(installed_components)
    end

    private

    # Component-specific removal methods
    def remove_dlabs_agents
      ui.subsection('Removing dLabs agents')

      unless ui.component_installed?(:dlabs)
        ui.info('No dLabs agents found to remove')
        return { removed_count: 0, error_count: 0 }
      end

      symlink_manager.remove_dlabs_symlinks
    end

    def remove_wshobson_agents
      ui.subsection('Removing wshobson agents')

      unless ui.component_installed?(:wshobson_agents)
        ui.info('No wshobson agents found to remove')
        return { removed_count: 0, error_count: 0 }
      end

      symlink_manager.remove_wshobson_agent_symlinks
    end

    def remove_wshobson_commands
      ui.subsection('Removing wshobson commands')

      unless ui.component_installed?(:wshobson_commands)
        ui.info('No wshobson commands found to remove')
        return { removed_count: 0, error_count: 0 }
      end

      symlink_manager.remove_wshobson_command_symlinks
    end

    def remove_awesome_agents
      ui.subsection('Removing awesome-claude-code-subagents')

      unless ui.component_installed?(:awesome)
        ui.info('No awesome-claude-code-subagents found to remove')
        return { removed_count: 0, error_count: 0 }
      end

      symlink_manager.remove_awesome_agent_symlinks
    end

    # Utility methods
    def cleanup_empty_directories
      ui.subsection('Cleaning up empty directories')

      directories_to_check = [
        Config.tools_dir,
        Config.workflows_dir,
        Config.commands_dir,
        Config.agents_dir
      ]

      directories_to_check.each do |dir|
        next unless Dir.exist?(dir)
        next unless Dir.empty?(dir)

        begin
          Dir.rmdir(dir)
          ui.removed("empty directory: #{File.basename(dir)}")
        rescue SystemCallError => e
          ui.warn("Could not remove directory #{dir}: #{e.message}")
        end
      end
    end

    def verify_removal(component)
      case component.to_sym
      when :dlabs
        !ui.component_installed?(:dlabs)
      when :wshobson_agents
        !ui.component_installed?(:wshobson_agents)
      when :wshobson_commands
        !ui.component_installed?(:wshobson_commands)
      when :awesome
        !ui.component_installed?(:awesome)
      else
        false
      end
    end
  end
end