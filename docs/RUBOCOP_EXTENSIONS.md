# RuboCop Extensions Setup

## Overview

Added RuboCop extension libraries to improve code quality checks for minitest and Rake files:

- `rubocop-minitest` - Provides cops specifically for minitest test files
- `rubocop-rake` - Provides cops specifically for Rakefile and rake tasks

## Installation

### Gemfile Changes

Added to the development/test group:

```ruby
gem 'rubocop-minitest', '~> 0.35'
gem 'rubocop-rake', '~> 0.6'
```

### Configuration

Updated `.rubocop.yml` with:

- Plugin configuration using the modern `plugins:` syntax
- Enabled new cops with `NewCops: enable`
- Project-specific exclusions for test files and Rakefile
- Disabled overly strict cops for test files (e.g., `Minitest/MultipleAssertions`)

## Benefits

### Minitest Cops

- **Minitest/EmptyLineBeforeAssertionMethods** - Enforces spacing before assertions for readability
- **Minitest/MultipleAssertions** - Detects tests with too many assertions (disabled for our project)
- **Minitest/AssertEqual** - Ensures proper use of assert_equal vs assert
- **Minitest/RefuteEqual** - Ensures proper use of refute_equal vs refute
- And many more...

### Rake Cops

- **Rake/Desc** - Ensures all tasks have descriptions
- **Rake/DuplicateTask** - Detects duplicate task definitions
- **Rake/DuplicateNamespace** - Detects duplicate namespace definitions

## Usage

Run RuboCop with extensions:

```bash
bundle exec rubocop
```

Run only on specific file types:

```bash
bundle exec rubocop test/          # Check test files with minitest cops
bundle exec rubocop Rakefile       # Check Rakefile with rake cops
```

## Configuration Highlights

```yaml
plugins:
  - rubocop-minitest
  - rubocop-rake

AllCops:
  NewCops: enable
  TargetRubyVersion: 3.4

# Allow longer methods in tests
Metrics/MethodLength:
  Exclude:
    - 'test/**/*'

# Allow multiple assertions per test
Minitest/MultipleAssertions:
  Enabled: false
```

This setup provides better code quality checks while maintaining flexibility for test files where some strict rules don't apply.
