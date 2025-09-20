# frozen_string_literal: true

module ClaudeAgents
  # Removal service for safe cleanup of symlinks and installations
  class Remover
    include Components
    include Batch
    include Interactive
    include Utilities

    attr_reader :ui, :symlink_manager

    def initialize(user_interface)
      @ui = user_interface
      @symlink_manager = SymlinkManager.new(user_interface)
    end
  end
end
