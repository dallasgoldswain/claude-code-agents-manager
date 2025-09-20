# frozen_string_literal: true

module ClaudeAgents
  module UIComponents
    # Animated spinner and progress-bar affordances for long-running tasks.
    module Progress
      def spinner(message)
        spinner = TTY::Spinner.new("[:spinner] #{message}", format: :dots)
        yield(spinner) if block_given?
        spinner
      end

      def progress_bar(title, total)
        TTY::ProgressBar.new("#{title} [:bar] :percent", total: total)
      end
    end
  end
end
