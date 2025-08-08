# CQRS Pattern

> **Related Documents:**
> - [Service Structure](../02-architecture/01-service-structure.md)
> - [Clean Architecture Principles](../02-architecture/02-clean-architecture.md)
> - [Service Structure Summary](../02-architecture/04-service-structure-summary.md)

## Overview

Command Query Responsibility Segregation (CQRS) is a pattern that separates read and write operations for a data store. In our service structure, we implement CQRS to improve performance, scalability, and maintainability.

## Core Concepts

### 1. Commands (Write Operations)
Commands represent operations that change the state of the system.

```go
// Commands are write operations
type CreateUserCommand struct {
    Name  string `json:"name" validate:"required,min=2"`
    Email string `json:"email" validate:"required,email"`
}

type UpdateUserCommand struct {
    ID    string `json:"id" validate:"required"`
    Name  string `json:"name" validate:"required,min=2"`
    Email string `json:"email" validate:"required,email"`
}

type DeleteUserCommand struct {
    ID string `json:"id" validate:"required"`
}
```

### 2. Queries (Read Operations)
Queries represent operations that retrieve data without changing state.

```go
// Queries are read operations
type GetUserQuery struct {
    ID string `json:"id" validate:"required"`
}

type ListUsersQuery struct {
    Limit  int `json:"limit"`
    Offset int `json:"offset"`
}

type SearchUsersQuery struct {
    Query  string `json:"query"`
    Limit  int    `json:"limit"`
    Offset int    `json:"offset"`
}
```

### 3. Handlers
Handlers process commands and queries.

```go
// Command Handlers
type CreateUserHandler struct {
    repo repository.UserWriter
}

func (h *CreateUserHandler) Handle(ctx context.Context, cmd CreateUserCommand) (*User, error) {
    // Command handling logic
}

// Query Handlers
type GetUserHandler struct {
    repo repository.UserReader
}

func (h *GetUserHandler) Handle(ctx context.Context, query GetUserQuery) (*User, error) {
    // Query handling logic
}
```

## Implementation in Our Architecture

### 1. Domain Layer - Repository Interfaces

```go
// domain/repository/user_repository.go
package repository

// Separate read/write interfaces for CQRS
type UserReader interface {
    GetByID(ctx context.Context, id string) (*User, error)
    List(ctx context.Context, limit, offset int) ([]*User, error)
    Count(ctx context.Context) (int, error)
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

### 2. Application Layer - Command Handlers

```go
// application/user/command.go
package user

import (
    "context"
    "golang-arch/internal/services/user_service/domain/entity"
    "golang-arch/internal/services/user_service/domain/repository"
    "golang-arch/internal/services/user_service/domain/types"
)

type CreateUserCommand struct {
    Name  string `json:"name" validate:"required,min=2"`
    Email string `json:"email" validate:"required,email"`
}

type CreateUserHandler struct {
    repo repository.UserWriter
}

func NewCreateUserHandler(repo repository.UserWriter) *CreateUserHandler {
    return &CreateUserHandler{
        repo: repo,
    }
}

func (h *CreateUserHandler) Handle(ctx context.Context, cmd CreateUserCommand) (*entity.User, error) {
    // Validate email
    email, err := types.NewEmail(cmd.Email)
    if err != nil {
        return nil, err
    }

    // Validate name
    name, err := types.NewName(cmd.Name)
    if err != nil {
        return nil, err
    }

    // Create entity
    user := entity.NewUser(name.Value(), email.Value())

    // Validate entity
    if err := user.Validate(); err != nil {
        return nil, err
    }

    // Save to repository
    if err := h.repo.Create(ctx, user); err != nil {
        return nil, err
    }

    return user, nil
}
```

### 3. Application Layer - Query Handlers

```go
// application/user/query.go
package user

import (
    "context"
    "golang-arch/internal/services/user_service/domain/entity"
    "golang-arch/internal/services/user_service/domain/repository"
    "golang-arch/internal/services/user_service/domain/types"
)

type GetUserQuery struct {
    ID string `json:"id" validate:"required"`
}

type GetUserHandler struct {
    repo repository.UserReader
}

func NewGetUserHandler(repo repository.UserReader) *GetUserHandler {
    return &GetUserHandler{
        repo: repo,
    }
}

func (h *GetUserHandler) Handle(ctx context.Context, query GetUserQuery) (*entity.User, error) {
    return h.repo.GetByID(ctx, query.ID)
}

