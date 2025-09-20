# frozen_string_literal: true

module ClaudeAgents
  # User interface utilities with colorful output and interactive prompts
  class UI
    attr_reader :pastel, :prompt

    def initialize
      @pastel = Pastel.new
      @prompt = TTY::Prompt.new
    end

    # Color methods
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

    def separator
      puts pastel.dim('─' * 80)
    end

    def newline
      puts
    end

    # Status indicators
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

    # Interactive prompts
    def confirm(message, default: false)
      prompt.yes?(pastel.cyan(message.to_s), default: default)
    rescue TTY::Reader::InputInterrupt
      raise UserCancelledError, 'User cancelled operation'
    end

    def select(message, choices)
      prompt.select(pastel.cyan(message), choices)
    rescue TTY::Reader::InputInterrupt
      raise UserCancelledError, 'User cancelled operation'
    end

    def multiselect(message, choices)
      prompt.multi_select(pastel.cyan(message), choices)
    rescue TTY::Reader::InputInterrupt
      raise UserCancelledError, 'User cancelled operation'
    end

    # Headers and titles
    def title(message)
      box = TTY::Box.frame(
        width: 80,
        height: 5,
        align: :center,
        padding: 1,
        style: {
          fg: :cyan,
          border: {
            fg: :bright_cyan
          }
        }
      ) do
        pastel.bright_cyan.bold(message)
      end
      puts box
    end

    def section(message)
      puts
      puts pastel.bright_blue.bold("▶ #{message}")
      puts pastel.dim('─' * (message.length + 2))
    end

    def subsection(message)
      puts pastel.blue("  ▸ #{message}")
    end

    # Progress indicators
    def spinner(message)
      spinner = TTY::Spinner.new("[:spinner] #{message}", format: :dots)
      yield(spinner) if block_given?
      spinner
    end

    def progress_bar(title, total)
      TTY::ProgressBar.new("#{title} [:bar] :percent", total: total)
    end

    # Summary displays
    def summary_table(data)
      table = TTY::Table.new do |t|
        data.each { |row| t << row }
      end

      puts table.render(:unicode, padding: [0, 1])
    end

    def component_selection_menu
      choices = []

      Config::COMPONENTS.each do |key, info|
        status = component_installed?(key) ? pastel.green('[INSTALLED]') : pastel.dim('[NOT INSTALLED]')
        choice_text = "#{info[:name]} - #{info[:description]} #{status}"
        choices << { name: choice_text, value: key }
      end

      multiselect('Select components to install:', choices)
    end

    def removal_confirmation_menu
      installed_components = Config.all_components.select { |component| component_installed?(component) }

      return [] if installed_components.empty?

      choices = installed_components.map do |component|
        info = Config.component_info(component)
        { name: "#{info[:name]} - #{info[:description]}", value: component }
      end

      multiselect('Select components to remove:', choices)
    end

    # Status checking
    def component_installed?(component)
      case component
      when :dlabs
        Dir.glob(File.join(Config.agents_dir, 'dLabs-*')).any?
      when :wshobson_agents
        Dir.glob(File.join(Config.agents_dir, 'wshobson-*')).any?
      when :wshobson_commands
        Dir.exist?(Config.tools_dir) || Dir.exist?(Config.workflows_dir)
      when :awesome
        # Check for category-prefixed files (not dLabs- or wshobson-)
        Dir.glob(File.join(Config.agents_dir, '*-*'))
           .reject { |path| File.basename(path).start_with?('dLabs-', 'wshobson-') }
           .any?
      else
        false
      end
    end

    def display_installation_summary(results)
      newline
      section('Installation Summary')

      summary_data = [
        ['Component', 'Status', 'Files Processed', 'Links Created', 'Skipped'],
        :separator
      ]

      results.each do |component, result|
        info = Config.component_info(component)
        status = result[:success] ? pastel.green('✅ Success') : pastel.red('❌ Failed')

        summary_data << [
          info[:name],
          status,
          result[:total_files].to_s,
          result[:created_links].to_s,
          result[:skipped_files].to_s
        ]
      end

      summary_table(summary_data)
    end

    def display_removal_summary(results)
      newline
      section('Removal Summary')

      summary_data = [
        ['Component', 'Status', 'Files Removed', 'Errors'],
        :separator
      ]

      results.each do |component, result|
        info = Config.component_info(component)
        status = result[:success] ? pastel.green('✅ Success') : pastel.red('❌ Failed')

        summary_data << [
          info[:name],
          status,
          result[:removed_count].to_s,
          result[:error_count].to_s
        ]
      end

      summary_table(summary_data)
    end

    def display_status
      title('Claude Agents Status')

      status_data = [
        ['Component', 'Status', 'Installed Files'],
        :separator
      ]

      Config.all_components.each do |component|
        info = Config.component_info(component)
        installed = component_installed?(component)
        status = installed ? pastel.green('✅ Installed') : pastel.dim('⭕ Not Installed')

        file_count = if installed
                       case component
                       when :dlabs
                         Dir.glob(File.join(Config.agents_dir, 'dLabs-*')).length
                       when :wshobson_agents
                         Dir.glob(File.join(Config.agents_dir, 'wshobson-*')).length
                       when :wshobson_commands
                         Dir.glob(File.join(Config.commands_dir, '**/*')).length
                       when :awesome
                         Dir.glob(File.join(Config.agents_dir, '*-*'))
                            .reject { |path| File.basename(path).start_with?('dLabs-', 'wshobson-') }
                            .length
                       else
                         0
                       end
                     else
                       0
                     end

        status_data << [info[:name], status, file_count.to_s]
      end

      summary_table(status_data)
    end
  end
end
