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
- Ruby 3.0+ for the Ruby CLI and testing
- Bundler for dependency management

### Development Setup

1. Fork the repository
2. Clone your fork:

   ```bash
   git clone <your-fork-url>
   cd claude-agents
   ```

3. Install Ruby dependencies:

   ```bash
   bundle install
   ```

4. Run the installation to understand the current structure:

   ```bash
   ./bin/claude-agents install
   ```

5. Create a feature branch:

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

1. Create agent in `agents/dallasLabs/` directory
2. Run setup using Ruby CLI:

   ```bash
   ./bin/claude-agents setup dlabs
   ```

3. Test in Claude Code:

   ```bash
   # Verify agent is available
   ls ~/.claude/agents/dLabs-*

   # Test agent invocation in Claude Code
   @dLabs-your-agent-name "test prompt"
   ```

4. Run the test suite to ensure everything works:

   ```bash
   # Run all tests
   rake test

   # Run specific test suites
   rake test:unit
   rake test:integration

   # Run with custom test runner
   bin/test --verbose
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

#### Ruby CLI Testing (Recommended)

Use the comprehensive test suite for development:

```bash
# Run all tests (91+ tests)
rake test

# Run specific test categories
rake test:unit                              # Unit tests (70+ tests)
rake test:integration                       # Integration tests (21+ tests)
rake test:performance                       # Performance-focused tests

# Run with specific options
rake test:fast_fail                         # Stop on first failure
rake test:failures_only                     # Show only failures
rake test:watch                             # Continuous testing

# Use custom test runner
bin/test                                    # All tests
bin/test --suite unit                       # Specific suite
bin/test --verbose --parallel               # With options
```

#### Manual Testing in Clean Environment

For manual verification:

```bash
# Remove existing symlinks for testing
./bin/claude-agents remove dlabs
./bin/claude-agents remove wshobson-agents
./bin/claude-agents remove wshobson-commands
./bin/claude-agents remove awesome

# Test individual components
./bin/claude-agents setup dlabs
./bin/claude-agents setup wshobson-agents
./bin/claude-agents setup wshobson-commands
./bin/claude-agents setup awesome

# Test complete installation
./bin/claude-agents install

# Check system health
./bin/claude-agents doctor
```

#### Legacy Script Testing (Deprecated)

For backward compatibility testing:

```bash
# Remove existing symlinks for testing
rm -rf ~/.claude/agents/dLabs-*
rm -rf ~/.claude/commands/wshobson-*

# Test individual legacy scripts (deprecated)
./bin/setup_agents.sh
./bin/setup_wshobson_agents_symlinks.sh
./bin/setup_wshobson_commands_symlinks.sh
./bin/setup_awesome_agents_symlinks.sh

# Test legacy installer (deprecated)
./bin/install.sh
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

## Testing Requirements

### Test-Driven Development

This project follows TDD principles:

- **Write tests first**: All new functionality requires tests before implementation
- **Real data only**: No mocking - tests use actual file operations and CLI execution
- **Comprehensive coverage**: Unit tests, integration tests, and performance tests required
- **Performance thresholds**: Critical operations must complete under 1s, memory usage under 50MB

### Testing Standards

Before contributing code changes:

```bash
# All tests must pass
rake test

# Code quality checks
bundle exec rubocop

# Performance verification
rake test:performance

# Manual CLI testing
./bin/claude-agents doctor
```

### Test Documentation

For detailed testing information, see [TESTING.md](TESTING.md). The testing guide includes:

- 91+ comprehensive tests across all functionality
- Test helpers and utilities for file operations, CLI testing, and performance monitoring
- Custom test runners and reporters
- Continuous testing workflows

## Pull Request Process

1. **Pre-submission Checklist:**
   - [ ] All tests pass (`rake test`)
   - [ ] Code quality checks pass (`bundle exec rubocop`)
   - [ ] All scripts execute without errors
   - [ ] Documentation updated if needed
   - [ ] CHANGELOG.md updated for significant changes
   - [ ] New agents tested in Claude Code
   - [ ] Code follows project style guidelines
   - [ ] Performance tests pass for any optimizations

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
