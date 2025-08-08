# API Testing Documentation

## Overview

This section provides comprehensive testing documentation for all API endpoints in the golang-arch project. It includes testing strategies, tools, and examples for ensuring API reliability and functionality.

## Testing Strategy

### Testing Pyramid

1. **Unit Tests** (70%): Test individual functions and methods
2. **Integration Tests** (20%): Test API endpoints and database interactions
3. **End-to-End Tests** (10%): Test complete user workflows

### Testing Levels

- **Unit Tests**: Fast, isolated tests for business logic
- **Integration Tests**: Test API endpoints with database
- **Contract Tests**: Ensure API contracts are maintained
- **Performance Tests**: Load and stress testing
- **Security Tests**: Authentication and authorization testing

## Testing Tools

### Primary Tools

- **Go Testing**: Built-in testing framework
- **Testify**: Enhanced assertions and mocking
- **Gin Test**: HTTP testing for Gin framework
- **Postman**: API testing and collection management
- **Newman**: Command-line Postman runner

### Additional Tools

- **Dredd**: API Blueprint testing
- **Artillery**: Load testing
- **OWASP ZAP**: Security testing
- **SonarQube**: Code quality analysis

## Test Structure

### Unit Tests

```go
// internal/services/auth/service_test.go
package auth

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestUserRegistration(t *testing.T) {
    // Arrange
    service := NewAuthService(mockRepo, mockValidator)
    request := RegisterRequest{
        Email:    "test@example.com",
        Password: "SecurePass123!",
        Name:     "Test User",
    }

    // Act
    result, err := service.Register(request)

    // Assert
    assert.NoError(t, err)
    assert.NotNil(t, result)
    assert.Equal(t, "test@example.com", result.Email)
}
```

### Integration Tests

```go
// tests/http/auth_test.go
package http

import (
    "testing"
    "net/http"
    "net/http/httptest"
    "encoding/json"
    "bytes"
    "github.com/gin-gonic/gin"
    "github.com/stretchr/testify/assert"
)

func TestRegisterEndpoint(t *testing.T) {
    // Setup
    gin.SetMode(gin.TestMode)
    router := setupTestRouter()
    
    // Test data
    requestBody := map[string]interface{}{
        "email":    "test@example.com",
        "password": "SecurePass123!",
        "name":     "Test User",
    }
    jsonBody, _ := json.Marshal(requestBody)
    
    // Create request
    req, _ := http.NewRequest("POST", "/v1/auth/register", bytes.NewBuffer(jsonBody))
    req.Header.Set("Content-Type", "application/json")
    
    // Execute request
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    
    // Assertions
    assert.Equal(t, http.StatusCreated, w.Code)
    
    var response map[string]interface{}
    json.Unmarshal(w.Body.Bytes(), &response)
    assert.True(t, response["success"].(bool))
}
```

## Postman Collections

### Collection Structure

```
API Testing Collections/
├── Auth Service/
│   ├── Register User
│   ├── Login User
│   ├── Get Profile
│   └── Update Profile
├── User Service/
│   ├── Get User
│   ├── Create User
│   ├── Update User
│   └── Search Users
├── Product Service/
│   ├── Get Products
│   ├── Create Product
│   ├── Update Product
│   └── Search Products
└── Order Service/
    ├── Create Order
    ├── Get Order
    ├── Process Payment
    └── List Orders
```

### Environment Variables

```json
{
  "base_url": "https://api.example.com/v1",
  "auth_token": "{{auth_token}}",
  "user_id": "{{user_id}}",
  "product_id": "{{product_id}}",
  "order_id": "{{order_id}}"
}
```

### Pre-request Scripts

```javascript
// Set auth token from previous response
pm.environment.set("auth_token", pm.response.json().data.token.access_token);
```

### Test Scripts

```javascript
// Validate response structure
pm.test("Response has correct structure", function () {
    const response = pm.response.json();
    pm.expect(response).to.have.property('success');
    pm.expect(response).to.have.property('data');
    pm.expect(response).to.have.property('message');
    pm.expect(response).to.have.property('meta');
});

// Validate status code
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

// Validate response time
pm.test("Response time is less than 500ms", function () {
    pm.expect(pm.response.responseTime).to.be.below(500);
});
```

## Test Data Management

### Test Fixtures

```yaml
# tests/fixtures/users.yaml
users:
  - id: "550e8400-e29b-41d4-a716-446655440000"
    email: "test@example.com"
    password: "SecurePass123!"
    name: "Test User"
    status: "active"
  
  - id: "550e8400-e29b-41d4-a716-446655440001"
    email: "admin@example.com"
    password: "AdminPass123!"
    name: "Admin User"
    status: "active"
    role: "admin"
```

### Database Seeds

