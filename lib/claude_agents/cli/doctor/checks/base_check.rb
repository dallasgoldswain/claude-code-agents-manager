# frozen_string_literal: true

module ClaudeAgents
  class CLI < Thor
    module Doctor
      module Checks
        # Base class for doctor checks. Concrete subclasses must implement `call`.
        class BaseCheck
          def initialize(ui)
            @ui = ui
          end

          def call
            raise NotImplementedError, "#{self.class.name} must implement #call"
          end

          private

          attr_reader :ui
        end
      end
    end
  end
end
