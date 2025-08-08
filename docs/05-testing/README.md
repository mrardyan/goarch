# Testing Strategy

## Overview

This section covers the comprehensive testing strategy for the Go project, including unit tests, integration tests, and end-to-end tests. The testing approach follows the testing pyramid principle and ensures high code quality and reliability.

## Testing Pyramid

### 🧪 Unit Tests (70%)
- **Scope**: Individual functions, methods, and components
- **Speed**: Fast execution (< 100ms per test)
- **Isolation**: No external dependencies
- **Coverage**: High coverage of business logic

### 🔗 Integration Tests (20%)
- **Scope**: Service boundaries and external integrations
- **Speed**: Medium execution (1-10s per test)
- **Dependencies**: Database, external APIs, message queues
- **Coverage**: Service interaction validation

### 🌐 End-to-End Tests (10%)
- **Scope**: Complete user workflows
- **Speed**: Slow execution (10s-60s per test)
- **Dependencies**: Full application stack
- **Coverage**: Critical business paths

## Test Organization

### Directory Structure
```
tests/
├── unit/                    # Unit tests
│   ├── domain/             # Domain logic tests
│   ├── application/        # Use case tests
│   └── infrastructure/     # Repository tests
├── integration/            # Integration tests
│   ├── services/          # Service integration tests
│   ├── database/          # Database integration tests
│   └── external/          # External API tests
├── e2e/                   # End-to-end tests
│   ├── api/               # API workflow tests
│   └── workflows/         # Business workflow tests
└── performance/           # Performance tests
    ├── load/              # Load testing
    └── stress/            # Stress testing
```

## Unit Testing

### Domain Layer Testing
```go
// Example: Domain entity test
func TestUser_ValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        {"valid email", "user@example.com", false},
        {"invalid email", "invalid-email", true},
        {"empty email", "", true},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            user := &User{Email: tt.email}
            err := user.ValidateEmail()
            
            if (err != nil) != tt.wantErr {
                t.Errorf("User.ValidateEmail() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

### Application Layer Testing
```go
// Example: Use case test
func TestCreateUserUseCase_Execute(t *testing.T) {
    // Arrange
    mockRepo := &MockUserRepository{}
    useCase := NewCreateUserUseCase(mockRepo)
    
    // Act
    result, err := useCase.Execute(CreateUserCommand{
        Name:  "John Doe",
        Email: "john@example.com",
    })
    
    // Assert
    assert.NoError(t, err)
    assert.NotNil(t, result)
    assert.Equal(t, "John Doe", result.Name)
}
```

### Infrastructure Layer Testing
```go
// Example: Repository test
func TestPostgresUserRepository_Create(t *testing.T) {
    // Arrange
    db := setupTestDB(t)
    repo := NewPostgresUserRepository(db)
    
    // Act
    user := &User{Name: "Test User", Email: "test@example.com"}
    err := repo.Create(user)
    
    // Assert
    assert.NoError(t, err)
    assert.NotZero(t, user.ID)
}
```

## Integration Testing

### Database Integration Tests
```go
func TestUserRepositoryIntegration(t *testing.T) {
    // Setup test database
    db := setupTestDatabase(t)
    defer cleanupTestDatabase(t, db)
    
    repo := NewPostgresUserRepository(db)
    
    // Test CRUD operations
    t.Run("Create and Find", func(t *testing.T) {
        user := &User{Name: "Integration Test", Email: "integration@test.com"}
        
        // Create
        err := repo.Create(user)
        assert.NoError(t, err)
        
        // Find
        found, err := repo.FindByID(user.ID)
        assert.NoError(t, err)
        assert.Equal(t, user.Name, found.Name)
    })
}
```

### Service Integration Tests
```go
func TestUserServiceIntegration(t *testing.T) {
    // Setup test environment
    db := setupTestDatabase(t)
    cache := setupTestCache(t)
    
    userRepo := NewPostgresUserRepository(db)
    userService := NewUserService(userRepo, cache)
    
    // Test service operations
    t.Run("Create User with Cache", func(t *testing.T) {
        user, err := userService.CreateUser(CreateUserRequest{
            Name:  "Service Test",
            Email: "service@test.com",
        })
        
        assert.NoError(t, err)
        assert.NotNil(t, user)
        
        // Verify cache is populated
        cached, err := cache.Get(fmt.Sprintf("user:%d", user.ID))
        assert.NoError(t, err)
        assert.NotNil(t, cached)
    })
}
```

## End-to-End Testing

### API Workflow Tests
```go
func TestUserAPIE2E(t *testing.T) {
    // Setup test server
    app := setupTestApplication(t)
    defer app.Shutdown()
    
    // Test complete user workflow
    t.Run("User Registration and Login", func(t *testing.T) {
        // 1. Register user
        registerResp := httptest.NewRecorder()
        registerReq := httptest.NewRequest("POST", "/api/v1/users", 
            strings.NewReader(`{"name":"E2E Test","email":"e2e@test.com","password":"password123"}`))
        registerReq.Header.Set("Content-Type", "application/json")
        
        app.ServeHTTP(registerResp, registerReq)
        assert.Equal(t, http.StatusCreated, registerResp.Code)
        
        // 2. Login user
        loginResp := httptest.NewRecorder()
        loginReq := httptest.NewRequest("POST", "/api/v1/auth/login",
            strings.NewReader(`{"email":"e2e@test.com","password":"password123"}`))
        loginReq.Header.Set("Content-Type", "application/json")
        
        app.ServeHTTP(loginResp, loginReq)
        assert.Equal(t, http.StatusOK, loginResp.Code)
        
        // 3. Verify token
        var loginResult map[string]interface{}
        json.Unmarshal(loginResp.Body.Bytes(), &loginResult)
        assert.NotEmpty(t, loginResult["token"])
    })
}
```

## Performance Testing

### Load Testing
```go
func TestUserAPI_LoadTest(t *testing.T) {
    if testing.Short() {
        t.Skip("Skipping load test in short mode")
    }
    
    app := setupTestApplication(t)
    defer app.Shutdown()
    
    // Simulate concurrent user creation
    const numUsers = 100
    const concurrency = 10
    
    var wg sync.WaitGroup
    results := make(chan error, numUsers)
    
    for i := 0; i < numUsers; i++ {
        wg.Add(1)
        go func(id int) {
            defer wg.Done()
            
            resp := httptest.NewRecorder()
            req := httptest.NewRequest("POST", "/api/v1/users",
                strings.NewReader(fmt.Sprintf(`{"name":"Load Test %d","email":"load%d@test.com","password":"password123"}`, id, id)))
            req.Header.Set("Content-Type", "application/json")
            
            app.ServeHTTP(resp, req)
            
            if resp.Code != http.StatusCreated {
                results <- fmt.Errorf("expected status 201, got %d", resp.Code)
            } else {
                results <- nil
            }
        }(i)
    }
    
    wg.Wait()
    close(results)
    
    // Check results
    for err := range results {
        assert.NoError(t, err)
    }
}
```

## Test Utilities

### Test Database Setup
```go
func setupTestDatabase(t *testing.T) *sql.DB {
    // Create test database
    db, err := sql.Open("postgres", "postgres://test:test@localhost/test_db?sslmode=disable")
    require.NoError(t, err)
    
    // Run migrations
    err = runMigrations(db)
    require.NoError(t, err)
    
    return db
}

