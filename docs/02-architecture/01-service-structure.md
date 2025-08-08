# Service Structure

> **Related Documents:**
> - [Clean Architecture Principles](../02-architecture/02-clean-architecture.md)
> - [CQRS Pattern](../02-architecture/03-cqrs-pattern.md)
> - [Service Structure Summary](../02-architecture/04-service-structure-summary.md)

## Overview

This document describes the service structure that implements Clean Architecture principles with CQRS support, providing clear organization, separation of concerns, and support for advanced patterns.

## Service Structure
```
{service-name}/
├── domain/                    # Pure business rules
│   ├── entity/                # Core entities (Account, Role, etc)
│   ├── repository/            # Abstract interfaces (ports)
│   ├── service/               # Domain service logic (pure functions)
│   └── types/                 # Value objects, enums, primitives
│
├── application/              # Use case orchestration (commands/queries)
│   ├── {subdomain}/          # E.g. account/, role/, etc
│       ├── command.go
│       ├── query.go
│       └── dto.go
│
├── delivery/                 # Controller / handler layer
│   └── http/                 # HTTP handlers & routing
│       ├── handler.go
│       ├── router.go
│       └── middleware.go
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

### 1. Domain Layer Organization

#### Domain Structure
```
domain/
├── entity/          # Core business entities
├── repository/      # Abstract interfaces (ports)
├── service/         # Domain service logic
└── types/          # Value objects, enums, primitives
```

**Benefits:**
- **Clear separation** of entities, interfaces, and value objects
- **Repository interfaces** are properly isolated as ports
- **Domain services** are separated from entities
- **Value objects and types** have their own space

### 2. CQRS Support in Application Layer

#### Application Structure
```
application/
├── {subdomain}/    # E.g. account/, role/, etc
    ├── command.go
    ├── query.go
    └── dto.go
```

**Benefits:**
- **Command Query Responsibility Segregation (CQRS)**
- **Commands** for write operations
- **Queries** for read operations
- **DTOs** for data transfer objects
- **Subdomain organization** for complex services

### 3. Technology-Specific Infrastructure

#### Infrastructure Structure
```
infrastructure/
└── repository.go
```

#### Infrastructure Structure
```
infrastructure/
├── postgres/        # DB repositories
├── redis/          # Cache layer
├── emailservice/   # External service clients
└── persistence.go  # Optional DB setup logic
```

**Benefits:**
- **Technology-specific organization** (PostgreSQL, Redis, etc.)
- **External service adapters** are clearly separated
- **Persistence setup** is isolated

### 4. Service-Specific Configuration

```
config/
└── config.go
```

**Benefits:**
- Each service has its own configuration structure
- Maintains consistency across services
- Clear separation of configuration concerns

### 5. Dedicated Initialization Layer

```
init/
└── init.go
```

**Benefits:**
- **Dependency injection wiring** is separated from business logic
- Service is more modular
- Easier to test and maintain

## Implementation Guidelines

### 1. Domain Layer

#### Entity Package
```go
// domain/entity/{{.ServicePackage}}.go
package entity

type {{.ServiceTitle}} struct {
    ID        string
    Name      string
    Email     string
    CreatedAt time.Time
    UpdatedAt time.Time
}

func New{{.ServiceTitle}}(name, email string) *{{.ServiceTitle}} {
    // Implementation
}

func ({{.ServicePackage}} *{{.ServiceTitle}}) Validate() error {
    // Business validation
}
```

#### Repository Package
```go
// domain/repository/{{.ServicePackage}}_repository.go
package repository

type {{.ServiceTitle}}Repository interface {
    Create(ctx context.Context, {{.ServicePackage}} *entity.{{.ServiceTitle}}) error
    GetByID(ctx context.Context, id string) (*entity.{{.ServiceTitle}}, error)
    Update(ctx context.Context, {{.ServicePackage}} *entity.{{.ServiceTitle}}) error
    Delete(ctx context.Context, id string) error
    List(ctx context.Context, limit, offset int) ([]*entity.{{.ServiceTitle}}, error)
}

// Separate read/write interfaces for CQRS
type {{.ServiceTitle}}Reader interface {
    GetByID(ctx context.Context, id string) (*entity.{{.ServiceTitle}}, error)
    List(ctx context.Context, limit, offset int) ([]*entity.{{.ServiceTitle}}, error)
}

type {{.ServiceTitle}}Writer interface {
    Create(ctx context.Context, {{.ServicePackage}} *entity.{{.ServiceTitle}}) error
    Update(ctx context.Context, {{.ServicePackage}} *entity.{{.ServiceTitle}}) error
    Delete(ctx context.Context, id string) error
}
```

#### Types Package
```go
// domain/types/email.go
package types

type Email struct {
    value string
}

func NewEmail(email string) (*Email, error) {
    // Validation logic
}

// domain/types/pagination.go
package types

type Pagination struct {
    Limit  int
    Offset int
}

type SortOrder string

const (
    SortOrderAsc  SortOrder = "asc"
    SortOrderDesc SortOrder = "desc"
)
```

### 2. Application Layer

#### Command Handlers
```go
// application/{{.ServicePackage}}/command.go
package {{.ServicePackage}}

type Create{{.ServiceTitle}}Command struct {
    Name  string `json:"name" validate:"required,min=2"`
    Email string `json:"email" validate:"required,email"`
}

type Create{{.ServiceTitle}}Handler struct {
    repo repository.{{.ServiceTitle}}Writer
}

