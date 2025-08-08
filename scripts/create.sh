#!/bin/bash

# Service Creation Script
# Usage: ./scripts/create.sh service <service-name>
# Usage: ./scripts/create.sh subdomain <subdomain-name> <service-name>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔨 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to render template
render_template() {
    local template_file="$1"
    local output_file="$2"
    local service_name="$3"
    local service_title="$4"
    local service_package="$5"
    
    # Process output filename to replace template placeholders
    local processed_output_file=$(echo "$output_file" | sed -e "s/{{\.ServiceName}}/$service_name/g" \
        -e "s/{{\.ServiceTitle}}/$service_title/g" \
        -e "s/{{\.ServicePackage}}/$service_package/g")
    
    # Create output directory if it doesn't exist
    mkdir -p "$(dirname "$processed_output_file")"
    
    # Render template using sed
    sed -e "s/{{\.ServiceName}}/$service_name/g" \
        -e "s/{{\.ServiceTitle}}/$service_title/g" \
        -e "s/{{\.ServicePackage}}/$service_package/g" \
        "$template_file" > "$processed_output_file"
}

# Function to create a service with enhanced structure
create_service() {
    SERVICE_DIR="internal/services/$SERVICE_NAME"
    
    if [ -d "$SERVICE_DIR" ]; then
        print_error "Service $SERVICE_NAME already exists!"
        exit 1
    fi
    
    print_status "Creating enhanced service structure..."
    mkdir -p "$SERVICE_DIR"/{domain/{entity,repository,service,types},application,delivery/http,infrastructure/{postgres,redis,emailservice},config,init}
    
    # Create domain layer
    print_status "Creating domain layer..."
    render_template "templates/service/domain/entity/entity.go.tmpl" \
                   "$SERVICE_DIR/domain/entity/{{.ServicePackage}}.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    render_template "templates/service/domain/repository/repository.go.tmpl" \
                   "$SERVICE_DIR/domain/repository/{{.ServicePackage}}_repository.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    render_template "templates/service/domain/types/types.go.tmpl" \
                   "$SERVICE_DIR/domain/types/types.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    # Create application layer with default subdomain
    print_status "Creating application layer..."
    mkdir -p "$SERVICE_DIR/application/$SERVICE_PACKAGE"
    
    render_template "templates/service/application/{{.ServicePackage}}/command.go.tmpl" \
                   "$SERVICE_DIR/application/$SERVICE_PACKAGE/command.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    render_template "templates/service/application/{{.ServicePackage}}/query.go.tmpl" \
                   "$SERVICE_DIR/application/$SERVICE_PACKAGE/query.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    render_template "templates/service/application/{{.ServicePackage}}/dto.go.tmpl" \
                   "$SERVICE_DIR/application/$SERVICE_PACKAGE/dto.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    # Create delivery layer
    print_status "Creating delivery layer..."
    render_template "templates/service/delivery/http/handler.go.tmpl" \
                   "$SERVICE_DIR/delivery/http/handler.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    render_template "templates/service/delivery/http/router.go.tmpl" \
                   "$SERVICE_DIR/delivery/http/router.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    # Create infrastructure layer
    print_status "Creating infrastructure layer..."
    render_template "templates/service/infrastructure/postgres/repository.go.tmpl" \
                   "$SERVICE_DIR/infrastructure/postgres/repository.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    # Create config layer
    print_status "Creating config layer..."
    render_template "templates/service/config/config.go.tmpl" \
                   "$SERVICE_DIR/config/config.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    # Create init layer
    print_status "Creating init layer..."
    render_template "templates/service/init/init.go.tmpl" \
                   "$SERVICE_DIR/init/init.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    # Create module facade
    print_status "Creating module facade..."
    render_template "templates/service/module.go.tmpl" \
                   "$SERVICE_DIR/module.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    # Create tests
    print_status "Creating test files..."
    mkdir -p "tests/services/$SERVICE_NAME"
    
    render_template "templates/service/tests/service_test.go.tmpl" \
                   "tests/services/$SERVICE_NAME/service_test.go" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    # Create migration
    print_status "Creating database migration..."
    MIGRATION_NAME="create_${SERVICE_PACKAGE}s_table"
    MIGRATION_FILE="src/migrations/$(date +%Y%m%d%H%M%S)_${MIGRATION_NAME}.sql"
    
    render_template "templates/service/migration.sql.tmpl" \
                   "$MIGRATION_FILE" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    # Create documentation
    print_status "Creating documentation..."
    mkdir -p "docs/08-services/$SERVICE_NAME"
    
    render_template "templates/service/README.md.tmpl" \
                   "docs/08-services/$SERVICE_NAME/README.md" \
                   "$SERVICE_NAME" "$SERVICE_TITLE" "$SERVICE_PACKAGE"
    
    # Create service registration template
    print_status "Creating service registration template..."
    cat > "docs/08-services/$SERVICE_NAME/registration.md" << EOF
# {{.ServiceTitle}} Service Registration

## Bootstrap Integration

Add the following to \`internal/bootstrap/di.go\`:

\`\`\`go
import (
    "golang-arch/internal/services/$SERVICE_NAME"
    "golang-arch/internal/services/$SERVICE_NAME/config"
)

// In the setupServices function:
func (c *Container) setupServices() {
    // ... existing services ...
    
    // Register {{.ServiceTitle}} service
    {{.ServicePackage}}Config := config.Default{{.ServiceTitle}}Config()
    {{.ServicePackage}}Module, err := $SERVICE_NAME.NewModule(c.DB, c.Logger, {{.ServicePackage}}Config)
    if err != nil {
        log.Fatalf("Failed to create {{.ServiceTitle}} module: %v", err)
    }
    
    // Setup routes
    {{.ServicePackage}}Module.SetupRoutes(c.Router.Group("/api/v1"))
}
\`\`\`

## Environment Variables

Add to your configuration:

\`\`\`yaml
# {{.ServiceTitle}} Service Configuration
{{.ServicePackage}}_service:
  enabled: true
  timeout: 30s
  cache:
    enabled: true
    ttl: 5m
  database:
    max_open_conns: 25
    max_idle_conns: 5
    conn_max_lifetime: 5m
  api:
    rate_limit: 100
    timeout: 30
\`\`\`

## Database Migration

Run the migration:

\`\`\`bash
make migrate-up
\`\`\`

## Testing

Run service tests:

\`\`\`bash
go test ./tests/services/$SERVICE_NAME/...
\`\`\`
EOF
    
    print_success "Enhanced service '$SERVICE_NAME' created successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Review and customize the generated files"
    echo "2. Add your business logic in application/$SERVICE_PACKAGE/"
    echo "3. Implement database operations in infrastructure/postgres/"
    echo "4. Customize HTTP handlers in delivery/http/"
    echo "5. Add tests in tests/services/$SERVICE_NAME/"
    echo "6. Register the service in internal/bootstrap/di.go"
    echo "7. Run the database migration: make migrate-up"
    echo "8. Test the service: go test ./tests/services/$SERVICE_NAME/..."
    echo ""
    echo "📚 Documentation created at:"
    echo "   - docs/08-services/$SERVICE_NAME/README.md"
    echo "   - docs/08-services/$SERVICE_NAME/registration.md"
    echo ""
    echo "🗄️  Database migration created at:"
    echo "   - $MIGRATION_FILE"
    echo ""
    echo "🧪 Test files created at:"
    echo "   - tests/services/$SERVICE_NAME/service_test.go"
    echo ""
    print_warning "Remember to:"
    echo "   - Add proper validation and business rules"
    echo "   - Implement proper error handling"
    echo "   - Add comprehensive tests"
    echo "   - Update API documentation"
    echo "   - Configure monitoring and logging"
}

# Function to create a subdomain
create_subdomain() {
    SUBDOMAIN_NAME="$1"
    SERVICE_NAME="$2"
    SERVICE_DIR="internal/services/$SERVICE_NAME"
    
    if [ ! -d "$SERVICE_DIR" ]; then
        print_error "Service $SERVICE_NAME does not exist!"
        exit 1
    fi
    
    SUBDOMAIN_DIR="$SERVICE_DIR/application/$SUBDOMAIN_NAME"
    
    if [ -d "$SUBDOMAIN_DIR" ]; then
        print_error "Subdomain $SUBDOMAIN_NAME already exists in service $SERVICE_NAME!"
        exit 1
    fi
    
    print_status "Creating subdomain '$SUBDOMAIN_NAME' in service '$SERVICE_NAME'..."
    mkdir -p "$SUBDOMAIN_DIR"
    
    # Convert subdomain name to various formats
    SUBDOMAIN_TITLE=$(echo $SUBDOMAIN_NAME | sed 's/-/ /g' | sed 's/\b\w/\U&/g' | sed 's/ //g')
    SUBDOMAIN_PACKAGE=$(echo $SUBDOMAIN_NAME | sed 's/-//g')
    
    # Create subdomain files
    print_status "Creating subdomain files..."
    
    # Command file
    cat > "$SUBDOMAIN_DIR/command.go" << EOF
package $SUBDOMAIN_NAME

import (
	"context"
	"golang-arch/internal/services/$SERVICE_NAME/domain/entity"
	"golang-arch/internal/services/$SERVICE_NAME/domain/repository"
	"golang-arch/internal/services/$SERVICE_NAME/domain/types"
)

// Create${SUBDOMAIN_TITLE}Command represents the command to create a ${SUBDOMAIN_TITLE}
type Create${SUBDOMAIN_TITLE}Command struct {
	Name  string \`json:"name" validate:"required,min=2"\`
	Email string \`json:"email" validate:"required,email"\`
}

// Create${SUBDOMAIN_TITLE}Handler handles the creation of a ${SUBDOMAIN_TITLE}
type Create${SUBDOMAIN_TITLE}Handler struct {
	repo repository.${SUBDOMAIN_TITLE}Writer
}

// NewCreate${SUBDOMAIN_TITLE}Handler creates a new command handler
func NewCreate${SUBDOMAIN_TITLE}Handler(repo repository.${SUBDOMAIN_TITLE}Writer) *Create${SUBDOMAIN_TITLE}Handler {
	return &Create${SUBDOMAIN_TITLE}Handler{
		repo: repo,
	}
}

// Handle executes the create command
func (h *Create${SUBDOMAIN_TITLE}Handler) Handle(ctx context.Context, cmd Create${SUBDOMAIN_TITLE}Command) (*entity.${SUBDOMAIN_TITLE}, error) {
	// TODO: Implement command handling logic
	return nil, nil
}
EOF

    # Query file
    cat > "$SUBDOMAIN_DIR/query.go" << EOF
package $SUBDOMAIN_NAME

import (
	"context"
	"golang-arch/internal/services/$SERVICE_NAME/domain/entity"
	"golang-arch/internal/services/$SERVICE_NAME/domain/repository"
)

// Get${SUBDOMAIN_TITLE}Query represents the query to get a ${SUBDOMAIN_TITLE}
type Get${SUBDOMAIN_TITLE}Query struct {
	ID string \`json:"id" validate:"required"\`
}

// Get${SUBDOMAIN_TITLE}Handler handles the retrieval of a ${SUBDOMAIN_TITLE}
type Get${SUBDOMAIN_TITLE}Handler struct {
	repo repository.${SUBDOMAIN_TITLE}Reader
}

// NewGet${SUBDOMAIN_TITLE}Handler creates a new query handler
func NewGet${SUBDOMAIN_TITLE}Handler(repo repository.${SUBDOMAIN_TITLE}Reader) *Get${SUBDOMAIN_TITLE}Handler {
	return &Get${SUBDOMAIN_TITLE}Handler{
		repo: repo,
	}
}

// Handle executes the get query
func (h *Get${SUBDOMAIN_TITLE}Handler) Handle(ctx context.Context, query Get${SUBDOMAIN_TITLE}Query) (*entity.${SUBDOMAIN_TITLE}, error) {
	// TODO: Implement query handling logic
	return nil, nil
}
EOF

    # DTO file
    cat > "$SUBDOMAIN_DIR/dto.go" << EOF
package $SUBDOMAIN_NAME

import (
	"time"
)

// Create${SUBDOMAIN_TITLE}Request represents the request to create a ${SUBDOMAIN_TITLE}
type Create${SUBDOMAIN_TITLE}Request struct {
	Name  string \`json:"name" validate:"required,min=2"\`
	Email string \`json:"email" validate:"required,email"\`
}

// Create${SUBDOMAIN_TITLE}Response represents the response for creating a ${SUBDOMAIN_TITLE}
type Create${SUBDOMAIN_TITLE}Response struct {
	ID        string    \`json:"id"\`
	Name      string    \`json:"name"\`
	Email     string    \`json:"email"\`
	CreatedAt time.Time \`json:"created_at"\`
	UpdatedAt time.Time \`json:"updated_at"\`
}

// Get${SUBDOMAIN_TITLE}Response represents the response for getting a ${SUBDOMAIN_TITLE}
type Get${SUBDOMAIN_TITLE}Response struct {
	ID        string    \`json:"id"\`
	Name      string    \`json:"name"\`
	Email     string    \`json:"email"\`
	CreatedAt time.Time \`json:"created_at"\`
	UpdatedAt time.Time \`json:"updated_at"\`
}
EOF
    
    print_success "Subdomain '$SUBDOMAIN_NAME' created successfully in service '$SERVICE_NAME'!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Review and customize the generated files in $SUBDOMAIN_DIR/"
    echo "2. Add your business logic in application/$SUBDOMAIN_NAME/"
    echo "3. Update domain entities and repositories if needed"
    echo "4. Add tests for the new subdomain"
    echo "5. Update HTTP handlers to include the new subdomain"
    echo ""
    echo "📁 Files created:"
    echo "   - $SUBDOMAIN_DIR/command.go"
    echo "   - $SUBDOMAIN_DIR/query.go"
    echo "   - $SUBDOMAIN_DIR/dto.go"
    echo ""
    print_warning "Remember to:"
    echo "   - Implement the TODO sections in the generated files"
    echo "   - Add proper validation and business rules"
    echo "   - Add comprehensive tests"
    echo "   - Update API documentation"
}

if [ $# -lt 2 ]; then
    echo "Usage: $0 <type> <name> [service-name]"
    echo "Types: service, subdomain"
    echo "Examples:"
    echo "  $0 service user-service"
    echo "  $0 subdomain account user-service"
    exit 1
fi

TYPE=$1
NAME=$2

# Convert name to various formats
SERVICE_NAME=$(echo $NAME | sed 's/-/_/g')
SERVICE_TITLE=$(echo $NAME | sed 's/-/ /g' | sed 's/\b\w/\U&/g' | sed 's/ //g')
SERVICE_PACKAGE=$(echo $NAME | sed 's/-//g')

print_status "Creating $TYPE: $NAME..."

case $TYPE in
    "service")
        create_service
        ;;
    "subdomain")
        if [ $# -lt 3 ]; then
            print_error "Subdomain creation requires both subdomain name and service name"
            echo "Usage: $0 subdomain <subdomain-name> <service-name>"
            exit 1
        fi
        SUBDOMAIN_NAME=$2
        SERVICE_NAME=$3
        create_subdomain "$SUBDOMAIN_NAME" "$SERVICE_NAME"
        ;;
    *)
        print_error "Unknown type: $TYPE"
        echo "Available types: service, subdomain"
        exit 1
        ;;
esac 