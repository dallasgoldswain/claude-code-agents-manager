# frozen_string_literal: true

module ClaudeAgents
  class FileProcessor
    # Routing logic for selecting the correct file-mapping processor per component.
    module ComponentMappings
      def get_file_mappings_for_component(component)
        key = component.to_sym
        info = Config.component_info(key)
        raise ValidationError, "Unknown component: #{key}" unless info

        source_dir = validate_source_directory(key)
        processor_for(info[:processor], key).call(key, source_dir, info)
      end

      private

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
    end
  end
end
