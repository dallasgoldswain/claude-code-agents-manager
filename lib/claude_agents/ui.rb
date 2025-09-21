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

    attr_reader :pastel, :prompt, :verbose_mode

    def initialize(color: true, verbose: false)
      @pastel = Pastel.new(enabled: color)
      @prompt = TTY::Prompt.new
      # Maintain @verbose for tests that manipulate it directly
      @verbose_mode = verbose
      @verbose = verbose
    end

    # Basic output methods expected by tests
    def say(message)
      puts message
    end

    def verbose(message)
      return unless @verbose || @verbose_mode

      output = begin
        val = pastel.dim(message)
        # Mocha stub in tests may return nil – fall back to plain message
        val = message if val.nil? || (val.respond_to?(:empty?) && val.empty?)
        val
      rescue StandardError
        message
      end
      puts output
    end

    def warning(message)
      warn(message)
    end

    # Table rendering method
    # Revised table API expected by tests: table(headers, rows, style:, padding:)
    def table(headers, rows, style: :unicode, padding: [0, 1])
      table = TTY::Table.new(headers, rows)
      rendered = table.render(style, padding: padding)
      puts rendered
    end

    # Spinner method for showing progress
    def with_spinner(message, success: 'done')
      spinner = TTY::Spinner.new("[:spinner] #{message}", format: :dots)
      spinner.auto_spin
      begin
        result = yield
        spinner.success("(#{success})")
        result
      rescue StandardError
        spinner.error('(failed)') if spinner.respond_to?(:error)
        raise
      end
    end

    # Menu selection methods
    def select_components(components = nil)
      if components
        multiselect('Select components to install:', components, per_page: 10)
      else
        component_selection_menu
      end
    end

    def select_action(actions = nil)
      if actions
        # actions is a hash of symbol => description expected by tests
        prompt.select('What would you like to do?', actions, per_page: 10)
      else
        prompt.select('What would you like to do?', {
                        install: 'Install components',
                        remove: 'Remove components',
                        status: 'Show status',
                        exit: 'Exit'
                      }, per_page: 10)
      end
    end

    # Additional UI methods expected by tests
    def newline
      puts
    end

    def section(title)
      puts
      puts pastel.cyan.bold("== #{title} ==")
      puts
    end

    # Revised box API to match test expectations
    # box('Title', 'Content', border: :thick, padding: 1, style: {})
    def box(title, content, border: :thick, padding: 1, style: {})
      args = { title: { top_left: title }, border: border, padding: padding }
      args[:style] = style unless style.nil? || style.empty?
      frame = TTY::Box.frame(content, **args)
      puts frame
    end

    # Alias for multiselect for backward compatibility
    # Interactive prompt wrappers (override module versions to control signatures for tests)
    def confirm(message, default: false)
      if default == false
        prompt.yes?(message)
      else
        prompt.yes?(message, default: default)
      end
    rescue TTY::Reader::InputInterrupt
      raise UserCancelledError, 'User cancelled operation'
    end

    def ask(message, default: nil)
      if default.nil?
        prompt.ask(message)
      else
        prompt.ask(message, default: default)
      end
    rescue TTY::Reader::InputInterrupt
      raise UserCancelledError, 'User cancelled operation'
    end

    def ask_password(message)
      prompt.mask(message)
    rescue TTY::Reader::InputInterrupt
      raise UserCancelledError, 'User cancelled operation'
    end

    def select(message, choices, per_page: nil)
      if per_page
        prompt.select(message, choices, per_page: per_page)
      else
        prompt.select(message, choices)
      end
    rescue TTY::Reader::InputInterrupt
      raise UserCancelledError, 'User cancelled operation'
    end

    def multiselect(message, choices, per_page: nil)
      if per_page
        prompt.multi_select(message, choices, per_page: per_page)
      else
        prompt.multi_select(message, choices)
      end
    rescue TTY::Reader::InputInterrupt
      raise UserCancelledError, 'User cancelled operation'
    end

    def multi_select(message, choices)
      multiselect(message, choices)
    end

    # Formatting helpers expected by tests
    def pluralize(count, singular, plural = nil)
      word = (count == 1 ? singular : (plural || "#{singular}s"))
      "#{count} #{word}"
    end

    # Support legacy positional signature truncate(text, length)
    def truncate(text, length = 30, omission: '...')
      return text if text.nil? || text.length <= length

      slice = text[0, length]
      # Try to avoid cutting mid-word
      if (last_space = slice.rindex(' ')) && last_space > (length * 0.4)
        slice = slice[0, last_space]
      end
      slice + omission
    end

    def format_duration(seconds)
      return '0s' if seconds.nil? || seconds <= 0
      return format('%.1fs', seconds) if seconds < 1
      return format('%.1fs', seconds) if seconds < 10
      return format('%.0fs', seconds) if seconds < 60

      minutes = (seconds / 60).floor
      remaining = seconds % 60
      return format('%dm %ds', minutes, remaining.round) if seconds < 3600

      hours = (seconds / 3600).floor
      remaining_minutes = ((seconds % 3600) / 60).floor
      return format('%dh %dm', hours, remaining_minutes) if seconds < 86_400

      days = (seconds / 86_400).floor
      remaining_hours = ((seconds % 86_400) / 3600).floor
      format('%dd %dh', days, remaining_hours)
    end

    def format_size(bytes)
      return '0 B' if bytes.nil? || bytes.zero?

      units = %w[B KB MB GB TB]
      size = bytes.to_f
      idx = 0
      while size >= 1024 && idx < units.size - 1
        size /= 1024.0
        idx += 1
      end
      if idx.positive?
        # show one decimal place
        format('%<num>.1f %<unit>s', num: size, unit: units[idx])
      else
        format('%<num>.0f %<unit>s', num: size, unit: units[idx])
      end
    end

    # Override status display to meet test expectations
    def display_status
      components = Config::Components.component_status
      if components.empty?
        puts 'No components installed'
        return
      end

      rows = [['Component', 'Status', 'Installed Files'], :separator]
      components.each do |c|
        status = c[:installed] ? 'installed' : 'not installed'
        rows << [c[:name], status, (c[:symlinks] || 0).to_s]
      end
      summary_table(rows)

      return unless @verbose || @verbose_mode

      components.each do |c|
        puts "Last updated: #{c[:last_updated]}" if c[:last_updated]
      end
    end

    # Override format_error to ensure exact output expected by tests
    def format_error(error)
      class_name = error.class.name.split('::').last
      label = if error.class == StandardError
                'Standard Error'
              elsif class_name.end_with?('Error') && class_name != 'Error'
                base = class_name.sub(/Error$/, '')
                "#{base} Error"
              else
                class_name
              end
      line = "#{label}: #{error.message}"
      colored = begin
        val = pastel.red(line)
        val = line if val.nil? || (val.respond_to?(:empty?) && val.empty?)
        val
      rescue StandardError
        line
      end
      puts colored
      return unless (@verbose || @verbose_mode) && error.backtrace

      puts 'Backtrace:'
      error.backtrace.first(5).each { |trace_line| puts trace_line }
    end
  end
end
