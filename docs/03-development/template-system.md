# Template System Documentation

## Overview

The template system provides a standardized way to generate Go services following the enhanced layered architecture with CQRS support. This system ensures consistency, maintainability, and follows clean architecture principles.

## Architecture

### Template Structure

```
templates/service/
├── application/
│   └── {{.ServicePackage}}/
│       ├── command.go.tmpl      # CQRS Commands
│       ├── query.go.tmpl        # CQRS Queries
│       └── dto.go.tmpl          # Data Transfer Objects
├── config/
│   └── config.go.tmpl           # Service Configuration
├── delivery/
│   └── http/
│       ├── handler.go.tmpl      # HTTP Handlers
│       └── router.go.tmpl       # HTTP Routing
├── domain/
│   ├── entity/
│   │   └── entity.go.tmpl       # Domain Entities
│   ├── repository/
│   │   └── repository.go.tmpl   # Repository Interfaces
│   └── types/
│       └── types.go.tmpl        # Value Objects
├── infrastructure/
│   └── postgres/
│       └── repository.go.tmpl   # PostgreSQL Implementation
├── init/
│   └── init.go.tmpl             # Service Initialization
├── module.go.tmpl               # Service Module Facade
├── migration.sql.tmpl           # Database Migration
├── README.md.tmpl               # Service Documentation
└── tests/
    └── service_test.go.tmpl     # Test Templates
```

### Template Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{{.ServiceName}}` | Service name in snake_case | `user_service` |
| `{{.ServiceTitle}}` | Service name in PascalCase | `UserService` |
| `{{.ServicePackage}}` | Service name in camelCase | `userService` |

### Generated Service Structure

```
internal/services/{service_name}/
├── application/
│   └── {service_package}/
│       ├── command.go           # CQRS Commands
│       ├── query.go             # CQRS Queries
│       └── dto.go               # Data Transfer Objects
├── config/
│   └── config.go                # Service Configuration
├── delivery/
│   └── http/
│       ├── handler.go           # HTTP Handlers
│       └── router.go            # HTTP Routing
├── domain/
│   ├── entity/
│   │   └── {service_package}.go # Domain Entity
│   ├── repository/
│   │   └── {service_package}_repository.go # Repository Interface
│   └── types/
│       └── types.go             # Value Objects
├── infrastructure/
│   └── postgres/
│       └── repository.go        # PostgreSQL Implementation
├── init/
│   └── init.go                  # Service Initialization
└── module.go                    # Service Module Facade
```

## Usage

### Creating a Service

```bash
# Basic service creation
./scripts/create.sh service user-service

# Service with specific name
./scripts/create.sh service product-catalog
```

### Creating a Subdomain

```bash
# Create subdomain in existing service
./scripts/create.sh subdomain account user-service

# Create subdomain with specific name
./scripts/create.sh subdomain inventory product-catalog
```

## Template Features

### 1. Enhanced Layered Architecture

Each template follows the enhanced layered architecture pattern:

- **Domain Layer**: Pure business logic with entities, repositories, and value objects
- **Application Layer**: CQRS pattern with commands, queries, and DTOs
- **Infrastructure Layer**: External dependencies (database, external APIs)
- **Delivery Layer**: HTTP handlers and routing
- **Config Layer**: Service-specific configuration
- **Init Layer**: Dependency injection and service initialization

### 2. CQRS Support

The application layer implements Command Query Responsibility Segregation:

- **Commands**: Write operations (Create, Update, Delete)
- **Queries**: Read operations (Get, List, Search)
- **DTOs**: Data transfer objects for API requests/responses

### 3. Clean Architecture Principles

- **Dependency Inversion**: Depend on abstractions, not concretions
- **Interface Segregation**: Focused, single-purpose interfaces
- **Single Responsibility**: Each layer has one reason to change
- **Open/Closed**: Extensible without modification

### 4. Validation and Error Handling

- **Input Validation**: Struct tags for validation rules
- **Domain Validation**: Business rule validation in entities
- **Error Handling**: Consistent error types and messages
- **Error Wrapping**: Proper error context preservation

### 5. Database Integration

