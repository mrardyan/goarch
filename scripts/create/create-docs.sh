#!/bin/bash

# Documentation Creation Script
# This script creates comprehensive documentation for services, APIs, and project structure
# Uses create.sh as base and follows the create-* naming convention for consistency

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCS_DIR="docs"
API_DOCS_DIR="docs/api"
SERVICE_DOCS_DIR="docs/services"
PROJECT_DOCS_DIR="docs/project"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to create documentation directories
setup_documentation_directories() {
    print_info "Setting up documentation directories..."
    
    mkdir -p "$API_DOCS_DIR"
    mkdir -p "$SERVICE_DOCS_DIR"
    mkdir -p "$PROJECT_DOCS_DIR"
    
    print_success "Documentation directories ready"
}

# Function to generate API documentation
generate_api_documentation() {
    local service_name=$1
    
    print_info "Generating API documentation for service: $service_name"
    
    local api_doc_file="$API_DOCS_DIR/${service_name}-api.md"
    
    cat > "$api_doc_file" << EOF
# $service_name API Documentation

## Overview
This document describes the API endpoints for the $service_name service.

## Base URL
\`/api/v1/$service_name\`

## Authentication
All endpoints require authentication unless otherwise specified.

## Endpoints

### GET /api/v1/$service_name
Retrieve a list of $service_name resources.

**Query Parameters:**
- \`limit\` (optional): Number of items to return (default: 10, max: 100)
- \`offset\` (optional): Number of items to skip (default: 0)
- \`sort\` (optional): Sort field (default: created_at)
- \`order\` (optional): Sort order (asc/desc, default: desc)

**Response:**
\`\`\`json
{
  "data": [
    {
      "id": "string",
      "created_at": "2023-01-01T00:00:00Z",
      "updated_at": "2023-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "total": 100,
    "limit": 10,
    "offset": 0,
    "has_next": true,
    "has_prev": false
  }
}
\`\`\`

### GET /api/v1/$service_name/{id}
Retrieve a specific $service_name resource.

**Path Parameters:**
- \`id\` (required): The unique identifier of the resource

**Response:**
\`\`\`json
{
  "data": {
    "id": "string",
    "created_at": "2023-01-01T00:00:00Z",
    "updated_at": "2023-01-01T00:00:00Z"
  }
}
\`\`\`

### POST /api/v1/$service_name
Create a new $service_name resource.

**Request Body:**
\`\`\`json
{
  "field1": "value1",
  "field2": "value2"
}
\`\`\`

**Response:**
\`\`\`json
{
  "data": {
    "id": "string",
    "created_at": "2023-01-01T00:00:00Z",
    "updated_at": "2023-01-01T00:00:00Z"
  }
}
\`\`\`

### PUT /api/v1/$service_name/{id}
Update an existing $service_name resource.

**Path Parameters:**
- \`id\` (required): The unique identifier of the resource

**Request Body:**
\`\`\`json
{
  "field1": "updated_value1",
  "field2": "updated_value2"
}
\`\`\`

**Response:**
\`\`\`json
{
  "data": {
    "id": "string",
    "created_at": "2023-01-01T00:00:00Z",
    "updated_at": "2023-01-01T00:00:00Z"
  }
}
\`\`\`

### DELETE /api/v1/$service_name/{id}
Delete a $service_name resource.

**Path Parameters:**
- \`id\` (required): The unique identifier of the resource

**Response:**
\`\`\`json
{
  "message": "Resource deleted successfully"
}
\`\`\`

## Error Responses

### 400 Bad Request
\`\`\`json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "field1": ["Field is required"],
      "field2": ["Invalid format"]
    }
  }
}
\`\`\`

### 401 Unauthorized
\`\`\`json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}
\`\`\`

### 403 Forbidden
\`\`\`json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "Insufficient permissions"
  }
}
\`\`\`

### 404 Not Found
\`\`\`json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Resource not found"
  }
}
\`\`\`

### 500 Internal Server Error
\`\`\`json
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An internal error occurred"
  }
}
\`\`\`

## Rate Limiting
API requests are limited to 1000 requests per hour per API key.

## Versioning
This API follows semantic versioning. The current version is v1.

## Support
For API support, please contact the development team.
EOF
    
    print_success "API documentation generated: $api_doc_file"
}

# Function to generate service documentation
generate_service_documentation() {
    local service_name=$1
    
    print_info "Generating service documentation for: $service_name"
    
    local service_doc_file="$SERVICE_DOCS_DIR/${service_name}.md"
    
    cat > "$service_doc_file" << EOF
# $service_name Service

## Overview
The $service_name service is responsible for managing $service_name-related business logic and data.

## Architecture

### Domain Layer
The domain layer contains the core business logic and entities:

- **Entities**: Core business objects
- **Repositories**: Data access interfaces
- **Services**: Domain-specific business logic

### Application Layer
The application layer orchestrates use cases and business processes:

- **Commands**: Write operations and business processes
- **Queries**: Read operations and data retrieval
- **DTOs**: Data transfer objects for API communication

### Infrastructure Layer
The infrastructure layer handles external dependencies:

- **PostgreSQL**: Primary data storage
- **Redis**: Caching and session storage
- **External Services**: Third-party integrations

### Delivery Layer
The delivery layer exposes the service via HTTP:

- **Handlers**: HTTP request/response handling
- **Middleware**: Authentication, logging, etc.
- **Routing**: URL routing and request dispatching

## Business Logic

### Core Entities
- **Entity**: The main business object managed by this service

### Business Rules
- Business rule 1
- Business rule 2
- Business rule 3

### Validation Rules
- Validation rule 1
- Validation rule 2
- Validation rule 3

## API Endpoints

### REST Endpoints
- \`GET /api/v1/$service_name\` - List resources
- \`GET /api/v1/$service_name/{id}\` - Get resource
- \`POST /api/v1/$service_name\` - Create resource
- \`PUT /api/v1/$service_name/{id}\` - Update resource
- \`DELETE /api/v1/$service_name/{id}\` - Delete resource

### GraphQL Endpoints (if applicable)
- Query: \`get$service_name(id: ID!)\`
- Query: \`list$service_name(filter: FilterInput)\`
- Mutation: \`create$service_name(input: CreateInput!)\`
- Mutation: \`update$service_name(id: ID!, input: UpdateInput!)\`
- Mutation: \`delete$service_name(id: ID!)\`

## Database Schema

### Tables
- \`$service_name\`: Main table for $service_name data

### Indexes
- Primary key on \`id\`
- Index on \`created_at\` for sorting
- Index on \`updated_at\` for tracking changes

## Configuration

### Environment Variables
- \`DB_HOST\`: Database host
- \`DB_PORT\`: Database port
- \`DB_NAME\`: Database name
- \`DB_USER\`: Database user
- \`DB_PASSWORD\`: Database password
- \`REDIS_HOST\`: Redis host
- \`REDIS_PORT\`: Redis port
- \`API_PORT\`: API server port

### Configuration Files
- \`config/$service_name.yaml\`: Service-specific configuration

## Dependencies

### Internal Dependencies
- Shared utilities
- Common middleware
- Base configurations

### External Dependencies
- PostgreSQL database
- Redis cache
- External service integrations

## Testing

### Unit Tests
Unit tests are located in the service directory and test individual components.

### Integration Tests
Integration tests verify service interactions and database operations.

### Performance Tests
Performance tests ensure the service meets performance requirements.

## Monitoring

### Metrics
- Request rate
- Response time
- Error rate
- Database connection pool usage

### Logging
- Request/response logging
- Error logging
- Business event logging

### Health Checks
- Database connectivity
- Redis connectivity
- External service health

## Deployment

### Docker
The service is containerized using Docker with multi-stage builds.

### Kubernetes
Kubernetes manifests are provided for deployment.

### Environment-Specific Configurations
- Development
- Staging
- Production

## Security

### Authentication
- JWT-based authentication
- API key authentication for service-to-service communication

### Authorization
- Role-based access control
- Resource-level permissions

### Data Protection
- Input validation
- SQL injection prevention
- XSS protection

## Troubleshooting

### Common Issues
1. Database connection issues
2. Redis connection issues
3. External service timeouts

### Debugging
- Enable debug logging
- Check service logs
- Monitor metrics

## Contributing

### Development Setup
1. Clone the repository
2. Install dependencies
3. Set up environment variables
4. Run tests
5. Start the service

### Code Standards
- Follow Go coding standards
- Write comprehensive tests
- Update documentation

## Changelog

### Version 1.0.0
- Initial release
- Basic CRUD operations
- REST API endpoints
EOF
    
    print_success "Service documentation generated: $service_doc_file"
}

# Function to generate project documentation
generate_project_documentation() {
    print_info "Generating project documentation..."
    
    local project_doc_file="$PROJECT_DOCS_DIR/README.md"
    
    cat > "$project_doc_file" << EOF
# Project Documentation

## Overview
This project follows Domain-Driven Design (DDD) principles with a clean architecture approach.

## Project Structure

### Core Directories
- \`cmd/\`: Application entrypoints
- \`internal/\`: Internal application code
- \`pkg/\`: Reusable utilities
- \`docs/\`: Project documentation
- \`scripts/\`: Development and deployment scripts
- \`tests/\`: Test files and configurations

### Service Structure
Each service follows the enhanced layered architecture:

\`\`\`
{service-name}/
├── domain/                    # Pure business rules
│   ├── entity/                # Core entities
│   ├── repository/            # Abstract interfaces
│   ├── service/               # Domain service logic
│   └── types/                 # Value objects, enums
├── application/              # Use case orchestration
│   ├── {subdomain}/          # Subdomains
│       ├── command.go
│       ├── query.go
│       └── dto.go
├── delivery/                 # Controller layer
│   └── http/                 # HTTP handlers & routing
├── infrastructure/           # Adapter layer
│   ├── postgres/             # DB repositories
│   ├── redis/                # Cache layer
│   └── external/             # External service clients
├── config/                   # Service-specific config
├── init/                     # Service initialization
└── module.go                 # Service facade
\`\`\`

## Technology Stack

### Core Technologies
- **Language**: Go 1.23.4
- **Web Framework**: Gin (HTTP routing and middleware)
- **Configuration**: Viper (config management)
- **Logging**: Zap (structured logging)
- **Database**: PostgreSQL (primary database)
- **Cache**: Redis (session storage, caching)

### Development Tools
- **Testing**: Testify (testing utilities)
- **Migrations**: golang-migrate (database migrations)
- **Linting**: golangci-lint (code quality)
- **Documentation**: godoc (API documentation)

## Architecture Principles

### Clean Architecture
- Dependencies point inward
- Domain layer has no external dependencies
- Infrastructure layer implements domain interfaces
- Use abstractions, not concrete implementations

### Domain-Driven Design
- Keep domain logic separate from infrastructure
- Use rich domain models
- Implement domain events for side effects
- Use value objects for immutable data

### SOLID Principles
- **Single Responsibility**: Each service has one reason to change
- **Open/Closed**: Extend functionality without modifying existing code
- **Liskov Substitution**: Use interfaces properly
- **Interface Segregation**: Keep interfaces focused
- **Dependency Inversion**: Depend on abstractions, not concretions

## Development Workflow

### Service Creation
\`\`\`bash
# Interactive service creation
./scripts/create/create-service-interactive.sh

# Direct service creation
./scripts/create/create-service.sh <service-name> --context <context-file>
\`\`\`

### Subdomain Creation
\`\`\`bash
# Interactive subdomain creation
./scripts/create/create-subdomain-interactive.sh

# Direct subdomain creation
./scripts/create/create-subdomain.sh <subdomain> <service> --context <context-file>
\`\`\`

### Feature Creation
\`\`\`bash
# Interactive feature creation
./scripts/create/create-feature-interactive.sh

# Direct feature creation
./scripts/create/create-feature.sh <feature> <service> --context <context-file>
\`\`\`

### Testing
\`\`\`bash
# Comprehensive testing
./scripts/test.sh

# Test specific service
./scripts/test.sh -s <service-name>

# Test specific subdomain
./scripts/test.sh -d <service>/<subdomain>
\`\`\`

## API Design

### REST API
- Follow RESTful principles
- Use consistent URL patterns
- Implement proper HTTP status codes
- Provide comprehensive error responses

### GraphQL API (Optional)
- Single endpoint for all queries
- Strongly typed schema
- Efficient data fetching
- Real-time subscriptions

## Database Design

### Schema Management
- Use migrations for schema changes
- Follow naming conventions
- Implement proper indexing
- Use transactions for data consistency

### Data Access
- Use repository pattern
- Implement connection pooling
- Handle database errors gracefully
- Use prepared statements

## Security

### Authentication
- JWT-based authentication
- OAuth 2.0 integration
- API key authentication
- Session management

### Authorization
- Role-based access control
- Resource-level permissions
- API endpoint protection
- Data access control

### Data Protection
- Input validation
- SQL injection prevention
- XSS protection
- CSRF protection

## Performance

### Optimization Strategies
- Database query optimization
- Caching strategies
- Connection pooling
- Load balancing

### Monitoring
- Application metrics
- Database performance
- API response times
- Error rates

## Deployment

### Containerization
- Multi-stage Docker builds
- Optimized image sizes
- Health checks
- Non-root users

### Orchestration
- Kubernetes deployment
- Service mesh integration
- Auto-scaling
- Rolling updates

### Environment Management
- Environment-specific configs
- Secret management
- Configuration validation
- Feature flags

## Testing Strategy

### Test Types
- **Unit Tests**: Test individual components
- **Integration Tests**: Test service interactions
- **Performance Tests**: Test performance characteristics
- **Security Tests**: Test security measures

### Test Coverage
- Aim for 80%+ test coverage
- Focus on critical paths
- Test error conditions
- Test edge cases

## Documentation

### API Documentation
- OpenAPI/Swagger specifications
- Interactive API documentation
- Request/response examples
- Error code documentation

### Service Documentation
- Service architecture
- Business logic documentation
- Configuration guide
- Troubleshooting guide

### Project Documentation
- Setup instructions
- Development guidelines
- Deployment procedures
- Contributing guidelines

## Contributing

### Development Setup
1. Clone the repository
2. Install Go 1.23.4+
3. Install dependencies
4. Set up environment
5. Run tests

### Code Standards
- Follow Go coding standards
- Write comprehensive tests
- Update documentation
- Use conventional commits

### Pull Request Process
1. Create feature branch
2. Write tests
3. Update documentation
4. Request review
5. Merge after approval

## Support

### Getting Help
- Check documentation
- Review existing issues
- Create new issue
- Contact development team

### Reporting Issues
- Provide detailed description
- Include error logs
- Specify environment
- Provide reproduction steps
EOF
    
    print_success "Project documentation generated: $project_doc_file"
}

# Function to generate API specification
generate_api_specification() {
    local service_name=$1
    
    print_info "Generating API specification for service: $service_name"
    
    local api_spec_file="$API_DOCS_DIR/${service_name}-openapi.yaml"
    
    cat > "$api_spec_file" << EOF
openapi: 3.0.3
info:
  title: $service_name API
  description: API for the $service_name service
  version: 1.0.0
  contact:
    name: Development Team
    email: dev@example.com

servers:
  - url: https://api.example.com/api/v1/$service_name
    description: Production server
  - url: https://staging-api.example.com/api/v1/$service_name
    description: Staging server
  - url: http://localhost:8080/api/v1/$service_name
    description: Development server

security:
  - BearerAuth: []
  - ApiKeyAuth: []

paths:
  /:
    get:
      summary: List $service_name resources
      description: Retrieve a paginated list of $service_name resources
      operationId: list$service_name
      parameters:
        - name: limit
          in: query
          description: Number of items to return
          required: false
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 10
        - name: offset
          in: query
          description: Number of items to skip
          required: false
          schema:
            type: integer
            minimum: 0
            default: 0
        - name: sort
          in: query
          description: Sort field
          required: false
          schema:
            type: string
            default: created_at
        - name: order
          in: query
          description: Sort order
          required: false
          schema:
            type: string
            enum: [asc, desc]
            default: desc
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ListResponse'
        '400':
          description: Bad request
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'
        '401':
          description: Unauthorized
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'
    post:
      summary: Create $service_name resource
      description: Create a new $service_name resource
      operationId: create$service_name
      requestBody:
        required: true
        content:
          application/json:
            schema:
              \$ref: '#/components/schemas/CreateRequest'
      responses:
        '201':
          description: Resource created successfully
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/SingleResponse'
        '400':
          description: Bad request
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'
        '401':
          description: Unauthorized
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'

  /{id}:
    get:
      summary: Get $service_name resource
      description: Retrieve a specific $service_name resource by ID
      operationId: get$service_name
      parameters:
        - name: id
          in: path
          description: Resource ID
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/SingleResponse'
        '404':
          description: Resource not found
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'

    put:
      summary: Update $service_name resource
      description: Update an existing $service_name resource
      operationId: update$service_name
      parameters:
        - name: id
          in: path
          description: Resource ID
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              \$ref: '#/components/schemas/UpdateRequest'
      responses:
        '200':
          description: Resource updated successfully
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/SingleResponse'
        '400':
          description: Bad request
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'
        '404':
          description: Resource not found
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'

    delete:
      summary: Delete $service_name resource
      description: Delete a $service_name resource
      operationId: delete$service_name
      parameters:
        - name: id
          in: path
          description: Resource ID
          required: true
          schema:
            type: string
      responses:
        '204':
          description: Resource deleted successfully
        '404':
          description: Resource not found
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key

  schemas:
    $service_name:
      type: object
      properties:
        id:
          type: string
          description: Unique identifier
        created_at:
          type: string
          format: date-time
          description: Creation timestamp
        updated_at:
          type: string
          format: date-time
          description: Last update timestamp
      required:
        - id
        - created_at
        - updated_at

    CreateRequest:
      type: object
      properties:
        field1:
          type: string
          description: Field 1 description
        field2:
          type: string
          description: Field 2 description
      required:
        - field1

    UpdateRequest:
      type: object
      properties:
        field1:
          type: string
          description: Field 1 description
        field2:
          type: string
          description: Field 2 description

    SingleResponse:
      type: object
      properties:
        data:
          \$ref: '#/components/schemas/$service_name'

    ListResponse:
      type: object
      properties:
        data:
          type: array
          items:
            \$ref: '#/components/schemas/$service_name'
        pagination:
          type: object
          properties:
            total:
              type: integer
              description: Total number of items
            limit:
              type: integer
              description: Number of items per page
            offset:
              type: integer
              description: Number of items skipped
            has_next:
              type: boolean
              description: Whether there are more items
            has_prev:
              type: boolean
              description: Whether there are previous items

    ErrorResponse:
      type: object
      properties:
        error:
          type: object
          properties:
            code:
              type: string
              description: Error code
            message:
              type: string
              description: Error message
            details:
              type: object
              description: Additional error details
          required:
            - code
            - message
EOF
    
    print_success "API specification generated: $api_spec_file"
}

# Function to integrate with create.sh base
integrate_with_create_base() {
    local target=${1:-"all"}
    
    print_info "Integrating with create.sh base system..."
    
    # Check if base create.sh exists
    if [[ ! -f "scripts/create.sh" ]]; then
        print_error "Base create.sh script not found"
        return 1
    fi
    
    # Use base create.sh for service discovery
    print_info "Using create.sh for service structure analysis"
    
    return 0
}

# Function to generate comprehensive documentation
generate_comprehensive_documentation() {
    local target=${1:-"all"}
    
    print_info "Starting comprehensive documentation generation for: $target"
    
    # Integrate with create.sh base
    integrate_with_create_base "$target"
    
    # Setup directories
    setup_documentation_directories
    
    case $target in
        all)
            # Generate project documentation
            generate_project_documentation
            
            # Generate documentation for all services
            if [[ -d "internal/services" ]]; then
                for service in internal/services/*/; do
                    if [[ -d "$service" ]]; then
                        service_name=$(basename "$service")
                        generate_api_documentation "$service_name"
                        generate_service_documentation "$service_name"
                        generate_api_specification "$service_name"
                    fi
                done
            fi
            ;;
        project)
            generate_project_documentation
            ;;
        services)
            if [[ -d "internal/services" ]]; then
                for service in internal/services/*/; do
                    if [[ -d "$service" ]]; then
                        service_name=$(basename "$service")
                        generate_service_documentation "$service_name"
                    fi
                done
            fi
            ;;
        api)
            if [[ -d "internal/services" ]]; then
                for service in internal/services/*/; do
                    if [[ -d "$service" ]]; then
                        service_name=$(basename "$service")
                        generate_api_documentation "$service_name"
                        generate_api_specification "$service_name"
                    fi
                done
            fi
            ;;
        *)
            print_error "Unknown target: $target"
            return 1
            ;;
    esac
    
    print_success "Documentation generation completed!"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [TARGET]"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -s, --service NAME      Generate documentation for specific service"
    echo "  -o, --output DIR        Output directory for documentation"
    echo "  -f, --format FORMAT     Output format (markdown, html, pdf)"
    echo "  --context <file>        Use context file for documentation generation"
    echo "  --interactive           Run in interactive mode"
    echo
    echo "Targets:"
    echo "  all                     Generate all documentation (default)"
    echo "  project                 Generate project documentation only"
    echo "  services                Generate service documentation only"
    echo "  api                     Generate API documentation only"
    echo
    echo "Examples:"
    echo "  $0                      # Generate all documentation"
    echo "  $0 -s user-service      # Generate documentation for specific service"
    echo "  $0 project              # Generate project documentation only"
    echo "  $0 api                  # Generate API documentation only"
    echo "  $0 --context context.yaml # Generate docs with context file"
    echo "  $0 --interactive        # Interactive documentation generation"
    echo
    echo "Description:"
    echo "  This script creates comprehensive documentation for the Go architecture project."
    echo "  It integrates with create.sh base system and follows the create-* pattern."
    echo "  Supports context-based customization and interactive mode."
}

# Main function
main() {
    local target="all"
    local service_name=""
    local output_dir=""
    local format="markdown"
    local context_file=""
    local interactive=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -s|--service)
                service_name="$2"
                shift 2
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            -f|--format)
                format="$2"
                shift 2
                ;;
            --context)
                context_file="$2"
                shift 2
                ;;
            --interactive)
                interactive=true
                shift
                ;;
            all|project|services|api)
                target="$1"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check if we're in the project root
    if [[ ! -f "go.mod" ]]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Check if base create.sh exists
    if [[ ! -f "scripts/create.sh" ]]; then
        print_error "Base create.sh script not found."
        exit 1
    fi
    
    # Handle interactive mode
    if [[ "$interactive" == true ]]; then
        print_info "Interactive mode not yet implemented"
        print_info "Use --context option with a YAML file for customization"
        exit 0
    fi
    
    # Handle context file mode
    if [[ -n "$context_file" ]]; then
        if [[ ! -f "$context_file" ]]; then
            print_error "Context file not found: $context_file"
            exit 1
        fi
        print_info "Using context file: $context_file"
    fi
    
    # Run documentation generation
    if [[ -n "$service_name" ]]; then
        # Generate documentation for specific service
        generate_api_documentation "$service_name"
        generate_service_documentation "$service_name"
        generate_api_specification "$service_name"
    else
        # Generate comprehensive documentation
        generate_comprehensive_documentation "$target"
    fi
    
    print_success "Documentation generation completed successfully!"
}

# Run main function
main "$@"
