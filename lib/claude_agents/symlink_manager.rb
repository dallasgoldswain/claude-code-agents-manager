# frozen_string_literal: true

module ClaudeAgents
  # Symlink management with safety checks and detailed reporting
  class SymlinkManager
    include Validation
    include Creation
    include Removal
    include Cleanup

    attr_reader :ui, :config

    # Flexible initialization:
    #  - initialize(ui)
    #  - initialize(ui, config_hash)
    #  - initialize(config_hash, ui: ui)
    #  - initialize(config_hash)  (ui can be injected later for limited operations)
    def initialize(first = nil, second = nil, ui: nil)
      if first.is_a?(Hash) && second.nil? && ui.nil?
        @config = first
      elsif first && second.nil? && !first.is_a?(Hash)
        # Single non-hash argument treated as UI
        @ui = first
      else
        # Two positional or hash + keyword ui
        @ui = first unless first.is_a?(Hash)
        @config = first if first.is_a?(Hash)
        @ui = second if second
      end
      @ui = ui if ui # explicit keyword arg wins

      @temporary_dry_run = false
    end

    def dry_run?
      !!(@temporary_dry_run || (@config && @config[:dry_run]))
    end

    # Internal helper to temporarily enable dry run mode for a block
    def with_dry_run(flag)
      previous = @temporary_dry_run
      @temporary_dry_run = flag
      yield
    ensure
      @temporary_dry_run = previous
    end
  end
end
