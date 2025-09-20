# frozen_string_literal: true

module ClaudeAgents
  # User interface utilities with colorful output and interactive prompts
  class UI
    include UIComponents::Messages
    include UIComponents::Layout
    include UIComponents::Progress
    include UIComponents::Status
    include UIComponents::Summaries
    include UIComponents::Interactions

    attr_reader :pastel, :prompt

    def initialize
      @pastel = Pastel.new
      @prompt = TTY::Prompt.new
    end
  end
end
