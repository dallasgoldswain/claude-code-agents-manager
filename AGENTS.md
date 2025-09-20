# Claude Agents Contributor Guide

## Project Overview
Claude Agents provides a Ruby-based command-line interface for installing, managing, and inspecting curated Claude Code agent collections. The CLI orchestrates symlink management, repository coordination, and status reporting for several upstream agent sets (dLabs, wshobson, Awesome Claude, and wshobson commands). The application centers on `ClaudeAgents::CLI` (Thor commands) with rich terminal output handled by `ClaudeAgents::UI` and supporting service objects in `lib/claude_agents/`.

## Build and Test Commands
- Install Ruby dependencies: `bundle install`
- Run the CLI locally: `./bin/claude-agents <command>` (e.g., `install`, `status`, `remove`)
- Package checks via RuboCop: `bundle exec rubocop`
- Automated test suite: `bundle exec rspec`

> Requires Ruby ≥ 3.0 and Bundler matching `Gemfile.lock` (2.6.9 at time of writing).

## Code Style Guidelines
- Follow the style enforced by RuboCop (`bundle exec rubocop`); project metrics limits are tuned for short, focused methods and modular structure.
- Keep UI logic declarative—rely on existing mixins in `lib/claude_agents/ui_components/` rather than growing `ClaudeAgents::UI` directly.
- Prefer descriptive method names and extract helpers when adding conditionals or loops that would trigger `Metrics/*` cops.
- Preserve ASCII output unless the interface already uses emoji/Unicode indicators.

## Testing Instructions
1. After dependency installation, run the full suite with `bundle exec rspec`.
2. To scope to a single spec file (useful for iterative work): `bundle exec rspec spec/path/to_spec.rb`.
3. For CLI-flow changes, exercise commands manually, e.g. `./bin/claude-agents status`, to validate TTY prompt and table rendering.
4. When modifying file operations or symlink behavior, test on a disposable workspace to confirm no unintended deletions.

## Security Considerations
- The installer and remover manipulate symlinks under the user’s Claude workspace; ensure paths are validated before performing filesystem writes to avoid directory traversal issues.
- External commands (e.g., `git`, `gh`) run in user space—never shell out with unchecked input from users.
- Avoid embedding secrets; configuration should rely on environment or upstream tools (GitHub CLI) for authentication.
- When adding new dependencies, prefer well-maintained gems and pin versions in the `Gemfile` to prevent supply-chain surprises.
