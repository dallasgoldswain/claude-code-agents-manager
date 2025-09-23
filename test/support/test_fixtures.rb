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

  # Directory structure fixtures
  def self.create_dlabs_fixture(base_dir)
    # Mirror actual project structure: agents/dallasLabs/agents/*.md
    dlabs_dir = File.join(base_dir, "agents", "dallasLabs", "agents")
    FileUtils.mkdir_p(dlabs_dir)

    agents = %w[
      django-developer.md
      js-ts-tech-lead.md
      data-analysis-expert.md
      python-backend-engineer.md
      debug-specialist.md
      ruby-expert.md
      joker.md
    ]

    agents.each do |agent|
      File.write(File.join(dlabs_dir, agent), DLABS_AGENT_CONTENT)
    end

    dlabs_dir
  end

  # Component configuration for testing
  def self.create_full_test_structure(base_dir)
    {
      dlabs: create_dlabs_fixture(base_dir)
      # Other components omitted intentionally for dLabs-only test focus
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
