# frozen_string_literal: true

module ClaudeAgents
  # Base error class providing optional metadata for richer feedback
  class Error < StandardError
    attr_reader :code, :details

    def initialize(message, code: nil, details: nil)
      super(message)
      @code = code
      @details = details
    end
  end

  # Specific error classes used by tests and components
  class ValidationError < Error; end
  class InstallationError < Error; end
  class SymlinkError < Error; end
  class UserCancelledError < Error; end
  class InvalidComponentError < Error; end
  class PermissionError < Error; end
  class DirectoryNotFoundError < Error; end
  class ConfigurationError < Error; end
  class DependencyError < Error; end
  class FileProcessingError < Error; end
  class AggregateError < StandardError
    attr_reader :errors

    def initialize(message = 'Multiple errors occurred', errors: [])
      @errors = errors
      super(message)
    end
  end

  class ContextualError < Error
    attr_reader :context, :original_error

    def initialize(message, context: nil, original_error: nil, **additional_context)
      # Merge additional context keywords into main context
      full_context = if context.is_a?(Hash)
                       context.merge(additional_context)
                     else
                       additional_context.empty? ? context : additional_context
                     end
      super(message)
      @context = full_context
      @original_error = original_error
    end

    # Provide Ruby exception chaining compatibility expected by tests
    def cause
      @original_error
    end
  end
end
