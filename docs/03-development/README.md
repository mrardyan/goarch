# Development Guide

## Overview

This section covers development practices, setup, and workflows for the Go project. It provides comprehensive guidance for developers working on the codebase, including configuration management, environment setup, and development tools.

## Development Environment

### Prerequisites
- **Go**: Version 1.21 or higher
- **PostgreSQL**: Version 13 or higher
- **Redis**: Version 6 or higher
- **Docker**: For containerized development
- **Git**: Version control

### Local Setup
```bash
# Clone the repository
git clone <repository-url>
cd golang-arch

# Install dependencies
go mod download

# Setup environment
cp templates/env/env.development.template .env
# Edit .env with your local configuration

# Run setup script
./scripts/setup.sh

# Start development services
docker-compose up -d

# Run the application
go run cmd/main/main.go
```

## Project Structure

### Directory Organization
```
├── cmd/                    # Application entrypoints
│   ├── main/              # HTTP server
│   └── worker/            # Background worker
├── internal/              # Private application code
│   ├── bootstrap/         # Application bootstrap
│   ├── services/          # Domain services
│   └── shared/            # Shared utilities
├── pkg/                   # Public packages
├── scripts/               # Development scripts
├── templates/             # Code generation templates
├── tests/                 # Test files
└── docs/                  # Documentation
```

### Code Organization Principles
1. **Domain-Driven Design**: Code organized by business domains
2. **Clean Architecture**: Clear separation of concerns
3. **Dependency Injection**: Loose coupling between components
4. **Interface Segregation**: Small, focused interfaces

## Development Workflow

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/user-authentication

# Make changes and commit
git add .
git commit -m "feat: add user authentication"

# Push and create pull request
git push origin feature/user-authentication
```

### 2. Service Creation
```bash
# Create new service
./scripts/create.sh service auth-service

# This generates:
# - Domain entities and interfaces
# - Application use cases
# - Infrastructure implementations
# - HTTP handlers and routing
# - Database migrations
# - Unit tests
```

### 3. Testing
```bash
# Run all tests
go test ./...

# Run tests with coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# Run specific test types
go test -tags=unit ./...
go test -tags=integration ./...
go test -tags=e2e ./...
```

### 4. Code Quality
```bash
# Run linter
golangci-lint run

# Format code
go fmt ./...

# Run security scan
gosec ./...

# Check for vulnerabilities
govulncheck ./...
```

## Configuration Management

### Environment Configuration
```go
// Configuration structure
type Config struct {
    Server   ServerConfig   `mapstructure:"server"`
    Database DatabaseConfig `mapstructure:"database"`
    Redis    RedisConfig    `mapstructure:"redis"`
    JWT      JWTConfig      `mapstructure:"jwt"`
    Log      LogConfig      `mapstructure:"log"`
}

type ServerConfig struct {
    Port    int    `mapstructure:"port"`
    Host    string `mapstructure:"host"`
    Timeout int    `mapstructure:"timeout"`
}

type DatabaseConfig struct {
    Host     string `mapstructure:"host"`
    Port     int    `mapstructure:"port"`
    Name     string `mapstructure:"name"`
    User     string `mapstructure:"user"`
    Password string `mapstructure:"password"`
    SSLMode  string `mapstructure:"ssl_mode"`
}

// Load configuration
func LoadConfig() (*Config, error) {
    viper.SetConfigName("config")
    viper.SetConfigType("yaml")
    viper.AddConfigPath(".")
    
    if err := viper.ReadInConfig(); err != nil {
        return nil, err
    }
    
    var config Config
    if err := viper.Unmarshal(&config); err != nil {
        return nil, err
    }
    
    return &config, nil
}
```

### Environment Variables
```bash
# Development environment
ENV=development
LOG_LEVEL=debug
DB_HOST=localhost
DB_PORT=5432
DB_NAME=app_dev
DB_USER=app_user
DB_PASSWORD=app_password
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=your-secret-key
```

## Development Tools

### Code Generation
```bash
# Generate mocks
mockgen -source=internal/services/user/domain/repository.go -destination=internal/services/user/infrastructure/mocks/mock_repository.go

# Generate API documentation
swag init -g cmd/main/main.go

# Generate database migrations
migrate create -ext sql -dir src/migrations -seq create_users_table
```

### IDE Configuration
```json
// .vscode/settings.json
{
    "go.useLanguageServer": true,
    "go.lintTool": "golangci-lint",
    "go.lintFlags": ["--fast"],
    "go.formatTool": "goimports",
    "go.testFlags": ["-v"],
    "go.coverOnSave": true,
    "go.coverOnTestPackage": true
}
```

### Git Hooks
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run tests
go test ./...

# Run linter
golangci-lint run

# Check formatting
go fmt ./...

# Exit with error if any command fails
exit $?
```

## Database Management

### Migration Management
```bash
# Create migration
migrate create -ext sql -dir src/migrations -seq create_users_table

# Run migrations
migrate -path src/migrations -database "postgres://user:pass@localhost/dbname?sslmode=disable" up

# Rollback migrations
migrate -path src/migrations -database "postgres://user:pass@localhost/dbname?sslmode=disable" down

# Check migration status
migrate -path src/migrations -database "postgres://user:pass@localhost/dbname?sslmode=disable" version
```

