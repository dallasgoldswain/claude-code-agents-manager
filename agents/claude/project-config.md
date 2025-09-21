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
