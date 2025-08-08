# Project Overview

## Introduction

This is a well-structured Go project template that follows domain-driven design principles and clean architecture patterns. It's designed to be a **monolith with clear service boundaries**, making it easy to maintain and scale.

## Architecture Philosophy

### Monolith with Service Boundaries

Unlike traditional monoliths where everything is tightly coupled, this template organizes code into **domain-oriented service modules**. Each service:

- Has its own domain logic and business rules
- Maintains clear boundaries with other services
- Can be easily extracted into a microservice later if needed
- Follows clean architecture principles

### Key Design Principles

1. **Domain-Driven Design (DDD)**: Each service encapsulates a specific business domain
2. **Clean Architecture**: Clear separation between layers (domain, application, infrastructure)
3. **Dependency Injection**: Centralized DI container for easy testing and configuration
4. **Shared Resources**: Common utilities and configurations shared across services

## Project Structure

```
├── cmd/                         # Entrypoints
│   ├── main/                    # Main HTTP server
│   └── worker/                  # Background job/worker runner
│
├── internal/                    # Internal application code
│   ├── bootstrap/               # Monolith bootstrap (DI, config, stitching)
│   ├── services/                # Domain-oriented service modules
│   └── shared/                  # Shared between services (not truly global)
│
├── pkg/                         # Reusable utilities (non-app-specific)
├── scripts/                     # Development and ops scripts
├── templates/                   # Templated files for environments/infrastructure
├── src/                         # Docker copy context
├── tests/                       # Centralized test directory
└── docs/                        # Project documentation
```

## Service Architecture

Each service follows a layered architecture:

```
{service-name}/
├── domain/          # Domain entities, value objects, interfaces
├── application/     # Use cases and orchestration logic
├── infrastructure/  # DB/repo impl, external APIs, adapters
└── delivery/        # Transport layer (HTTP handlers, routing, etc.)
```

### Layer Responsibilities

1. **Domain Layer**: Core business logic, entities, and interfaces
2. **Application Layer**: Use cases, orchestration, and business rules
3. **Infrastructure Layer**: Database implementations, external API clients
4. **Delivery Layer**: HTTP handlers, gRPC services, message queues

## Technology Stack

- **Language**: Go 1.21+
- **Web Framework**: Gin (HTTP routing and middleware)
- **Database**: PostgreSQL (primary database)
- **Cache**: Redis (session storage, caching)
- **Configuration**: Viper (config management)
- **Logging**: Zap (structured logging)
- **Testing**: Testify (testing utilities)
- **Migrations**: golang-migrate (database migrations)

## Development Workflow

1. **Create New Service**: Use `./scripts/create.sh service <service-name>`
2. **Implement Domain Logic**: Start with domain entities and business rules
3. **Add Application Layer**: Implement use cases and orchestration
4. **Create Infrastructure**: Add database repositories and external integrations
5. **Add Delivery Layer**: HTTP handlers, gRPC services, etc.
6. **Test**: Unit tests for each layer, integration tests for workflows
7. **Document**: Update service documentation and API specs

## Getting Started

1. **Setup Environment**:
   ```bash
   ./scripts/setup.sh
   ```

2. **Create Your First Service**:
   ```bash
   ./scripts/create.sh service user-service
   ```

3. **Run the Application**:
   ```bash
   go run cmd/main/main.go
   ```

4. **Run Tests**:
   ```bash
   go test ./...
   ```

## Benefits of This Architecture

- **Maintainability**: Clear separation of concerns makes code easy to understand and modify
- **Testability**: Dependency injection and interfaces make testing straightforward
- **Scalability**: Services can be easily extracted into microservices
- **Consistency**: Standardized structure across all services
- **Documentation**: Comprehensive documentation for each component

## Documentation Structure

This project includes comprehensive documentation organized into the following sections:

### 📋 [01. Overview](./README.md)
- Project introduction and architecture philosophy
- Technology stack and development workflow
- Getting started guide

### 🏗️ [02. Architecture](../02-architecture/)
- [Service Structure](../02-architecture/01-service-structure.md) - Detailed service architecture patterns
- [Clean Architecture](../02-architecture/02-clean-architecture.md) - Clean architecture implementation
- [CQRS Pattern](../02-architecture/03-cqrs-pattern.md) - Command Query Responsibility Segregation
- [Service Structure Summary](../02-architecture/04-service-structure-summary.md) - Architecture overview

### 🛠️ [03. Development](../03-development/)
- [Configuration](../03-development/01-configuration/) - Environment and configuration management
- [Environment Setup](../03-development/02-environment/) - Development environment setup
- [Prompt Generation](../03-development/03-prompt-generation/) - AI-assisted development tools
- [Template System](../03-development/template-system.md) - Code generation templates

### 🚀 [04. Deployment](../04-deployment/)
- [Deployment Scripts](../04-deployment/deployment-script.md) - Deployment automation

### 🧪 [05. Testing](../05-testing/)
- Testing strategies and best practices
- Unit, integration, and performance testing

### 🔒 [06. Security](../06-security/)
- Security best practices and guidelines
- Authentication and authorization patterns

### ⚡ [07. Performance](../07-performance/)
- Performance optimization strategies
- Monitoring and profiling

### 🏢 [08. Services](../08-services/)
- Individual service documentation
- Service-specific patterns and implementations

### 🌍 [09. Internationalization](../09-internationalization/)
- [Overview](../09-internationalization/01-overview.md) - i18n implementation
- [Usage Guide](../09-internationalization/02-usage-guide.md) - How to use i18n features
- [Database Storage](../09-internationalization/03-database-storage.md) - i18n data persistence
- [Interoperability](../09-internationalization/04-interoperability.md) - Cross-service i18n
- [Best Practices](../09-internationalization/05-best-practices.md) - i18n best practices

### 📚 [10. API Documentation](../10-api-documentation/)
- [API Standards](../10-api-documentation/01-api-standards/) - API design standards
- [API Specifications](../10-api-documentation/02-api-specs/) - OpenAPI specifications
- [API Testing](../10-api-documentation/03-api-testing/) - API testing strategies
- [API Versioning](../10-api-documentation/04-api-versioning/) - Version management
- [API Security](../10-api-documentation/05-api-security/) - API security guidelines

## Next Steps

- Read the [Architecture Documentation](../02-architecture/) for detailed design decisions
- Check [Development Guide](../03-development/) for setup and development practices
- Review [Testing Strategy](../05-testing/) for testing approaches
- See [Deployment Guide](../04-deployment/) for deployment procedures
- Explore [API Documentation](../10-api-documentation/) for API design patterns 