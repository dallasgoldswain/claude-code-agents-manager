# frozen_string_literal: true

module ClaudeAgents
  class FileProcessor
    # Mapping helpers for awesome-claude-code category-based agents.
    module AwesomeMappings
      def process_awesome_agent_files(source_dir)
        categories_dir = File.join(source_dir, 'categories')
        return [] unless Dir.exist?(categories_dir)

        awesome_markdown_files(categories_dir).map do |file|
          flattened = flattened_category_filename(categories_dir, file)
          build_mapping(file, File.join(Config.agents_dir, flattened), flattened)
        end
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
    end
  end
end
