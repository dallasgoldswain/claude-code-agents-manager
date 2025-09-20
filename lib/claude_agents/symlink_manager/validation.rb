# frozen_string_literal: true

module ClaudeAgents
  class SymlinkManager
    # Helpers for validating managed filesystem paths.
    module Validation
      def validate_managed_path!(path)
        expanded = File.expand_path(path)
        allowed_roots = Config.allowed_symlink_roots

        if allowed_roots.any? { |root| expanded == root || expanded.start_with?("#{root}#{File::SEPARATOR}") }
          return expanded
        end

        raise SymlinkError, "Destination outside managed directories: #{expanded}"
      end
    end
  end
end