func cleanupTestDatabase(t *testing.T, db *sql.DB) {
    // Clean up test data
    _, err := db.Exec("TRUNCATE TABLE users CASCADE")
    require.NoError(t, err)
    
    err = db.Close()
    require.NoError(t, err)
}
```

### Mock Generation
```go
//go:generate mockgen -destination=mocks/mock_user_repository.go -package=mocks github.com/yourproject/internal/services/user/domain UserRepository
```

## Test Configuration

### Environment Variables
```bash
# Test configuration
TEST_DB_URL=postgres://test:test@localhost/test_db?sslmode=disable
TEST_REDIS_URL=redis://localhost:6379/1
TEST_LOG_LEVEL=error
```

### Test Tags
```bash
# Run specific test types
go test -tags=unit ./...
go test -tags=integration ./...
go test -tags=e2e ./...
go test -tags=performance ./...

# Skip slow tests
go test -short ./...
```

## Coverage Requirements

### Minimum Coverage
- **Domain Layer**: 95% coverage
- **Application Layer**: 90% coverage
- **Infrastructure Layer**: 85% coverage
- **Overall**: 80% coverage

### Coverage Reports
```bash
# Generate coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html

# View coverage in terminal
go tool cover -func=coverage.out
```

## Continuous Integration

### GitHub Actions
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-go@v2
        with:
          go-version: '1.21'
      - run: go test -v -race -coverprofile=coverage.out ./...
      - run: go tool cover -func=coverage.out
```

## Best Practices

### Test Naming
- Use descriptive test names that explain the scenario
- Follow the pattern: `Test{Function}_{Scenario}_{ExpectedResult}`
- Group related tests using subtests

### Test Data Management
- Use factories for creating test data
- Clean up test data after each test
- Use unique identifiers to avoid conflicts

### Assertions
- Use clear, descriptive assertions
- Test one thing per test case
- Use table-driven tests for multiple scenarios

### Performance
- Keep unit tests fast (< 100ms)
- Use parallel testing where appropriate
- Mock external dependencies

### Maintainability
- Keep tests simple and readable
- Avoid test code duplication
- Use helper functions for common setup

## Related Documentation

- [Development Guide](../03-development/) - Development practices
- [Architecture Documentation](../02-architecture/) - System design
- [API Documentation](../10-api-documentation/) - API testing
- [Performance Testing](../07-performance/) - Performance validation
