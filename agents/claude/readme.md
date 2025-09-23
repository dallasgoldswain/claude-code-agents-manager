# Ultimate Ruby Subagent Setup Guide for Claude Code

This package contains production-ready Ruby subagent configurations for Claude Code, providing expert-level Ruby development assistance with proactive code improvement suggestions.

## 🚀 Quick Start

### Installation

1. Create the `.claude/agents/` directory in your project root:
   ```bash
   mkdir -p .claude/agents
   ```

2. Copy the configuration files to your project:
   ```bash
   cp ruby-expert-pro.md .claude/agents/
   cp rails-api-expert.md .claude/agents/
   cp cli-gem-expert.md .claude/agents/
   cp ruby-performance-tester.md .claude/agents/
   ```

3. Create a `.claude.yaml` configuration file in your project root:
   ```yaml
   default_agent: ruby-expert-pro
   auto_invoke:
     - pattern: "*.rb"
       agent: ruby-expert-pro
     - pattern: "app/controllers/api/*"
       agent: rails-api-expert
     - pattern: "*.gemspec"
       agent: cli-gem-expert
     - pattern: "test/**/*_test.rb"
       agent: ruby-performance-tester
   ```

## 📦 Package Contents

### Core Subagents

| Agent | File | Purpose |
|-------|------|---------|
| **Ruby Expert Pro** | `ruby-expert-pro.md` | Main Ruby specialist with metaprogramming, Rails patterns, and proactive optimization |
| **Rails API Expert** | `rails-api-expert.md` | RESTful API development, serialization, authentication |
| **CLI & Gem Expert** | `cli-gem-expert.md` | Command-line tools, TTY toolkit, gem packaging |
| **Performance Tester** | `ruby-performance-tester.md` | Benchmarking, profiling, Minitest patterns |

## 🎯 Usage Patterns

### Automatic Invocation

The Ruby Expert Pro agent will automatically activate for:
- All `.rb` files
- Rails applications
- Ruby scripts
- Gem development

### Manual Invocation

You can explicitly request a specific agent:
```
@rails-api-expert: Help me design a RESTful API for user management
@cli-gem-expert: Create a CLI tool with interactive prompts
@ruby-performance-tester: Optimize this database query
```

### Proactive Improvements

The agents will automatically suggest:
- **Performance optimizations** (N+1 queries, memory usage)
- **Security enhancements** (SQL injection prevention, authentication)
- **Code quality improvements** (refactoring, patterns)
- **Ruby idioms** (more expressive syntax)
- **Test coverage** (missing tests, better assertions)

## 🔧 Configuration

### Project-Specific Customization

Create a `.claude/agents/project-config.md` file:

```markdown
---
name: project-ruby-expert
extends: ruby-expert-pro
---

# Additional Project Rules

## Code Standards
- Use double quotes for strings
- Maximum line length: 100 characters
- Prefer `unless` over `if !`

## Naming Conventions
- Use `_service` suffix for service objects
- Use `_query` suffix for query objects
- Use `_form` suffix for form objects

## Testing Requirements
- Minimum 95% code coverage
- All public methods must have tests
- Use factories instead of fixtures
```

### Team Standards Integration

Add your RuboCop configuration to the agent:

```yaml
# .rubocop.yml
AllCops:
  NewCops: enable
  TargetRubyVersion: 3.2

Style/StringLiterals:
  EnforcedStyle: double_quotes

Metrics/MethodLength:
  Max: 15
```

Then reference it in your agent configuration:
```markdown
## Code Standards
Follow the team's .rubocop.yml configuration for all generated code.
```

## 📊 Performance Optimization Examples

The agents will proactively identify and fix:

### N+1 Query Detection
```ruby
# Before (identified by agent)
users.each do |user|
  puts user.posts.count  # N+1 query!
end

# After (suggested by agent)
users.includes(:posts).each do |user|
  puts user.posts.size  # No additional queries
end
```

### Memory Optimization
```ruby
# Before
def process_large_file(file)
  File.read(file).split("\n").map(&:strip)  # Loads entire file
end

# After (suggested by agent)
def process_large_file(file)
  File.foreach(file).lazy.map(&:strip)  # Processes line by line
end
```

### Ruby Idioms
```ruby
# Before
array.select { |x| x > 5 }.map { |x| x * 2 }

# After (suggested by agent)
array.filter_map { |x| x * 2 if x > 5 }
```

## 🧪 Testing Integration

The agents automatically generate tests:

```ruby
# When you write:
class UserService
  def create_user(params)
    User.create!(params)
  end
end

# Agent generates:
class UserServiceTest < Minitest::Test
  def test_create_user_with_valid_params
    params = { name: 'John', email: 'john@example.com' }
    user = UserService.new.create_user(params)
    
    assert_instance_of User, user
    assert_equal 'John', user.name
    assert_equal 'john@example.com', user.email
  end
  
  def test_create_user_with_invalid_params
    assert_raises(ActiveRecord::RecordInvalid) do
      UserService.new.create_user({})
    end
  end
end
```

## 🚦 Quality Metrics

Track your subagent effectiveness:

| Metric | Target | Measurement |
|--------|--------|-------------|
| Code Coverage | >90% | SimpleCov reports |
| Query Performance | <100ms | Rails logs |
| Memory Usage | <500MB | Memory profiler |
| Code Quality | A rating | RuboCop grade |
| Test Speed | <5min | CI/CD metrics |

## 🔌 MCP Server Configuration (Optional)

For enhanced functionality, configure MCP servers:

```json
{
  "mcpServers": {
    "ruby-docs": {
      "type": "stdio",
      "command": "ruby-doc-server",
      "args": ["--version", "3.2.0"]
    },
    "rubygems": {
      "type": "http",
      "url": "https://rubygems.org/api/v1/"
    },
    "rails-guides": {
      "type": "http",
      "url": "https://api.rubyonrails.org/"
    }
  }
}
```

## 📚 Additional Resources

### Ruby Style Guides
- [Ruby Style Guide](https://rubystyle.guide)
- [Rails Style Guide](https://rails.rubystyle.guide)
- [RuboCop Documentation](https://docs.rubocop.org)

### Performance Tools
- [ruby-prof](https://github.com/ruby-prof/ruby-prof)
- [benchmark-ips](https://github.com/evanphx/benchmark-ips)
- [memory_profiler](https://github.com/SamSaffron/memory_profiler)

### Testing Resources
- [Minitest Documentation](https://docs.seattlerb.org/minitest/)
- [Rails Testing Guide](https://guides.rubyonrails.org/testing.html)
- [Better Specs](https://www.betterspecs.org/)

## 🤝 Contributing

To improve these subagents:

1. Fork the repository
2. Create a feature branch
3. Add your improvements
4. Test thoroughly
5. Submit a pull request

## 📄 License

MIT License - Feel free to customize for your team's needs.

## 🙋 Support

For issues or questions:
- Check the [Claude Code documentation](https://docs.claude.com/en/docs/claude-code)
- Review the agent configurations
- Customize based on your project needs

---

**Remember**: These agents don't just write Ruby code—they write Ruby code that makes developers smile with its elegance and clarity! 💎