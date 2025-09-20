# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    # CLI commands for running system diagnostics.
    module DoctorCommands
      def self.included(base)
        configure_doctor_command(base)
      end

      def self.configure_doctor_command(base)
        base.desc 'doctor', doctor_description
        base.long_desc(doctor_long_description)
      end

      def self.doctor_description
        'Check system health and dependencies'
      end

      def self.doctor_long_description
        <<~DESC
          Run system diagnostics to check:
          • GitHub CLI availability and authentication
          • Directory permissions
          • Symlink integrity
          • Repository status

          Use this command to troubleshoot installation issues.
        DESC
      end

      def doctor
        configure_ui
        CLI::Doctor::Runner.new(ui).call
      rescue StandardError => e
        ErrorHandler.handle_error(e, ui)
      end
    end
  end
end
