# ABOUTME: Unit tests for ClaudeAgents::Installer focusing on component validation
# frozen_string_literal: true

require_relative "../test_helper"

class InstallerTest < ClaudeAgentsTest
  def setup
    super
    @ui = create_test_ui
    @installer = ClaudeAgents::Installer.new(@ui)
  end

  def test_install_component_with_unknown_component_raises_installation_error
    error = assert_raises(ClaudeAgents::InstallationError) do
      @installer.install_component(:nonexistent_component)
    end
    assert_includes error.message, "Unknown component"
  end
end
