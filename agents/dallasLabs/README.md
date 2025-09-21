# Claude Code – Ruby Subagents

This bundle installs a **federated set of Ruby-focused subagents** for Claude Code:
- `ruby-architect` (triage + idiomatic Ruby/metaprogramming/perf)
- `rails-optimizer` (Rails refactor & performance)
- `gem-smith` (gem authoring)
- `cli-artist` (graphical CLIs / TUIs)
- `minitest-maestro` (testing via Minitest)
- `bench-profiler` (benchmarking & profiling)

## Install
1. Unzip this archive at the root of your project. It will create a `.claude/` folder:
   ```
   .claude/
     settings.json
     agents/
       ruby-architect.md
       rails-optimizer.md
       gem-smith.md
       cli-artist.md
       minitest-maestro.md
       bench-profiler.md
   ```
2. Open the project in Claude Code.
3. Run **`/agents`** to verify agents are discovered.

> You can also place these files in `~/.claude/agents/` for user-wide availability.

## Usage
- Ask Claude: “**Use the ruby-architect subagent** to refactor this service object.”
- “**Have rails-optimizer** eliminate N+1s in `OrdersController#index`.”
- “**Ask bench-profiler** to compare these two implementations with `benchmark-ips`.”
- “**Use minitest-maestro** to add regression tests for this bug.”

## Safety & automation
- `settings.json` scopes tool permissions and adds a post-edit hook to auto-run RuboCop and Minitest when dependencies are present.
- Potentially destructive commands like `git push`, `bundle update`, and `gem push` are gated with **Ask**.

## Customize
- Edit `.claude/settings.json` to change tool permissions or hooks.
- Swap libraries in `cli-artist` (Thor/Commander/Curses) if preferred.
- Add Brakeman or RuboCop Performance to your Gemfile if using Rails.
