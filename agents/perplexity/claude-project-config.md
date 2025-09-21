# Ruby Project Standards

## Code Style
- Use 2-space indentation
- Prefer single quotes for strings
- Use trailing commas in multi-line collections
- Maximum line length: 100 characters
- Follow Rubocop community style guide

## Performance Requirements
- Database queries must be under 100ms
- API endpoints must respond under 200ms
- Background jobs should handle failures gracefully
- Use connection pooling for database connections
- Implement proper caching strategies

## Testing Standards
- Minimum 90% test coverage for core business logic
- Use factories instead of fixtures
- Mock external dependencies in unit tests
- Keep unit tests under 100ms execution time
- Write integration tests for critical user workflows

## Dependency Management
- Pin major versions in Gemfile
- Regular security updates with `bundle audit`
- Document why each gem is needed
- Prefer mature, well-maintained gems
- Avoid gems with native extensions when possible

## Error Handling
- Use specific exception classes
- Implement proper logging with structured data
- Handle edge cases gracefully
- Provide meaningful error messages to users
- Use circuit breakers for external service calls

## Security Guidelines
- Always use parameter whitelisting (strong parameters)
- Validate and sanitize user input
- Use HTTPS for all external API calls
- Store secrets in environment variables
- Regular security scans with tools like Brakeman

## Documentation
- Maintain up-to-date README with setup instructions
- Document API endpoints with examples
- Use YARD for inline code documentation
- Include troubleshooting guide
- Document deployment procedures