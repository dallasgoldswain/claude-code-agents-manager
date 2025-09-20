# frozen_string_literal: true

module ClaudeAgents
  # Main CLI interface using Thor for command management
  class CLI < Thor
    include Thor::Actions
    include InstallCommands
    include SetupCommands
    include RemoveCommands
    include StatusCommands
    include DoctorCommands
    include Helpers

    class_option :verbose, type: :boolean, aliases: '-v', desc: 'Enable verbose output'
    class_option :no_color, type: :boolean, desc: 'Disable colored output'

    attr_reader :ui

    def initialize(*args)
      super
      @ui = UI.new
    rescue StandardError => e
      puts "Initialization error: #{e.message}"
      exit 1
    end

    def self.exit_on_failure?
      true
    end

    # Command definitions with minimal implementations
    desc 'doctor', 'Check system health and dependencies'
    def doctor
      configure_ui
      CLI::Doctor::Runner.new(ui).call
    rescue StandardError => e
      ErrorHandler.handle_error(e, ui)
    end

    desc 'status', 'Show installation status of all components'
    def status
      configure_ui
      ui.display_status
    rescue StandardError => e
      ErrorHandler.handle_error(e, ui)
    end

    desc 'version', 'Show version information'
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

    desc 'install', 'Interactive installation of Claude Code agents'
    option :component, type: :string, aliases: '-c'
    option :yes, type: :boolean, aliases: '-y'
    option :force, type: :boolean, aliases: '-f'
    def install
      configure_ui
      installer = Installer.new(ui)
      handle_install_request(installer)
    rescue StandardError => e
      ErrorHandler.handle_error(e, ui)
    end

    desc 'setup COMPONENT', 'Setup specific component'
    def setup(component)
      configure_ui
      validate_component!(component)
      installer = Installer.new(ui)
      result = installer.install_component(component)
      report_setup_result(component, result)
    rescue StandardError => e
      ErrorHandler.handle_error(e, ui)
    end

    desc 'remove [COMPONENT]', 'Remove installed agents'
    option :force, type: :boolean, aliases: '-f'
    def remove(component = nil)
      configure_ui
      remover = Remover.new(ui)
      handle_remove_component(remover, component)
    rescue StandardError => e
      ErrorHandler.handle_error(e, ui)
    end
  end
end
