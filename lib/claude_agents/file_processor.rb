# frozen_string_literal: true

module ClaudeAgents
  # File processing utilities for filtering, validation, and path management
  class FileProcessor
    attr_reader :ui

    def initialize(ui)
      @ui = ui
    end

    # File filtering methods
    def should_skip_file?(file_path)
      filename = File.basename(file_path)
      return true if File.directory?(file_path)
      return true if Config.skip_file?(filename)

      # Additional specific skips
      return true if filename.start_with?(".")
      return true if file_path.include?("/examples/")

      false
    end

    def eligible_files_in_directory(directory)
      return [] unless Dir.exist?(directory)

      Dir.glob(File.join(directory, "**/*"))
         .select { |file| File.file?(file) }
         .reject { |file| should_skip_file?(file) }
    end

    def process_dlabs_files(source_dir)
      process_generic_files(source_dir, "dLabs-")
    end

    def process_generic_files(source_dir, prefix)
      return [] unless Dir.exist?(source_dir)

      begin
        files = Dir.glob(File.join(source_dir, "*"))
                   .select { |file| File.file?(file) }
                   .reject { |file| should_skip_file?(file) }
      rescue Errno::EACCES => e
        raise FileOperationError,
              "Permission denied accessing directory: #{source_dir} - #{e.message}"
      end

      files.map do |file|
        filename = File.basename(file)
        prefixed_name = prefix ? "#{prefix}#{filename}" : filename
        {
          source: file,
          destination: File.join(Config.agents_dir, prefixed_name),
          display_name: prefixed_name
        }
      end
    end

    # Removed non-dLabs processing methods in dLabs-only mode

    def count_files_in_directory(directory)
      eligible_files_in_directory(directory).length
    end

    def validate_source_directory(component)
      source_dir = Config.source_dir_for(component)

      unless Dir.exist?(source_dir)
        raise FileOperationError,
              "Source directory for #{component} does not exist: #{source_dir}. " \
              "Please run the installation first."
      end

      source_dir
    end

    def get_file_mappings_for_component(component)
      unless Config.valid_component?(component)
        raise ValidationError, "Invalid component: #{component}"
      end

      source_dir = validate_source_directory(component)

      case component.to_sym
      when :dlabs
        process_dlabs_files(source_dir)
      when :test
        process_generic_files(source_dir, Config.prefix_for(component))
      else
        raise ValidationError, "Unknown component: #{component}"
      end
    end

    def validate_file_mapping(mapping)
      source = mapping[:source]
      destination = mapping[:destination]

      raise FileOperationError, "Source file does not exist: #{source}" unless File.exist?(source)

      unless File.readable?(source)
        raise FileOperationError, "Source file is not readable: #{source}"
      end

      # Ensure destination directory exists
      dest_dir = File.dirname(destination)
      FileUtils.mkdir_p(dest_dir)

      true
    end

    private

    def find_markdown_files(directory)
      return [] unless Dir.exist?(directory)

      Dir.glob(File.join(directory, "**/*.md"))
         .select { |file| File.file?(file) }
         .reject { |file| should_skip_file?(file) }
    end

    def generate_destination_path(destination_dir, relative_path, prefix)
      # Handle special command structure (tools/ and workflows/)
      if relative_path.start_with?("tools/", "workflows/")
        # Preserve directory structure for commands
        filename = File.basename(relative_path)
        prefixed_filename = if prefix
                              "#{prefix}#{filename}"
                            else
                              filename
                            end
        directory = File.dirname(relative_path)
        return File.join(destination_dir, directory, prefixed_filename)
      end

      # For other paths with directories, apply prefix first then flatten
      if relative_path.include?("/")
        directory = File.dirname(relative_path)
        filename = File.basename(relative_path)

        # Apply prefix to filename first
        prefixed_filename = if prefix
                              "#{prefix}#{filename}"
                            else
                              filename
                            end

        # Then create flattened name only if no prefix (for category flattening)
        final_filename = if prefix
                           prefixed_filename
                         else
                           "#{directory}-#{prefixed_filename}"
                         end
      else
        final_filename = if prefix
                           "#{prefix}#{relative_path}"
                         else
                           relative_path
                         end
      end

      File.join(destination_dir, final_filename)
    end

    def generate_display_name(filename, prefix)
      if prefix
        "#{prefix}#{filename}"
      else
        filename
      end
    end
  end
end
