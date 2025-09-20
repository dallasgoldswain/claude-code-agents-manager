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

    desc 'doctor', 'Check system health and dependencies'
    long_desc <<~DESC
      Run system diagnostics to check:
      • GitHub CLI availability and authentication
      • Directory permissions
      • Symlink integrity
      • Repository status

      Use this command to troubleshoot installation issues.
    DESC
    def doctor
      configure_ui
      CLI::Doctor::Runner.new(ui).call
    rescue StandardError => e
      ErrorHandler.handle_error(e, ui)
    end

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

    private

    def configure_ui
      return unless options[:no_color]

      ui.pastel.enabled = false
    end

    def validate_component!(component)
      return if Config.valid_component?(component)

      available = Config.all_components.join(', ')
      raise ValidationError, "Invalid component: #{component}. Available: #{available}"
    end
  end
end
