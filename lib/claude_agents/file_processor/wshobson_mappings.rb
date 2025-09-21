# frozen_string_literal: true

module ClaudeAgents
  class FileProcessor
    # Mapping helpers for wshobson command collections.
    module WshobsonMappings
      def process_wshobson_command_files(source_dir)
        return [] unless Dir.exist?(source_dir)

        [].tap do |mappings|
          mappings.concat(command_tool_mappings(source_dir))
          mappings.concat(command_workflow_mappings(source_dir))
          mappings.concat(command_root_mappings(source_dir))
        end
      end

      private

      def command_tool_mappings(source_dir)
        tools_root = File.join(source_dir, 'tools')
        return [] unless Dir.exist?(tools_root)

        recursive_command_mappings(tools_root, Config.tools_dir, 'tools')
      end

      def command_workflow_mappings(source_dir)
        workflows_root = File.join(source_dir, 'workflows')
        return [] unless Dir.exist?(workflows_root)

        recursive_command_mappings(workflows_root, Config.workflows_dir, 'workflows')
      end

      def command_root_mappings(source_dir)
        Dir.glob(File.join(source_dir, '*')).each_with_object([]) do |file, memo|
          next unless eligible_command_file?(file)

          filename = File.basename(file)
          memo << build_mapping(
            file,
            File.join(Config.commands_dir, "wshobson-#{filename}"),
            "wshobson-#{filename}"
          )
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

      def recursive_command_mappings(source_root, dest_root, prefix)
        Dir.glob(File.join(source_root, '**', '*')).each_with_object([]) do |file, memo|
          next unless eligible_command_file?(file)

          relative = file.sub(%r{^#{Regexp.escape(source_root)}/?}, '')
          destination_dir = File.join(dest_root, File.dirname(relative))
          FileUtils.mkdir_p(destination_dir)
          memo << build_mapping(
            file,
            File.join(destination_dir, File.basename(file)),
            File.join(prefix, relative)
          )
        end
      end
    end
  end
end
