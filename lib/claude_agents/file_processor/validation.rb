# frozen_string_literal: true

module ClaudeAgents
  class FileProcessor
    # Validation helpers for source directories and file mappings.
    module Validation
      def count_files_in_directory(directory)
        eligible_files_in_directory(directory).length
      end

      def validate_source_directory(component)
        source_dir = Config.source_dir_for(component)

        unless Dir.exist?(source_dir)
          raise ValidationError,
                "Source directory for #{component} does not exist: #{source_dir}. Please run the installation first."
        end

        source_dir
      end

      def validate_file_mapping(mapping)
        source = mapping[:source]
        destination = mapping[:destination]

        raise FileOperationError, "Source file does not exist: #{source}" unless File.exist?(source)
        raise FileOperationError, "Source file is not readable: #{source}" unless File.readable?(source)

        dest_dir = File.dirname(destination)
        FileUtils.mkdir_p(dest_dir)

        true
      end
    end
  end
end
