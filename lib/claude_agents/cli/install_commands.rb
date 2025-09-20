# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    # CLI commands responsible for interactive and scripted installations.
    module InstallCommands
      def self.included(base)
        configure_install_command(base)
        configure_install_options(base)
      end

      def self.configure_install_command(base)
        base.desc 'install', install_description
        base.long_desc(install_long_description)
      end

      def self.install_description
        'Interactive installation of Claude Code agents'
      end

      def self.install_long_description
        <<~DESC
          Launch an interactive installer that allows you to select which agent collections
          to install. The installer will:

          • Show you what's currently installed
          • Let you choose which components to install
          • Handle repository cloning and updates automatically
          • Create organized symlinks in ~/.claude/

          Components available:
          • dLabs agents - Local specialized agents (5 agents)
          • wshobson agents - Production-ready agents (82 agents)
          • wshobson commands - Workflow tools (56 commands)
          • awesome-claude-code-subagents - Industry-standard agents (116 agents)
        DESC
      end

      def self.configure_install_options(base)
        base.option :component, type: :string, aliases: '-c',
                                desc: 'Install specific component (dlabs, wshobson-agents, wshobson-commands, awesome)'
        base.option :yes, type: :boolean, aliases: '-y', desc: 'Skip interactive prompts and install all'
      end

      def install
        configure_ui
        installer = Installer.new(ui)
        execute_install(installer)
      rescue StandardError => e
        ErrorHandler.handle_error(e, ui)
      end

      private

      def execute_install(installer)
        if options[:component]
          validate_component!(options[:component])
          installer.install_component(options[:component])
        elsif options[:yes]
          installer.install_components(Config.all_components)
        else
          installer.interactive_install
        end
      end
    end
  end
end
