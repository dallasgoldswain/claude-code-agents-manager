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

    def process_prefixed_files(source_dir, destination_root:, prefix: nil)
      return [] unless Dir.exist?(source_dir)

      Dir.glob(File.join(source_dir, '*'))
         .select { |file| File.file?(file) }
         .reject { |file| should_skip_file?(file) }
         .map do |file|
        filename = File.basename(file)
        display_name = [prefix, filename].compact.join

        {
          source: file,
          destination: File.join(destination_root, display_name),
          display_name: display_name
        }
      end
    end

    def process_wshobson_command_files(source_dir)
      return [] unless Dir.exist?(source_dir)

      [].tap do |mappings|
        mappings.concat(command_tool_mappings(source_dir))
        mappings.concat(command_workflow_mappings(source_dir))
        mappings.concat(command_root_mappings(source_dir))
      end
    end

    def process_awesome_agent_files(source_dir)
      categories_dir = File.join(source_dir, 'categories')
      return [] unless Dir.exist?(categories_dir)

      awesome_markdown_files(categories_dir).map do |file|
        flattened = flattened_category_filename(categories_dir, file)
        build_mapping(file, flattened)
      end
    end

    def count_files_in_directory(directory)
      eligible_files_in_directory(directory).length
    end

    def validate_source_directory(component)
      source_dir = Config.source_dir_for(component)

      unless Dir.exist?(source_dir)
        raise ValidationError,
              "Source directory for #{component} does not exist: #{source_dir}. " \
              'Please run the installation first.'
      end

      source_dir
    end

    def get_file_mappings_for_component(component)
      key = component.to_sym
      info = Config.component_info(key)
      raise ValidationError, "Unknown component: #{key}" unless info

      source_dir = validate_source_directory(key)
      processor_for(info[:processor], key).call(key, source_dir, info)
    end

    def validate_file_mapping(mapping)
      source = mapping[:source]
      destination = mapping[:destination]

      raise FileOperationError, "Source file does not exist: #{source}" unless File.exist?(source)

      raise FileOperationError, "Source file is not readable: #{source}" unless File.readable?(source)

      # Ensure destination directory exists
      dest_dir = File.dirname(destination)
      FileUtils.mkdir_p(dest_dir) unless Dir.exist?(dest_dir)

      true
    end

    private

    def awesome_markdown_files(categories_dir)
      Dir.glob(File.join(categories_dir, '**/*.md')).reject { |file| should_skip_file?(file) }
    end

    def flattened_category_filename(categories_dir, file)
      rel_path = Pathname.new(file).relative_path_from(Pathname.new(categories_dir))
      category_name = rel_path.dirname.to_s.split('-', 2).last
      filename = File.basename(file)

      category_name && category_name != '.' ? "#{category_name}-#{filename}" : filename
    end

    def build_mapping(source, display_name)
      {
        source: source,
        destination: File.join(Config.agents_dir, display_name),
        display_name: display_name
      }
    end

    def processor_for(processor_key, component)
      {
        prefixed: method(:prefixed_component_mappings),
        wshobson_commands: method(:wshobson_command_mappings),
        awesome: method(:awesome_component_mappings)
      }.fetch(processor_key) do
        raise ValidationError, "Unknown processor for component: #{component}"
      end
    end

    def prefixed_component_mappings(component, source_dir, info)
      destination_dir = Config.destination_dir_for(component)
      process_prefixed_files(
        source_dir,
        destination_root: destination_dir,
        prefix: info[:prefix]
      )
    end

    def wshobson_command_mappings(_component, source_dir, _info)
      process_wshobson_command_files(source_dir)
    end

    def awesome_component_mappings(_component, source_dir, _info)
      process_awesome_agent_files(source_dir)
    end

    def command_tool_mappings(source_dir)
      build_command_mappings(File.join(source_dir, 'tools')) do |file|
        filename = File.basename(file)
        {
          source: file,
          destination: File.join(Config.tools_dir, filename),
          display_name: "tools/#{filename}"
        }
      end
    end

    def command_workflow_mappings(source_dir)
      build_command_mappings(File.join(source_dir, 'workflows')) do |file|
        filename = File.basename(file)
        {
          source: file,
          destination: File.join(Config.workflows_dir, filename),
          display_name: "workflows/#{filename}"
        }
      end
    end

    def command_root_mappings(source_dir)
      Dir.glob(File.join(source_dir, '*')).each_with_object([]) do |file, memo|
        next unless eligible_command_file?(file)

        filename = File.basename(file)
        memo << {
          source: file,
          destination: File.join(Config.commands_dir, "wshobson-#{filename}"),
          display_name: "wshobson-#{filename}"
        }
      end
    end

    def build_command_mappings(directory)
      return [] unless Dir.exist?(directory)

      Dir.glob(File.join(directory, '*')).each_with_object([]) do |file, memo|
        next unless eligible_command_file?(file)

        memo << yield(file)
      end
    end

    def eligible_command_file?(file)
      File.file?(file) && !should_skip_file?(file)
    end
  end
end
