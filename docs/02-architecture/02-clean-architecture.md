# Clean Architecture Principles

> **Related Documents:**
> - [Service Structure](../02-architecture/01-service-structure.md)
> - [CQRS Pattern](../02-architecture/03-cqrs-pattern.md)
> - [Service Structure Summary](../02-architecture/04-service-structure-summary.md)

## Overview

This document describes the Clean Architecture principles applied in our Go project, ensuring maintainable, testable, and scalable code.

## Core Principles

### 1. Dependency Rule
**Dependencies point inward**: Domain → Application → Infrastructure → Delivery

```
┌─────────────────────────────────────────────────────────────┐
│                    Delivery Layer                          │
│  (HTTP Handlers, gRPC Services, CLI Commands)             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                       │
│  (Database, External APIs, File System, Cache)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Application Layer                          │
│  (Use Cases, Command/Query Handlers, Orchestration)       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer                           │
│  (Entities, Value Objects, Business Rules, Interfaces)    │
└─────────────────────────────────────────────────────────────┘
```

### 2. Dependency Inversion Principle

#### ✅ Good Example
```go
// Domain layer defines the interface
type UserRepository interface {
    Create(ctx context.Context, user *User) error
    GetByID(ctx context.Context, id string) (*User, error)
}

// Application layer depends on the interface
type CreateUserHandler struct {
    repo UserRepository  // Interface, not concrete implementation
}

// Infrastructure layer implements the interface
type PostgreSQLUserRepository struct {
    db *sql.DB
}

func (r *PostgreSQLUserRepository) Create(ctx context.Context, user *User) error {
    // PostgreSQL implementation
}
```

#### ❌ Bad Example
```go
// Application layer depends on concrete implementation
type CreateUserHandler struct {
    repo *PostgreSQLUserRepository  // Concrete implementation
}
```

### 3. Interface Segregation

#### ✅ Good Example
```go
// Focused interfaces
type UserReader interface {
    GetByID(ctx context.Context, id string) (*User, error)
    List(ctx context.Context, limit, offset int) ([]*User, error)
}

type UserWriter interface {
    Create(ctx context.Context, user *User) error
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id string) error
}

// Combine when needed
type UserRepository interface {
    UserReader
    UserWriter
}
```

#### ❌ Bad Example
```go
// Large interface forcing implementations to depend on unused methods
type UserRepository interface {
    Create(ctx context.Context, user *User) error
    GetByID(ctx context.Context, id string) (*User, error)
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id string) error
    List(ctx context.Context, limit, offset int) ([]*User, error)
    Search(ctx context.Context, query string) ([]*User, error)
    BulkCreate(ctx context.Context, users []*User) error
    BulkUpdate(ctx context.Context, users []*User) error
    BulkDelete(ctx context.Context, ids []string) error
}
```

## Layer Responsibilities

### 1. Domain Layer
**Purpose**: Core business logic and rules

**Contains**:
- Entities (business objects)
- Value Objects (immutable objects)
- Domain Services (pure business logic)
- Repository Interfaces (ports)

**Rules**:
- No external dependencies
- Pure business logic
- No framework dependencies
- No infrastructure concerns

```go
// domain/entity/user.go
type User struct {
    ID        string
    Name      string
    Email     string
    CreatedAt time.Time
    UpdatedAt time.Time
}

func (u *User) Validate() error {
    if u.Name == "" {
        return ErrInvalidName
    }
    if u.Email == "" {
        return ErrInvalidEmail
    }
    return nil
}

// domain/repository/user_repository.go
type UserRepository interface {
    Create(ctx context.Context, user *User) error
    GetByID(ctx context.Context, id string) (*User, error)
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id string) error
}
```

### 2. Application Layer
**Purpose**: Use case orchestration and business workflow

**Contains**:
- Command Handlers (write operations)
- Query Handlers (read operations)
- DTOs (Data Transfer Objects)
- Use Case Orchestration

**Rules**:
- Depends only on domain layer
- Orchestrates domain objects
- Handles business workflow
- No infrastructure concerns

```go
// application/user/command.go
type CreateUserCommand struct {
    Name  string `json:"name" validate:"required,min=2"`
    Email string `json:"email" validate:"required,email"`
}

type CreateUserHandler struct {
    repo repository.UserWriter
}

func (h *CreateUserHandler) Handle(ctx context.Context, cmd CreateUserCommand) (*User, error) {
    user := entity.NewUser(cmd.Name, cmd.Email)
    
    if err := user.Validate(); err != nil {
        return nil, err
    }
    
    if err := h.repo.Create(ctx, user); err != nil {
        return nil, err
    }
    
    return user, nil
}
```

