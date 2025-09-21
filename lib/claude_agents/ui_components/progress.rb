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

      def with_progress(title, **options)
        default_options = { width: 30 }
        merged_options = default_options.merge(options)

        format = "#{title} [:bar] :percent"
        format += ' :current/:total' if merged_options[:total]

        bar = TTY::ProgressBar.new(format, **merged_options)
        result = yield(bar) if block_given?
        bar.finish
        result
      end
    end
  end
end
