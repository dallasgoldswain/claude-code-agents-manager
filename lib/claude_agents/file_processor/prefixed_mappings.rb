# frozen_string_literal: true

module ClaudeAgents
  class FileProcessor
    # Builds file mappings for components that use prefixed filenames.
    module PrefixedMappings
      def process_prefixed_files(source_dir, destination_root:, prefix: nil)
        return [] unless Dir.exist?(source_dir)

        Dir.glob(File.join(source_dir, '*'))
           .select { |file| File.file?(file) }
           .reject { |file| should_skip_file?(file) }
           .map do |file|
          filename = File.basename(file)
          display_name = [prefix, filename].compact.join

          build_mapping(file, File.join(destination_root, display_name), display_name)
        end
      end
    end
  end
end
