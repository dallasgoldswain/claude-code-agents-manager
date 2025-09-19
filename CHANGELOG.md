# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-09-19

### Added

#### Interactive Installation System

- **Interactive install script** - Users can now choose which components to install
- **Automatic cleanup detection** - Detects existing installations and offers removal options
- **Component-specific prompts** - Individual yes/no prompts for each agent collection
- **Smart installation order** - Optimized installation sequence for better user experience

#### Removal Management

- **Complete removal system** with dedicated scripts for each collection:
  - `remove_dlabs_agents.sh` - Removes dLabs agent symlinks
  - `remove_wshobson_agents.sh` - Removes wshobson agent symlinks
  - `remove_awesome_agents.sh` - Removes awesome-claude-code-subagents symlinks
  - `remove_wshobson_commands.sh` - Removes wshobson command symlinks
- **Automatic cleanup integration** - Removal scripts integrated into install process
- **Safe removal logic** - Validates symlinks before removal, handles edge cases
- **Progress feedback** - Colored output with removal summaries and statistics

#### Branding Updates

- **dLabs rebranding** - Changed all "dallas-" prefixes to "dLabs-" for better branding
- **Consistent naming** - Updated all scripts, documentation, and examples
- **Agent prefix migration** - All Dallas Labs agents now use `dLabs-` prefix

### Changed

#### Installation Experience

- **install.sh** - Complete rewrite with interactive prompts and user choice
- **User-driven installation** - No longer installs everything by default
- **Removal-first workflow** - Offers cleanup before new installations
- **Better error handling** - Enhanced error messages and validation

#### Documentation Updates

- **CLAUDE.md** - Updated all references to use dLabs naming
- **README.md** - Updated examples, naming conventions, and usage patterns
- **CONTRIBUTING.md** - Updated development guidelines and testing procedures
- **Consistent terminology** - All documentation now uses dLabs branding

#### Script Improvements

- **setup_agents.sh** - Updated to use dLabs prefix and improved messaging
- **Enhanced error handling** - Better validation and user feedback across all scripts
- **Executable permissions** - All removal scripts properly configured

### Technical Improvements

- **Modular removal system** - Each collection has dedicated, focused removal script
- **Interactive shell functions** - Reusable yes/no prompt system
- **Better detection logic** - Improved existing installation detection
- **Cross-platform compatibility** - Enhanced bash script compatibility

## [0.1.0] - 2025-09-19

### Added

#### Core System

- Initial release of the Claude Agents Collection management system
- Automated installation script (`install.sh`) for complete setup
- Comprehensive agent aggregation from multiple sources (203 agents total)
- Multi-repository management with organized symlink structure

#### Agent Collections

- **dLabs Collection** (5 agents)
  - `dLabs-django-developer` - Django 5+ with modern Python practices
  - `dLabs-js-ts-tech-lead` - JavaScript/TypeScript technical leadership
  - `dLabs-data-analysis-expert` - Data analysis and visualization
  - `dLabs-python-backend-engineer` - Python backend development
  - `dLabs-debug-specialist` - Debugging and troubleshooting

- **External Collections Integration**
  - wshobson agents collection (82 production-ready agents)
  - awesome-claude-code-subagents (116 industry-standard agents)
  - wshobson commands collection (56 automation tools and workflows)

#### Setup Scripts

- `setup_agents.sh` - dLabs agent symlink management
- `setup_wshobson_agents_symlinks.sh` - wshobson agents with prefixing
- `setup_wshobson_commands_symlinks.sh` - Commands organized in tools/workflows
- `setup_awesome_agents_symlinks.sh` - Category-prefixed agent organization

#### Organization Features

- Consistent naming conventions with source prefixes
- Organized directory structure (`~/.claude/agents/`, `~/.claude/commands/`)
- Automatic handling of existing symlinks and graceful updates
- Colored terminal output for setup progress tracking

#### Documentation

- Comprehensive README with quick start guide
- CLAUDE.md for Claude Code integration guidance
- Agent categorization and usage examples
- Multi-agent workflow documentation

#### Repository Management

- `.gitignore` for external repository exclusion
- Automated cloning of external collections
- Update mechanisms for keeping collections current
- Error handling for missing dependencies

### Infrastructure

- Cross-platform bash scripts with proper error handling
- Modular setup system allowing individual collection management
- Scalable architecture for adding new agent sources
- Clean separation between local and external collections

## [0.1.0] - 2025-01-XX

### Added

- Initial dLabs agent definitions
- Basic symlink setup scripts
- Core project structure

---

## Release Notes

### Version 1.0.0 Highlights

This initial release establishes the Claude Agents Collection as a comprehensive management system for Claude Code agents. The system successfully aggregates 200+ specialized agents from multiple sources while maintaining organized structure and easy access.

**Key Features:**

- One-command installation and setup
- Unified access to agents from multiple collections
- Multi-agent orchestration capabilities
- Automated update mechanisms
- Comprehensive documentation

**Agent Coverage:**

- Full software development lifecycle
- Multiple programming languages and frameworks
- Infrastructure and DevOps specializations
- Business and domain-specific expertise
- Quality assurance and security

The release provides immediate access to production-ready agents while maintaining a clean architecture for future expansion.
