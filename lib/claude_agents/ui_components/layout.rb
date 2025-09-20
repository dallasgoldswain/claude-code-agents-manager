# frozen_string_literal: true

module ClaudeAgents
  module UIComponents
    # Layout helpers for drawing framed titles, sections, and tables.
    module Layout
      TITLE_FRAME_OPTIONS = {
        width: 80,
        height: 5,
        align: :center,
        padding: 1,
        style: {
          fg: :cyan,
          border: { fg: :bright_cyan }
        }
      }.freeze

      def separator
        puts pastel.dim('─' * 80)
      end

      def newline
        puts
      end

      def title(message)
        puts TTY::Box.frame(**TITLE_FRAME_OPTIONS) { pastel.bright_cyan.bold(message) }
      end

      def section(message)
        newline
        puts pastel.bright_blue.bold("▶ #{message}")
        puts pastel.dim('─' * (message.length + 2))
      end

      def subsection(message)
        puts pastel.blue("  ▸ #{message}")
      end

      def summary_table(data)
        table = TTY::Table.new { |t| data.each { |row| t << row } }
        puts table.render(:unicode, padding: [0, 1])
      end
    end
  end
end
