# Claude Agents Collection

A comprehensive agent management system that aggregates multiple Claude Code agent collections into a unified workspace, providing access to 200+ specialized AI agents and automation tools.

## Overview

This repository combines the best Claude Code agents from multiple sources:

- **dallasLabs Collection** (5 agents) - Specialized agents for Django, JavaScript/TypeScript, data analysis, Python backend, and debugging
- **wshobson Collection** (82 agents) - Production-ready subagents covering the full software development lifecycle
- **Awesome Claude Code Subagents** (116 agents) - Industry-standard subagents organized by domain
- **wshobson Commands** (56 tools/workflows) - Multi-agent orchestration and automation commands

## Quick Start

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and configured
- [GitHub CLI](https://cli.github.com/) (`gh`) for repository cloning
- Ruby 3.0+ (for the enhanced CLI experience)
- Git for repository management

### Installation

```bash
# Clone this repository
git clone <your-repo-url>
cd claude-agents

# Install Ruby dependencies
bundle install

# Run the enhanced Ruby CLI installer (recommended)
./bin/claude-agents install

# Legacy installer (deprecated - use Ruby CLI above)
./install.sh
```

**🚀 The Ruby CLI provides:**
- Interactive component selection
- Beautiful colored output with progress indicators
- System health diagnostics
- Safe operations with confirmation prompts
- Comprehensive error handling

This will:

1. Clone all external agent repositories into the `agents/` directory
2. Set up organized symlinks in `~/.claude/agents/` and `~/.claude/commands/`
3. Make all 200+ agents immediately available in Claude Code

### Manual Setup

**Ruby CLI (Recommended):**
```bash
# Individual component setup
./bin/claude-agents setup dlabs
./bin/claude-agents setup wshobson-agents
./bin/claude-agents setup wshobson-commands
./bin/claude-agents setup awesome

# Check installation status
./bin/claude-agents status

# System health check
./bin/claude-agents doctor
```

**Legacy Bash Scripts (Deprecated):**
```bash
# Complete setup (use Ruby CLI instead)
./install.sh

# Individual component setup (use ./bin/claude-agents setup <component> instead)
./bin/setup_agents.sh                      # dLabs agents
./bin/setup_wshobson_agents_symlinks.sh    # wshobson agents
./bin/setup_wshobson_commands_symlinks.sh  # wshobson commands
./bin/setup_awesome_agents_symlinks.sh     # Awesome Claude Code subagents
```

## Agent Organization

### Naming Conventions

All agents are prefixed by their source for easy identification:

- `dLabs-*` - dLabs agents (local)
- `wshobson-*` - wshobson collection agents
- `{category}-*` - Awesome Claude Code subagents (e.g., `data-ai-ml-engineer`)

### Directory Structure

```
~/.claude/
├── agents/                     # All agents (200+)
│   ├── dLabs-*                # dLabs (5)
│   ├── wshobson-*             # wshobson agents (82)
│   └── {category}-*           # Categorized agents (116)
└── commands/                   # Automation tools
    ├── tools/                 # Single-purpose utilities (41)
    └── workflows/             # Multi-agent orchestration (15)
```

## Available Agent Categories

### Core Development

- **Languages**: Python, JavaScript/TypeScript, Java, Go, Rust, C++, PHP, etc.
- **Frameworks**: Django, React, Angular, Spring Boot, Laravel, Flutter, etc.
- **Architecture**: Backend, Frontend, Full-stack, Microservices, APIs

### Infrastructure & DevOps

- **Cloud**: AWS, Azure, GCP architects
- **Containers**: Docker, Kubernetes specialists
- **Deployment**: CI/CD, Terraform, Infrastructure as Code
- **Monitoring**: SRE, Performance, Security

### Specialized Domains

- **Data & AI**: ML engineers, Data scientists, Analytics experts
- **Security**: Auditors, Penetration testers, Compliance
- **Business**: Product managers, Technical writers, Legal advisors

### Quality Assurance

- **Testing**: Automation, TDD, QA experts
- **Code Review**: Architecture review, Performance optimization
- **Debugging**: Error detection, Troubleshooting specialists

## Multi-Agent Workflows

The wshobson commands enable sophisticated multi-agent orchestration:

### Workflows (15 available)

- `feature-development` - Full feature implementation with multiple agents
- `security-hardening` - Comprehensive security review and implementation
- `performance-optimization` - Multi-faceted performance improvements
- `incident-response` - Coordinated incident management

### Tools (41 available)

- `api-scaffold` - Generate API structures
- `security-scan` - Automated security analysis
- `deploy-checklist` - Pre-deployment verification
- `tech-debt` - Technical debt assessment

## Usage Examples

### Using Individual Agents

```bash
# In Claude Code, invoke agents by name:
@dLabs-django-developer "Help me optimize this Django view"
@wshobson-security-auditor "Review this authentication code"
@data-ai-ml-engineer "Design a machine learning pipeline"
```

### Using Workflows

```bash
# Execute multi-agent workflows:
/feature-development "Implement user authentication with OAuth"
/performance-optimization "Optimize database queries and caching"
/security-hardening "Secure the payment processing system"
```

## Repository Structure

```
claude-agents/
├── bin/                                    # Scripts and executables
│   ├── claude-agents                       # Ruby CLI (primary interface)
│   ├── test                                # Test runner script
│   ├── install.sh                          # Legacy bash installer (deprecated)
│   ├── setup_*.sh                          # Legacy setup scripts (deprecated)
│   └── remove_*.sh                         # Legacy removal scripts (deprecated)
├── lib/                                    # Ruby CLI implementation
├── test/                                   # Test suite (unit & integration)
├── Gemfile                                 # Ruby dependencies
├── Rakefile                                # Development and testing tasks
└── agents/                                 # Agent collections (auto-created)
    ├── dallasLabs/                         # Local agent definitions
    ├── awesome-claude-code-subagents/      # VoltAgent collection
    ├── wshobson-agents/                    # wshobson agent collection
    └── wshobson-commands/                  # wshobson command collection
```

## CLI Interface

### Ruby CLI Commands

```bash
# Installation and setup
./bin/claude-agents install                 # Interactive installation
./bin/claude-agents setup <component>       # Setup specific component

# Management
./bin/claude-agents status                  # Show installation status
./bin/claude-agents remove <component>      # Remove component
./bin/claude-agents doctor                  # System health check

# Information
./bin/claude-agents version                 # Show version
./bin/claude-agents help                    # Show help
```

## Development Workflow

### Rake Tasks

The project includes comprehensive Rake tasks for development, testing, and quality assurance:

#### Testing Tasks

```bash
# Run all tests
rake test                                   # Run complete test suite
rake test:all                               # Same as above
rake test:unit                              # Unit tests only
rake test:integration                       # Integration tests only

# Specialized test runs
rake test:performance                       # Performance-focused tests
rake test:coverage                          # Tests with coverage reporting
rake test:fast_fail                         # Stop on first failure with minimal output
rake test:failures_only                     # Show only test failures
rake test:watch                             # Continuous testing (requires entr)

# Individual test execution
rake test:file[path/to/test_file.rb]        # Run specific test file
rake test:method[TestClass,test_method]     # Run specific test method

# Test reporting
rake test:report                            # Generate detailed test report
```

#### Code Quality Tasks

```bash
# Linting
rake rubocop                                # Run RuboCop linter
rake rubocop:autocorrect                    # Auto-fix RuboCop issues
rake rubocop:autocorrect_all                # Auto-fix all issues (including unsafe)
```

#### Development Tasks

```bash
# Environment setup
rake dev:setup                             # Setup development environment
rake dev:clean                             # Clean test artifacts
rake dev:check                             # Full check (tests + linting)
rake dev:benchmark                          # Benchmark test execution time

# Default task
rake                                        # Run tests + linting
```

#### CI/CD Tasks

```bash
# Continuous Integration
rake ci:local                               # Run full CI pipeline locally
rake ci:quick                               # Quick CI check (unit tests + linting)
```

#### Documentation Tasks

```bash
# Documentation generation
rake doc:tests                              # Generate test documentation
```

### Architecture Overview

The Ruby CLI is built using a service-oriented architecture:

```
lib/
├── claude_agents.rb                        # Main module with version
├── claude_agents_cli.rb                    # Thor-based CLI interface
└── claude_agents/
    ├── config.rb                           # Centralized configuration
    ├── installer.rb                        # Component installation service
    ├── remover.rb                           # Component removal service
    ├── symlink_manager.rb                  # Symlink creation and management
    ├── file_processor.rb                   # File processing and naming
    ├── ui.rb                               # TTY-based user interface
    └── errors.rb                           # Custom error classes
```

**Service Layer Design:**
- **Config**: Manages component definitions and paths
- **Installer**: Handles repository cloning and setup
- **Remover**: Manages safe component removal
- **SymlinkManager**: Creates organized symlink structures
- **FileProcessor**: Applies naming conventions and file transformations
- **UI**: Provides colored output, progress indicators, and user interaction

### Testing Architecture

The project implements a comprehensive testing strategy:

```
test/
├── test_helper.rb                          # Test configuration and setup
├── minitest.rb                             # Minitest configuration
├── unit/                                   # Unit tests for individual components
│   ├── config_test.rb
│   ├── file_processor_test.rb
│   ├── symlink_manager_test.rb
│   └── error_handling_test.rb
├── integration/                            # Integration tests for CLI commands
│   └── cli_commands_test.rb
└── support/                                # Test utilities and helpers
    ├── cli_helpers.rb
    ├── filesystem_helpers.rb
    └── test_fixtures.rb
```

**Testing Features:**
- **Minitest-based**: Using Ruby's built-in testing framework
- **Isolated environments**: Each test uses temporary directories
- **CLI testing**: Full command-line interface testing with real file operations
- **Performance monitoring**: Execution time tracking and benchmarking
- **Coverage reporting**: Optional test coverage analysis

## Updating Collections

**Ruby CLI (Recommended):**
```bash
# Reinstall with latest updates
./bin/claude-agents install

# Or manually update repositories
./bin/claude-agents doctor  # Check repository status
```

**Manual Repository Updates:**
```bash
# Update individual collections manually
cd agents/awesome-claude-code-subagents && git pull && cd ../..
cd agents/wshobson-agents && git pull && cd ../..
cd agents/wshobson-commands && git pull && cd ../..

# Legacy installer (deprecated - use Ruby CLI instead)
./install.sh
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:

- Adding new dLabs agents
- Reporting issues with external collections
- Improving setup scripts and documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [VoltAgent](https://github.com/VoltAgent) - awesome-claude-code-subagents collection
- [wshobson](https://github.com/wshobson) - agents and commands collections
- [Anthropic](https://www.anthropic.com) - Claude Code platform

## Support

For issues related to:

- **This repository**: Open an issue here
- **External collections**: Refer to their respective repositories
- **Claude Code**: See [official documentation](https://docs.anthropic.com/en/docs/claude-code)

---

**Total Available**: 203 agents + 56 commands across all development domains
