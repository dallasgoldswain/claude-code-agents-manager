# frozen_string_literal: true

module ClaudeAgents
  # Error handling utility methods shared across the CLI
  module ErrorHandler
    module_function

    def handle_error(error, ui)
      case error
      when UserCancelledError
        ui.info 'Operation cancelled by user.'
        exit 0
      when ValidationError
        ui.error "Validation failed: #{error.message}"
        ui.error "Details: #{error.details}" if error.details
        exit 1
      when InstallationError, RemovalError, FileOperationError, SymlinkError
        ui.error "#{error.class.name.split('::').last}: #{error.message}"
        ui.error "Code: #{error.code}" if error.code
        ui.error "Details: #{error.details}" if error.details
        exit 1
      when RepositoryError
        ui.error "Repository error: #{error.message}"
        ui.warn 'Please check your internet connection and GitHub CLI installation.'
        exit 1
      else
        ui.error "Unexpected error: #{error.message}"
        ui.error "Backtrace: #{error.backtrace.first(5).join("\n")}"
        exit 1
      end
    end
  end
end
