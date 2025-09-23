# Rails

- Always use the latest stable Rails version (7.1+) for new projects
- Prefer Rails API mode for backend services and microservices
- Use strong parameters and proper validation for all user inputs
- Follow RESTful conventions for API endpoints

## Database & Models

- Use ActiveRecord migrations for all database changes
- Keep migrations reversible with proper `down` methods
- Use database indexes for frequently queried columns
- Prefer database-level constraints over application-level validations for data integrity
- Use `rails db:schema:load` for new environments, not running all migrations

## API Development

- Use `rails new --api` for API-only applications
- Implement proper serialization with ActiveModel::Serializer or Blueprinter
- Use JWT tokens for stateless authentication
- Implement proper error handling with structured JSON responses
- Use `rack-cors` for CORS configuration in API applications

## Performance

- Use database query optimization (`includes`, `joins`, `select`)
- Implement caching strategies (fragment, action, page caching)
- Use background jobs with Sidekiq for long-running operations
- Monitor N+1 queries with `bullet` gem
- Use database connection pooling for high-traffic applications

## Security

- Always use strong parameters for mass assignment protection
- Implement proper authentication and authorization (Devise + CanCanCan or Pundit)
- Use HTTPS in production with `force_ssl = true`
- Sanitize user inputs to prevent XSS attacks
- Use `rails credentials` for sensitive configuration

## Testing

- Use RSpec for comprehensive testing (unit, integration, request specs)
- Use FactoryBot for test data creation
- Test API endpoints with request specs
- Use VCR for testing external API integrations
- Maintain high test coverage but focus on critical business logic

## Deployment

- Use Docker for containerized deployments
- Configure proper logging with structured JSON logs
- Use health check endpoints for load balancers
- Implement proper database connection handling in production
- Use environment variables for configuration management

## Development Tools

- Use `rails console` for debugging and data exploration
- Use `rails dbconsole` for direct database access
- Use `rails routes` to inspect application routes
- Use `rails stats` to analyze code metrics
- Keep development and production gems properly separated in Gemfile