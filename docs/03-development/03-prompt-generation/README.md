# Enhanced Prompt-Based Generation System

This directory contains the enhanced prompt-based generation system that enables intelligent service, subdomain, and feature creation using context and rules, with interactive mode, comprehensive testing, and automated documentation generation.

## Overview

The enhanced prompt-based generation system provides a more intelligent approach to code generation compared to traditional template-based systems. It uses:

- **Interactive mode** with guided prompts and real-time validation
- **Context gathering** to understand business requirements
- **Rule-based generation** to apply domain-specific patterns
- **Comprehensive testing framework** to ensure code quality
- **Automated documentation generation** for APIs, services, and projects
- **Validation systems** to ensure code quality
- **Integration capabilities** to work with existing services

## System Components

### 1. Rules (`rules/service-generation-rules.yaml`)
Defines the rules and patterns for code generation, including:
- Naming conventions
- Architecture patterns
- Business logic rules
- Security requirements
- Performance considerations

### 2. Frameworks (`frameworks/service-context-questions.yaml`)
Provides structured questions to gather context for:
- Service creation
- Subdomain creation
- Feature/use case creation

### 3. Validation (`validation/service-code-validation.yaml`)
Defines validation rules for:
- Code quality
- Architecture compliance
- Security standards
- Performance requirements

### 4. Contexts (`contexts/`)
Contains context files for service, subdomain, and feature generation:

#### Example Context Files:
- `user-service-example-context.yaml` - User management service example
- `product-catalog-example-context.yaml` - Product catalog service example
- `order-service-example-context.yaml` - Order management service example
- `auth-service-example-context.yaml` - Authentication service example

#### Context File Naming Convention:
- Service context files: `{service-name}-context.yaml`
- Subdomain context files: `{service-name}-{subdomain-name}-context.yaml`
- Feature context files: `{service-name}-{feature-name}-context.yaml`
- Example files: `{service-name}-example-context.yaml`

## Enhanced Features

### 🎯 Interactive Mode
The system now provides interactive creation scripts with guided prompts:

#### Interactive Service Creation
```bash
# Start interactive service creation
./scripts/create-service-interactive.sh
```

#### Interactive Subdomain Creation
```bash
# Start interactive subdomain creation
./scripts/create-subdomain-interactive.sh
```

#### Interactive Feature Creation
```bash
# Start interactive feature creation
./scripts/create-feature-interactive.sh
```

### 🧪 Comprehensive Testing Framework
The system includes a comprehensive testing framework:

```bash
# Test all code
./scripts/test.sh

# Test specific service
./scripts/test.sh -s user-service

# Test specific subdomain
./scripts/test.sh -d user-service/profile

# Generate coverage report
./scripts/test.sh -c
```

The testing framework includes:
- **Syntax Check**: Go syntax validation
- **Compilation Test**: Build verification
- **Unit Tests**: Individual component testing
- **Integration Tests**: Service interaction testing
- **Performance Tests**: Performance characteristics
- **Linting**: Code quality checks
- **Security Check**: Security vulnerability scanning
- **Structure Validation**: Architecture compliance

### 📚 Automated Documentation Generation
The system automatically generates comprehensive documentation:

```bash
# Generate all documentation
./scripts/create/create-docs.sh

# Generate API documentation only
./scripts/create/create-docs.sh api

# Generate documentation for specific service
./scripts/create/create-docs.sh -s user-service
```

Documentation includes:
- **API Documentation**: REST API docs with examples
- **Service Documentation**: Architecture and business logic docs
- **OpenAPI Specifications**: Machine-readable API specs
- **Project Documentation**: Setup and development guides

## Scripts

### Service Creation

#### Basic Usage
```bash
# Create context file for a new service
./scripts/create-service.sh user-service

# Generate service with context file
./scripts/create-service.sh user-service --context docs/03-development/prompt-generation/contexts/user-service-context.yaml

# Interactive mode
./scripts/create-service.sh user-service --interactive

# Validate existing service
./scripts/create-service.sh user-service --validate
```

#### Context File Structure
```yaml
# Service Context for user-service
service:
  name: user-service
  purpose: "User management with authentication and profile management"
  domain: "identity"
  
business:
  entities: ["User", "Profile", "Role"]
  rules: ["Email must be unique", "Password must be strong"]
  relationships: ["User has one Profile", "User has many Roles"]
  lifecycle: "User registration → Email verification → Profile completion"
  
technical:
  storage: "postgresql"
  external_dependencies: ["email-service", "auth-service"]
  performance_requirements: "Handle 1000 concurrent users"
  security_requirements: "JWT authentication, rate limiting"
  
api:
  endpoints: ["GET /users", "POST /users", "PUT /users/{id}", "DELETE /users/{id}"]
  authentication: "JWT"
  rate_limiting: "100 requests per minute"
  versioning: "v1"
  
integration:
  event_publishing: ["user.created", "user.updated", "user.deleted"]
  event_consumption: ["email.verified", "profile.updated"]
  monitoring: "User metrics, error tracking"
  logging: "Structured logging with correlation IDs"
```

### Subdomain Creation

#### Basic Usage
```bash
# Create context file for a new subdomain
./scripts/create-subdomain.sh user_profile user-service

# Generate subdomain with context file
./scripts/create-subdomain.sh user_profile user-service --context docs/03-development/prompt-generation/contexts/user-service-user_profile-context.yaml

# Interactive mode
./scripts/create-subdomain.sh user_profile user-service --interactive

# Validate existing subdomain
./scripts/create-subdomain.sh user_profile user-service --validate
```

