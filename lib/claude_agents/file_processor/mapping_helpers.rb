# frozen_string_literal: true

module ClaudeAgents
  class FileProcessor
    # Shared helper for building mapping hashes with consistent keys.
    module MappingHelpers
      private

      def build_mapping(source, destination, display_name)
        {
          source: source,
          destination: destination,
          display_name: display_name
        }
      end
    end
  end
end
