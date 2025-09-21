#!/bin/bash

# Ultimate Ruby Subagent Setup Script for Claude Code
# This script sets up the complete Ruby development environment with Claude Code subagents

set -e

echo "🚀 Setting up Ultimate Ruby Subagents for Claude Code..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}→${NC} $1"
}

# Check if we're in a Ruby project
if [ ! -f "Gemfile" ] && [ ! -f "*.gemspec" ]; then
    print_info "This doesn't appear to be a Ruby project. Continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 1
    fi
fi

# Create .claude directory structure
print_info "Creating Claude Code directory structure..."

mkdir -p .claude/agents
mkdir -p .claude/templates

print_success "Created .claude directory structure"

# Create the main Ruby expert configuration
print_info "Creating Ruby Expert Pro agent..."

cat > .claude/agents/ruby-expert-pro.md << 'EOF'
---
name: ruby-expert-pro
description: Elite Ruby development specialist. MUST BE USED PROACTIVELY for Ruby code optimization, Rails patterns, metaprogramming, gem development, CLI tools, and testing frameworks.
model: sonnet
tools: Read, Write, Bash, Grep, Context7
---

# Elite Ruby Development Expert

You are a **proactive Ruby development specialist** with deep expertise across the entire Ruby ecosystem. Your mission is to write production-quality Ruby code that experienced Rubyists consider elegant, performant, and maintainable.

[Configuration continues - truncated for brevity]
EOF

print_success "Created Ruby Expert Pro agent"

# Create Rails API expert
print_info "Creating Rails API Expert agent..."

cat > .claude/agents/rails-api-expert.md << 'EOF'
---
name: rails-api-expert
description: Rails API development specialist for RESTful services, serialization, authentication, and performance optimization.
model: sonnet
tools: Read, Write, Bash, Database-Query
---

# Rails API Development Specialist

[Configuration continues - truncated for brevity]
EOF

print_success "Created Rails API Expert agent"

# Create CLI & Gem expert
print_info "Creating CLI & Gem Expert agent..."

cat > .claude/agents/cli-gem-expert.md << 'EOF'
---
name: cli-gem-expert
description: Ruby CLI and gem development specialist using TTY toolkit, Thor, and professional gem structure.
model: sonnet
tools: Read, Write, Bash, Gem-Builder
---

# CLI & Gem Development Expert

[Configuration continues - truncated for brevity]
EOF

print_success "Created CLI & Gem Expert agent"

# Create Performance & Testing expert
print_info "Creating Performance & Testing Expert agent..."

cat > .claude/agents/ruby-performance-tester.md << 'EOF'
---
name: ruby-performance-tester
description: Ruby performance optimization and Minitest testing specialist.
model: sonnet
tools: Read, Write, Bash, Profiler
---

# Ruby Performance & Testing Expert

[Configuration continues - truncated for brevity]
EOF

print_success "Created Performance & Testing Expert agent"

# Create .claude.yaml configuration
print_info "Creating Claude configuration file..."

if [ -f ".claude.yaml" ]; then
    print_info ".claude.yaml already exists. Create backup? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cp .claude.yaml .claude.yaml.backup
        print_success "Created backup: .claude.yaml.backup"
    fi
fi

cat > .claude.yaml << 'EOF'
# Claude Code Configuration for Ruby Projects
default_agent: ruby-expert-pro

auto_invoke:
  - pattern: "*.rb"
    agent: ruby-expert-pro
  - pattern: "app/controllers/api/**/*.rb"
    agent: rails-api-expert
  - pattern: "*.gemspec"
    agent: cli-gem-expert
  - pattern: "test/**/*_test.rb"
    agent: ruby-performance-tester

project:
  ruby_version: "3.2.0"
  test_framework: "minitest"
  
behaviors:
  proactive_suggestions: true
  auto_generate_tests: true
  include_benchmarks: true
EOF

print_success "Created .claude.yaml configuration"

# Create sample RuboCop configuration if it doesn't exist
if [ ! -f ".rubocop.yml" ]; then
    print_info "Creating sample RuboCop configuration..."
    
    cat > .rubocop.yml << 'EOF'
AllCops:
  NewCops: enable
  TargetRubyVersion: 3.2
  Exclude:
    - 'db/**/*'
    - 'config/**/*'
    - 'script/**/*'
    - 'vendor/**/*'

Style/StringLiterals:
  EnforcedStyle: double_quotes

Style/FrozenStringLiteralComment:
  Enabled: true

Metrics/MethodLength:
  Max: 15

Metrics/ClassLength:
  Max: 100

Layout/LineLength:
  Max: 100
EOF
    
    print_success "Created .rubocop.yml"
else
    print_info ".rubocop.yml already exists, skipping..."
fi

# Add to .gitignore if needed
if [ -f ".gitignore" ]; then
    if ! grep -q ".claude.yaml.backup" .gitignore; then
        echo "" >> .gitignore
        echo "# Claude Code backups" >> .gitignore
        echo ".claude.yaml.backup" >> .gitignore
        print_success "Updated .gitignore"
    fi
fi

# Create sample project configuration
print_info "Creating project-specific configuration template..."

cat > .claude/agents/project-config.md << 'EOF'
---
name: project-ruby-expert
extends: ruby-expert-pro
---

# Project-Specific Ruby Configuration

## Additional Project Rules

### Code Standards
- Follow team conventions in .rubocop.yml
- Use semantic naming for all methods and variables
- Document all public APIs with YARD

### Testing Requirements
- Minimum 95% code coverage
- All public methods must have tests
- Use factories instead of fixtures

### Performance Requirements
- All database queries must complete in < 100ms
- Background jobs for operations > 3 seconds
- Implement caching for frequently accessed data

## Team Conventions

Add your team-specific conventions here...
EOF

print_success "Created project configuration template"

# Detect project type and provide recommendations
echo ""
print_info "Analyzing project type..."

if [ -f "Gemfile" ]; then
    if grep -q "rails" Gemfile; then
        print_success "Detected Rails application"
        echo "  Recommended agents: ruby-expert-pro, rails-api-expert"
    fi
    
    if grep -q "rspec" Gemfile; then
        print_info "Detected RSpec. Consider adding an RSpec specialist agent."
    fi
    
    if grep -q "thor" Gemfile || grep -q "tty" Gemfile; then
        print_success "Detected CLI tools"
        echo "  Recommended agent: cli-gem-expert"
    fi
fi

if [ -f "*.gemspec" ]; then
    print_success "Detected Ruby gem project"
    echo "  Recommended agents: cli-gem-expert, ruby-expert-pro"
fi

# Final setup steps
echo ""
echo "✨ Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Review and customize agent configurations in .claude/agents/"
echo "2. Update .claude.yaml with your project-specific settings"
echo "3. Add team conventions to .claude/agents/project-config.md"
echo "4. Test the agents with: claude code"
echo ""
echo "Quick test commands:"
echo "  - For Ruby development: echo '@ruby-expert-pro optimize this code' | claude"
echo "  - For API development: echo '@rails-api-expert design a REST API' | claude"
echo "  - For CLI tools: echo '@cli-gem-expert create a CLI' | claude"
echo "  - For testing: echo '@ruby-performance-tester write tests' | claude"
echo ""
print_success "Happy Ruby coding with Claude! 💎"