# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository is a comprehensive agent management system that aggregates multiple Claude Code agent collections into a unified workspace. It combines:

- **dLabs agents** (`agents/dallasLabs/`) - 5 specialized agents with focus on specific technologies
- **wshobson agents** (82 agents) - Production-ready subagents covering full software development lifecycle
- **awesome-claude-code-subagents** (116 agents) - Industry-standard subagents organized by domain
- **wshobson commands** (56 commands) - Workflows and tools for multi-agent orchestration

The repository provides both a modern Ruby CLI (primary) and legacy bash scripts to clone external repositories and create organized symlink structures for seamless Claude Code integration.

## Agent Architecture

### Agent Definition Format
Each agent is defined in a markdown file with YAML frontmatter containing:
- `name`: Agent identifier
- `description`: Brief description of the agent's capabilities
- `tools`: List of tools the agent uses

The content includes specialized instructions, checklists, and behavior patterns for the agent.

### Agent Collections Structure

**dLabs Agents** (`agents/dallasLabs/` → `~/.claude/agents/dLabs-*`)
- `dLabs-django-developer.md` - Django 5+ with modern Python practices
- `dLabs-js-ts-tech-lead.md` - JavaScript/TypeScript technical leadership
- `dLabs-data-analysis-expert.md` - Data analysis and visualization
- `dLabs-python-backend-engineer.md` - Python backend development
- `dLabs-debug-specialist.md` - Debugging and troubleshooting

**External Collections** (prefixed by source)
- `wshobson-*` - 82 production-ready agents covering architecture, languages, domains
- Category-prefixed agents from awesome-claude-code-subagents (116 total)

## Development Commands

### Ruby CLI (Primary Interface)

**Prerequisites:**
```bash
# Install Ruby dependencies
bundle install
```

**Main Commands:**
```bash
# Interactive installation and setup
./bin/claude-agents install

# Individual component management
./bin/claude-agents setup dlabs
./bin/claude-agents setup wshobson-agents
./bin/claude-agents setup wshobson-commands
./bin/claude-agents setup awesome

# System diagnostics and health check
./bin/claude-agents doctor

# Status and information
./bin/claude-agents status
./bin/claude-agents version

# Component removal
./bin/claude-agents remove dlabs
./bin/claude-agents remove wshobson-agents
```

**Code Quality:**
```bash
# Run RuboCop linting (required before commits)
bundle exec rubocop

# Auto-fix RuboCop issues
bundle exec rubocop -a

# Run RSpec tests (when available)
bundle exec rspec
```

**Testing and Debugging:**
```bash
# Test specific commands
./bin/claude-agents doctor    # System health diagnostics
./bin/claude-agents status    # Component installation status
./bin/claude-agents version   # Version and component info

# Debug CLI loading issues
DEBUG=1 ./bin/claude-agents <command>

# Ruby console for debugging
bundle exec pry
```

### Legacy Bash Scripts
```bash
# Complete setup (with deprecation warning)
./bin/install.sh

# Individual setup scripts
./bin/setup_agents.sh                     # dLabs agents
./bin/setup_wshobson_agents_symlinks.sh   # wshobson agents
./bin/setup_wshobson_commands_symlinks.sh # wshobson commands
./bin/setup_awesome_agents_symlinks.sh    # awesome agents

# Removal scripts
./bin/remove_dlabs_agents.sh
./bin/remove_wshobson_agents.sh
./bin/remove_wshobson_commands.sh
./bin/remove_awesome_agents.sh
```

### Repository Management
```bash
# Update external repositories (Ruby CLI recommended)
./bin/claude-agents doctor  # Shows repository status

# Manual updates
cd agents/awesome-claude-code-subagents && git pull && cd ../..
cd agents/wshobson-agents && git pull && cd ../..
cd agents/wshobson-commands && git pull && cd ../..
```

## Agent Organization

### Destination Structure
- **Agents**: `~/.claude/agents/` with source prefixes (dLabs-, wshobson-, category-)
- **Commands**: `~/.claude/commands/tools/` and `~/.claude/commands/workflows/`

