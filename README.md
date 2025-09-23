# dLabs Claude Agents (Slim Edition)

Minimal Claude Code agent management focused solely on a curated local dLabs agent set.

## Agents (7)

| Agent | File |
|-------|------|
| Django Developer | dLabs-django-developer.md |
| JS/TS Tech Lead | dLabs-js-ts-tech-lead.md |
| Data Analysis Expert | dLabs-data-analysis-expert.md |
| Python Backend Engineer | dLabs-python-backend-engineer.md |
| Debug Specialist | dLabs-debug-specialist.md |
| Ruby Expert | dLabs-ruby-expert.md |
| Joker (Creative Wildcard) | dLabs-joker.md |

Add new agents by dropping markdown files into `agents/dallasLabs/agents/` and re-running setup.

## Install (Quick Start)

```bash
bundle install           # Install Ruby dependencies (first time)
./bin/claude-agents setup dlabs
```

Symlinks are created in `~/.claude/agents/` (idempotent: existing ones are skipped).

## Commands

```bash
./bin/claude-agents setup dlabs    # Install/update symlinks
./bin/claude-agents remove dlabs   # Remove dLabs symlinks
./bin/claude-agents status         # Show status table
./bin/claude-agents doctor         # Basic environment diagnostics
./bin/claude-agents version        # Show version
```

## Development

```bash
rake test        # Run tests
rake rubocop     # Lint
rake dev:check   # Tests + lint
```

Fail-fast modes:

```bash
FAIL_FAST=1 bundle exec rake test          # Stop on first failure
FAILURES_ONLY=1 bundle exec rake test      # Print only failing tests + summary
PROJECT_BT=1 FAIL_FAST=1 bundle exec rake test  # Fail-fast with trimmed backtraces
```

## Architecture

Core services (Zeitwerk autoloaded): Config, FileProcessor, SymlinkManager, Installer, Remover, UI, Errors.

## Testing

All tests use real filesystem operations in isolated temp dirs (no mocks). Custom reporter supports failure-only and fail-fast workflows.

Run a focused file:

```bash
ruby -Itest test/unit/symlink_manager_test.rb
```

## Adding an Agent

1. Create `agents/dallasLabs/agents/your-agent.md`
2. Include YAML frontmatter (`name`, `description`, optional `tools`)
3. Run `./bin/claude-agents setup dlabs`

## Requirements

- [GitHub CLI](https://cli.github.com/) (`gh`) for repository cloning
- Ruby 3.0+ (for the enhanced CLI experience)
- Git for repository management

## Full Installation Steps

```bash
# Clone this repository
git clone <your-repo-url>
cd claude-agents

# Install Ruby dependencies
bundle install

# Install dLabs agents
./bin/claude-agents setup dlabs
```

CLI behavior:

1. Create symlinks for all dLabs agent markdown files into `~/.claude/agents/`
2. Skip any that already exist (idempotent)
3. Provide colored feedback (linked / skipped / removed)

### Manual Setup

## Commands (Duplicate quick-reference)

```bash
./bin/claude-agents setup dlabs   # Install / refresh symlinks
./bin/claude-agents remove dlabs  # Remove dLabs symlinks
./bin/claude-agents status        # Show installation status
./bin/claude-agents version       # Show version
./bin/claude-agents doctor        # Basic environment diagnostics
```

## Agent Organization & Naming

All local agents use the `dLabs-` prefix.

### Directory Structure

```text
~/.claude/
└── agents/
    ├── dLabs-django-developer.md
    ├── dLabs-js-ts-tech-lead.md
    ├── dLabs-data-analysis-expert.md
    ├── dLabs-python-backend-engineer.md
    ├── dLabs-debug-specialist.md
    ├── dLabs-ruby-expert.md
    └── dLabs-joker.md
```

## Agent Files

Each agent markdown file contains frontmatter (name, description, tools) and operational guidance. Extend or customize them in `agents/dallasLabs/agents/` then re-run setup.

## Add / Update Agents

Add a new markdown file under `agents/dallasLabs/agents/` and rerun:

```bash
./bin/claude-agents setup dlabs
```text

Symlinks update idempotently.

## Usage Examples

```bash
@dLabs-django-developer "Optimize this Django queryset"
@dLabs-python-backend-engineer "Design a background job system"
@dLabs-ruby-expert "Refactor this service object"
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
    └── dallasLabs/                         # Local dLabs agent definitions
```

## CLI Interface (Extended)

```bash
./bin/claude-agents setup dlabs      # Install/update symlinks
./bin/claude-agents remove dlabs     # Remove symlinks
./bin/claude-agents status           # Show status
./bin/claude-agents doctor           # Environment diagnostic
./bin/claude-agents version          # Show version

# Management
./bin/claude-agents status                  # Show installation status
./bin/claude-agents remove <component>      # Remove component
./bin/claude-agents doctor                  # System health check

# Information
./bin/claude-agents version                 # Show version
./bin/claude-agents help                    # Show help
```

## Notes

This slim edition focuses only on local dLabs agents. For external collections, use the upstream multi-collection repository.

## License

MIT

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
rake test:coverage                          # Tests with coverage reporting
rake test:fast_fail                         # Stop on first failure with minimal output
rake test:failures_only                     # Show only test failures
rake test:watch                             # Continuous testing (requires entr)

# Individual test execution
rake test:file[path/to/test_file.rb]        # Run specific test file
rake test:method[TestClass,test_method]     # Run specific test method

# Test reporting
rake test:report                            # Generate detailed test report

# Custom test runner
bin/test                                    # Run all tests with custom runner
bin/test --suite unit                       # Run specific test suite
bin/test --verbose --parallel               # Run with options
```

### Dev Tasks

```bash
rake test           # Run full test suite
rake rubocop        # Lint
rake dev:check      # Tests + lint
```

<!-- Duplicate extended architecture section removed -->

<!-- Duplicate testing detail section removed (see earlier Testing section) -->

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for adding or modifying dLabs agents.

<!-- License already declared earlier; keeping single canonical section above -->
