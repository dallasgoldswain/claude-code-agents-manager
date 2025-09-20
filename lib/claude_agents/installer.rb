# frozen_string_literal: true

module ClaudeAgents
  # Installation service with repository management and interactive setup
  class Installer
    include Components
    include Interactive
    include Repositories

    attr_reader :ui, :file_processor, :symlink_manager

    def initialize(user_interface)
      @ui = user_interface
      @file_processor = FileProcessor.new(user_interface)
      @symlink_manager = SymlinkManager.new(user_interface)
    end
  end
end
