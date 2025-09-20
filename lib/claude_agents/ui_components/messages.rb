# frozen_string_literal: true

module ClaudeAgents
  module UIComponents
    # Terminal helpers for presenting status and notification messages with color.
    module Messages
      def success(message)
        puts pastel.green("✅ #{message}")
      end

      def error(message)
        puts pastel.red("❌ #{message}")
      end

      def warn(message)
        puts pastel.yellow("⚠️  #{message}")
      end

      def info(message)
        puts pastel.blue("ℹ️  #{message}")
      end

      def highlight(message)
        puts pastel.cyan("🔸 #{message}")
      end

      def dim(message)
        puts pastel.dim(message)
      end

      def linked(message)
        puts pastel.green('  LINKED: ') + message
      end

      def skipped(message)
        puts pastel.yellow('  SKIPPED: ') + message
      end

      def removed(message)
        puts pastel.red('  REMOVED: ') + message
      end

      def processing(message)
        puts pastel.blue('  PROCESSING: ') + message
      end
    end
  end
end
