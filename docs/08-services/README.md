# Services Documentation

## Overview

This section covers individual service documentation, service-specific patterns, and implementations within the monolith. Each service follows clean architecture principles and domain-driven design patterns.

## Service Architecture

### Service Structure
Each service follows a consistent structure:
```
{service-name}/
├── domain/              # Domain entities, value objects, interfaces
│   ├── entity/          # Business entities
│   ├── repository/      # Repository interfaces
│   └── types/          # Domain types and constants
├── application/         # Use cases and orchestration
│   ├── command/        # Command handlers
│   ├── query/          # Query handlers
│   └── dto/            # Data transfer objects
├── infrastructure/      # External implementations
│   ├── postgres/       # Database implementations
│   └── external/       # External service clients
└── delivery/           # Transport layer
    └── http/           # HTTP handlers and routing
```

### Service Communication
- **Internal Communication**: Direct service calls within the monolith
- **External Communication**: HTTP APIs, gRPC, message queues
- **Event-Driven**: Domain events for loose coupling

## Service Categories

### 🔐 Authentication Service
**Purpose**: User authentication, authorization, and session management

**Key Features**:
- JWT token generation and validation
- Password hashing and verification
- Role-based access control (RBAC)
- Multi-factor authentication (MFA)
- Session management

**Domain Entities**:
- User
- Role
- Permission
- Session

