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
- Git for repository management

### Installation

```bash
# Clone this repository
git clone <your-repo-url>
cd claude-agents

# Run the complete installation
./install.sh
```

This will:

1. Clone all external agent repositories
2. Set up organized symlinks in `~/.claude/agents/` and `~/.claude/commands/`
3. Make all 200+ agents immediately available in Claude Code

### Manual Setup

If you prefer individual setup:

```bash
# dallasLabs agents only
./setup_agents.sh

# wshobson agents
./setup_wshobson_agents_symlinks.sh

# wshobson commands
./setup_wshobson_commands_symlinks.sh

# Awesome Claude Code subagents
./setup_awesome_agents_symlinks.sh
```

## Agent Organization

### Naming Conventions

All agents are prefixed by their source for easy identification:

- `dallas-*` - dallasLabs agents (local)
- `wshobson-*` - wshobson collection agents
- `{category}-*` - Awesome Claude Code subagents (e.g., `data-ai-ml-engineer`)

### Directory Structure

```
~/.claude/
├── agents/                     # All agents (200+)
│   ├── dallas-*               # dallasLabs (5)
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
@dallas-django-developer "Help me optimize this Django view"
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

## Updating Collections

Keep all agent collections up to date:

```bash
# Update all external repositories
./install.sh

# Or update individual collections
cd awesome-claude-code-subagents && git pull && cd ..
cd wshobson-agents && git pull && cd ..
cd wshobson-commands && git pull && cd ..
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:

- Adding new dallasLabs agents
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
