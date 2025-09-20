# frozen_string_literal: true

require 'zeitwerk'
require 'thor'
require 'pastel'
require 'tty-prompt'
require 'tty-spinner'
require 'tty-progressbar'
require 'tty-table'
require 'tty-box'
require 'fileutils'
require 'pathname'

# Core namespace for the Claude Agents CLI and supporting services.
module ClaudeAgents
  VERSION = '0.3.0'

  class << self
    def loader
      @loader ||= begin
        loader = Zeitwerk::Loader.for_gem
        loader.inflector.inflect(
          'cli' => 'CLI',
          'ui' => 'UI',
          'ui_components' => 'UIComponents'
        )
        loader.setup
        loader
      end
    end
  end
end

ClaudeAgents.loader