**API Endpoints**:
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/logout` - User logout
- `POST /auth/refresh` - Token refresh
- `GET /auth/profile` - User profile

### 👥 User Service
**Purpose**: User management and profile operations

**Key Features**:
- User CRUD operations
- Profile management
- User preferences
- Account settings

**Domain Entities**:
- User
- Profile
- Preference
- Address

**API Endpoints**:
- `GET /users` - List users
- `GET /users/{id}` - Get user
- `POST /users` - Create user
- `PUT /users/{id}` - Update user
- `DELETE /users/{id}` - Delete user

### 📦 Product Service
**Purpose**: Product catalog and inventory management

**Key Features**:
- Product catalog management
- Inventory tracking
- Product categories
- Product search and filtering

**Domain Entities**:
- Product
- Category
- Inventory
- ProductImage

**API Endpoints**:
- `GET /products` - List products
- `GET /products/{id}` - Get product
- `POST /products` - Create product
- `PUT /products/{id}` - Update product
- `DELETE /products/{id}` - Delete product

### 🛒 Order Service
**Purpose**: Order processing and management

**Key Features**:
- Order creation and management
- Payment processing
- Order status tracking
- Order history

**Domain Entities**:
- Order
- OrderItem
- Payment
- Shipping

**API Endpoints**:
- `GET /orders` - List orders
- `GET /orders/{id}` - Get order
- `POST /orders` - Create order
- `PUT /orders/{id}` - Update order
- `DELETE /orders/{id}` - Cancel order

### 📧 Notification Service
**Purpose**: Email, SMS, and push notifications

**Key Features**:
- Email notifications
- SMS notifications
- Push notifications
- Notification templates
- Delivery tracking

**Domain Entities**:
- Notification
- Template
- Recipient
- DeliveryLog

**API Endpoints**:
- `POST /notifications/send` - Send notification
- `GET /notifications` - List notifications
- `GET /notifications/{id}` - Get notification
- `PUT /notifications/{id}` - Update notification

### 📊 Analytics Service
**Purpose**: Data analytics and reporting

**Key Features**:
- User behavior analytics
- Business metrics
- Custom reports
- Data visualization

**Domain Entities**:
- Event
- Metric
- Report
- Dashboard

**API Endpoints**:
- `GET /analytics/events` - List events
- `POST /analytics/events` - Track event
- `GET /analytics/metrics` - Get metrics
- `GET /analytics/reports` - Generate reports

## Service Implementation Patterns

### Domain Layer Implementation
```go
// Domain entity example
type User struct {
    ID        uint      `json:"id"`
    Name      string    `json:"name"`
    Email     string    `json:"email"`
    Role      string    `json:"role"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

// Domain validation
func (u *User) Validate() error {
    if u.Name == "" {
        return errors.New("name is required")
    }
    
    if u.Email == "" {
        return errors.New("email is required")
    }
    
    if !isValidEmail(u.Email) {
        return errors.New("invalid email format")
    }
    
    return nil
}

// Domain business logic
func (u *User) ChangeRole(newRole string) error {
    if !isValidRole(newRole) {
        return errors.New("invalid role")
    }
    
    u.Role = newRole
    u.UpdatedAt = time.Now()
    
    return nil
}
```

### Repository Pattern
```go
// Repository interface
type UserRepository interface {
    Create(ctx context.Context, user *User) error
    FindByID(ctx context.Context, id uint) (*User, error)
    FindByEmail(ctx context.Context, email string) (*User, error)
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id uint) error
    List(ctx context.Context, offset, limit int) ([]User, error)
}

// PostgreSQL implementation
type PostgresUserRepository struct {
    db *sql.DB
}

func NewPostgresUserRepository(db *sql.DB) *PostgresUserRepository {
    return &PostgresUserRepository{db: db}
}

func (r *PostgresUserRepository) Create(ctx context.Context, user *User) error {
    query := `
        INSERT INTO users (name, email, role, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id
    `
    
    return r.db.QueryRowContext(ctx, query,
        user.Name, user.Email, user.Role, user.CreatedAt, user.UpdatedAt,
    ).Scan(&user.ID)
}

func (r *PostgresUserRepository) FindByID(ctx context.Context, id uint) (*User, error) {
    query := `
        SELECT id, name, email, role, created_at, updated_at
        FROM users WHERE id = $1
    `
    
    user := &User{}
    err := r.db.QueryRowContext(ctx, query, id).Scan(
        &user.ID, &user.Name, &user.Email, &user.Role, &user.CreatedAt, &user.UpdatedAt,
    )
    
    if err != nil {
        return nil, err
    }
    
    return user, nil
}
```

### Application Layer Implementation
```go
// Use case interface
type CreateUserUseCase interface {
    Execute(ctx context.Context, command CreateUserCommand) (*User, error)
}

// Command
type CreateUserCommand struct {
    Name  string `json:"name" binding:"required"`
    Email string `json:"email" binding:"required,email"`
    Role  string `json:"role" binding:"required"`
}

// Use case implementation
type createUserUseCase struct {
    userRepo UserRepository
    eventBus EventBus
}

func NewCreateUserUseCase(userRepo UserRepository, eventBus EventBus) CreateUserUseCase {
    return &createUserUseCase{
        userRepo: userRepo,
        eventBus: eventBus,
    }
}

func (uc *createUserUseCase) Execute(ctx context.Context, command CreateUserCommand) (*User, error) {
    // Validate command
    if err := command.Validate(); err != nil {
        return nil, err
    }
    
    // Check if user already exists
    existingUser, _ := uc.userRepo.FindByEmail(ctx, command.Email)
    if existingUser != nil {
        return nil, errors.New("user already exists")
    }
    
    // Create user
    user := &User{
        Name:      command.Name,
        Email:     command.Email,
        Role:      command.Role,
        CreatedAt: time.Now(),
        UpdatedAt: time.Now(),
    }
    
    if err := user.Validate(); err != nil {
        return nil, err
    }
    
    if err := uc.userRepo.Create(ctx, user); err != nil {
        return nil, err
    }
    
    // Publish domain event
    event := &UserCreatedEvent{
        UserID: user.ID,
        Email:  user.Email,
    }
    uc.eventBus.Publish(event)
    
    return user, nil
}
```

### Delivery Layer Implementation
```go
// HTTP handler
type UserHandler struct {
    createUserUseCase CreateUserUseCase
    getUserUseCase    GetUserUseCase
    updateUserUseCase UpdateUserUseCase
    deleteUserUseCase DeleteUserUseCase
}

func NewUserHandler(
    createUserUseCase CreateUserUseCase,
    getUserUseCase GetUserUseCase,
    updateUserUseCase UpdateUserUseCase,
    deleteUserUseCase DeleteUserUseCase,
) *UserHandler {
    return &UserHandler{
        createUserUseCase: createUserUseCase,
        getUserUseCase:    getUserUseCase,
        updateUserUseCase: updateUserUseCase,
        deleteUserUseCase: deleteUserUseCase,
    }
}

func (h *UserHandler) CreateUser(c *gin.Context) {
    var command CreateUserCommand
    if err := c.ShouldBindJSON(&command); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    user, err := h.createUserUseCase.Execute(c.Request.Context(), command)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(http.StatusCreated, user)
}

func (h *UserHandler) GetUser(c *gin.Context) {
    id, err := strconv.ParseUint(c.Param("id"), 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user id"})
        return
    }
    
    user, err := h.getUserUseCase.Execute(c.Request.Context(), uint(id))
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
        return
    }
    
    c.JSON(http.StatusOK, user)
}

// Router setup
func SetupUserRoutes(router *gin.RouterGroup, handler *UserHandler) {
    users := router.Group("/users")
    {
        users.POST("", handler.CreateUser)
        users.GET("/:id", handler.GetUser)
        users.PUT("/:id", handler.UpdateUser)
        users.DELETE("/:id", handler.DeleteUser)
    }
}
```

## Service Dependencies

### Dependency Injection
```go
// Service container
type ServiceContainer struct {
    UserService     *UserService
    ProductService  *ProductService
    OrderService    *OrderService
    AuthService     *AuthService
}

func NewServiceContainer(config *Config) *ServiceContainer {
    // Initialize database
    db := initDatabase(config.Database)
    
    // Initialize repositories
    userRepo := NewPostgresUserRepository(db)
    productRepo := NewPostgresProductRepository(db)
    orderRepo := NewPostgresOrderRepository(db)
    
    // Initialize use cases
    createUserUseCase := NewCreateUserUseCase(userRepo, eventBus)
    getUserUseCase := NewGetUserUseCase(userRepo)
    updateUserUseCase := NewUpdateUserUseCase(userRepo)
    deleteUserUseCase := NewDeleteUserUseCase(userRepo)
    
    // Initialize services
    userService := NewUserService(createUserUseCase, getUserUseCase, updateUserUseCase, deleteUserUseCase)
    productService := NewProductService(productRepo)
    orderService := NewOrderService(orderRepo)
    authService := NewAuthService(userRepo)
    
    return &ServiceContainer{
        UserService:    userService,
        ProductService: productService,
        OrderService:   orderService,
        AuthService:    authService,
    }
}
```

### Service Communication
```go
// Service-to-service communication
type OrderService struct {
    orderRepo    OrderRepository
    userService  UserService
    productService ProductService
    notificationService NotificationService
}

func (s *OrderService) CreateOrder(ctx context.Context, command CreateOrderCommand) (*Order, error) {
    // Validate user exists
    user, err := s.userService.GetUser(ctx, command.UserID)
    if err != nil {
        return nil, errors.New("user not found")
    }
    
    // Validate products exist
    for _, item := range command.Items {
        product, err := s.productService.GetProduct(ctx, item.ProductID)
        if err != nil {
            return nil, fmt.Errorf("product %d not found", item.ProductID)
        }
        
        if product.Stock < item.Quantity {
            return nil, fmt.Errorf("insufficient stock for product %d", item.ProductID)
        }
    }
    
    // Create order
    order := &Order{
        UserID:    command.UserID,
        Items:     command.Items,
        Total:     calculateTotal(command.Items),
        Status:    "pending",
        CreatedAt: time.Now(),
    }
    
    if err := s.orderRepo.Create(ctx, order); err != nil {
        return nil, err
    }
    
    // Send notification
    notification := &Notification{
        UserID:  user.ID,
        Type:    "order_created",
        Message: fmt.Sprintf("Order #%d has been created", order.ID),
    }
    
    s.notificationService.SendNotification(ctx, notification)
    
    return order, nil
}
```

## Service Testing

### Unit Testing
```go
func TestCreateUserUseCase_Execute(t *testing.T) {
    // Arrange
    mockRepo := &MockUserRepository{}
    mockEventBus := &MockEventBus{}
    
    useCase := NewCreateUserUseCase(mockRepo, mockEventBus)
    
    command := CreateUserCommand{
        Name:  "John Doe",
        Email: "john@example.com",
        Role:  "user",
    }
    
    // Act
    user, err := useCase.Execute(context.Background(), command)
    
    // Assert
    assert.NoError(t, err)
    assert.NotNil(t, user)
    assert.Equal(t, command.Name, user.Name)
    assert.Equal(t, command.Email, user.Email)
    assert.Equal(t, command.Role, user.Role)
}
```

### Integration Testing
```go
func TestUserServiceIntegration(t *testing.T) {
    // Setup test database
    db := setupTestDatabase(t)
    defer cleanupTestDatabase(t, db)
    
    // Initialize service
    userRepo := NewPostgresUserRepository(db)
    eventBus := NewInMemoryEventBus()
    createUserUseCase := NewCreateUserUseCase(userRepo, eventBus)
    
    // Test user creation
    command := CreateUserCommand{
        Name:  "Integration Test",
        Email: "integration@test.com",
        Role:  "user",
    }
    
    user, err := createUserUseCase.Execute(context.Background(), command)
    assert.NoError(t, err)
    assert.NotNil(t, user)
    
    // Verify user was saved
    savedUser, err := userRepo.FindByID(context.Background(), user.ID)
    assert.NoError(t, err)
    assert.Equal(t, user.Name, savedUser.Name)
}
```

## Service Configuration

### Environment Variables
```bash
# Service-specific configuration
USER_SERVICE_PORT=8081
PRODUCT_SERVICE_PORT=8082
ORDER_SERVICE_PORT=8083
AUTH_SERVICE_PORT=8084

# Database configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=app_db
DB_USER=app_user
DB_PASSWORD=app_password

# Redis configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
```

### Service Discovery
```go
// Service registry
type ServiceRegistry struct {
    services map[string]ServiceInfo
    mu       sync.RWMutex
}

type ServiceInfo struct {
    Name     string
    Host     string
    Port     int
    Health   string
    Metadata map[string]string
}

func (sr *ServiceRegistry) Register(service ServiceInfo) {
    sr.mu.Lock()
    defer sr.mu.Unlock()
    
    sr.services[service.Name] = service
}

func (sr *ServiceRegistry) GetService(name string) (ServiceInfo, bool) {
    sr.mu.RLock()
    defer sr.mu.RUnlock()
    
    service, exists := sr.services[name]
    return service, exists
}
```

## Service Monitoring

### Health Checks
```go
// Service health check
func (s *UserService) HealthCheck() HealthStatus {
    return HealthStatus{
        Service:   "user-service",
        Status:    "healthy",
        Timestamp: time.Now(),
        Checks: map[string]interface{}{
            "database": "connected",
            "cache":    "connected",
        },
    }
}

// Health check endpoint
func HealthCheckHandler(services map[string]HealthChecker) gin.HandlerFunc {
    return func(c *gin.Context) {
        health := make(map[string]HealthStatus)
        
        for name, service := range services {
            health[name] = service.HealthCheck()
        }
        
        c.JSON(http.StatusOK, health)
    }
}
```

### Metrics Collection
```go
// Service metrics
type ServiceMetrics struct {
    RequestCount   prometheus.Counter
    RequestLatency prometheus.Histogram
    ErrorCount     prometheus.Counter
}

func NewServiceMetrics(serviceName string) *ServiceMetrics {
    return &ServiceMetrics{
        RequestCount: prometheus.NewCounter(prometheus.CounterOpts{
            Name: fmt.Sprintf("%s_requests_total", serviceName),
            Help: "Total number of requests",
        }),
        RequestLatency: prometheus.NewHistogram(prometheus.HistogramOpts{
            Name: fmt.Sprintf("%s_request_duration_seconds", serviceName),
            Help: "Request duration in seconds",
        }),
        ErrorCount: prometheus.NewCounter(prometheus.CounterOpts{
            Name: fmt.Sprintf("%s_errors_total", serviceName),
            Help: "Total number of errors",
        }),
    }
}
```

## Related Documentation

- [Architecture Documentation](../02-architecture/) - Service architecture patterns
- [Development Guide](../03-development/) - Service development practices
- [API Documentation](../10-api-documentation/) - Service API specifications
- [Testing Strategy](../05-testing/) - Service testing approaches
