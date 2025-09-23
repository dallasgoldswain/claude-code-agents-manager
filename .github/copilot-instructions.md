maps = processor.get_file_mappings_for_component(:awesome)

# Copilot Project Instructions (Ruby ≥ 3.4.6)

Ultra-focused guidance for AI coding agents. Keep it lean; change only within existing service boundaries.

## 1. Purpose

Clone upstream agent/command repos, normalize filenames, expose them via symlinks under `~/.claude/{agents,commands}`. Core logic: `lib/claude_agents`. Never introduce a parallel architecture.

## 2. Service Layer Map

`config.rb` (truth source: components, counts, prefixes, destinations) – extend here only.
`installer.rb` (repo clone/update via `gh`, build file mappings, delegate to symlinks).
`file_processor.rb` (all filename shaping + skip logic; category flattening for "awesome" collection).
`symlink_manager.rb` (single place for create/remove + result hashes `{status:, display_name: ...}`).
`remover.rb` (batch removal flow; no direct FS deletions elsewhere).
`ui.rb` (TTY + color output; never `puts` from services directly).
`errors.rb` (typed errors + central handler).
`claude_agents_cli.rb` (Thor thin façade; validate → delegate → format).

## 3. Ruby 3.4+ Guidance

Target runtime: `ruby ">= 3.4.6"` (see Gemfile). Use: pattern matching (case/in guards) sparingly & only if it simplifies existing branching (no wholesale rewrites). Avoid: introducing Ractors / fibers for parallelism without approval. Assume frozen string literals; keep `# frozen_string_literal: true`. Prefer `Pathname` only where already used (`file_processor` category logic). Do not swap standard lib choices (e.g. keep `FileUtils`, not `Pathname` rewrites) unless adding narrowly-scoped helper.

## 4. Naming & Flattening Rules

Agents: `dLabs-*`, `wshobson-*`, `category-*` (awesome: strip leading numeric segment from folder, then prefix filename with cleaned category). Commands: tools/workflows directories preserved; root commands get `wshobson-` prefix. Modify ONLY relevant `process_*` method bodies; never post-process after mapping.

## 5. Skip / Filtering

Single entry: `FileProcessor#should_skip_file?` (+ `Config.skip_file?`). Rules: ignore dirs, dotfiles, `examples/`, patterns in global skip list. Add new exclusion? Extend that method—nowhere else.

## 6. Idempotency & Safety

Existing destination → return `:skipped`. Removal only touches symlinks. Never mutate source repos. Any bulk rename or mass deletion requires prior approval.

## 7. Adding a Component

1. Add to `COMPONENTS` (+ optional `REPOSITORIES`). 2. Implement branch in `get_file_mappings_for_component`. 3. Add installer method. 4. Extend `UI#component_installed?`. 5. Add unit test (mapping) + integration test (`setup <component>`). 6. Update README counts + this file.

## 8. Testing (Minitest)

Primary fast loops: `rake test:fast_fail`, then `rake dev:check` before commit. Assert returned hashes (keys: `:total_files`, `:created_links`, `:skipped_files`). Use provided helpers (no ad‑hoc tmp dirs). No mocking except external commands (`gh`, `git`).

## 9. CLI Conventions

No business logic in Thor actions. Always gate with `validate_component!`. UI color off via `--no-color`. New command = small wrapper returning structured results.

## 10. External Tooling

GitHub CLI mandatory (checked in `doctor`). TTY gems + Pastel already provisioned—reuse. Do not add formatting abstractions.

## 11. Performance

Show progress bar only if >5 files (preserve). Mapping generation = in-memory array; if future component large enough to risk memory, segment inside processor (after approval). Keep full test suite < ~30s.

## 12. Style

Two leading ABOUTME lines for every new Ruby file. Keep service object naming symmetry. No global mutable state beyond cached paths in `Config` (reset via `reset_cache!` in tests).

## 13. Prohibited

`--no-verify`; direct `File.symlink`; repo git ops outside `Installer`; silent changes to flattening or prefixes; adding concurrency primitives; speculative refactors of working code.

## 14. Examples

```ruby
maps = ClaudeAgents::FileProcessor.new(ui).get_file_mappings_for_component(:awesome)
ClaudeAgents::SymlinkManager.new(ui).create_symlinks(maps)
```

## 15. Uncertainty Protocol

Pause & ask before: naming rule changes, concurrency, caching, large-scale refactors. Extend—not replace—existing patterns.