#### Context File Structure
```yaml
# Subdomain Context for user_profile in user-service
subdomain:
  name: user_profile
  service: user-service
  purpose: "User profile management with avatar upload"
  
business:
  operations: ["create", "read", "update", "delete", "upload_avatar"]
  rules: ["Profile must have at least one field", "Avatar size limit 5MB"]
  validations: ["Email format validation", "Phone number validation"]
  
integration:
  entity_relationships: ["Profile belongs to User"]
  data_flow: "User creation → Profile creation → Avatar upload"
  api_integration: "REST API with file upload support"
  
api:
  endpoints: ["GET /profiles/{id}", "PUT /profiles/{id}", "POST /profiles/{id}/avatar"]
  methods: ["GET", "PUT", "POST"]
  authentication: "JWT"
  
database:
  tables: ["profiles", "profile_avatars"]
  migrations: ["create_profiles_table", "create_profile_avatars_table"]
  indexes: ["profiles_user_id_idx", "profiles_email_idx"]
```

### Feature Creation

#### Basic Usage
```bash
# Create context file for a new feature
./scripts/create-feature.sh user_registration user-service

# Create feature in specific subdomain
./scripts/create-feature.sh email_verification user-service profile

# Generate feature with context file
./scripts/create-feature.sh user_registration user-service --context docs/03-development/prompt-generation/contexts/user-service-user_registration-context.yaml

# Interactive mode
./scripts/create-feature.sh user_registration user-service --interactive

# Validate existing feature
./scripts/create-feature.sh user_registration user-service --validate
```

#### Context File Structure
```yaml
# Feature Context for user_registration
feature:
  name: user_registration
  service: user-service
  purpose: "User registration with email verification"
  
requirements:
  user_stories: ["As a user, I want to register with email and password", "As a user, I want to verify my email"]
  business_rules: ["Email must be unique", "Password must meet security requirements"]
  validation_rules: ["Email format validation", "Password strength validation"]
  error_handling: ["Email already exists", "Invalid email format", "Weak password"]
  
implementation:
  api_endpoints: ["POST /api/v1/users/register", "POST /api/v1/users/verify-email"]
  database_changes: ["Add verification_token to users table", "Add email_verified_at to users table"]
  external_dependencies: ["email-service for sending verification emails"]
  security_requirements: "Rate limiting, input validation, secure token generation"
  
integration:
  existing_entities: ["User entity with additional fields"]
  event_publishing: ["user.registered", "user.email_verified"]
  event_consumption: ["email.sent"]
  ui_requirements: "Registration form, email verification page"
  
testing:
  unit_tests: ["Test email validation", "Test password validation", "Test token generation"]
  integration_tests: ["Test registration flow", "Test email verification flow"]
  performance_tests: ["Test concurrent registrations"]
```

## Workflow

### 1. Context Gathering
1. Run the script with `--interactive` flag
2. Edit the generated context file with your requirements
3. Review and refine the context

### 2. Code Generation
1. Run the script with `--context` flag pointing to your context file
2. Review the generated code
3. Customize as needed

### 3. Validation
1. Run the script with `--validate` flag
2. Fix any issues identified
3. Ensure all tests pass

### 4. Integration
1. Add the generated code to your project
2. Update dependencies and imports
3. Add to your DI container
4. Create database migrations if needed

## Best Practices

### Context File Creation
- Be specific about business requirements
- Include all relevant technical details
- Consider security and performance implications
- Document relationships and dependencies

### Code Review
- Review generated code before committing
- Ensure it follows project conventions
- Add missing business logic
- Update documentation

### Testing
- Add unit tests for generated code
- Create integration tests for new features
- Test error scenarios
- Validate performance requirements

## Integration with Existing Workflow

The prompt-based generation system integrates with the existing `create.sh` script:

1. **Base Structure**: Uses existing templates for consistent structure
2. **Context Customization**: Applies context-based customizations
3. **Validation**: Ensures generated code meets standards
4. **Documentation**: Updates relevant documentation

## Future Enhancements

### Planned Features
- **AI-powered suggestions** for context improvement
- **Template customization** based on domain patterns
- **Code quality analysis** and automatic fixes
- **Integration with CI/CD** for automated validation
- **Plugin system** for custom generators

### Extensibility
- **Custom rules** for domain-specific patterns
- **Template plugins** for specialized requirements
- **Validation plugins** for custom quality checks
- **Integration plugins** for external tools

## Troubleshooting

### Common Issues

#### Context File Not Found
```bash
# Ensure the context file exists and path is correct
ls -la docs/03-development/prompt-generation/contexts/
```

#### Validation Failures
```bash
# Check Go compilation
cd internal/services/user_service && go build .

# Check for missing dependencies
go mod tidy
```

#### Template Rendering Issues
```bash
# Check template syntax
./scripts/create.sh service test-service

# Verify template variables
cat templates/service/domain/entity/entity.go.tmpl
```

### Debug Mode
```bash
# Enable debug output
DEBUG=1 ./scripts/create-service.sh user-service --context context.yaml
```

## Contributing

### Adding New Rules
1. Edit `generation-rules.yaml`
2. Add new rule categories
3. Update validation system
4. Test with existing services

### Adding New Questions
1. Edit `question-framework.yaml`
2. Add new question categories
3. Update context file structure
4. Test with new services

### Adding New Validations
1. Edit `validation-system.yaml`
2. Add new validation rules
3. Update validation scripts
4. Test with existing code

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review the context file structure
3. Validate your requirements
4. Test with a simple example first
