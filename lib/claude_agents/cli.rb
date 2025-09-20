# frozen_string_literal: true

module ClaudeAgents
  # Main CLI interface using Thor for command management
  class CLI < Thor
    include Thor::Actions
    include InstallCommands
    include SetupCommands
    include RemoveCommands
    include StatusCommands
    include DoctorCommands

    class_option :verbose, type: :boolean, aliases: '-v', desc: 'Enable verbose output'
    class_option :no_color, type: :boolean, desc: 'Disable colored output'

    attr_reader :ui

    def initialize(*args)
      super
      @ui = UI.new
    rescue StandardError => e
      puts "Initialization error: #{e.message}"
      exit 1
    end

    private

    def configure_ui
      return unless options[:no_color]

      ui.pastel.enabled = false
    end

    def validate_component!(component)
      return if Config.valid_component?(component)

      available = Config.all_components.join(', ')
      raise ValidationError, "Invalid component: #{component}. Available: #{available}"
    end
  end
end
