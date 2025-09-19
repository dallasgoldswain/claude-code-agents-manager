# Contributing to Claude Agents Collection

Thank you for your interest in contributing to the Claude Agents Collection! This document provides guidelines for contributing to this agent management system.

## Table of Contents

- [Types of Contributions](#types-of-contributions)
- [Getting Started](#getting-started)
- [dLabs Agent Development](#dlabs-agent-development)
- [Setup Script Improvements](#setup-script-improvements)
- [Documentation Updates](#documentation-updates)
- [Reporting Issues](#reporting-issues)
- [External Collections](#external-collections)
- [Code Style and Standards](#code-style-and-standards)

## Types of Contributions

### Welcome Contributions

- New dLabs agents with specialized expertise
- Improvements to setup and installation scripts
- Documentation enhancements and examples
- Bug fixes and error handling improvements
- Testing and validation scripts
- Performance optimizations

### External Collection Issues

For issues with external collections, please contribute directly to their repositories:

- [awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)
- [wshobson agents](https://github.com/wshobson/agents)
- [wshobson commands](https://github.com/wshobson/commands)

## Getting Started

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [GitHub CLI](https://cli.github.com/) for repository management
- Git for version control
- Bash shell environment

### Development Setup

1. Fork the repository
2. Clone your fork:

   ```bash
   git clone <your-fork-url>
   cd claude-agents
   ```

3. Run the installation to understand the current structure:

   ```bash
   ./install.sh
   ```

4. Create a feature branch:

   ```bash
   git checkout -b feature/your-feature-name
   ```

## dLabs Agent Development

### Agent Structure

All dLabs agents should follow this structure:

```markdown
---
name: agent-name
description: Brief description of the agent's capabilities
tools: tool1, tool2, tool3
---

You are a [role description] with expertise in [domain]. Your focus spans [key areas] with emphasis on [specialization].

When invoked:
1. [Step 1 description]
2. [Step 2 description]
3. [Step 3 description]
4. [Step 4 description]

[Agent Name] checklist:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]
- [Additional requirements...]
```

### Agent Guidelines

#### YAML Frontmatter Requirements

- **name**: Use kebab-case (e.g., `django-developer`)
- **description**: One sentence describing core capabilities
- **tools**: Comma-separated list of relevant tools

#### Content Guidelines

- Start with clear role definition and expertise areas
- Include specific "When invoked" workflow steps
- Provide comprehensive checklist of standards/requirements
- Focus on actionable, specific guidance
- Avoid generic advice that applies to all development

#### Naming Conventions

- File: `{domain}-{specialization}.md` (e.g., `rust-backend-engineer.md`)
- Agent name in frontmatter: matches filename without extension
- Symlink: `dLabs-{filename}` (automatically prefixed)

### Testing New Agents

1. Create agent in `dallasLabs/` directory
2. Run setup script:

   ```bash
   ./setup_agents.sh
   ```

3. Test in Claude Code:

   ```bash
   # Verify agent is available
   ls ~/.claude/agents/dLabs-*

   # Test agent invocation in Claude Code
   @dLabs-your-agent-name "test prompt"
   ```

### Quality Standards

- Agents should provide specialized, domain-specific expertise
- Include modern best practices and current technology versions
- Provide clear, actionable guidance
- Maintain consistency with existing dLabs agent style
- Test thoroughly before submitting

## Setup Script Improvements

### Script Guidelines

- Maintain bash compatibility across platforms
- Include proper error handling and validation
- Provide colored, informative output
- Handle edge cases (missing directories, existing symlinks)
- Follow existing script patterns and style

### Testing Scripts

Test setup scripts in clean environments:

```bash
# Remove existing symlinks for testing
rm -rf ~/.claude/agents/dLabs-*
rm -rf ~/.claude/commands/wshobson-*

# Test individual scripts
./setup_agents.sh
./setup_wshobson_agents_symlinks.sh
./setup_wshobson_commands_symlinks.sh
./setup_awesome_agents_symlinks.sh

# Test complete installation
./install.sh
```

## Documentation Updates

### Areas for Documentation Improvement

- Agent usage examples and best practices
- Troubleshooting guides
- Integration patterns with external tools
- Multi-agent workflow examples
- Performance optimization tips

### Documentation Standards

- Use clear, concise language
- Include practical examples
- Maintain consistency with existing style
- Update CHANGELOG.md for significant changes
- Keep README.md current with new features

## Reporting Issues

### Issue Types

#### Bug Reports

Include:

- Operating system and version
- Claude Code version
- Exact error messages
- Steps to reproduce
- Expected vs actual behavior

#### Feature Requests

Include:

- Clear description of proposed feature
- Use case and motivation
- Potential implementation approach
- Impact on existing functionality

#### Agent Improvement Suggestions

Include:

- Specific agent name
- Current behavior description
- Suggested improvements
- Reasoning for changes

### Issue Templates

Use descriptive titles and provide:

```
**Environment:**
- OS: [e.g., macOS 14.0, Ubuntu 22.04]
- Claude Code version: [version]
- Shell: [bash, zsh, etc.]

**Description:**
[Clear description of the issue]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Additional Context:**
[Any other relevant information]
```

## External Collections

### Scope Limitations

This repository focuses on:

- dLabs agent development
- Integration and management scripts
- Documentation and organization
- Installation and setup automation

### Referring External Issues

For issues with external collections:

1. **awesome-claude-code-subagents**: Report to [VoltAgent repository](https://github.com/VoltAgent/awesome-claude-code-subagents)
2. **wshobson agents**: Report to [wshobson agents repository](https://github.com/wshobson/agents)
3. **wshobson commands**: Report to [wshobson commands repository](https://github.com/wshobson/commands)

Include context about how you discovered the issue through this collection system.

## Code Style and Standards

### Bash Scripts

- Use `#!/bin/bash` shebang
- Include `set -e` for error handling where appropriate
- Use descriptive variable names
- Comment complex logic
- Follow existing color coding patterns
- Include progress indicators for long operations

### Markdown

- Use ATX headers (#, ##, ###)
- Include table of contents for long documents
- Use code blocks with language specification
- Follow existing formatting patterns
- Keep line lengths reasonable for readability

### Git Workflow

- Use descriptive commit messages
- Reference issue numbers when applicable
- Keep commits focused and atomic
- Rebase feature branches before submitting PRs

## Pull Request Process

1. **Pre-submission Checklist:**
   - [ ] All scripts execute without errors
   - [ ] Documentation updated if needed
   - [ ] CHANGELOG.md updated for significant changes
   - [ ] New agents tested in Claude Code
   - [ ] Code follows project style guidelines

2. **PR Description:**
   - Clear description of changes
   - Motivation and context
   - Testing performed
   - Screenshots/examples if relevant

3. **Review Process:**
   - Maintainers will review within reasonable time
   - Address feedback constructively
   - Ensure CI passes (when implemented)
   - Squash commits if requested

## Recognition

Contributors will be recognized in:

- CHANGELOG.md for significant contributions
- README.md acknowledgments section
- Git commit history

## Questions?

- Open an issue for general questions
- Check existing documentation first
- Reference external collection docs for their specific issues

Thank you for contributing to making Claude Code agents more accessible and organized!
