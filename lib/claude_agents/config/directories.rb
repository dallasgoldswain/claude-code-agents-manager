# frozen_string_literal: true

module ClaudeAgents
  class Config
    # Directory path helpers for managed Claude resources.
    module Directories
      module_function

      def claude_dir
        File.expand_path('~/.claude')
      end

      def agents_dir
        File.join(claude_dir, 'agents')
      end

      def commands_dir
        File.join(claude_dir, 'commands')
      end

      def tools_dir
        File.join(commands_dir, 'tools')
      end

      def workflows_dir
        File.join(commands_dir, 'workflows')
      end

      def project_root
        File.expand_path('../../..', __dir__)
      end

      def agents_source_dir
        File.join(project_root, 'agents')
      end

      def ensure_directories!
        [claude_dir, agents_dir, commands_dir, tools_dir, workflows_dir, agents_source_dir].each do |dir|
          FileUtils.mkdir_p(dir)
        end
      end

      def allowed_symlink_roots
        [agents_dir, commands_dir, tools_dir, workflows_dir].map { |dir| File.expand_path(dir) }.uniq
      end
    end
  end
end