type ListUsersQuery struct {
    Limit  int `json:"limit"`
    Offset int `json:"offset"`
}

type ListUsersResult struct {
    Users []*entity.User `json:"users"`
    Total int            `json:"total"`
    Limit int            `json:"limit"`
    Offset int           `json:"offset"`
}

type ListUsersHandler struct {
    repo repository.UserReader
}

func NewListUsersHandler(repo repository.UserReader) *ListUsersHandler {
    return &ListUsersHandler{
        repo: repo,
    }
}

func (h *ListUsersHandler) Handle(ctx context.Context, query ListUsersQuery) (*ListUsersResult, error) {
    // Create pagination
    pagination := types.NewPagination(query.Limit, query.Offset)

    // Get users
    users, err := h.repo.List(ctx, pagination.Limit, pagination.Offset)
    if err != nil {
        return nil, err
    }

    // Get total count
    total, err := h.repo.Count(ctx)
    if err != nil {
        return nil, err
    }

    return &ListUsersResult{
        Users:  users,
        Total:  total,
        Limit:  pagination.Limit,
        Offset: pagination.Offset,
    }, nil
}
```

### 4. Infrastructure Layer - Separate Read/Write Models

```go
// infrastructure/postgres/user_repository.go
package postgres

type UserRepository struct {
    db *sql.DB
}

// Write operations
func (r *UserRepository) Create(ctx context.Context, user *entity.User) error {
    query := `INSERT INTO users (id, name, email, created_at, updated_at) VALUES ($1, $2, $3, $4, $5)`
    _, err := r.db.ExecContext(ctx, query, user.ID, user.Name, user.Email, user.CreatedAt, user.UpdatedAt)
    return err
}

func (r *UserRepository) Update(ctx context.Context, user *entity.User) error {
    query := `UPDATE users SET name = $1, email = $2, updated_at = $3 WHERE id = $4`
    _, err := r.db.ExecContext(ctx, query, user.Name, user.Email, user.UpdatedAt, user.ID)
    return err
}

func (r *UserRepository) Delete(ctx context.Context, id string) error {
    query := `DELETE FROM users WHERE id = $1`
    _, err := r.db.ExecContext(ctx, query, id)
    return err
}

// Read operations
func (r *UserRepository) GetByID(ctx context.Context, id string) (*entity.User, error) {
    query := `SELECT id, name, email, created_at, updated_at FROM users WHERE id = $1`
    var user entity.User
    err := r.db.QueryRowContext(ctx, query, id).Scan(&user.ID, &user.Name, &user.Email, &user.CreatedAt, &user.UpdatedAt)
    if err != nil {
        return nil, err
    }
    return &user, nil
}

func (r *UserRepository) List(ctx context.Context, limit, offset int) ([]*entity.User, error) {
    query := `SELECT id, name, email, created_at, updated_at FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2`
    rows, err := r.db.QueryContext(ctx, query, limit, offset)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var users []*entity.User
    for rows.Next() {
        var user entity.User
        err := rows.Scan(&user.ID, &user.Name, &user.Email, &user.CreatedAt, &user.UpdatedAt)
        if err != nil {
            return nil, err
        }
        users = append(users, &user)
    }
    return users, nil
}

func (r *UserRepository) Count(ctx context.Context) (int, error) {
    query := `SELECT COUNT(*) FROM users`
    var count int
    err := r.db.QueryRowContext(ctx, query).Scan(&count)
    return count, err
}
```

### 5. Delivery Layer - HTTP Handlers

```go
// delivery/http/user_handler.go
package http

import (
    "net/http"
    "strconv"
    "github.com/gin-gonic/gin"
    "go.uber.org/zap"
    "golang-arch/internal/services/user_service/application/user"
)

type UserHandler struct {
    createHandler *user.CreateUserHandler
    getHandler    *user.GetUserHandler
    listHandler   *user.ListUsersHandler
    updateHandler *user.UpdateUserHandler
    deleteHandler *user.DeleteUserHandler
    logger        *zap.Logger
}

func NewUserHandler(
    createHandler *user.CreateUserHandler,
    getHandler *user.GetUserHandler,
    listHandler *user.ListUsersHandler,
    updateHandler *user.UpdateUserHandler,
    deleteHandler *user.DeleteUserHandler,
    logger *zap.Logger,
) *UserHandler {
    return &UserHandler{
        createHandler: createHandler,
        getHandler:    getHandler,
        listHandler:   listHandler,
        updateHandler: updateHandler,
        deleteHandler: deleteHandler,
        logger:        logger,
    }
}

