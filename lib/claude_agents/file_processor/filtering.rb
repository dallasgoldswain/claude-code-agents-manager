# frozen_string_literal: true

module ClaudeAgents
  class FileProcessor
    # Filtering helpers for skipping ineligible files before mapping.
    module Filtering
      def should_skip_file?(file_path)
        filename = File.basename(file_path)
        return true if File.directory?(file_path)
        return true if Config.skip_file?(filename)
        return true if filename.start_with?('.')
        return true if file_path.include?('/examples/')

        false
      end

      def eligible_files_in_directory(directory)
        return [] unless Dir.exist?(directory)

        Dir.glob(File.join(directory, '**/*'))
           .select { |file| File.file?(file) }
           .reject { |file| should_skip_file?(file) }
      end
    end
  end
end
