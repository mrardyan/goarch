# Service Structure Summary

> **Related Documents:**
> - [Service Structure](../02-architecture/01-service-structure.md)
> - [Clean Architecture Principles](../02-architecture/02-clean-architecture.md)
> - [CQRS Pattern](../02-architecture/03-cqrs-pattern.md)

## Overview

This document provides a quick reference for the service structure that implements Clean Architecture principles with CQRS support.

## Quick Start

### Creating a New Service
```bash
./scripts/create.sh service auth-service
```

### Adding a Subdomain to Existing Service
```bash
./scripts/create.sh subdomain account user-service
```

## Structure Overview

```
{service-name}/
├── domain/                    # Pure business rules
│   ├── entity/                # Core entities
│   ├── repository/            # Abstract interfaces (ports)
│   ├── service/               # Domain service logic
│   └── types/                 # Value objects, enums, primitives
│
├── application/              # Use case orchestration (commands/queries)
│   ├── {subdomain}/          # E.g. account/, role/, etc
│       ├── command.go        # Write operations
│       ├── query.go          # Read operations
│       └── dto.go            # Data transfer objects
│
├── delivery/                 # Controller / handler layer
│   └── http/                 # HTTP handlers & routing
│       ├── handler.go        # HTTP handlers
│       ├── router.go         # Route configuration
│       └── middleware.go     # Middleware setup
│
├── infrastructure/           # Adapter layer (DB, cache, etc)
│   ├── postgres/             # DB repositories
│   ├── redis/                # Cache layer
│   ├── emailservice/         # External service clients
│   └── persistence.go        # Optional DB setup logic
│
├── config/                   # Service-specific config structures
│   └── config.go
│
├── init/                     # Service initialization logic (DI wiring)
│   └── init.go
│
└── module.go                 # Optional facade to expose
```

## Key Features

### 1. **CQRS Support**
- **Commands**: Write operations (Create, Update, Delete)
- **Queries**: Read operations (Get, List, Search)
- **Separate handlers** for commands and queries
- **Optimized read/write paths**

### 2. **Clean Architecture**
- **Domain layer**: Pure business logic, no external dependencies
- **Application layer**: Use case orchestration
- **Infrastructure layer**: External concerns (DB, APIs)
- **Delivery layer**: Transport concerns (HTTP, gRPC)

### 3. **Subdomain Organization**
- **Complex services** can have multiple subdomains
- **Each subdomain** has its own commands, queries, and DTOs
- **Clear separation** of business concerns

### 4. **Technology-Specific Infrastructure**
- **PostgreSQL**: Database repositories
- **Redis**: Caching layer
- **External services**: API clients
- **Easy to add** new data sources

## Usage Examples

### Creating a Service
```bash
# Create a new service with service structure
./scripts/create.sh service user-service

# This creates:
# - Domain entities, repositories, types
# - Application layer with CQRS
# - HTTP handlers and routing
# - PostgreSQL repository
# - Configuration and initialization
# - Module facade
```

### Adding Subdomains
```bash
# Add account subdomain to user service
./scripts/create.sh subdomain account user-service

# Add role subdomain to user service
./scripts/create.sh subdomain role user-service

# This creates:
# - application/account/command.go
# - application/account/query.go
# - application/account/dto.go
```

### Service Registration
```go
// In internal/bootstrap/di.go
import (
    "golang-arch/internal/services/user_service"
    "golang-arch/internal/services/user_service/config"
)

func (c *Container) setupServices() {
    // User service
    userConfig := config.DefaultUserConfig()
    userModule, err := user_service.NewModule(c.DB, c.Logger, userConfig)
    if err != nil {
        log.Fatalf("Failed to create user module: %v", err)
    }
    
    // Setup routes
    userModule.SetupRoutes(c.Router.Group("/api/v1"))
}
```

## Configuration

### Service Configuration
```yaml
user_service:
  enabled: true
  timeout: 30s
  cache:
    enabled: true
    ttl: 5m
  database:
    max_open_conns: 25
    max_idle_conns: 5
    conn_max_lifetime: 5m
  api:
    rate_limit: 100
    timeout: 30
```

## Benefits

### 1. **Performance**
- **Read optimization**: Separate read models and indexes
- **Write optimization**: Optimized write paths
- **Caching**: Different strategies for reads and writes

### 2. **Scalability**
- **Independent scaling**: Scale reads and writes separately
- **Database separation**: Use different databases for reads and writes
- **Technology flexibility**: Use different technologies for different operations

### 3. **Maintainability**
- **Clear separation**: Commands and queries are clearly separated
- **Single responsibility**: Each handler has a single responsibility
- **Testability**: Easy to test commands and queries independently

### 4. **Flexibility**
- **Different models**: Use different models for reads and writes
- **Different databases**: Use different databases for reads and writes
- **Different technologies**: Use different technologies for reads and writes



## Best Practices

### 1. **Command Validation**
```go
func (h *CreateUserHandler) Handle(ctx context.Context, cmd CreateUserCommand) (*entity.User, error) {
    // Validate command
    if err := h.validateCommand(cmd); err != nil {
        return nil, err
    }
    
    // Process command
    // ...
}
```

### 2. **Query Optimization**
```go
func (h *ListUsersHandler) Handle(ctx context.Context, query ListUsersQuery) (*ListUsersResult, error) {
    // Optimize pagination
    if query.Limit > 100 {
        query.Limit = 100
    }
    
    // Process query
    // ...
}
```

### 3. **Error Handling**
```go
func (h *GetUserHandler) Handle(ctx context.Context, query GetUserQuery) (*entity.User, error) {
    user, err := h.repo.GetByID(ctx, query.ID)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, fmt.Errorf("failed to get user: %w", err)
    }
    return user, nil
}
```

## Conclusion

The service structure provides:

1. **Better organization** with clear separation of concerns
2. **CQRS support** for better performance and scalability
3. **Technology-specific infrastructure** organization
4. **Service-specific configuration** management
5. **Dedicated initialization** layer

This structure aligns well with Clean Architecture principles and provides a solid foundation for building scalable, maintainable services.

---

## Changelog

### Version 1.0.0 (2024-08-07)
- Initial documentation of service structure summary