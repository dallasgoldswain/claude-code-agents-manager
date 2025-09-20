# frozen_string_literal: true

require 'test_helper'

class InstallerTest < ClaudeAgentsTest
  def setup
    super
    @ui = create_mock_ui
    @symlink_manager = mock('SymlinkManager')
    ClaudeAgents::SymlinkManager.stubs(:new).returns(@symlink_manager)
    @installer = ClaudeAgents::Installer.new(@ui)
  end

  def teardown
    super
    Mocha::Mock.reset_all
  end

  # Test initialization
  class InitializationTest < InstallerTest
    def test_initializes_with_ui
      assert_instance_of ClaudeAgents::Installer, @installer
      assert_respond_to @installer, :install
      assert_respond_to @installer, :install_all
    end

    def test_initializes_repositories_hash
      # Access private instance variable for testing
      repos = @installer.instance_variable_get(:@repositories)
      assert_instance_of Hash, repos
    end
  end

  # Test repository cloning
  class RepositoryCloneTest < InstallerTest
    def test_clones_repository_successfully
      with_temp_dir do |dir|
        repo_path = File.join(dir, 'test-repo')
        stub_system_command("git clone https://github.com/test/repo.git #{repo_path}", success: true)

        @ui.expects(:with_spinner).yields.returns(true)
        @installer.send(:clone_repository, 'https://github.com/test/repo.git', repo_path)

        # Note: actual cloning is stubbed, so directory won't exist
      end
    end

    def test_skips_cloning_if_repository_exists
      with_temp_dir do |dir|
        repo_path = File.join(dir, 'test-repo')
        FileUtils.mkdir_p(repo_path)
        FileUtils.mkdir_p(File.join(repo_path, '.git'))

        @ui.expects(:info).with(includes('already exists'))
        @installer.send(:clone_repository, 'https://github.com/test/repo.git', repo_path)
      end
    end

    def test_handles_clone_failure
      with_temp_dir do |dir|
        repo_path = File.join(dir, 'test-repo')
        stub_system_command("git clone https://github.com/test/repo.git #{repo_path}", success: false)

        @ui.expects(:with_spinner).yields.returns(false)
        @ui.expects(:error).with(includes('Failed to clone'))

        assert_raises(ClaudeAgents::InstallationError) do
          @installer.send(:clone_repository, 'https://github.com/test/repo.git', repo_path)
        end
      end
    end

    def test_updates_existing_repository
      with_temp_dir do |dir|
        repo_path = File.join(dir, 'test-repo')
        FileUtils.mkdir_p(File.join(repo_path, '.git'))

        Dir.expects(:chdir).with(repo_path).yields
        stub_system_command('git pull', success: true)

        @ui.expects(:with_spinner).yields.returns(true)
        @installer.send(:update_repository, repo_path)
      end
    end
  end

  # Test component installation
  class ComponentInstallationTest < InstallerTest
    def test_installs_dlabs_component
      with_mock_home do |home|
        dlabs_path = File.join(Dir.pwd, 'agents', 'dallasLabs')
        FileUtils.mkdir_p(dlabs_path)

        # Create sample agent files
        File.write(File.join(dlabs_path, 'test-agent.md'), '# Test Agent')

        @symlink_manager.expects(:create_symlinks).with('dlabs').once
        @ui.expects(:success).with(includes('dlabs installed'))

        @installer.install('dlabs')
      end
    end

    def test_installs_wshobson_agents
      repo_url = ClaudeAgents::Config::Repositories::WSHOBSON_AGENTS['url']
      local_path = ClaudeAgents::Config::Repositories::WSHOBSON_AGENTS['local_path']

      @installer.expects(:clone_repository).with(repo_url, local_path).once
      @symlink_manager.expects(:create_symlinks).with('wshobson-agents').once
      @ui.expects(:success).once

      @installer.install('wshobson-agents')
    end

    def test_installs_awesome_agents
      repo_url = ClaudeAgents::Config::Repositories::AWESOME_AGENTS['url']
      local_path = ClaudeAgents::Config::Repositories::AWESOME_AGENTS['local_path']

      @installer.expects(:clone_repository).with(repo_url, local_path).once
      @symlink_manager.expects(:create_symlinks).with('awesome').once
      @ui.expects(:success).once

      @installer.install('awesome')
    end

    def test_validates_component_name
      @ui.expects(:error).with(includes('Unknown component'))

      assert_raises(ClaudeAgents::InvalidComponentError) do
        @installer.install('invalid_component')
      end
    end
  end

  # Test install_all functionality
  class InstallAllTest < InstallerTest
    def test_installs_all_components_in_sequence
      ClaudeAgents::Config::Components::ALL.each do |component|
        @installer.expects(:install).with(component[:name]).once
      end

      @installer.install_all
    end

    def test_continues_on_individual_component_failure
      # First component succeeds, second fails, third succeeds
      @installer.expects(:install).with('dlabs').once
      @installer.expects(:install).with('wshobson-agents').raises(StandardError, 'Install failed')
      @installer.expects(:install).with('wshobson-commands').once
      @installer.expects(:install).with('awesome').once

      @ui.expects(:error).once  # For the failed component
      @ui.expects(:success).once  # For overall completion

      @installer.install_all
    end

    def test_reports_summary_after_install_all
      ClaudeAgents::Config::Components::ALL.each do |component|
        @installer.stubs(:install).with(component[:name])
      end

      @ui.expects(:success).with(includes('Installation complete')).once

      @installer.install_all
    end
  end

  # Test dependency checking
  class DependencyCheckTest < InstallerTest
    def test_checks_git_availability
      Open3.expects(:capture3).with('git --version').returns(['git version 2.0.0', '', 0])

      result = @installer.send(:check_git_available)
      assert result
    end

    def test_raises_error_if_git_not_available
      Open3.expects(:capture3).with('git --version').returns(['', 'command not found', 127])

      @ui.expects(:error).with(includes('Git is not installed'))

      assert_raises(ClaudeAgents::DependencyError) do
        @installer.send(:check_git_available)
      end
    end

    def test_checks_github_cli_availability
      Open3.expects(:capture3).with('gh --version').returns(['gh version 2.0.0', '', 0])

      result = @installer.send(:check_gh_available)
      assert result
    end

    def test_continues_without_gh_cli
      Open3.expects(:capture3).with('gh --version').returns(['', 'command not found', 127])

      @ui.expects(:warning).with(includes('GitHub CLI not found'))

      result = @installer.send(:check_gh_available)
      assert_nil result
    end
  end

  # Test directory creation
  class DirectoryCreationTest < InstallerTest
    def test_creates_required_directories
      with_mock_home do |home|
        @installer.send(:ensure_directories_exist)

        assert Dir.exist?(File.join(home, '.claude', 'agents'))
        assert Dir.exist?(File.join(home, '.claude', 'commands', 'tools'))
        assert Dir.exist?(File.join(home, '.claude', 'commands', 'workflows'))
      end
    end

    def test_handles_permission_errors_during_directory_creation
      with_mock_home do |home|
        claude_dir = File.join(home, '.claude')
        FileUtils.mkdir_p(claude_dir)
        FileUtils.chmod(0o444, claude_dir)  # Read-only

        @ui.expects(:error).with(includes('Permission denied'))

        assert_raises(ClaudeAgents::PermissionError) do
          @installer.send(:ensure_directories_exist)
        end
      ensure
        FileUtils.chmod(0o755, claude_dir) if Dir.exist?(claude_dir)
      end
    end
  end

  # Test progress tracking
  class ProgressTrackingTest < InstallerTest
    def test_shows_progress_during_batch_installation
      progress_bar = mock_progress_bar

      @ui.expects(:with_progress).yields(progress_bar).returns(true)
      progress_bar.expects(:advance).at_least_once

      ClaudeAgents::Config::Components::ALL.each do |component|
        @installer.stubs(:install).with(component[:name])
      end

      @installer.install_all
    end

    def test_updates_progress_message_for_each_component
      progress_bar = mock_progress_bar

      @ui.stubs(:with_progress).yields(progress_bar).returns(true)
      progress_bar.expects(:update).with(title: includes('dlabs')).once
      progress_bar.expects(:update).with(title: includes('wshobson')).at_least_once

      ClaudeAgents::Config::Components::ALL.each do |component|
        @installer.stubs(:install).with(component[:name])
      end

      @installer.install_all
    end
  end

  # Test rollback functionality
  class RollbackTest < InstallerTest
    def test_rolls_back_on_critical_failure
      with_mock_home do |home|
        # Simulate partial installation
        agents_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(agents_dir)
        test_link = File.join(agents_dir, 'test-link.md')
        FileUtils.touch(test_link)

        # Simulate failure during installation
        @symlink_manager.stubs(:create_symlinks).raises(StandardError, 'Critical failure')

        @ui.expects(:error).at_least_once
        @installer.expects(:rollback_installation).once

        assert_raises(StandardError) do
          @installer.install('dlabs')
        end
      end
    end

    def test_rollback_removes_created_symlinks
      with_mock_home do |home|
        agents_dir = File.join(home, '.claude', 'agents')
        FileUtils.mkdir_p(agents_dir)

        # Track created symlinks
        created_links = [
          File.join(agents_dir, 'test1.md'),
          File.join(agents_dir, 'test2.md')
        ]

        @installer.instance_variable_set(:@created_links, created_links)

        created_links.each do |link|
          FileUtils.expects(:rm_f).with(link).once
        end

        @installer.send(:rollback_installation)
      end
    end
  end
end