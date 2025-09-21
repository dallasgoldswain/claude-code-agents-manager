# frozen_string_literal: true

module ClaudeAgents
  class Config
    # Repository metadata for upstream agent sources.
    module Repositories
      module_function

      REPOSITORIES = {
        awesome: {
          url: 'VoltAgent/awesome-claude-code-subagents',
          dir: 'agents/awesome-claude-code-subagents',
          description: '116 industry-standard agents'
        },
        wshobson_agents: {
          url: 'wshobson/agents',
          dir: 'agents/wshobson-agents',
          description: '82 production-ready agents'
        },
        wshobson_commands: {
          url: 'wshobson/commands',
          dir: 'agents/wshobson-commands',
          description: '56 workflow tools'
        }
      }.freeze

      # Individual repository constants expected by tests
      AWESOME_AGENTS = REPOSITORIES[:awesome].freeze
      WSHOBSON_AGENTS = REPOSITORIES[:wshobson_agents].freeze
      WSHOBSON_COMMANDS = REPOSITORIES[:wshobson_commands].freeze

      def repository_for(component)
        REPOSITORIES[component.to_sym]
      end
    end
  end
end
