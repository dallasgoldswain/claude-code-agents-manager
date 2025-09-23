# Ruby

- I prefer to use modern Ruby 3.2+ with all the latest features
- Always use `bundle exec` for running commands to ensure proper gem environment
- Use Bundler for dependency management - never install gems globally except for development tools
- Make sure there is a Gemfile in the root directory for dependency management
- If there isn't a Gemfile, create one using `bundle init`

## Code Style & Quality

- Use RuboCop for linting and code style enforcement
- Follow Ruby community style guide conventions
- Use `rubocop -a` for auto-fixing style issues
- Prefer double quotes for strings unless interpolation is not needed
- Use frozen string literals: `# frozen_string_literal: true`

## Testing

- Use Minitest as the default testing framework (it's built into Ruby)
- Follow TDD principles - write tests before implementation
- Use factories instead of fixtures for test data
- Keep tests fast and isolated
- Use performance testing for critical code paths

## Project Structure

- Follow standard Ruby project structure:
  - `lib/` for main source code
  - `test/` for test files
  - `bin/` for executable scripts
  - `Gemfile` and `Gemfile.lock` for dependencies

## Performance

- Use `benchmark-ips` for performance testing
- Profile memory usage with `memory_profiler`
- Monitor object allocations in hot paths
- Use `ruby-prof` for detailed profiling when needed

## Development Tools

- Use `pry` or `debug` for debugging instead of `puts`
- Use `yard` for documentation generation
- Keep `Gemfile.lock` committed to ensure reproducible builds
- Use `bundle outdated` to check for gem updates