### Naming Conventions
- dLabs: `dLabs-{agent-name}.md`
- wshobson: `wshobson-{agent-name}.md`
- External: `{category}-{agent-name}.md`

## Architecture and Design

### Ruby CLI Architecture
The Ruby CLI is built using a service-oriented architecture with Thor framework:

- **`CLI`** - Main Thor-based CLI interface in `lib/claude_agents/cli.rb`
  - Commands are defined directly in the main CLI class (not in modules due to Thor autoloading issues)
  - Uses `exit_on_failure?` method to suppress Thor deprecation warnings
- **`Config`** - Centralized configuration management using module extension pattern
  - `Config::Directories` - Path management (`project_root` uses `../../..` from config dir)
  - `Config::Components` - Component definitions with source/destination mappings
  - `Config::Repositories` - External repository URLs and metadata
  - `Config::SkipPatterns` - File filtering rules
- **Service Classes:**
  - `Installer` - Handles component installation and repository cloning
  - `Remover` - Manages component removal and cleanup
  - `SymlinkManager` - Creates and manages symlinks between source and destination
  - `FileProcessor` - Processes individual files and applies naming conventions
  - `UI` - TTY-based user interface with colored output and progress indicators
- **Error Classes:** Structured exception handling with specialized error types
- **Doctor System:** Modular health check system in `cli/doctor/` with individual check classes

### Component Configuration
Components are defined in `lib/claude_agents/config.rb` with:
- Repository URLs and local directories
- Source and destination paths
- Naming prefixes and conventions
- File skip patterns

### Development Workflow

**Adding New dLabs Agents:**
1. Create agent definition in `agents/dallasLabs/` with YAML frontmatter
2. Run `./bin/claude-agents setup dlabs` to create symlinks
3. Test agent through Claude Code interface

**Updating External Collections:**
1. Use `./bin/claude-agents install` for interactive updates
2. Use `./bin/claude-agents doctor` to check repository status
3. Existing symlinks are preserved unless explicitly recreated

**Code Development:**
- Follow Ruby style guide (enforced by RuboCop)
- Service classes handle specific responsibilities
- UI class provides consistent user experience with TTY gems
- Error classes provide structured exception handling
- Zeitwerk for autoloading and namespace management

**Critical Architecture Notes:**
- Thor command registration timing issues: Commands must be defined directly in CLI class, not in included modules
- `Config.project_root` path calculation is critical - it determines where doctor checks look for directories
- Repository status checks reference `Config::Repositories::REPOSITORIES` constant
- Doctor system uses modular check classes that inherit from `BaseCheck`

### Multi-Agent Orchestration
- wshobson commands enable complex multi-agent workflows
- Commands coordinate multiple agents for full-stack operations
- Tools provide focused, single-purpose functionality

## Repository Structure

```
├── bin/                                    # Executables and scripts
│   ├── claude-agents                       # Primary Ruby CLI
│   ├── install.sh                          # Legacy installer (deprecated)
│   └── setup_*.sh                          # Legacy setup scripts
├── lib/                                    # Ruby CLI implementation
│   ├── claude_agents.rb                    # Main module and version
│   └── claude_agents/                      # Service classes and modules
│       ├── cli.rb                          # Thor CLI interface
│       ├── config.rb                       # Configuration management
│       ├── installer.rb                    # Installation service
│       ├── remover.rb                      # Removal service
│       ├── symlink_manager.rb              # Symlink operations
│       ├── file_processor.rb               # File filtering and processing
│       ├── ui.rb                           # User interface with TTY gems
│       └── error*.rb                       # Error classes
├── agents/                                 # Agent collections (auto-created)
│   ├── dallasLabs/                         # Local agent definitions
│   ├── awesome-claude-code-subagents/      # External: VoltAgent collection
│   ├── wshobson-agents/                    # External: wshobson agent collection
│   └── wshobson-commands/                  # External: wshobson command collection
├── Gemfile                                 # Ruby dependencies
└── CHANGELOG.md                            # Version history
```

The system maintains separation between local (`agents/dallasLabs`) and external collections while providing unified access through Claude Code via organized symlinks in `~/.claude/agents/` and `~/.claude/commands/`.