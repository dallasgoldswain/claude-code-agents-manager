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

# Or use the legacy bash installer
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

**Legacy Bash Scripts:**
```bash
# dLabs agents only
./bin/setup_agents.sh

# wshobson agents
./bin/setup_wshobson_agents_symlinks.sh

# wshobson commands
./bin/setup_wshobson_commands_symlinks.sh

# Awesome Claude Code subagents
./bin/setup_awesome_agents_symlinks.sh
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
│   ├── install.sh                          # Legacy bash installer
│   ├── setup_agents.sh                     # dLabs agents setup
│   ├── setup_wshobson_agents_symlinks.sh   # wshobson agents setup
│   ├── setup_wshobson_commands_symlinks.sh # wshobson commands setup
│   ├── setup_awesome_agents_symlinks.sh    # awesome agents setup
│   └── remove_*.sh                         # Removal scripts
├── lib/                                    # Ruby CLI implementation
├── Gemfile                                 # Ruby dependencies
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

## Updating Collections

**Ruby CLI (Recommended):**
```bash
# Reinstall with latest updates
./bin/claude-agents install

# Or manually update repositories
./bin/claude-agents doctor  # Check repository status
```

**Legacy Method:**
```bash
# Update all external repositories
./bin/install.sh

# Or update individual collections
cd agents/awesome-claude-code-subagents && git pull && cd ../..
cd agents/wshobson-agents && git pull && cd ../..
cd agents/wshobson-commands && git pull && cd ../..
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
