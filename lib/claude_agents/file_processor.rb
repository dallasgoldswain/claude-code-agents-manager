# frozen_string_literal: true

module ClaudeAgents
  # File processing utilities for filtering, validation, and path management
  class FileProcessor
    include Filtering
    include PrefixedMappings
    include WshobsonMappings
    include AwesomeMappings
    include ComponentMappings
    include Validation
    include MappingHelpers

    attr_reader :ui

    def initialize(user_interface)
      @ui = user_interface
    end
  end
end
