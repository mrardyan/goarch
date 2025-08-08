# Cursor Rules Navigation Guide

This folder contains the project's cursor rules organized by topic for better maintainability and navigation.

## Quick Reference

| File | Purpose | Key Rules |
|------|---------|-----------|
| [01-communication-patterns.mdc](./01-communication-patterns.mdc) | Prompt prefixes and commands | `discussion:`, `propose:`, `plan:`, `continue:`, `commit`, `explain`, `retry` |
| [02-architecture-principles.mdc](./02-architecture-principles.mdc) | Architecture patterns and principles | Clean Architecture, DDD, SOLID, dependency inversion |
| [03-development-guidelines.mdc](./03-development-guidelines.mdc) | Code style and conventions | Naming, file organization, error handling, logging |
| [04-documentation-standards.mdc](./04-documentation-standards.mdc) | Documentation structure and process | File organization, naming conventions, update process |
| [05-commit-standards.mdc](./05-commit-standards.mdc) | Git commit conventions | Message format, commit order, workflow |
| [06-testing-strategy.mdc](./06-testing-strategy.mdc) | Testing approaches and organization | Unit tests, integration tests, temporary tests |
| [07-deployment-guidelines.mdc](./07-deployment-guidelines.mdc) | Deployment and environment config | Containerization, environment variables, monitoring |
| [08-troubleshooting.mdc](./08-troubleshooting.mdc) | Common issues and debugging | Import cycles, configuration, database issues |

## Project Overview

This is a Go project following Domain-Driven Design (DDD) principles with a monolith architecture that has clear service boundaries. The project uses Gin for HTTP routing, Viper for configuration, and Zap for logging.

## Technology Stack

- **Language**: Go 1.23.4
- **Web Framework**: Gin (HTTP routing and middleware)
- **Configuration**: Viper (config management)
- **Logging**: Zap (structured logging)
- **Database**: PostgreSQL (primary database)
- **Cache**: Redis (session storage, caching)
- **Testing**: Testify (testing utilities)
- **Migrations**: golang-migrate (database migrations)

## Project Structure

```
├── cmd/                    # Application entrypoints
│   ├── main/              # Main HTTP server
│   └── worker/            # Background job worker
├── internal/              # Internal application code
│   ├── bootstrap/         # DI container, config, server setup
│   ├── services/          # Domain-oriented service modules
│   └── shared/           # Shared utilities (not truly global)
├── pkg/                   # Reusable utilities (non-app-specific)
├── src/                   # Docker copy context, migrations, templates
├── tests/                 # Centralized test directory
├── docs/                  # Project documentation
├── scripts/               # Development and ops scripts
└── .temp/                 # Temporary files and plans
```

## How to Use These Rules

1. **For Communication**: See [01-communication-patterns.mdc](./01-communication-patterns.mdc)
2. **For Architecture Decisions**: See [02-architecture-principles.mdc](./02-architecture-principles.mdc)
3. **For Code Style**: See [03-development-guidelines.mdc](./03-development-guidelines.mdc)
4. **For Documentation**: See [04-documentation-standards.mdc](./04-documentation-standards.mdc)
5. **For Git Workflow**: See [05-commit-standards.mdc](./05-commit-standards.mdc)
6. **For Testing**: See [06-testing-strategy.mdc](./06-testing-strategy.mdc)
7. **For Deployment**: See [07-deployment-guidelines.mdc](./07-deployment-guidelines.mdc)
8. **For Troubleshooting**: See [08-troubleshooting.mdc](./08-troubleshooting.mdc)

## Quick Commands Reference

### Communication Patterns
- `discussion:` or `ask:` - Brainstorming and planning
- `propose:` - Present ideas for review
- `plan:` - Create structured action plan
- `continue:` - Resume work from plan
- `commit` - Commit changes per changes
- `commit once` - Commit all at once
- `commit <module/layer/context/feature>` - Commit specific components
- `explain <context>` - Explain recent changes
- `retry` - Retry last task with same context

### Common Development Commands
```bash
# Setup and build
make setup
make build
make run

# Testing
make test

# Database
make migrate-up
make migrate-down

# Docker
make docker-build
make docker-run
```

## Maintenance

- Keep rules up to date with project evolution
- Update related files when changing rules
- Use clear, descriptive file names
- Maintain consistency across all rule files