### 3. Infrastructure Layer
**Purpose**: External concerns and data persistence

**Contains**:
- Database implementations
- External API clients
- Cache implementations
- File system operations

**Rules**:
- Implements domain interfaces
- Handles external concerns
- No business logic
- Framework-specific code

```go
// infrastructure/postgres/user_repository.go
type PostgreSQLUserRepository struct {
    db *sql.DB
}

func (r *PostgreSQLUserRepository) Create(ctx context.Context, user *User) error {
    query := `INSERT INTO users (id, name, email, created_at, updated_at) VALUES ($1, $2, $3, $4, $5)`
    _, err := r.db.ExecContext(ctx, query, user.ID, user.Name, user.Email, user.CreatedAt, user.UpdatedAt)
    return err
}
```

### 4. Delivery Layer
**Purpose**: Transport and presentation concerns

**Contains**:
- HTTP handlers
- gRPC services
- CLI commands
- API routing

**Rules**:
- Handles transport concerns
- Validates input
- Formats output
- No business logic

```go
// delivery/http/user_handler.go
type UserHandler struct {
    createHandler *application.CreateUserHandler
    getHandler    *application.GetUserHandler
    logger        *zap.Logger
}

func (h *UserHandler) CreateUser(c *gin.Context) {
    var req CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{Error: "Invalid request"})
        return
    }
    
    cmd := application.CreateUserCommand{
        Name:  req.Name,
        Email: req.Email,
    }
    
    user, err := h.createHandler.Handle(c.Request.Context(), cmd)
    if err != nil {
        h.logger.Error("Failed to create user", zap.Error(err))
        c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "Failed to create user"})
        return
    }
    
    c.JSON(http.StatusCreated, CreateUserResponse{
        ID:        user.ID,
        Name:      user.Name,
        Email:     user.Email,
        CreatedAt: user.CreatedAt,
        UpdatedAt: user.UpdatedAt,
    })
}
```

## Benefits

### 1. Testability
- Each layer can be tested independently
- Easy to mock dependencies
- Business logic is isolated from infrastructure

### 2. Maintainability
- Clear separation of concerns
- Easy to understand and modify
- Changes in one layer don't affect others

### 3. Scalability
- Easy to add new features
- Easy to replace implementations
- Easy to add new delivery mechanisms

### 4. Independence
- Framework independent
- Database independent
- External service independent

## Best Practices

### 1. Dependency Injection
```go
// Use interfaces for dependencies
type UserService struct {
    repo   repository.UserRepository
    cache  cache.UserCache
    logger *zap.Logger
}

// Inject dependencies through constructor
func NewUserService(repo repository.UserRepository, cache cache.UserCache, logger *zap.Logger) *UserService {
    return &UserService{
        repo:   repo,
        cache:  cache,
        logger: logger,
    }
}
```

### 2. Error Handling
```go
// Use custom error types for domain errors
var (
    ErrUserNotFound = errors.New("user not found")
    ErrInvalidEmail = errors.New("invalid email")
)

// Handle errors at appropriate layers
func (h *CreateUserHandler) Handle(ctx context.Context, cmd CreateUserCommand) (*User, error) {
    if err := validateEmail(cmd.Email); err != nil {
        return nil, fmt.Errorf("invalid email: %w", err)
    }
    // ... rest of implementation
}
```

### 3. Validation
```go
// Validate at domain level
func (u *User) Validate() error {
    if u.Name == "" {
        return ErrInvalidName
    }
    if !isValidEmail(u.Email) {
        return ErrInvalidEmail
    }
    return nil
}

// Validate at delivery level
func (h *UserHandler) CreateUser(c *gin.Context) {
    var req CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{Error: "Invalid request"})
        return
    }
}
```

## Conclusion

Clean Architecture provides a solid foundation for building maintainable, testable, and scalable applications. By following these principles, we ensure that our code is:

- **Independent of frameworks**
- **Testable**
- **Independent of UI**
- **Independent of database**
- **Independent of any external agency**

This architecture allows us to focus on business logic while keeping external concerns separate and manageable.

---

## Changelog

### Version 1.0.0 (2024-08-07)
- Initial documentation of Clean Architecture principles