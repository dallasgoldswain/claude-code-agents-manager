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
end
