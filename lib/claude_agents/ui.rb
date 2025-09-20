# frozen_string_literal: true

module ClaudeAgents
  # User interface utilities with colorful output and interactive prompts
  class UI
    include ClaudeAgents::UIComponents::Messages
    include ClaudeAgents::UIComponents::Layout
    include ClaudeAgents::UIComponents::Progress
    include ClaudeAgents::UIComponents::Status
    include ClaudeAgents::UIComponents::Summaries
    include ClaudeAgents::UIComponents::Interactions

    attr_reader :pastel, :prompt

    def initialize
      @pastel = Pastel.new
      @prompt = TTY::Prompt.new
    end
  end
end
