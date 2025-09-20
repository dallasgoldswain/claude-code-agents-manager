# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    # Status and version commands for the CLI.
    module StatusCommands
      def self.included(base)
        configure_status_command(base)
        configure_version_command(base)
      end

      def self.configure_status_command(base)
        base.desc 'status', status_description
        base.long_desc(status_long_description)
      end

      def self.status_description
        'Show installation status of all components'
      end

      def self.status_long_description
        <<~DESC
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

      def self.configure_version_command(base)
        base.desc 'version', 'Show version information'
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
