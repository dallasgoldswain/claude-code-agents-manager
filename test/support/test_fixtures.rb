# ABOUTME: Test fixture management for creating realistic test data
# ABOUTME: Provides agent files, directory structures, and component configurations

# frozen_string_literal: true

module TestFixtures
  # Agent file fixtures
  SAMPLE_AGENT_CONTENT = <<~AGENT
    ---
    name: sample-agent
    description: A sample agent for testing
    tools: ['editor', 'bash']
    ---

    # Sample Agent

    This is a sample agent used for testing the Claude Agents CLI.

    ## Capabilities

    - File editing
    - Bash command execution
    - Test automation

    ## Usage

    Use this agent for general development tasks.
  AGENT

  DLABS_AGENT_CONTENT = <<~AGENT
    ---
    name: dlabs-test-agent
    description: dLabs test agent
    tools: ['editor']
    ---

    # dLabs Test Agent

    Specialized test agent for dLabs collection.
  AGENT

  WSHOBSON_AGENT_CONTENT = <<~AGENT
    ---
    name: test-backend-engineer
    description: Backend engineering agent
    tools: ['editor', 'bash', 'database']
    ---

    # Backend Engineer Agent

    Production-ready backend development agent.
  AGENT

  AWESOME_AGENT_CONTENT = <<~AGENT
    ---
    name: frontend-developer
    description: Frontend development specialist
    tools: ['editor', 'browser']
    ---

    # Frontend Developer

    Industry-standard frontend development agent.
  AGENT

  # Directory structure fixtures
  def self.create_dlabs_fixture(base_dir)
    dlabs_dir = File.join(base_dir, "agents", "dallasLabs")
    FileUtils.mkdir_p(dlabs_dir)

    agents = %w[
      django-developer.md
      js-ts-tech-lead.md
      data-analysis-expert.md
      python-backend-engineer.md
      debug-specialist.md
    ]

    agents.each do |agent|
      File.write(File.join(dlabs_dir, agent), DLABS_AGENT_CONTENT)
    end

    dlabs_dir
  end

  def self.create_wshobson_agents_fixture(base_dir)
    agents_dir = File.join(base_dir, "agents", "wshobson-agents")
    FileUtils.mkdir_p(agents_dir)

    # Create a subset of agents for testing
    agents = %w[
      backend-engineer.md
      frontend-developer.md
      devops-specialist.md
      qa-engineer.md
      architect.md
    ]

    agents.each do |agent|
      File.write(File.join(agents_dir, agent), WSHOBSON_AGENT_CONTENT)
    end

    agents_dir
  end

  def self.create_wshobson_commands_fixture(base_dir)
    commands_dir = File.join(base_dir, "agents", "wshobson-commands")
    tools_dir = File.join(commands_dir, "tools")
    workflows_dir = File.join(commands_dir, "workflows")

    FileUtils.mkdir_p([tools_dir, workflows_dir])

    # Create tool files
    tools = %w[
      git-workflow.md
      testing-suite.md
      deployment.md
    ]

    tools.each do |tool|
      content = <<~TOOL
        # #{File.basename(tool, '.md').gsub('-', ' ').split.map(&:capitalize).join(' ')}

        Tool for #{File.basename(tool, '.md')}.
      TOOL
      File.write(File.join(tools_dir, tool), content)
    end

    # Create workflow files
    workflows = %w[
      full-stack-development.md
      ci-cd-pipeline.md
    ]

    workflows.each do |workflow|
      content = <<~WORKFLOW
        # #{File.basename(workflow, '.md').gsub('-', ' ').split.map(&:capitalize).join(' ')}

        Workflow for #{File.basename(workflow, '.md')}.
      WORKFLOW
      File.write(File.join(workflows_dir, workflow), content)
    end

    commands_dir
  end

  def self.create_awesome_agents_fixture(base_dir)
    awesome_dir = File.join(base_dir, "agents", "awesome-claude-code-subagents")
    FileUtils.mkdir_p(awesome_dir)

    # Create category-based structure
    categories = {
      "frontend" => %w[react-developer.md vue-specialist.md],
      "backend" => %w[api-architect.md database-expert.md],
      "devops" => %w[kubernetes-expert.md terraform-specialist.md]
    }

    categories.each do |category, agents|
      category_dir = File.join(awesome_dir, "categories", category)
      FileUtils.mkdir_p(category_dir)

      agents.each do |agent|
        File.write(File.join(category_dir, agent), AWESOME_AGENT_CONTENT)
      end
    end

    awesome_dir
  end

  # Component configuration for testing
  def self.create_full_test_structure(base_dir)
    {
      dlabs: create_dlabs_fixture(base_dir),
      wshobson_agents: create_wshobson_agents_fixture(base_dir),
      wshobson_commands: create_wshobson_commands_fixture(base_dir),
      awesome: create_awesome_agents_fixture(base_dir)
    }
  end

  # Mock repository for git testing
  def self.create_mock_repository(repo_dir, files = {})
    FileUtils.mkdir_p(repo_dir)

    Dir.chdir(repo_dir) do
      system("git init --quiet")
      system('git config user.name "Test User"')
      system('git config user.email "test@example.com"')

      files.each do |filename, content|
        File.write(filename, content)
        system("git add #{filename}")
      end

      system('git commit -m "Initial commit" --quiet')
    end

    repo_dir
  end

  # Error simulation fixtures
  def self.create_permission_denied_directory(path)
    FileUtils.mkdir_p(path)
    File.chmod(0o444, path) # Read-only
  end

  def self.create_broken_symlink(link_path, target_path)
    FileUtils.mkdir_p(File.dirname(link_path))
    File.symlink(target_path, link_path)
    # Don't create the target, making it a broken symlink
  end

  # Validation fixtures
  def self.invalid_yaml_agent_content
    <<~INVALID
      ---
      name: invalid-agent
      description: "Unclosed quote
      tools: [invalid, yaml
      ---

      # Invalid Agent

      This agent has invalid YAML frontmatter.
    INVALID
  end

  def self.minimal_valid_agent_content
    <<~MINIMAL
      ---
      name: minimal
      description: Minimal agent
      ---

      # Minimal Agent
    MINIMAL
  end
end