```sql
-- tests/seeds/users.sql
INSERT INTO users (id, email, password_hash, name, status, created_at) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'test@example.com', '$2a$10$...', 'Test User', 'active', NOW()),
('550e8400-e29b-41d4-a716-446655440001', 'admin@example.com', '$2a$10$...', 'Admin User', 'active', NOW());
```

## Performance Testing

### Load Testing with Artillery

```yaml
# tests/performance/load-test.yml
config:
  target: 'https://api.example.com'
  phases:
    - duration: 60
      arrivalRate: 10
  defaults:
    headers:
      Authorization: 'Bearer {{ $randomString() }}'

scenarios:
  - name: "API Load Test"
    requests:
      - get:
          url: "/v1/products"
      - get:
          url: "/v1/products/{{ $randomInt(1, 100) }}"
      - post:
          url: "/v1/auth/login"
          json:
            email: "test@example.com"
            password: "password123"
```

### Stress Testing

```yaml
# tests/performance/stress-test.yml
config:
  target: 'https://api.example.com'
  phases:
    - duration: 120
      arrivalRate: 50
    - duration: 60
      arrivalRate: 100
    - duration: 30
      arrivalRate: 200
```

## Security Testing

### Authentication Tests

```go
func TestAuthenticationRequired(t *testing.T) {
    // Test endpoints that require authentication
    endpoints := []string{
        "/v1/users/profile",
        "/v1/orders",
        "/v1/products/create",
    }
    
    for _, endpoint := range endpoints {
        req, _ := http.NewRequest("GET", endpoint, nil)
        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)
        
        assert.Equal(t, http.StatusUnauthorized, w.Code)
    }
}
```

### Authorization Tests

```go
func TestAdminOnlyEndpoints(t *testing.T) {
    // Test with regular user token
    req, _ := http.NewRequest("GET", "/v1/admin/users", nil)
    req.Header.Set("Authorization", "Bearer "+userToken)
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    
    assert.Equal(t, http.StatusForbidden, w.Code)
    
    // Test with admin token
    req.Header.Set("Authorization", "Bearer "+adminToken)
    w = httptest.NewRecorder()
    router.ServeHTTP(w, req)
    
    assert.Equal(t, http.StatusOK, w.Code)
}
```

## Contract Testing

### API Contract Validation

```go
func TestAPIContract(t *testing.T) {
    // Test response schema validation
    response := makeRequest(t, "GET", "/v1/users/1")
    
    // Validate required fields
    assert.Contains(t, response, "success")
    assert.Contains(t, response, "data")
    assert.Contains(t, response, "message")
    assert.Contains(t, response, "meta")
    
    // Validate data structure
    data := response["data"].(map[string]interface{})
    assert.Contains(t, data, "id")
    assert.Contains(t, data, "email")
    assert.Contains(t, data, "name")
}
```

## Test Automation

### CI/CD Pipeline

```yaml
# .github/workflows/api-tests.yml
name: API Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Go
      uses: actions/setup-go@v2
      with:
        go-version: 1.21
    
    - name: Run unit tests
      run: go test ./... -v
    
    - name: Run integration tests
      run: go test ./tests/integration/... -v
    
    - name: Run API tests with Newman
      run: |
        npm install -g newman
        newman run tests/postman/collections/api-tests.json
```

### Test Reports

```go
// Generate test coverage report
func TestMain(m *testing.M) {
    // Setup
    setupTestEnvironment()
    
    // Run tests
    code := m.Run()
    
    // Cleanup
    cleanupTestEnvironment()
    
    os.Exit(code)
}
```

## Best Practices

### Test Organization

1. **Test Naming**: Use descriptive test names
2. **Test Isolation**: Each test should be independent
3. **Test Data**: Use fixtures and factories
4. **Cleanup**: Always clean up test data
5. **Assertions**: Use meaningful assertions

### Test Coverage

- **Unit Tests**: 90%+ coverage
- **Integration Tests**: All critical paths
- **API Tests**: All endpoints
- **Security Tests**: Authentication and authorization

### Test Data Management

- Use separate test databases
- Clean up after each test
- Use factories for test data
- Avoid hardcoded values

## Monitoring and Reporting

### Test Metrics

- Test execution time
- Test success rate
- Code coverage percentage
- API response times
- Error rates

### Test Reports

```bash
# Generate coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html

# Generate test report
go test -json ./... > test-report.json
```

## Troubleshooting

### Common Issues

1. **Database Connection**: Ensure test database is available
2. **Authentication**: Check token generation and validation
3. **Data Cleanup**: Verify test data is properly cleaned
4. **Environment Variables**: Ensure test environment is configured

### Debug Tips

- Use verbose logging in tests
- Check test database state
- Verify API responses manually
- Use Postman for manual testing
