# Golang Architecture Template

A well-structured Go project template following domain-driven design principles with clear separation of concerns.

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

## Quick Start

1. **Setup Environment**
   ```bash
   ./scripts/setup.sh
   ```

2. **Create a New Service**
   ```bash
   ./scripts/create.sh service user-service
   ```

3. **Run the Application**
   ```bash
   go run cmd/main/main.go
   ```

4. **Run Tests**
   ```bash
   go test ./...
   ```

## Architecture Overview

This template follows a **monolith with clear service boundaries** approach:

- **Domain-Driven Design**: Each service encapsulates its domain logic
- **Clean Architecture**: Clear separation between layers (domain, application, infrastructure)
- **Dependency Injection**: Centralized DI container for easy testing and configuration
- **Shared Resources**: Common utilities and configurations shared across services

## Key Features

- 🏗️ **Modular Service Architecture**: Each service is self-contained with its own domain logic
- 🔧 **Dependency Injection**: Centralized configuration and service wiring
- 📝 **Comprehensive Testing**: Unit, integration, and performance tests
- 🚀 **Deployment Ready**: Docker and DigitalOcean App Platform templates
- 📚 **Documentation**: Extensive documentation for each service and component

## Development Workflow

1. **Create New Service**: Use the template script to generate service structure
2. **Implement Domain Logic**: Start with domain entities and business rules
3. **Add Application Layer**: Implement use cases and orchestration
4. **Create Infrastructure**: Add database repositories and external integrations
5. **Add Delivery Layer**: HTTP handlers, gRPC services, etc.
6. **Test**: Unit tests for each layer, integration tests for workflows
7. **Document**: Update service documentation and API specs

## Contributing

Please read the development documentation in `docs/development/` for detailed guidelines on:

- Code style and conventions
- Testing strategies
- Documentation standards
- Deployment procedures

## License

MIT License - see LICENSE file for details 