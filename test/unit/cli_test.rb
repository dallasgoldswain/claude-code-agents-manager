# frozen_string_literal: true

require 'test_helper'

class CLITest < ClaudeAgentsTest
  include CLITestHelper

  def setup
    @ui = build_stubbed_ui
    ClaudeAgents::UI.stubs(:new).returns(@ui)
    super
    @cli.instance_variable_set(:@options, Thor::CoreExt::HashWithIndifferentAccess.new)
  end

  def teardown
    super
    ClaudeAgents::UI.unstub(:new)
  end

  # -- install command --------------------------------------------------------------------------

  def test_install_runs_interactive_mode_by_default
    installer = mock('Installer')
    ClaudeAgents::Installer.stubs(:new).with(@ui).returns(installer)
    # Without flags the CLI should drop into the interactive installer.
    installer.expects(:interactive_install).once

    run_command(:install)
  end

  def test_install_with_component_option_validates_and_installs_specific_collection
    installer = mock('Installer')
    ClaudeAgents::Installer.stubs(:new).with(@ui).returns(installer)
    Config.stubs(:valid_component?).with('dlabs').returns(true)

    # Passing --component chooses the targeted install flow.
    installer.expects(:install_component).with('dlabs').once

    run_command(:install, [], component: 'dlabs')
  ensure
    Config.unstub(:valid_component?) if Config.respond_to?(:unstub)
  end

  def test_install_with_yes_option_installs_all_components
    installer = mock('Installer')
    ClaudeAgents::Installer.stubs(:new).with(@ui).returns(installer)
    Config.stubs(:all_components).returns(%w[dlabs awesome])

    # --yes should fast track to installing every component.
    installer.expects(:install_components).with(%w[dlabs awesome]).once

    run_command(:install, [], yes: true)
  ensure
    Config.unstub(:all_components) if Config.respond_to?(:unstub)
  end

  # -- setup command ----------------------------------------------------------------------------

  def test_setup_reports_success_when_links_created
    installer = mock('Installer')
    ClaudeAgents::Installer.stubs(:new).with(@ui).returns(installer)
    Config.stubs(:valid_component?).with('dlabs').returns(true)
    installer.stubs(:install_component).returns(created_links: 2)
    # When we create links we surface a success message to the user.
    @ui.expects(:success).with(includes('Successfully installed')).once

    run_command(:setup, ['dlabs'])
  ensure
    Config.unstub(:valid_component?) if Config.respond_to?(:unstub)
  end

  def test_setup_warns_when_nothing_installed
    installer = mock('Installer')
    ClaudeAgents::Installer.stubs(:new).with(@ui).returns(installer)
    Config.stubs(:valid_component?).with('dlabs').returns(true)
    installer.stubs(:install_component).returns(created_links: 0)
    # No new links -> gentle warning instead of success.
    @ui.expects(:warn).with(includes('No new')).once

    run_command(:setup, ['dlabs'])
  ensure
    Config.unstub(:valid_component?) if Config.respond_to?(:unstub)
  end

  # -- remove command ---------------------------------------------------------------------------

  def test_remove_without_component_runs_interactive_flow
    remover = mock('Remover')
    ClaudeAgents::Remover.stubs(:new).with(@ui).returns(remover)
    # No arguments means we kick off the interactive removal flow.
    remover.expects(:interactive_remove).once

    run_command(:remove)
  end

  def test_remove_with_all_argument_removes_everything
    remover = mock('Remover')
    ClaudeAgents::Remover.stubs(:new).with(@ui).returns(remover)
    # The literal "all" shortcut should map to remove_all.
    remover.expects(:remove_all).once

    run_command(:remove, ['all'])
  end

  def test_remove_with_specific_component_shows_result_message
    remover = mock('Remover')
    ClaudeAgents::Remover.stubs(:new).with(@ui).returns(remover)
    Config.stubs(:valid_component?).with('dlabs').returns(true)
    remover.stubs(:remove_component).with('dlabs').returns(removed_count: 1)
    # Successful removals bubble up through the UI so the user can see the outcome.
    @ui.expects(:success).with(includes('Successfully removed')).once

    run_command(:remove, ['dlabs'])
  ensure
    Config.unstub(:valid_component?) if Config.respond_to?(:unstub)
  end

  # -- status command ---------------------------------------------------------------------------

  def test_status_delegates_to_ui
    # status is a thin wrapper around the UI helper.
    @ui.expects(:display_status).once

    run_command(:status)
  end

  # -- doctor command ---------------------------------------------------------------------------

  def test_doctor_invokes_runner
    runner = mock('Doctor::Runner')
    ClaudeAgents::CLI::Doctor::Runner.stubs(:new).with(@ui).returns(runner)
    # doctor simply hands off to the runner service.
    runner.expects(:call).once

    run_command(:doctor)
  ensure
    ClaudeAgents::CLI::Doctor::Runner.unstub(:new)
  end

  def test_doctor_errors_are_forwarded_to_error_handler
    runner = mock('Doctor::Runner')
    ClaudeAgents::CLI::Doctor::Runner.stubs(:new).with(@ui).returns(runner)
    runner.stubs(:call).raises(StandardError, 'check failed')
    # Any exception should be surfaced through the shared error handler.
    ClaudeAgents::ErrorHandler.expects(:handle_error).with(instance_of(StandardError), @ui).once

    run_command(:doctor)
  ensure
    ClaudeAgents::CLI::Doctor::Runner.unstub(:new)
  end

  # -- configuration helpers --------------------------------------------------------------------

  def test_configure_ui_disables_colors_when_no_color_option_used
    pastel = mock('Pastel')
    pastel.expects(:enabled=).with(false).once
    @ui.stubs(:pastel).returns(pastel)
    @cli.instance_variable_set(:@options, Thor::CoreExt::HashWithIndifferentAccess.new('no_color' => true))

    # Setting --no-color should toggle the underlying Pastel instance off.
    @cli.send(:configure_ui)
  end

  private

  def build_stubbed_ui
    pastel = mock('Pastel')
    pastel.stubs(:enabled=)

    ui = mock('UI')
    ui.stubs(:pastel).returns(pastel)
    ui.stubs(:display_status)
    ui.stubs(:newline)
    ui.stubs(:success)
    ui.stubs(:info)
    ui.stubs(:warn)
    ui.stubs(:title)
    ui.stubs(:subsection)
    ui.stubs(:error)
    ui.stubs(:dim)
    ui
  end
end
