# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository is a comprehensive agent management system that aggregates multiple Claude Code agent collections into a unified workspace. It combines:

- **Dallas Labs agents** (`dallasLabs/`) - 5 specialized agents with focus on specific technologies
- **wshobson agents** (82 agents) - Production-ready subagents covering full software development lifecycle
- **awesome-claude-code-subagents** (116 agents) - Industry-standard subagents organized by domain
- **wshobson commands** (56 commands) - Workflows and tools for multi-agent orchestration

The repository provides automated setup scripts to clone external repositories and create organized symlink structures for seamless Claude Code integration.

## Agent Architecture

### Agent Definition Format
Each agent is defined in a markdown file with YAML frontmatter containing:
- `name`: Agent identifier
- `description`: Brief description of the agent's capabilities
- `tools`: List of tools the agent uses

The content includes specialized instructions, checklists, and behavior patterns for the agent.

### Agent Collections Structure

**Dallas Labs Agents** (`dallasLabs/` → `~/.claude/agents/dallas-*`)
- `dallas-django-developer.md` - Django 5+ with modern Python practices
- `dallas-js-ts-tech-lead.md` - JavaScript/TypeScript technical leadership
- `dallas-data-analysis-expert.md` - Data analysis and visualization
- `dallas-python-backend-engineer.md` - Python backend development
- `dallas-debug-specialist.md` - Debugging and troubleshooting

**External Collections** (prefixed by source)
- `wshobson-*` - 82 production-ready agents covering architecture, languages, domains
- Category-prefixed agents from awesome-claude-code-subagents (116 total)

## Setup and Development Commands

### Initial Installation
```bash
# Complete setup: clone repositories and configure all symlinks
./install.sh
```

### Individual Setup Scripts
```bash
# Dallas Labs agents
./setup_agents.sh

# wshobson agents (with wshobson- prefix)
./setup_wshobson_agents_symlinks.sh

# wshobson commands (tools/ and workflows/ directories)
./setup_wshobson_commands_symlinks.sh

# awesome-claude-code-subagents (category-prefixed)
./setup_awesome_agents_symlinks.sh
```

### Repository Management
```bash
# Update all external repositories
cd awesome-claude-code-subagents && git pull && cd ..
cd wshobson-agents && git pull && cd ..
cd wshobson-commands && git pull && cd ..
```

## Agent Organization

### Destination Structure
- **Agents**: `~/.claude/agents/` with source prefixes (dallas-, wshobson-, category-)
- **Commands**: `~/.claude/commands/tools/` and `~/.claude/commands/workflows/`

### Naming Conventions
- Dallas Labs: `dallas-{agent-name}.md`
- wshobson: `wshobson-{agent-name}.md`
- External: `{category}-{agent-name}.md`

## Development Workflow

### Adding New Dallas Labs Agents
1. Create agent definition in `dallasLabs/` with YAML frontmatter
2. Run `./setup_agents.sh` to create symlinks
3. Test agent through Claude Code interface

### Updating External Collections
1. Use `./install.sh` to pull latest versions
2. Existing symlinks are preserved unless explicitly recreated
3. New agents from updates are automatically linked

### Multi-Agent Orchestration
- Use wshobson commands for complex workflows
- Commands coordinate multiple agents for full-stack operations
- Tools provide focused, single-purpose functionality

## Repository Structure

```
├── install.sh                              # Main installation script
├── dallasLabs/                             # Local agent definitions
├── awesome-claude-code-subagents/          # External: VoltAgent collection
├── wshobson-agents/                        # External: wshobson agent collection
├── wshobson-commands/                      # External: wshobson command collection
└── setup_*.sh                             # Individual setup scripts
```

The system maintains separation between local (`dallasLabs`) and external collections while providing unified access through Claude Code.