// CreateUser handles POST /users
func (h *UserHandler) CreateUser(c *gin.Context) {
    var req CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{Error: "Invalid request"})
        return
    }

    cmd := user.CreateUserCommand{
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

// GetUser handles GET /users/:id
func (h *UserHandler) GetUser(c *gin.Context) {
    id := c.Param("id")
    if id == "" {
        c.JSON(http.StatusBadRequest, ErrorResponse{Error: "User ID is required"})
        return
    }

    query := user.GetUserQuery{ID: id}
    user, err := h.getHandler.Handle(c.Request.Context(), query)
    if err != nil {
        h.logger.Error("Failed to get user", zap.Error(err))
        c.JSON(http.StatusNotFound, ErrorResponse{Error: "User not found"})
        return
    }

    c.JSON(http.StatusOK, GetUserResponse{
        ID:        user.ID,
        Name:      user.Name,
        Email:     user.Email,
        CreatedAt: user.CreatedAt,
        UpdatedAt: user.UpdatedAt,
    })
}

// ListUsers handles GET /users
func (h *UserHandler) ListUsers(c *gin.Context) {
    limitStr := c.DefaultQuery("limit", "10")
    offsetStr := c.DefaultQuery("offset", "0")

    limit, err := strconv.Atoi(limitStr)
    if err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{Error: "Invalid limit parameter"})
        return
    }

    offset, err := strconv.Atoi(offsetStr)
    if err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{Error: "Invalid offset parameter"})
        return
    }

    query := user.ListUsersQuery{
        Limit:  limit,
        Offset: offset,
    }

    result, err := h.listHandler.Handle(c.Request.Context(), query)
    if err != nil {
        h.logger.Error("Failed to list users", zap.Error(err))
        c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "Failed to list users"})
        return
    }

    c.JSON(http.StatusOK, ListUsersResponse{
        Users:  result.Users,
        Total:  result.Total,
        Limit:  result.Limit,
        Offset: result.Offset,
    })
}
```

## Benefits of CQRS

### 1. **Performance Optimization**
- **Read optimization**: Use read-optimized models and indexes
- **Write optimization**: Use write-optimized models and strategies
- **Caching**: Different caching strategies for reads and writes

### 2. **Scalability**
- **Read scaling**: Scale read operations independently
- **Write scaling**: Scale write operations independently
- **Database separation**: Use different databases for reads and writes

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

func (h *CreateUserHandler) validateCommand(cmd CreateUserCommand) error {
    if cmd.Name == "" {
        return ErrInvalidName
    }
    if cmd.Email == "" {
        return ErrInvalidEmail
    }
    return nil
}
```

### 2. **Query Optimization**
```go
func (h *ListUsersHandler) Handle(ctx context.Context, query ListUsersQuery) (*ListUsersResult, error) {
    // Optimize pagination
    if query.Limit > 100 {
        query.Limit = 100
    }
    if query.Offset < 0 {
        query.Offset = 0
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

### 4. **Caching Strategy**
```go
type CachedUserReader struct {
    repo  repository.UserReader
    cache cache.UserCache
}

func (r *CachedUserReader) GetByID(ctx context.Context, id string) (*entity.User, error) {
    // Try cache first
    if user, err := r.cache.Get(ctx, id); err == nil {
        return user, nil
    }
    
    // Fallback to repository
    user, err := r.repo.GetByID(ctx, id)
    if err != nil {
        return nil, err
    }
    
    // Cache the result
    r.cache.Set(ctx, id, user)
    return user, nil
}
```

## Conclusion

CQRS is a powerful pattern that provides significant benefits for complex applications:

1. **Performance**: Optimize reads and writes independently
2. **Scalability**: Scale read and write operations separately
3. **Maintainability**: Clear separation of concerns
4. **Flexibility**: Use different models and technologies

In our service structure, CQRS is implemented through:

- **Separate repository interfaces** for reads and writes
- **Command and query handlers** in the application layer
- **Optimized infrastructure implementations** for different operations
- **Clear separation** in the delivery layer

This approach ensures that our services are performant, scalable, and maintainable.

---

## Changelog

### Version 1.0.0 (2024-08-07)
- Initial documentation of CQRS pattern implementation