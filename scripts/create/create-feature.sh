#!/bin/bash

# Prompt-Based Feature/Use Case Creation Script
# Creates features within existing services or subdomains using context and rules

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RULES_FILE="docs/03-development/prompt-generation/rules/service-generation-rules.yaml"
QUESTION_FRAMEWORK="docs/03-development/prompt-generation/frameworks/service-context-questions.yaml"
VALIDATION_SYSTEM="docs/03-development/prompt-generation/validation/service-code-validation.yaml"
TEMP_DIR="docs/03-development/prompt-generation/contexts"

# Function to print colored output
print_status() {
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

# Function to validate feature parameters
validate_feature_params() {
    local feature_name="$1"
    local service_name="$2"
    local subdomain_name="$3"
    
    # Check if feature name is provided
    if [[ -z "$feature_name" ]]; then
        print_error "Feature name is required"
        return 1
    fi
    
    # Check if service name is provided
    if [[ -z "$service_name" ]]; then
        print_error "Service name is required"
        return 1
    fi
    
    # Check if service exists
    local service_dir="internal/services/$(echo "$service_name" | sed 's/-/_/g')"
    if [[ ! -d "$service_dir" ]]; then
        print_error "Service '$service_name' does not exist"
        return 1
    fi
    
    # Check if subdomain exists (if provided)
    if [[ -n "$subdomain_name" ]]; then
        local subdomain_dir="$service_dir/application/$subdomain_name"
        if [[ ! -d "$subdomain_dir" ]]; then
            print_error "Subdomain '$subdomain_name' does not exist in service '$service_name'"
            return 1
        fi
    fi
    
    # Validate feature name format
    if [[ ! "$feature_name" =~ ^[a-z][a-z0-9_]*[a-z0-9]$ ]]; then
        print_error "Feature name must be in snake_case (e.g., user_registration, email_verification)"
        return 1
    fi
    
    return 0
}

# Function to gather feature context interactively
gather_feature_context() {
    local feature_name="$1"
    local service_name="$2"
    local subdomain_name="$3"
    
    print_status "Gathering context for feature: $feature_name"
    if [[ -n "$subdomain_name" ]]; then
        print_status "  in subdomain: $subdomain_name"
    fi
    print_status "  in service: $service_name"
    
    # Create temporary context file
    local context_file="$TEMP_DIR/${service_name}"
    if [[ -n "$subdomain_name" ]]; then
        context_file="${context_file}-${subdomain_name}"
    fi
    context_file="${context_file}-${feature_name}-context.yaml"
    mkdir -p "$TEMP_DIR"
    
    cat > "$context_file" << EOF
# Feature Context for $feature_name
feature:
  name: $feature_name
  service: $service_name
EOF

    if [[ -n "$subdomain_name" ]]; then
        cat >> "$context_file" << EOF
  subdomain: $subdomain_name
EOF
    fi

    cat >> "$context_file" << EOF
  purpose: ""
  
requirements:
  user_stories: []
  business_rules: []
  validation_rules: []
  error_handling: []
  
implementation:
  api_endpoints: []
  database_changes: []
  external_dependencies: []
  security_requirements: ""
  
integration:
  existing_entities: []
  event_publishing: []
  event_consumption: []
  ui_requirements: ""
  
testing:
  unit_tests: []
  integration_tests: []
  performance_tests: []
EOF

    print_status "Context file created: $context_file"
    print_status "Please edit this file with feature details, then run:"
    if [[ -n "$subdomain_name" ]]; then
        print_status "  ./scripts/create-feature.sh $feature_name $service_name $subdomain_name --context $context_file"
    else
        print_status "  ./scripts/create-feature.sh $feature_name $service_name --context $context_file"
    fi
    
    return 0
}

# Function to load and validate context
load_feature_context() {
    local context_file="$1"
    
    if [[ ! -f "$context_file" ]]; then
        print_error "Context file not found: $context_file"
        return 1
    fi
    
    # Load context using yq (if available) or basic parsing
    if command -v yq &> /dev/null; then
        # Use yq for YAML parsing
        FEATURE_PURPOSE=$(yq eval '.feature.purpose' "$context_file")
        USER_STORIES=$(yq eval '.requirements.user_stories[]' "$context_file" | tr '\n' ',' | sed 's/,$//')
        BUSINESS_RULES=$(yq eval '.requirements.business_rules[]' "$context_file" | tr '\n' ',' | sed 's/,$//')
        API_ENDPOINTS=$(yq eval '.implementation.api_endpoints[]' "$context_file" | tr '\n' ',' | sed 's/,$//')
        DATABASE_CHANGES=$(yq eval '.implementation.database_changes[]' "$context_file" | tr '\n' ',' | sed 's/,$//')
    else
        # Basic parsing for common YAML structure
        print_warning "yq not found, using basic YAML parsing"
        FEATURE_PURPOSE=$(grep -A1 "purpose:" "$context_file" | tail -1 | sed 's/^[[:space:]]*//')
        USER_STORIES=$(grep -A1 "user_stories:" "$context_file" | tail -1 | sed 's/^[[:space:]]*//')
        API_ENDPOINTS=$(grep -A1 "api_endpoints:" "$context_file" | tail -1 | sed 's/^[[:space:]]*//')
    fi
    
    # Set defaults if not provided
    FEATURE_PURPOSE=${FEATURE_PURPOSE:-"Feature for $feature_name"}
    USER_STORIES=${USER_STORIES:-"Implement $feature_name functionality"}
    API_ENDPOINTS=${API_ENDPOINTS:-"GET /api/v1/$feature_name,POST /api/v1/$feature_name"}
    
    return 0
}

# Function to generate feature
generate_feature() {
    local feature_name="$1"
    local service_name="$2"
    local subdomain_name="$3"
    local context_file="$4"
    
    print_status "Generating feature: $feature_name"
    if [[ -n "$subdomain_name" ]]; then
        print_status "  in subdomain: $subdomain_name"
    fi
    print_status "  in service: $service_name"
    
    # Load context
    load_feature_context "$context_file"
    
    local service_dir="internal/services/$(echo "$service_name" | sed 's/-/_/g')"
    
    # Determine target directory
    local target_dir="$service_dir/application"
    if [[ -n "$subdomain_name" ]]; then
        target_dir="$target_dir/$subdomain_name"
    else
        # Create feature-specific subdomain if not provided
        target_dir="$target_dir/$feature_name"
        mkdir -p "$target_dir"
    fi
    
    # Generate feature files
    generate_feature_files "$target_dir" "$feature_name" "$context_file"
    
    # Apply context-based customizations
    customize_feature "$target_dir" "$feature_name" "$context_file"
    
    print_success "Feature '$feature_name' generated successfully"
    print_status "Next steps:"
    print_status "  1. Review generated code in $target_dir"
    print_status "  2. Implement business logic in command.go and query.go"
    print_status "  3. Add DTOs in dto.go"
    print_status "  4. Add API endpoints in delivery layer"
    print_status "  5. Create database migrations if needed"
    print_status "  6. Add tests for the feature"
    
    return 0
}

# Function to generate feature files
generate_feature_files() {
    local target_dir="$1"
    local feature_name="$2"
    local context_file="$3"
    
    print_status "Generating feature files"
    
    # Create or update command.go
    if [[ ! -f "$target_dir/command.go" ]]; then
        create_command_file "$target_dir" "$feature_name"
    else
        update_command_file "$target_dir" "$feature_name"
    fi
    
    # Create or update query.go
    if [[ ! -f "$target_dir/query.go" ]]; then
        create_query_file "$target_dir" "$feature_name"
    else
        update_query_file "$target_dir" "$feature_name"
    fi
    
    # Create or update dto.go
    if [[ ! -f "$target_dir/dto.go" ]]; then
        create_dto_file "$target_dir" "$feature_name"
    else
        update_dto_file "$target_dir" "$feature_name"
    fi
    
    return 0
}

# Function to create command file
create_command_file() {
    local target_dir="$1"
    local feature_name="$2"
    
    local feature_pascal=$(echo "$feature_name" | sed 's/_\([a-z]\)/\U\1/g' | sed 's/^\([a-z]\)/\U\1/')
    
    cat > "$target_dir/command.go" << EOF
package application

import (
	"context"
	"fmt"
)

// ${feature_pascal}Command represents commands for $feature_name feature
type ${feature_pascal}Command struct {
	// TODO: Add dependencies
}

// New${feature_pascal}Command creates a new ${feature_pascal}Command
func New${feature_pascal}Command() *${feature_pascal}Command {
	return &${feature_pascal}Command{}
}

// TODO: Add command methods for $feature_name
// Example:
// func (c *${feature_pascal}Command) Create(ctx context.Context, req Create${feature_pascal}Request) error {
//     // Implementation
// }
EOF
}

# Function to update command file
update_command_file() {
    local target_dir="$1"
    local feature_name="$2"
    
    local feature_pascal=$(echo "$feature_name" | sed 's/_\([a-z]\)/\U\1/g' | sed 's/^\([a-z]\)/\U\1/')
    
    # Add feature-specific commands to existing file
    cat >> "$target_dir/command.go" << EOF

// ${feature_pascal}Command represents commands for $feature_name feature
type ${feature_pascal}Command struct {
	// TODO: Add dependencies
}

// New${feature_pascal}Command creates a new ${feature_pascal}Command
func New${feature_pascal}Command() *${feature_pascal}Command {
	return &${feature_pascal}Command{}
}

// TODO: Add command methods for $feature_name
// Example:
// func (c *${feature_pascal}Command) Create(ctx context.Context, req Create${feature_pascal}Request) error {
//     // Implementation
// }
EOF
}

# Function to create query file
create_query_file() {
    local target_dir="$1"
    local feature_name="$2"
    
    local feature_pascal=$(echo "$feature_name" | sed 's/_\([a-z]\)/\U\1/g' | sed 's/^\([a-z]\)/\U\1/')
    
    cat > "$target_dir/query.go" << EOF
package application

import (
	"context"
	"fmt"
)

// ${feature_pascal}Query represents queries for $feature_name feature
type ${feature_pascal}Query struct {
	// TODO: Add dependencies
}

// New${feature_pascal}Query creates a new ${feature_pascal}Query
func New${feature_pascal}Query() *${feature_pascal}Query {
	return &${feature_pascal}Query{}
}

// TODO: Add query methods for $feature_name
// Example:
// func (q *${feature_pascal}Query) GetByID(ctx context.Context, id string) (*${feature_pascal}DTO, error) {
//     // Implementation
// }
EOF
}

# Function to update query file
update_query_file() {
    local target_dir="$1"
    local feature_name="$2"
    
    local feature_pascal=$(echo "$feature_name" | sed 's/_\([a-z]\)/\U\1/g' | sed 's/^\([a-z]\)/\U\1/')
    
    # Add feature-specific queries to existing file
    cat >> "$target_dir/query.go" << EOF

// ${feature_pascal}Query represents queries for $feature_name feature
type ${feature_pascal}Query struct {
	// TODO: Add dependencies
}

// New${feature_pascal}Query creates a new ${feature_pascal}Query
func New${feature_pascal}Query() *${feature_pascal}Query {
	return &${feature_pascal}Query{}
}

// TODO: Add query methods for $feature_name
// Example:
// func (q *${feature_pascal}Query) GetByID(ctx context.Context, id string) (*${feature_pascal}DTO, error) {
//     // Implementation
// }
EOF
}

# Function to create DTO file
create_dto_file() {
    local target_dir="$1"
    local feature_name="$2"
    
    local feature_pascal=$(echo "$feature_name" | sed 's/_\([a-z]\)/\U\1/g' | sed 's/^\([a-z]\)/\U\1/')
    
    cat > "$target_dir/dto.go" << EOF
package application

import (
	"time"
)

// ${feature_pascal}DTO represents the data transfer object for $feature_name
type ${feature_pascal}DTO struct {
	ID        string    \`json:"id"\`
	CreatedAt time.Time \`json:"created_at"\`
	UpdatedAt time.Time \`json:"updated_at"\`
	// TODO: Add feature-specific fields
}

// Create${feature_pascal}Request represents the request for creating $feature_name
type Create${feature_pascal}Request struct {
	// TODO: Add request fields
}

// Update${feature_pascal}Request represents the request for updating $feature_name
type Update${feature_pascal}Request struct {
	ID string \`json:"id" validate:"required"\`
	// TODO: Add request fields
}

// TODO: Add more DTOs as needed for $feature_name
EOF
}

# Function to update DTO file
update_dto_file() {
    local target_dir="$1"
    local feature_name="$2"
    
    local feature_pascal=$(echo "$feature_name" | sed 's/_\([a-z]\)/\U\1/g' | sed 's/^\([a-z]\)/\U\1/')
    
    # Add feature-specific DTOs to existing file
    cat >> "$target_dir/dto.go" << EOF

// ${feature_pascal}DTO represents the data transfer object for $feature_name
type ${feature_pascal}DTO struct {
	ID        string    \`json:"id"\`
	CreatedAt time.Time \`json:"created_at"\`
	UpdatedAt time.Time \`json:"updated_at"\`
	// TODO: Add feature-specific fields
}

// Create${feature_pascal}Request represents the request for creating $feature_name
type Create${feature_pascal}Request struct {
	// TODO: Add request fields
}

// Update${feature_pascal}Request represents the request for updating $feature_name
type Update${feature_pascal}Request struct {
	ID string \`json:"id" validate:"required"\`
	// TODO: Add request fields
}

// TODO: Add more DTOs as needed for $feature_name
EOF
}

# Function to customize feature based on context
customize_feature() {
    local target_dir="$1"
    local feature_name="$2"
    local context_file="$3"
    
    print_status "Applying context-based customizations"
    
    # Read context for customization
    if command -v yq &> /dev/null; then
        local user_stories=$(yq eval '.requirements.user_stories[]' "$context_file" 2>/dev/null || echo "")
        local business_rules=$(yq eval '.requirements.business_rules[]' "$context_file" 2>/dev/null || echo "")
        local api_endpoints=$(yq eval '.implementation.api_endpoints[]' "$context_file" 2>/dev/null || echo "")
        local database_changes=$(yq eval '.implementation.database_changes[]' "$context_file" 2>/dev/null || echo "")
    else
        local user_stories=""
        local business_rules=""
        local api_endpoints=""
        local database_changes=""
    fi
    
    # Customize user stories if specified
    if [[ -n "$user_stories" ]]; then
        customize_user_stories "$target_dir" "$user_stories"
    fi
    
    # Customize business rules if specified
    if [[ -n "$business_rules" ]]; then
        customize_business_rules "$target_dir" "$business_rules"
    fi
    
    # Customize API endpoints if specified
    if [[ -n "$api_endpoints" ]]; then
        customize_api_endpoints "$target_dir" "$api_endpoints"
    fi
    
    # Customize database changes if specified
    if [[ -n "$database_changes" ]]; then
        customize_database_changes "$target_dir" "$database_changes"
    fi
    
    return 0
}

# Function to customize user stories
customize_user_stories() {
    local target_dir="$1"
    local user_stories="$2"
    
    print_status "Customizing user stories"
    
    # Parse user stories (assuming comma-separated)
    IFS=',' read -ra STORY_ARRAY <<< "$user_stories"
    
    for story in "${STORY_ARRAY[@]}"; do
        story=$(echo "$story" | xargs) # trim whitespace
        if [[ -n "$story" ]]; then
            print_status "Adding user story: $story"
            # Here you would add story-specific code generation
            # For now, we'll just log the story
        fi
    done
}

# Function to customize business rules
customize_business_rules() {
    local target_dir="$1"
    local rules="$2"
    
    print_status "Customizing business rules"
    
    # Parse rules (assuming comma-separated)
    IFS=',' read -ra RULE_ARRAY <<< "$rules"
    
    for rule in "${RULE_ARRAY[@]}"; do
        rule=$(echo "$rule" | xargs) # trim whitespace
        if [[ -n "$rule" ]]; then
            print_status "Adding business rule: $rule"
            # Here you would add rule-specific code generation
            # For now, we'll just log the rule
        fi
    done
}

# Function to customize API endpoints
customize_api_endpoints() {
    local target_dir="$1"
    local endpoints="$2"
    
    print_status "Customizing API endpoints"
    
    # Parse endpoints (assuming comma-separated)
    IFS=',' read -ra ENDPOINT_ARRAY <<< "$endpoints"
    
    for endpoint in "${ENDPOINT_ARRAY[@]}"; do
        endpoint=$(echo "$endpoint" | xargs) # trim whitespace
        if [[ -n "$endpoint" ]]; then
            print_status "Adding endpoint: $endpoint"
            # Here you would add endpoint-specific code generation
            # For now, we'll just log the endpoint
        fi
    done
}

# Function to customize database changes
customize_database_changes() {
    local target_dir="$1"
    local changes="$2"
    
    print_status "Customizing database changes"
    
    # Parse changes (assuming comma-separated)
    IFS=',' read -ra CHANGE_ARRAY <<< "$changes"
    
    for change in "${CHANGE_ARRAY[@]}"; do
        change=$(echo "$change" | xargs) # trim whitespace
        if [[ -n "$change" ]]; then
            print_status "Adding database change: $change"
            # Here you would add change-specific migration generation
            # For now, we'll just log the change
        fi
    done
}

# Function to validate generated feature
validate_feature() {
    local feature_name="$1"
    local service_name="$2"
    local subdomain_name="$3"
    
    print_status "Validating generated feature"
    
    local service_dir="internal/services/$(echo "$service_name" | sed 's/-/_/g')"
    local target_dir="$service_dir/application"
    
    if [[ -n "$subdomain_name" ]]; then
        target_dir="$target_dir/$subdomain_name"
    else
        target_dir="$target_dir/$feature_name"
    fi
    
    # Check if target directory exists
    if [[ ! -d "$target_dir" ]]; then
        print_error "Feature directory not found: $target_dir"
        return 1
    fi
    
    # Check for required files
    local required_files=(
        "command.go"
        "query.go"
        "dto.go"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$target_dir/$file" ]]; then
            print_warning "Required file missing: $file"
        else
            print_success "✓ $file"
        fi
    done
    
    # Check for Go compilation
    print_status "Checking Go compilation..."
    if cd "$service_dir" && go build . 2>/dev/null; then
        print_success "Feature compiles successfully"
    else
        print_error "Feature compilation failed"
        return 1
    fi
    
    return 0
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <feature-name> <service-name> [subdomain-name] [options]"
    echo ""
    echo "Options:"
    echo "  --context <file>     Use context file for feature generation"
    echo "  --interactive        Run in interactive mode"
    echo "  --validate           Validate generated feature"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 user_registration user-service"
    echo "  $0 email_verification user-service profile"
    echo "  $0 user_registration user-service --context context.yaml"
    echo "  $0 user_registration user-service --interactive"
    echo "  $0 user_registration user-service --validate"
}

# Main function
main() {
    local feature_name=""
    local service_name=""
    local subdomain_name=""
    local context_file=""
    local interactive=false
    local validate_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --context)
                context_file="$2"
                shift 2
                ;;
            --interactive)
                interactive=true
                shift
                ;;
            --validate)
                validate_only=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$feature_name" ]]; then
                    feature_name="$1"
                elif [[ -z "$service_name" ]]; then
                    service_name="$1"
                elif [[ -z "$subdomain_name" ]]; then
                    subdomain_name="$1"
                else
                    print_error "Too many arguments provided"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check if required parameters are provided
    if [[ -z "$feature_name" ]] || [[ -z "$service_name" ]]; then
        print_error "Feature name and service name are required"
        show_usage
        exit 1
    fi
    
    # Validate parameters
    if ! validate_feature_params "$feature_name" "$service_name" "$subdomain_name"; then
        exit 1
    fi
    
    # Handle validation only mode
    if [[ "$validate_only" == true ]]; then
        validate_feature "$feature_name" "$service_name" "$subdomain_name"
        exit $?
    fi
    
    # Handle interactive mode
    if [[ "$interactive" == true ]]; then
        gather_feature_context "$feature_name" "$service_name" "$subdomain_name"
        exit 0
    fi
    
    # Handle context file mode
    if [[ -n "$context_file" ]]; then
        if ! generate_feature "$feature_name" "$service_name" "$subdomain_name" "$context_file"; then
            print_error "Failed to generate feature"
            exit 1
        fi
        
        # Validate generated feature
        if ! validate_feature "$feature_name" "$service_name" "$subdomain_name"; then
            print_error "Feature validation failed"
            exit 1
        fi
        
        print_success "Feature '$feature_name' created and validated successfully"
        exit 0
    fi
    
    # Default mode: create context file and exit
    gather_feature_context "$feature_name" "$service_name" "$subdomain_name"
    exit 0
}

# Run main function
main "$@"
