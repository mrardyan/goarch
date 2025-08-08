# Create Scripts

This directory contains all the service and feature creation scripts for the Go architecture project.

## Scripts Overview

### Core Scripts
- **`create.sh`** (in parent directory) - Base template generator for services and subdomains

### Enhanced Scripts (in this directory)

#### Service Creation
- **`create-service.sh`** - Create services with context file support
- **`create-service-interactive.sh`** - Interactive service creation with prompts

#### Subdomain Creation  
- **`create-subdomain.sh`** - Create subdomains with context file support
- **`create-subdomain-interactive.sh`** - Interactive subdomain creation with prompts

#### Feature Creation
- **`create-feature.sh`** - Create features with context file support
- **`create-feature-interactive.sh`** - Interactive feature creation with prompts

#### Documentation Creation
- **`create-docs.sh`** - Create comprehensive documentation with context file support

## Usage Examples

### Service Creation
```bash
# Basic service creation
./scripts/create/create-service.sh user-service

# With context file
./scripts/create/create-service.sh user-service --context context.yaml

# Interactive mode
./scripts/create/create-service-interactive.sh
```

### Subdomain Creation
```bash
# Basic subdomain creation
./scripts/create/create-subdomain.sh profile user-service

# With context file
./scripts/create/create-subdomain.sh profile user-service --context context.yaml

# Interactive mode
./scripts/create/create-subdomain-interactive.sh
```

### Feature Creation
```bash
# Basic feature creation
./scripts/create/create-feature.sh authentication user-service

# With context file
./scripts/create/create-feature.sh authentication user-service --context context.yaml

# Interactive mode
./scripts/create/create-feature-interactive.sh
```

### Documentation Creation
```bash
# Generate all documentation
./scripts/create/create-docs.sh

# Generate documentation for specific service
./scripts/create/create-docs.sh -s user-service

# Generate project documentation only
./scripts/create/create-docs.sh project

# Generate API documentation only
./scripts/create/create-docs.sh api

# With context file
./scripts/create/create-docs.sh --context context.yaml
```

## Script Dependencies

All enhanced scripts in this directory depend on the base `create.sh` script located in the parent directory (`scripts/create.sh`). The enhanced scripts provide:

- **Context-based customization** using YAML files
- **Interactive prompts** for guided creation
- **Advanced validation** and error handling
- **Comprehensive documentation** generation

## Architecture

```
scripts/
├── create.sh                    # Base template generator
└── create/
    ├── create-service.sh        # Enhanced service creation
    ├── create-service-interactive.sh
    ├── create-subdomain.sh      # Enhanced subdomain creation
    ├── create-subdomain-interactive.sh
    ├── create-feature.sh        # Enhanced feature creation
    ├── create-feature-interactive.sh
    ├── create-docs.sh           # Enhanced documentation creation
    └── README.md               # This file
```

## Context Files

Context files are YAML files that define the business requirements, technical specifications, and API design for the service/feature being created. They enable:

- **Consistent generation** across different environments
- **Business logic integration** from the start
- **API-first design** with proper specifications
- **Comprehensive documentation** generation

## Best Practices

1. **Use context files** for production services to ensure consistency
2. **Use interactive mode** for prototyping and learning
3. **Review generated code** before committing
4. **Update documentation** after customizing generated code
5. **Run tests** after creation to ensure everything works

## Migration from Old Scripts

If you were using the old script locations, update your commands:

```bash
# Old
./scripts/create-service.sh user-service

# New  
./scripts/create/create-service.sh user-service
```

The base `create.sh` script remains in the parent directory for backward compatibility and Makefile integration.