### Database Seeding
```go
// Seed data for development
func SeedDatabase(db *sql.DB) error {
    // Create admin user
    adminUser := &User{
        Name:     "Admin User",
        Email:    "admin@example.com",
        Password: "admin123",
        Role:     "admin",
    }
    
    if err := createUser(db, adminUser); err != nil {
        return err
    }
    
    // Create test data
    if err := createTestData(db); err != nil {
        return err
    }
    
    return nil
}
```

## Testing Strategy

### Test Organization
```
tests/
├── unit/              # Unit tests
├── integration/       # Integration tests
├── e2e/              # End-to-end tests
└── performance/      # Performance tests
```

### Test Utilities
```go
// Test database setup
func setupTestDatabase(t *testing.T) *sql.DB {
    db, err := sql.Open("postgres", "postgres://test:test@localhost/test_db?sslmode=disable")
    require.NoError(t, err)
    
    // Run migrations
    err = runMigrations(db)
    require.NoError(t, err)
    
    return db
}

// Test cleanup
func cleanupTestDatabase(t *testing.T, db *sql.DB) {
    _, err := db.Exec("TRUNCATE TABLE users CASCADE")
    require.NoError(t, err)
    
    err = db.Close()
    require.NoError(t, err)
}
```

## Development Scripts

### Available Scripts
```bash
# Setup development environment
./scripts/setup.sh

# Run tests
./scripts/test.sh

# Create new service
./scripts/create.sh service <service-name>

# Create new feature
./scripts/create.sh feature <feature-name>

# Deploy application
./scripts/deploy.sh

# Generate documentation
./scripts/create-docs.sh
```

### Custom Scripts
```bash
#!/bin/bash
# scripts/dev.sh - Development helper script

case "$1" in
    "start")
        echo "Starting development environment..."
        docker-compose up -d
        go run cmd/main/main.go
        ;;
    "test")
        echo "Running tests..."
        go test -v ./...
        ;;
    "lint")
        echo "Running linter..."
        golangci-lint run
        ;;
    "migrate")
        echo "Running migrations..."
        migrate -path src/migrations -database "$DATABASE_URL" up
        ;;
    *)
        echo "Usage: $0 {start|test|lint|migrate}"
        exit 1
        ;;
esac
```

## Debugging and Profiling

### Debug Configuration
```json
// .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Launch Package",
            "type": "go",
            "request": "launch",
            "mode": "auto",
            "program": "${workspaceFolder}/cmd/main/main.go",
            "env": {
                "ENV": "development"
            }
        }
    ]
}
```

### Profiling
```bash
# CPU profiling
go run -cpuprofile=cpu.prof cmd/main/main.go

# Memory profiling
go run -memprofile=mem.prof cmd/main/main.go

# Analyze profiles
go tool pprof cpu.prof
go tool pprof mem.prof
```

## Code Quality Standards

### Coding Standards
1. **Naming Conventions**: Use descriptive names
2. **Error Handling**: Always check and handle errors
3. **Documentation**: Document public APIs
4. **Testing**: Write tests for all functionality
5. **Performance**: Consider performance implications

### Code Review Checklist
- [ ] Code follows project conventions
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] Error handling is appropriate
- [ ] Performance considerations addressed
- [ ] Security implications considered

### Linting Rules
```yaml
# .golangci.yml
linters:
  enable:
    - gofmt
    - golint
    - govet
    - errcheck
    - staticcheck
    - gosimple
    - ineffassign
    - unused
    - misspell
    - gosec

linters-settings:
  govet:
    check-shadowing: true
  gosec:
    excludes:
      - G101 # Look for hardcoded credentials
```

## Development Best Practices

### 1. Code Organization
- Keep functions small and focused
- Use meaningful variable names
- Group related functionality
- Follow Go idioms

### 2. Error Handling
```go
// Good error handling
func processUser(user *User) error {
    if err := user.Validate(); err != nil {
        return fmt.Errorf("invalid user: %w", err)
    }
    
    if err := saveUser(user); err != nil {
        return fmt.Errorf("failed to save user: %w", err)
    }
    
    return nil
}
```

### 3. Logging
```go
// Structured logging
logger.Info("user created",
    "user_id", user.ID,
    "email", user.Email,
    "duration", time.Since(start),
)
```

### 4. Configuration
- Use environment variables for configuration
- Validate configuration on startup
- Provide sensible defaults
- Document all configuration options

### 5. Security
- Validate all inputs
- Use parameterized queries
- Implement proper authentication
- Follow security best practices

## Troubleshooting

### Common Issues
1. **Database Connection**: Check connection string and credentials
2. **Migration Errors**: Ensure database exists and user has permissions
3. **Test Failures**: Check test database setup and cleanup
4. **Build Errors**: Verify Go version and dependencies

### Debug Commands
```bash
# Check Go version
go version

# Check dependencies
go mod tidy
go mod verify

# Check database connection
psql -h localhost -U app_user -d app_dev

# Check Redis connection
redis-cli ping

# Check application logs
docker-compose logs app
```

## Related Documentation

- [Architecture Documentation](../02-architecture/) - System design and patterns
- [Configuration Guide](./01-configuration/) - Configuration management
- [Environment Setup](./02-environment/) - Development environment
- [Template System](./template-system.md) - Code generation
- [Testing Strategy](../05-testing/) - Testing approaches
- [Security Guidelines](../06-security/) - Security best practices 