# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    # Core command definitions for the CLI
    module Commands
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def define_commands
          define_doctor_command
          define_install_command
          define_setup_command
          define_remove_command
          define_status_command
          define_version_command
        end

        private

        def define_doctor_command
          desc 'doctor', 'Check system health and dependencies'
          long_desc <<~DESC
            Run system diagnostics to check:
            • GitHub CLI availability and authentication
            • Directory permissions
            • Symlink integrity
            • Repository status

            Use this command to troubleshoot installation issues.
          DESC
        end

        def define_install_command
          desc 'install', 'Interactive installation of Claude Code agents'
          long_desc <<~DESC
            Launch an interactive installer that allows you to select which agent collections
            to install. The installer will:

            • Show you what's currently installed
            • Let you choose which components to install
            • Handle repository cloning and updates automatically
            • Create organized symlinks in ~/.claude/

            You can also use options to automate the installation:
            • Use --component to install a specific component
            • Use --yes to install all components without prompts
            • Use --force to skip confirmation prompts
          DESC
          option :component, type: :string, aliases: '-c',
                 desc: 'Install specific component (dlabs, wshobson-agents, wshobson-commands, awesome)'
          option :yes, type: :boolean, aliases: '-y', desc: 'Skip interactive prompts and install all'
          option :force, type: :boolean, aliases: '-f', desc: 'Skip confirmation prompts'
        end

        def define_setup_command
          desc 'setup COMPONENT', 'Setup specific component (dlabs, wshobson-agents, wshobson-commands, awesome)'
          long_desc <<~DESC
            Setup a specific component without interactive prompts.

            Available components:
            • dlabs - dLabs agents (local specialized agents)
            • wshobson-agents - wshobson production-ready agents
            • wshobson-commands - wshobson workflow tools and commands
            • awesome - awesome-claude-code-subagents collection

            This command will create symlinks for the specified component only.
            It assumes repositories are already cloned. Use 'install' for full setup.
          DESC
        end

        def define_remove_command
          desc 'remove [COMPONENT]', 'Remove installed agents'
          long_desc <<~DESC
            Remove installed Claude Code agents. If no component is specified,
            launches an interactive removal tool.

            Available components:
            • dlabs - Remove dLabs agents
            • wshobson-agents - Remove wshobson agents
            • wshobson-commands - Remove wshobson commands
            • awesome - Remove awesome-claude-code-subagents
            • all - Remove everything (use with caution!)

            The removal process:
            • Only removes symlinks (source files are preserved)
            • Cleans up empty directories
            • Provides detailed feedback on what was removed
          DESC
          option :force, type: :boolean, aliases: '-f', desc: 'Skip confirmation prompts'
        end

        def define_status_command
          desc 'status', 'Show installation status of all components'
          long_desc <<~DESC
            Display a comprehensive status report showing:
            • Which components are currently installed
            • Number of agents/commands for each component
            • Installation paths and symlink health

            This is useful for:
            • Checking what's currently installed
            • Debugging installation issues
            • Getting an overview before making changes
          DESC
        end

        def define_version_command
          desc 'version', 'Show version information'
        end
      end

      def doctor
        configure_ui
        CLI::Doctor::Runner.new(ui).call
      rescue StandardError => e
        ErrorHandler.handle_error(e, ui)
      end

      def install
        configure_ui
        installer = Installer.new(ui)
        handle_install_request(installer)
      rescue StandardError => e
        ErrorHandler.handle_error(e, ui)
      end

      def setup(component)
        configure_ui
        validate_component!(component)
        installer = Installer.new(ui)
        result = installer.install_component(component)
        report_setup_result(component, result)
      rescue StandardError => e
        ErrorHandler.handle_error(e, ui)
      end

      def remove(component = nil)
        configure_ui
        remover = Remover.new(ui)
        handle_remove_component(remover, component)
      rescue StandardError => e
        ErrorHandler.handle_error(e, ui)
      end

      def status
        configure_ui
        ui.display_status
      rescue StandardError => e
        ErrorHandler.handle_error(e, ui)
      end

      def version
        puts "Claude Agents CLI v#{ClaudeAgents::VERSION}"
        puts 'A comprehensive management system for Claude Code agent collections'
        puts
        puts 'Components:'
        puts '• dLabs agents - Local specialized agents'
        puts '• wshobson agents - Production-ready development agents'
        puts '• wshobson commands - Multi-agent workflow tools'
        puts '• awesome-claude-code-subagents - Industry-standard agent collection'
        puts
        puts 'GitHub: https://github.com/dallasgoldswain/claude-code-agents-manager'
      end
    end
  end
end