- **Repository Pattern**: Abstract data access layer
- **PostgreSQL Support**: Optimized for PostgreSQL
- **Migration Support**: Automatic migration generation
- **Transaction Support**: Proper transaction handling

### 6. HTTP API Design

- **RESTful Principles**: Standard HTTP methods and status codes
- **Middleware Support**: Configurable middleware stack
- **Route Organization**: Logical route grouping
- **Response Consistency**: Standardized response formats

## Template Customization

### Adding New Templates

1. Create template file in appropriate directory
2. Use template variables for dynamic content
3. Follow naming conventions
4. Update create.sh script to include new template

### Modifying Existing Templates

1. Backup existing template
2. Make changes following architecture principles
3. Test with service creation
4. Update documentation if needed

### Template Variables

```bash
# Service name conversions
SERVICE_NAME="user-service"           # Original name
service_name="user_service"           # snake_case
ServiceTitle="UserService"            # PascalCase
service_package="userService"         # camelCase
```

## Best Practices

### 1. Template Design

- **Consistency**: Use consistent patterns across all templates
- **Simplicity**: Keep templates simple and readable
- **Maintainability**: Easy to understand and modify
- **Reusability**: Templates should be reusable across services

### 2. Code Generation

- **Validation**: Always include input validation
- **Error Handling**: Proper error handling and logging
- **Documentation**: Include TODO comments for customization
- **Testing**: Generate test files with templates

### 3. Architecture Compliance

- **Clean Architecture**: Follow dependency inversion
- **CQRS**: Separate read and write operations
- **Domain-Driven Design**: Rich domain models
- **SOLID Principles**: Apply all SOLID principles

### 4. Security

- **Input Validation**: Validate all inputs
- **SQL Injection**: Use prepared statements
- **Authentication**: Include auth middleware placeholders
- **Authorization**: Include authorization checks

### 5. Performance

- **Database Optimization**: Proper indexing strategies
- **Caching**: Include caching placeholders
- **Connection Pooling**: Configure connection pools
- **Rate Limiting**: Include rate limiting placeholders

## Migration from Legacy Templates

### What Changed

1. **Consolidated Structure**: Moved from dual template systems to single system
2. **Enhanced Architecture**: Improved layered architecture with CQRS
3. **Better Organization**: Clear separation of concerns
4. **Improved Maintainability**: Easier to understand and modify

### Migration Steps

1. **Backup**: Legacy templates backed up to `.temp/template-backup/`
2. **Consolidation**: All templates moved to `templates/service/`
3. **Script Update**: `create.sh` updated to use consolidated templates
4. **Testing**: Verified all templates work correctly

### Benefits

- **Reduced Confusion**: Single template system
- **Better Consistency**: Standardized architecture
- **Easier Maintenance**: One template system to maintain
- **Improved Quality**: Enhanced architecture patterns

## Troubleshooting

### Common Issues

1. **Template Variables Not Replaced**
   - Check template variable syntax
   - Verify render_template function
   - Ensure proper variable names

2. **Generated Code Doesn't Compile**
   - Check template syntax
   - Verify import statements
   - Test with go build

3. **Missing Files**
   - Check template paths in create.sh
   - Verify template file existence
   - Check directory permissions

### Debugging

```bash
# Test template rendering
./scripts/create.sh service test-service

# Check generated files
find internal/services/test_service -type f

# Verify compilation
go build ./internal/services/test_service/...

# Clean up test service
rm -rf internal/services/test_service
```

## Future Enhancements

### Planned Features

1. **Interactive Mode**: Guided service creation
2. **Custom Templates**: User-defined templates
3. **Plugin System**: Extensible template system
4. **Validation Rules**: Custom validation rules
5. **Testing Framework**: Enhanced test generation

### Extension Points

1. **Template Plugins**: Custom template generators
2. **Validation Plugins**: Custom validation rules
3. **Integration Plugins**: External service integrations
4. **Testing Plugins**: Custom test generators

## Conclusion

The consolidated template system provides a robust foundation for generating Go services that follow clean architecture principles and best practices. The system is designed to be maintainable, extensible, and consistent across all generated services.

For questions or issues, refer to the project documentation or create an issue in the project repository.
