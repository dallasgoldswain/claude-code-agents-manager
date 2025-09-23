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
        raise FileOperationError, "Permission denied accessing directory: #{source_dir} - #{e.message}"
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

    def process_wshobson_agent_files(source_dir)
      return [] unless Dir.exist?(source_dir)

      files = Dir.glob(File.join(source_dir, "*"))
                 .select { |file| File.file?(file) }
                 .reject { |file| should_skip_file?(file) }

      files.map do |file|
        filename = File.basename(file)
        {
          source: file,
          destination: File.join(Config.agents_dir, "wshobson-#{filename}"),
          display_name: "wshobson-#{filename}"
        }
      end
    end

    def process_wshobson_command_files(source_dir)
      return [] unless Dir.exist?(source_dir)

      file_mappings = []

      # Process tools directory
      tools_dir = File.join(source_dir, "tools")
      if Dir.exist?(tools_dir)
        Dir.glob(File.join(tools_dir, "*")).each do |file|
          next unless File.file?(file) && !should_skip_file?(file)

          filename = File.basename(file)
          file_mappings << {
            source: file,
            destination: File.join(Config.tools_dir, filename),
            display_name: "tools/#{filename}"
          }
        end
      end

      # Process workflows directory
      workflows_dir = File.join(source_dir, "workflows")
      if Dir.exist?(workflows_dir)
        Dir.glob(File.join(workflows_dir, "*")).each do |file|
          next unless File.file?(file) && !should_skip_file?(file)

          filename = File.basename(file)
          file_mappings << {
            source: file,
            destination: File.join(Config.workflows_dir, filename),
            display_name: "workflows/#{filename}"
          }
        end
      end

      # Process root directory files (with wshobson- prefix)
      Dir.glob(File.join(source_dir, "*")).each do |file|
        next unless File.file?(file) && !should_skip_file?(file)

        filename = File.basename(file)
        file_mappings << {
          source: file,
          destination: File.join(Config.commands_dir, "wshobson-#{filename}"),
          display_name: "wshobson-#{filename}"
        }
      end

      file_mappings
    end

    def process_awesome_agent_files(source_dir)
      categories_dir = File.join(source_dir, "categories")
      return [] unless Dir.exist?(categories_dir)

      file_mappings = []

      # Find all .md files in categories directory
      Dir.glob(File.join(categories_dir, "**/*.md")).each do |file|
        next if should_skip_file?(file)

        # Get relative path from categories directory
        rel_path = Pathname.new(file).relative_path_from(Pathname.new(categories_dir))

        # Extract category folder name and remove numeric prefix
        category_folder = rel_path.dirname.to_s
        category_name = category_folder.split("-", 2).last # Remove everything up to and including first dash
        filename = File.basename(file)

        # Create flattened filename with category prefix
        flattened_filename = if category_name == "."
                               filename
                             else
                               "#{category_name}-#{filename}"
                             end

        file_mappings << {
          source: file,
          destination: File.join(Config.agents_dir, flattened_filename),
          display_name: flattened_filename
        }
      end

      file_mappings
    end

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
      when :wshobson_agents
        process_wshobson_agent_files(source_dir)
      when :wshobson_commands
        process_wshobson_command_files(source_dir)
      when :awesome
        process_awesome_agent_files(source_dir)
      when :test
        # For testing purposes, use generic file processing
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
        if prefix
          prefixed_filename = "#{prefix}#{filename}"
        else
          prefixed_filename = filename
        end
        directory = File.dirname(relative_path)
        return File.join(destination_dir, directory, prefixed_filename)
      end

      # For other paths with directories, apply prefix first then flatten
      if relative_path.include?("/")
        directory = File.dirname(relative_path)
        filename = File.basename(relative_path)

        # Apply prefix to filename first
        if prefix
          prefixed_filename = "#{prefix}#{filename}"
        else
          prefixed_filename = filename
        end

        # Then create flattened name only if no prefix (for category flattening)
        if prefix
          final_filename = prefixed_filename
        else
          final_filename = "#{directory}-#{prefixed_filename}"
        end
      else
        if prefix
          final_filename = "#{prefix}#{relative_path}"
        else
          final_filename = relative_path
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
