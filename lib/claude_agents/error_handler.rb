# frozen_string_literal: true

module ClaudeAgents
  # Error handling utility methods shared across the CLI
  module ErrorHandler
    module_function

    def handle_error(error, user_interface)
      handler_for(error).call(error, user_interface)
    end

    HANDLER_MAP = {
      UserCancelledError => :handle_user_cancelled,
      ValidationError => :handle_validation_failure,
      InstallationError => :handle_process_failure,
      RemovalError => :handle_process_failure,
      FileOperationError => :handle_process_failure,
      SymlinkError => :handle_process_failure,
      RepositoryError => :handle_repository_failure
    }.freeze

    def handler_for(error)
      handler_name = HANDLER_MAP.find { |klass, _| error.is_a?(klass) }&.last
      method(handler_name || :handle_unexpected_error)
    end

    def handle_user_cancelled(_error, user_interface)
      user_interface.info 'Operation cancelled by user.'
      exit 0
    end

    def handle_validation_failure(error, user_interface)
      user_interface.error "Validation failed: #{error.message}"
      user_interface.error "Details: #{error.details}" if error.respond_to?(:details) && error.details
      exit 1
    end

    def handle_process_failure(error, user_interface)
      user_interface.error "#{error.class.name.split('::').last}: #{error.message}"
      user_interface.error "Code: #{error.code}" if error.respond_to?(:code) && error.code
      user_interface.error "Details: #{error.details}" if error.respond_to?(:details) && error.details
      exit 1
    end

    def handle_repository_failure(error, user_interface)
      user_interface.error "Repository error: #{error.message}"
      user_interface.warn 'Please check your internet connection and GitHub CLI installation.'
      exit 1
    end

    def handle_unexpected_error(error, user_interface)
      user_interface.error "Unexpected error: #{error.message}"
      user_interface.error "Backtrace: #{Array(error.backtrace).first(5).join("\n")}"
      exit 1
    end
  end
end
