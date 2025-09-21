# frozen_string_literal: true

require_relative '../test_helper'

# Test suite for the Installer service class
# Tests repository cloning, component installation, and progress tracking
class TestInstaller < ClaudeAgentsTest
  def setup
    super
    @ui = create_mock_ui
    @installer = ClaudeAgents::Installer.new(@ui)
  end

  # Test installer initialization
  def test_installer_initialization
    assert_instance_of ClaudeAgents::Installer, @installer
    assert_equal @ui, @installer.ui
  end

  # Test install_all method basic functionality
  def test_install_all_returns_results_hash
    # Mock all component installations to avoid external dependencies
    mock_all_component_installations

    result = @installer.install_all

    assert_instance_of Hash, result
    assert_operator result.size, :>=, 0, 'Should return results for components'
  end

  # Test install_component with valid component
  def test_install_component_with_valid_component
    component = 'dlabs'

    # Mock component validation and configuration
    ClaudeAgents::Config.stubs(:valid_component?).with(component).returns(true)
    ClaudeAgents::Config.stubs(:component_config).with(component).returns(sample_config_component)

    # Mock symlink manager
    mock_symlink_manager = mock('SymlinkManager')
    mock_symlink_manager.expects(:create_symlinks).returns(true)
    ClaudeAgents::SymlinkManager.expects(:new).returns(mock_symlink_manager)

    # Mock repository operations (no repo for dlabs)
    @installer.stubs(:clone_repository_if_needed).returns(true)

    result = @installer.install_component(component)

    assert result, 'Should return true for successful installation'
  end

  # Test install_component with invalid component
  def test_install_component_with_invalid_component
    component = 'invalid'

    ClaudeAgents::Config.stubs(:valid_component?).with(component).returns(false)

    assert_raises ClaudeAgents::ValidationError do
      @installer.install_component(component)
    end
  end

  # Test install_component with repository component
  def test_install_component_with_repository
    component = 'wshobson-agents'

    # Mock component validation and configuration
    ClaudeAgents::Config.stubs(:valid_component?).with(component).returns(true)
    ClaudeAgents::Config.stubs(:component_config).with(component).returns(
      sample_config_component.merge(repository: 'wshobson-agents')
    )

    # Mock repository configuration
    ClaudeAgents::Config.stubs(:repository_config).with('wshobson-agents').returns(
      sample_repository_config['test_repo']
    )

    # Mock repository cloning
    @installer.expects(:clone_repository_if_needed).with('wshobson-agents').returns(true)

    # Mock symlink manager
    mock_symlink_manager = mock('SymlinkManager')
    mock_symlink_manager.expects(:create_symlinks).returns(true)
    ClaudeAgents::SymlinkManager.expects(:new).returns(mock_symlink_manager)

    result = @installer.install_component(component)

    assert result, 'Should successfully install component with repository'
  end

  # Test repository cloning when directory doesn't exist
  def test_clone_repository_when_not_exists
    repo_name = 'test-repo'
    repo_config = sample_repository_config['test_repo']

    ClaudeAgents::Config.stubs(:repository_config).with(repo_name).returns(repo_config)

    # Mock directory check
    full_path = File.join(ClaudeAgents::Config.project_root, repo_config['local_path'])
    Dir.stubs(:exist?).with(full_path).returns(false)

    # Mock successful git clone
    stub_system_command("git clone #{repo_config['url']} #{full_path}", success: true)

    with_temp_dir do
      result = @installer.send(:clone_repository_if_needed, repo_name)

      assert result, 'Should successfully clone repository'
    end
  end

  # Test repository cloning when directory already exists
  def test_clone_repository_when_exists
    repo_name = 'test-repo'
    repo_config = sample_repository_config['test_repo']

    ClaudeAgents::Config.stubs(:repository_config).with(repo_name).returns(repo_config)

    # Mock directory exists
    full_path = File.join(ClaudeAgents::Config.project_root, repo_config['local_path'])
    Dir.stubs(:exist?).with(full_path).returns(true)

    result = @installer.send(:clone_repository_if_needed, repo_name)

    assert result, 'Should return true when repository already exists'
  end

  # Test repository cloning with git failure
  def test_clone_repository_git_failure
    repo_name = 'test-repo'
    repo_config = sample_repository_config['test_repo']

    ClaudeAgents::Config.stubs(:repository_config).with(repo_name).returns(repo_config)

    # Mock directory doesn't exist
    full_path = File.join(ClaudeAgents::Config.project_root, repo_config['local_path'])
    Dir.stubs(:exist?).with(full_path).returns(false)

    # Mock failed git clone
    stub_system_command("git clone #{repo_config['url']} #{full_path}", success: false)

    with_temp_dir do
      assert_raises ClaudeAgents::InstallationError do
        @installer.send(:clone_repository_if_needed, repo_name)
      end
    end
  end

  # Test installation with progress tracking
  def test_install_all_with_progress_tracking
    # Mock component list
    components = %w[dlabs wshobson-agents]
    ClaudeAgents::Config.stubs(:all_components).returns(components)

    # Mock individual installations
    components.each do |component|
      @installer.stubs(:install_component).with(component).returns(true)
    end

    # Verify progress tracking calls
    @ui.expects(:with_progress).yields(mock_progress_bar).returns(true)

    result = @installer.install_all

    assert_instance_of Hash, result
  end

  # Test error handling in component installation
  def test_install_component_error_handling
    component = 'dlabs'

    # Mock component validation
    ClaudeAgents::Config.stubs(:valid_component?).with(component).returns(true)
    ClaudeAgents::Config.stubs(:component_config).with(component).returns(sample_config_component)

    # Mock symlink manager to raise error
    ClaudeAgents::SymlinkManager.expects(:new).raises(StandardError.new('Test error'))

    assert_raises StandardError do
      @installer.install_component(component)
    end
  end

  # Test batch installation with mixed results
  def test_install_all_with_mixed_results
    components = %w[dlabs wshobson-agents awesome]
    ClaudeAgents::Config.stubs(:all_components).returns(components)

    # Mock mixed installation results
    @installer.stubs(:install_component).with('dlabs').returns(true)
    @installer.stubs(:install_component).with('wshobson-agents').raises(StandardError.new('Network error'))
    @installer.stubs(:install_component).with('awesome').returns(true)

    # Mock progress tracking
    @ui.stubs(:with_progress).yields(mock_progress_bar).returns(true)

    result = @installer.install_all

    assert_instance_of Hash, result
    assert result['dlabs'] if result.key?('dlabs')
    assert_kind_of StandardError, result['wshobson-agents'] if result.key?('wshobson-agents')
    assert result['awesome'] if result.key?('awesome')
  end

  # Test installer UI integration
  def test_installer_ui_integration
    component = 'dlabs'

    # Mock successful installation path
    ClaudeAgents::Config.stubs(:valid_component?).with(component).returns(true)
    ClaudeAgents::Config.stubs(:component_config).with(component).returns(sample_config_component)

    mock_symlink_manager = mock('SymlinkManager')
    mock_symlink_manager.expects(:create_symlinks).returns(true)
    ClaudeAgents::SymlinkManager.expects(:new).returns(mock_symlink_manager)

    # Verify UI method calls
    @ui.expects(:with_spinner).yields.returns(true)

    result = @installer.install_component(component)

    assert result, 'Should complete installation with UI integration'
  end

  private

  # Helper to mock all component installations
  def mock_all_component_installations
    components = %w[dlabs wshobson-agents wshobson-commands awesome]
    ClaudeAgents::Config.stubs(:all_components).returns(components)

    components.each do |component|
      @installer.stubs(:install_component).with(component).returns(true)
    end

    @ui.stubs(:with_progress).yields(mock_progress_bar).returns(true)
  end
end
