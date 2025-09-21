# frozen_string_literal: true

require 'test_helper'

class UITest < ClaudeAgentsTest
  def setup
    super
    setup_mocks
    setup_color_stubs
    @ui = ClaudeAgents::UI.new
  end

  private

  def setup_mocks
    @pastel = mock('Pastel')
    @prompt = mock('TTY::Prompt')
    Pastel.stubs(:new).returns(@pastel)
    TTY::Prompt.stubs(:new).returns(@prompt)

    # Mock TTY::Box to avoid complex styling issues in tests
    TTY::Box.stubs(:frame).returns('mocked frame')
  end

  def setup_color_stubs
    # Setup default color method stubs - return text as-is
    %w[green red yellow blue cyan magenta dim bold].each do |color|
      @pastel.stubs(color.to_sym).with(anything).returns { |text| text }
    end

    # Setup bright colors and chaining - return mock that handles method chaining
    chain_mock = stub_everything('chain_mock')
    chain_mock.stubs(:bold).returns(chain_mock)
    chain_mock.stubs(:call).returns('test')
    chain_mock.stubs(:to_s).returns('test')
    chain_mock.stubs(:to_str).returns('test')

    @pastel.stubs(:bright_cyan).returns(chain_mock)
    @pastel.stubs(:bright_blue).returns(chain_mock)
    @pastel.stubs(:bright_green).returns(chain_mock)
  end

  def teardown
    super
    Mocha::Mockery.instance.teardown
  end

  # Test initialization
  class InitializationTest < UITest
    def test_initializes_with_default_settings
      assert_instance_of ClaudeAgents::UI, @ui
      assert_respond_to @ui, :say
      assert_respond_to @ui, :success
      assert_respond_to @ui, :error
    end

    def test_initializes_with_color_disabled
      Pastel.expects(:new).with(enabled: false).returns(@pastel)

      ui = ClaudeAgents::UI.new(color: false)

      assert_instance_of ClaudeAgents::UI, ui
    end

    def test_initializes_with_verbose_mode
      ui = ClaudeAgents::UI.new(verbose: true)

      assert ui.instance_variable_get(:@verbose)
    end
  end

  # Test output methods
  class OutputMethodsTest < UITest
    def test_say_outputs_message
      stdout, = capture_output do
        @ui.say('Hello, world!')
      end

      assert_includes stdout, 'Hello, world!'
    end

    def test_success_outputs_with_green_color
      @pastel.expects(:green).with('Success!').returns('[GREEN]Success![/GREEN]')

      stdout, = capture_output do
        @ui.success('Success!')
      end

      assert_includes stdout, '[GREEN]Success![/GREEN]'
    end

    def test_error_outputs_with_red_color
      @pastel.expects(:red).with('Error!').returns('[RED]Error![/RED]')

      stdout, = capture_output do
        @ui.error('Error!')
      end

      assert_includes stdout, '[RED]Error![/RED]'
    end

    def test_warning_outputs_with_yellow_color
      @pastel.expects(:yellow).with('Warning!').returns('[YELLOW]Warning![/YELLOW]')

      stdout, = capture_output do
        @ui.warning('Warning!')
      end

      assert_includes stdout, '[YELLOW]Warning![/YELLOW]'
    end

    def test_info_outputs_with_blue_color
      @pastel.expects(:blue).with('Info').returns('[BLUE]Info[/BLUE]')

      stdout, = capture_output do
        @ui.info('Info')
      end

      assert_includes stdout, '[BLUE]Info[/BLUE]'
    end

    def test_verbose_only_outputs_in_verbose_mode
      @ui.instance_variable_set(:@verbose, false)

      stdout, = capture_output do
        @ui.verbose('Debug info')
      end

      assert_empty stdout

      @ui.instance_variable_set(:@verbose, true)

      stdout, = capture_output do
        @ui.verbose('Debug info')
      end

      assert_includes stdout, 'Debug info'
    end
  end

  # Test prompt methods
  class PromptMethodsTest < UITest
    def test_confirm_prompts_for_confirmation
      @prompt.expects(:yes?).with('Continue?').returns(true)

      result = @ui.confirm('Continue?')

      assert result
    end

    def test_ask_prompts_for_input
      @prompt.expects(:ask).with('Your name:').returns('Alice')

      result = @ui.ask('Your name:')

      assert_equal 'Alice', result
    end

    def test_ask_with_default_value
      @prompt.expects(:ask).with('Your name:', default: 'Bob').returns('Bob')

      result = @ui.ask('Your name:', default: 'Bob')

      assert_equal 'Bob', result
    end

    def test_select_prompts_for_selection
      choices = ['Option 1', 'Option 2', 'Option 3']
      @prompt.expects(:select).with('Choose:', choices).returns('Option 2')

      result = @ui.select('Choose:', choices)

      assert_equal 'Option 2', result
    end

    def test_multi_select_prompts_for_multiple_selections
      choices = %w[A B C D]
      @prompt.expects(:multi_select).with('Select multiple:', choices).returns(%w[A C])

      result = @ui.multi_select('Select multiple:', choices)

      assert_equal %w[A C], result
    end

    def test_masked_ask_for_sensitive_input
      @prompt.expects(:mask).with('Password:').returns('secret123')

      result = @ui.ask_password('Password:')

      assert_equal 'secret123', result
    end
  end

  # Test spinner methods
  class SpinnerTest < UITest
    def test_with_spinner_shows_spinner_during_operation
      spinner = mock('TTY::Spinner')
      TTY::Spinner.expects(:new).with('[:spinner] Loading...', format: :dots).returns(spinner)
      spinner.expects(:auto_spin)
      spinner.expects(:success).with('(done)')

      result = @ui.with_spinner('Loading...') do
        'result'
      end

      assert_equal 'result', result
    end

    def test_with_spinner_handles_failure
      spinner = mock('TTY::Spinner')
      TTY::Spinner.expects(:new).returns(spinner)
      spinner.expects(:auto_spin)
      spinner.expects(:error).with('(failed)')

      assert_raises(StandardError) do
        @ui.with_spinner('Loading...') do
          raise StandardError, 'Operation failed'
        end
      end
    end

    def test_with_spinner_custom_success_message
      spinner = mock('TTY::Spinner')
      TTY::Spinner.expects(:new).returns(spinner)
      spinner.expects(:auto_spin)
      spinner.expects(:success).with('(custom)')

      @ui.with_spinner('Loading...', success: 'custom') do
        'result'
      end
    end
  end

  # Test progress bar methods
  class ProgressBarTest < UITest
    def test_with_progress_shows_progress_bar
      progress = mock('TTY::ProgressBar')
      TTY::ProgressBar.expects(:new).with(
        'Processing [:bar] :percent :current/:total',
        total: 100,
        width: 30
      ).returns(progress)
      progress.expects(:finish)

      result = @ui.with_progress('Processing', total: 100) do |bar|
        bar.expects(:advance).with(10)
        bar.advance(10)
        'done'
      end

      assert_equal 'done', result
    end

    def test_progress_bar_auto_updates
      progress = mock('TTY::ProgressBar')
      TTY::ProgressBar.expects(:new).returns(progress)
      progress.expects(:advance).times(3)
      progress.expects(:finish)

      @ui.with_progress('Processing', total: 3) do |bar|
        3.times { bar.advance }
      end
    end

    def test_progress_bar_with_custom_format
      progress = mock('TTY::ProgressBar')
      TTY::ProgressBar.expects(:new).with(
        includes('[:bar]'),
        has_entries(format: :block)
      ).returns(progress)
      progress.expects(:finish)

      @ui.with_progress('Custom', total: 10, format: :block) do |_bar|
        'result'
      end
    end
  end

  # Test table rendering
  class TableRenderingTest < UITest
    def test_render_table_with_data
      headers = %w[Name Age City]
      rows = [
        ['Alice', 30, 'New York'],
        ['Bob', 25, 'London']
      ]

      table = mock('TTY::Table')
      TTY::Table.expects(:new).with(headers, rows).returns(table)
      renderer = mock('renderer')
      table.expects(:render).with(:unicode, padding: [0, 1]).returns(renderer)
      renderer.expects(:to_s).returns('TABLE OUTPUT')

      stdout, = capture_output do
        @ui.table(headers, rows)
      end

      assert_includes stdout, 'TABLE OUTPUT'
    end

    def test_render_table_with_custom_style
      headers = %w[A B]
      rows = [%w[1 2]]

      table = mock('TTY::Table')
      TTY::Table.expects(:new).returns(table)
      table.expects(:render).with(:ascii, padding: [0, 2]).returns(mock(to_s: 'OUTPUT'))

      @ui.table(headers, rows, style: :ascii, padding: [0, 2])
    end

    def test_render_empty_table
      headers = ['Column 1', 'Column 2']
      rows = []

      table = mock('TTY::Table')
      TTY::Table.expects(:new).with(headers, rows).returns(table)
      table.expects(:render).returns(mock(to_s: 'EMPTY TABLE'))

      stdout, = capture_output do
        @ui.table(headers, rows)
      end

      assert_includes stdout, 'EMPTY TABLE'
    end
  end

  # Test box rendering
  class BoxRenderingTest < UITest
    def test_render_box_with_title_and_content
      box_output = "╔══════════╗\n║  Title   ║\n║ Content  ║\n╚══════════╝"
      TTY::Box.expects(:frame).with(
        'Content',
        title: { top_left: 'Title' },
        padding: 1,
        border: :thick
      ).returns(box_output)

      stdout, = capture_output do
        @ui.box('Title', 'Content')
      end

      assert_includes stdout, box_output
    end

    def test_render_box_with_custom_style
      TTY::Box.expects(:frame).with(
        'Message',
        has_entries(
          border: :ascii,
          padding: [1, 2],
          style: { fg: :green, bg: :black }
        )
      ).returns('ASCII BOX')

      stdout, = capture_output do
        @ui.box('Title', 'Message',
                border: :ascii,
                padding: [1, 2],
                style: { fg: :green, bg: :black })
      end

      assert_includes stdout, 'ASCII BOX'
    end
  end

  # Test status display
  class StatusDisplayTest < UITest
    def test_display_status_shows_component_status
      with_mock_home do |_home|
        # Setup mock component status
        components_status = [
          { name: 'dlabs', installed: true, symlinks: 5 },
          { name: 'wshobson-agents', installed: false, symlinks: 0 }
        ]

        ClaudeAgents::Config::Components.expects(:component_status).returns(components_status)

        stdout, = capture_output do
          @ui.display_status
        end

        assert_includes stdout, 'dlabs'
        assert_includes stdout, 'installed'
        assert_includes stdout, '5'
        assert_includes stdout, 'wshobson-agents'
      end
    end

    def test_display_status_with_no_installations
      ClaudeAgents::Config::Components.expects(:component_status).returns([])

      stdout, = capture_output do
        @ui.display_status
      end

      assert_includes stdout, 'No components installed'
    end

    def test_display_detailed_status_with_verbose_mode
      @ui.instance_variable_set(:@verbose, true)

      components_status = [
        {
          name: 'dlabs',
          installed: true,
          symlinks: 3,
          repository: 'local',
          last_updated: Time.now
        }
      ]

      ClaudeAgents::Config::Components.expects(:component_status).returns(components_status)

      stdout, = capture_output do
        @ui.display_status
      end

      assert_includes stdout, 'dlabs'
      assert_includes stdout, 'Last updated'
    end
  end

  # Test error formatting
  class ErrorFormattingTest < UITest
    def test_format_error_with_standard_error
      error = StandardError.new('Something went wrong')

      stdout, = capture_output do
        @ui.format_error(error)
      end

      assert_includes stdout, 'Standard Error: Something went wrong'
    end

    def test_format_error_with_custom_error_class
      error = ClaudeAgents::InstallationError.new('Installation failed')

      @pastel.expects(:red).with('Installation Error: Installation failed').returns('[RED]Installation Error[/RED]')

      stdout, = capture_output do
        @ui.format_error(error)
      end

      assert_includes stdout, '[RED]Installation Error[/RED]'
    end

    def test_format_error_with_backtrace_in_verbose_mode
      @ui.instance_variable_set(:@verbose, true)

      error = StandardError.new('Error with trace')
      error.set_backtrace(%w[line1 line2 line3])

      stdout, = capture_output do
        @ui.format_error(error)
      end

      assert_includes stdout, 'Backtrace:'
      assert_includes stdout, 'line1'
    end
  end

  # Test interactive menus
  class InteractiveMenuTest < UITest
    def test_component_selection_menu
      components = %w[dlabs wshobson-agents awesome]
      @prompt.expects(:multi_select).with(
        'Select components to install:',
        components,
        per_page: 10
      ).returns(%w[dlabs awesome])

      result = @ui.select_components(components)

      assert_equal %w[dlabs awesome], result
    end

    def test_action_menu
      actions = {
        install: 'Install components',
        remove: 'Remove components',
        status: 'Show status',
        exit: 'Exit'
      }

      @prompt.expects(:select).with(
        'What would you like to do?',
        actions,
        per_page: 10
      ).returns(:install)

      result = @ui.select_action(actions)

      assert_equal :install, result
    end
  end

  # Test formatting helpers
  class FormattingHelpersTest < UITest
    def test_format_file_size
      assert_equal '1.0 KB', @ui.format_size(1024)
      assert_equal '1.5 MB', @ui.format_size(1_572_864)
      assert_equal '2.0 GB', @ui.format_size(2_147_483_648)
      assert_equal '100 B', @ui.format_size(100)
    end

    def test_format_duration
      assert_equal '0.5s', @ui.format_duration(0.5)
      assert_equal '1m 30s', @ui.format_duration(90)
      assert_equal '2h 5m', @ui.format_duration(7500)
      assert_equal '1d 2h', @ui.format_duration(93_600)
    end

    def test_truncate_text
      long_text = 'This is a very long text that needs to be truncated'

      assert_equal 'This is a...', @ui.truncate(long_text, 10)
      assert_equal 'This is a very long text...', @ui.truncate(long_text, 25)
      assert_equal long_text, @ui.truncate(long_text, 100)
    end

    def test_pluralize
      assert_equal '1 file', @ui.pluralize(1, 'file')
      assert_equal '2 files', @ui.pluralize(2, 'file')
      assert_equal '0 files', @ui.pluralize(0, 'file')
      assert_equal '1 directory', @ui.pluralize(1, 'directory', 'directories')
      assert_equal '3 directories', @ui.pluralize(3, 'directory', 'directories')
    end
  end
end
