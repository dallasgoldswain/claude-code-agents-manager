# frozen_string_literal: true

module ClaudeAgents
  # Main CLI interface using Thor for command management
  class CLI < Thor
    include Thor::Actions

    def initialize(*args)
      super
      @ui = UI.new
    rescue StandardError => e
      puts "Initialization error: #{e.message}"
      exit 1
    end

    # Class-level configuration
    class_option :verbose, type: :boolean, aliases: '-v', desc: 'Enable verbose output'
    class_option :no_color, type: :boolean, desc: 'Disable colored output'

    desc 'install', 'Interactive installation of Claude Code agents'
    long_desc <<~DESC
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
    option :component, type: :string, aliases: '-c',
           desc: 'Install specific component (dlabs, wshobson-agents, wshobson-commands, awesome)'
    option :yes, type: :boolean, aliases: '-y', desc: 'Skip interactive prompts and install all'

    def install
      configure_ui
      installer = Installer.new(@ui)

      if options[:component]
        validate_component!(options[:component])
        installer.install_component(options[:component])
      elsif options[:yes]
        installer.install_components(Config.all_components)
      else
        installer.interactive_install
      end
    rescue StandardError => e
      ErrorHandler.handle_error(e, @ui)
    end

    desc 'setup COMPONENT', 'Setup specific component (dlabs, wshobson-agents, wshobson-commands, awesome)'
    long_desc <<~DESC
      Setup a specific component without interactive prompts.

      Available components:
      • dlabs - dLabs agents (local specialized agents)
      • wshobson-agents - wshobson production-ready agents
      • wshobson-commands - wshobson workflow tools and commands
      • awesome - awesome-claude-code-subagents collection

      This command will create symlinks for the specified component only.
      Use 'install' for full interactive setup including repository management.
    DESC

    def setup(component)
      configure_ui
      validate_component!(component)

      installer = Installer.new(@ui)
      result = installer.install_component(component)

      @ui.newline
      if result[:created_links] > 0
        @ui.success("Successfully installed #{result[:created_links]} #{component} agents")
      else
        @ui.warn("No new #{component} agents were installed")
      end
    rescue StandardError => e
      ErrorHandler.handle_error(e, @ui)
    end

    desc 'remove [COMPONENT]', 'Remove installed agents'
    long_desc <<~DESC
      Remove installed Claude Code agents. If no component is specified,
      launches an interactive removal tool.

      Available components:
      • dlabs - Remove dLabs agents
      • wshobson-agents - Remove wshobson agents
      • wshobson-commands - Remove wshobson commands
      • awesome - Remove awesome-claude-code-subagents
      • all - Remove everything (use with caution!)

      The removal process:
      • Only removes symlinks (source files are preserved)
      • Cleans up empty directories
      • Provides detailed feedback on what was removed
    DESC
    option :force, type: :boolean, aliases: '-f', desc: 'Skip confirmation prompts'

    def remove(component = nil)
      configure_ui
      remover = Remover.new(@ui)

      if component.nil?
        remover.interactive_remove
      elsif component == 'all'
        remover.remove_all
      else
        validate_component!(component)
        result = remover.remove_component(component)

        @ui.newline
        if result[:removed_count] > 0
          @ui.success("Successfully removed #{result[:removed_count]} #{component} agents")
        else
          @ui.info("No #{component} agents were found to remove")
        end
      end
    rescue StandardError => e
      ErrorHandler.handle_error(e, @ui)
    end

    desc 'status', 'Show installation status of all components'
    long_desc <<~DESC
      Display a comprehensive status report showing:
      • Which components are currently installed
      • Number of agents/commands for each component
      • Installation paths and symlink health

      This is useful for:
      • Checking what's currently installed
      • Debugging installation issues
      • Getting an overview before making changes
    DESC

    def status
      configure_ui
      @ui.display_status
    rescue StandardError => e
      ErrorHandler.handle_error(e, @ui)
    end

    desc 'version', 'Show version information'
    def version
      puts "Claude Agents CLI v#{ClaudeAgents::VERSION}"
      puts 'A comprehensive management system for Claude Code agent collections'
      puts
      puts 'Components:'
      puts '• dLabs agents - Local specialized agents'
      puts '• wshobson agents - Production-ready development agents'
      puts '• wshobson commands - Multi-agent workflow tools'
      puts '• awesome-claude-code-subagents - Industry-standard agent collection'
      puts
      puts 'GitHub: https://github.com/dallasgoldswain/claude-code-agents-manager'
    end

    desc 'doctor', 'Check system health and dependencies'
    long_desc <<~DESC
      Run system diagnostics to check:
      • GitHub CLI availability and authentication
      • Directory permissions
      • Symlink integrity
      • Repository status

      Use this command to troubleshoot installation issues.
    DESC

    def doctor
      configure_ui
      @ui.title('Claude Agents System Doctor')

      checks = [
        -> { check_github_cli },
        -> { check_directories },
        -> { check_symlinks },
        -> { check_repositories }
      ]

      all_passed = true

      checks.each do |check|
        begin
          check.call
        rescue StandardError => e
          @ui.error("Check failed: #{e.message}")
          all_passed = false
        end
      end

      @ui.newline
      if all_passed
        @ui.success('All system checks passed! 🎉')
      else
        @ui.error('Some system checks failed. Please review the output above.')
        exit 1
      end
    rescue StandardError => e
      ErrorHandler.handle_error(e, @ui)
    end

    private

    def configure_ui
      # Configure UI based on options
      if options[:no_color]
        @ui.pastel.enabled = false
      end
    end

    def validate_component!(component)
      unless Config.valid_component?(component)
        available = Config.all_components.join(', ')
        raise ValidationError, "Invalid component: #{component}. Available: #{available}"
      end
    end

    # System health checks
    def check_github_cli
      @ui.subsection('Checking GitHub CLI')

      if system('which gh > /dev/null 2>&1')
        @ui.success('GitHub CLI is installed')

        if system('gh auth status > /dev/null 2>&1')
          @ui.success('GitHub CLI is authenticated')
        else
          @ui.warn('GitHub CLI is not authenticated. Run "gh auth login" to authenticate.')
        end
      else
        @ui.error('GitHub CLI is not installed. Please install it from https://cli.github.com/')
        raise ValidationError, 'GitHub CLI is required for repository management'
      end
    end

    def check_directories
      @ui.subsection('Checking directories')

      directories = [
        Config.claude_dir,
        Config.agents_dir,
        Config.commands_dir
      ]

      directories.each do |dir|
        if Dir.exist?(dir)
          if File.writable?(dir)
            @ui.success("#{dir} exists and is writable")
          else
            @ui.error("#{dir} exists but is not writable")
            raise ValidationError, "Directory permission error: #{dir}"
          end
        else
          @ui.info("#{dir} does not exist (will be created when needed)")
        end
      end
    end

    def check_symlinks
      @ui.subsection('Checking symlinks')

      broken_symlinks = []

      [Config.agents_dir, Config.commands_dir].each do |dir|
        next unless Dir.exist?(dir)

        Dir.glob(File.join(dir, '**/*')).each do |path|
          if File.symlink?(path) && !File.exist?(path)
            broken_symlinks << path
          end
        end
      end

      if broken_symlinks.empty?
        @ui.success('All symlinks are healthy')
      else
        @ui.warn("Found #{broken_symlinks.length} broken symlinks:")
        broken_symlinks.each { |link| @ui.dim("  • #{link}") }
      end
    end

    def check_repositories
      @ui.subsection('Checking repositories')

      Config::REPOSITORIES.each do |key, repo_info|
        repo_path = File.join(Config.project_root, repo_info[:dir])

        if Dir.exist?(repo_path)
          if Dir.exist?(File.join(repo_path, '.git'))
            @ui.success("#{repo_info[:dir]} repository is available")
          else
            @ui.warn("#{repo_info[:dir]} directory exists but is not a git repository")
          end
        else
          @ui.info("#{repo_info[:dir]} repository not cloned")
        end
      end

      # Check dLabs directory
      dlabs_path = File.join(Config.project_root, 'agents', 'dallasLabs')
      if Dir.exist?(dlabs_path)
        @ui.success('dallasLabs directory is available')
      else
        @ui.error('dallasLabs directory not found')
      end
    end
  end
end
