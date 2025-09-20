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
        build_command_mappings(File.join(source_dir, 'tools')) do |file|
          filename = File.basename(file)
          build_mapping(file, File.join(Config.tools_dir, filename), "tools/#{filename}")
        end
      end

      def command_workflow_mappings(source_dir)
        build_command_mappings(File.join(source_dir, 'workflows')) do |file|
          filename = File.basename(file)
          build_mapping(file, File.join(Config.workflows_dir, filename), "workflows/#{filename}")
        end
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
    end
  end
end