func (h *Create{{.ServiceTitle}}Handler) Handle(ctx context.Context, cmd Create{{.ServiceTitle}}Command) (*entity.{{.ServiceTitle}}, error) {
    // Command handling logic
}
```

#### Query Handlers
```go
// application/{{.ServicePackage}}/query.go
package {{.ServicePackage}}

type Get{{.ServiceTitle}}Query struct {
    ID string `json:"id" validate:"required"`
}

type Get{{.ServiceTitle}}Handler struct {
    repo repository.{{.ServiceTitle}}Reader
}

func (h *Get{{.ServiceTitle}}Handler) Handle(ctx context.Context, query Get{{.ServiceTitle}}Query) (*entity.{{.ServiceTitle}}, error) {
    // Query handling logic
}
```

#### DTOs
```go
// application/{{.ServicePackage}}/dto.go
package {{.ServicePackage}}

type Create{{.ServiceTitle}}Request struct {
    Name  string `json:"name" validate:"required,min=2"`
    Email string `json:"email" validate:"required,email"`
}

type Create{{.ServiceTitle}}Response struct {
    ID        string    `json:"id"`
    Name      string    `json:"name"`
    Email     string    `json:"email"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}
```

### 3. Infrastructure Layer

#### PostgreSQL Repository
```go
// infrastructure/postgres/{{.ServicePackage}}_repository.go
package postgres

type {{.ServiceTitle}}Repository struct {
    db *sql.DB
}

func (r *{{.ServiceTitle}}Repository) Create(ctx context.Context, {{.ServicePackage}} *entity.{{.ServiceTitle}}) error {
    // PostgreSQL implementation
}
```

#### Redis Cache
```go
// infrastructure/redis/{{.ServicePackage}}_cache.go
package redis

type {{.ServiceTitle}}Cache struct {
    client *redis.Client
}

func (c *{{.ServiceTitle}}Cache) Get(ctx context.Context, id string) (*entity.{{.ServiceTitle}}, error) {
    // Redis implementation
}
```

### 4. Delivery Layer

#### HTTP Handlers
```go
// delivery/http/handler.go
package http

type {{.ServiceTitle}}Handler struct {
    createHandler *application.Create{{.ServiceTitle}}Handler
    getHandler    *application.Get{{.ServiceTitle}}Handler
    logger        *zap.Logger
}

func (h *{{.ServiceTitle}}Handler) Create{{.ServiceTitle}}(c *gin.Context) {
    // HTTP handling logic
}
```

#### Router
```go
// delivery/http/router.go
package http

func Setup{{.ServiceTitle}}Routes(router *gin.RouterGroup, handler *{{.ServiceTitle}}Handler) {
    {{.ServicePackage}}s := router.Group("/{{.ServicePackage}}s")
    {
        {{.ServicePackage}}s.POST("/", handler.Create{{.ServiceTitle}})
        {{.ServicePackage}}s.GET("/:id", handler.Get{{.ServiceTitle}})
        {{.ServicePackage}}s.PUT("/:id", handler.Update{{.ServiceTitle}})
        {{.ServicePackage}}s.DELETE("/:id", handler.Delete{{.ServiceTitle}})
        {{.ServicePackage}}s.GET("/", handler.List{{.ServiceTitle}}s)
    }
}
```

### 5. Configuration

```go
// config/config.go
package config

type {{.ServiceTitle}}Config struct {
    Enabled bool   `mapstructure:"enabled"`
    Timeout string `mapstructure:"timeout"`
    Cache   struct {
        Enabled bool   `mapstructure:"enabled"`
        TTL     string `mapstructure:"ttl"`
    } `mapstructure:"cache"`
}
```

### 6. Initialization

```go
// init/init.go
package init

func New{{.ServiceTitle}}Service(db *sql.DB, cache *redis.Client, config *config.{{.ServiceTitle}}Config) (*{{.ServiceTitle}}Service, error) {
    // Dependency injection setup
    repo := postgres.New{{.ServiceTitle}}Repository(db)
    cache := redis.New{{.ServiceTitle}}Cache(cache)
    
    createHandler := application.NewCreate{{.ServiceTitle}}Handler(repo)
    getHandler := application.NewGet{{.ServiceTitle}}Handler(repo)
    
    handler := http.New{{.ServiceTitle}}Handler(createHandler, getHandler)
    
    return &{{.ServiceTitle}}Service{
        repo:    repo,
        cache:   cache,
        handler: handler,
        config:  config,
    }, nil
}
```



## Benefits

### 1. **Better Separation of Concerns**
- Domain logic is clearly separated from infrastructure
- Repository interfaces are isolated as ports
- Value objects have their own space

### 2. **CQRS Support**
- Commands and queries are separated
- Better performance for read-heavy operations
- Easier to optimize read and write paths

### 3. **Technology-Specific Organization**
- PostgreSQL, Redis, and external services are clearly separated
- Easier to add new data sources
- Better testability with mocks

### 4. **Service-Specific Configuration**
- Each service manages its own configuration
- Clear separation of configuration concerns
- Easier to maintain and deploy

### 5. **Dedicated Initialization**
- Dependency injection is separated from business logic
- Services are more modular
- Easier to test and maintain

## Conclusion

The service structure provides significant improvements:

1. **Better organization** with clear separation of concerns
2. **CQRS support** for better performance and scalability
3. **Technology-specific infrastructure** organization
4. **Service-specific configuration** management
5. **Dedicated initialization** layer

This structure aligns well with Clean Architecture principles and provides a solid foundation for building scalable, maintainable services.

---

## Changelog

### Version 1.0.0 (2024-08-07)
- Initial documentation of service structure