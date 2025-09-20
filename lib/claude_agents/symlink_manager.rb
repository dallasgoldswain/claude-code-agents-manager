# frozen_string_literal: true

module ClaudeAgents
  # Symlink management with safety checks and detailed reporting
  class SymlinkManager
    include Validation
    include Creation
    include Removal
    include Cleanup

    attr_reader :ui

    def initialize(user_interface)
      @ui = user_interface
    end
  end
end
