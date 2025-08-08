#!/bin/bash

# Prompt-Based Service Creation Script
# Uses rules and question framework for intelligent service generation

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
TEMPLATE_DIR="templates/service"
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

# Function to validate service name
validate_service_name() {
    local service_name="$1"
    
    # Check if service name is provided
    if [[ -z "$service_name" ]]; then
        print_error "Service name is required"
        return 1
    fi
    
    # Check if service name follows naming conventions
    if [[ ! "$service_name" =~ ^[a-z][a-z0-9-]*[a-z0-9]$ ]]; then
        print_error "Service name must be in kebab-case (e.g., user-service, product-catalog)"
        return 1
    fi
    
    # Check if service already exists
    if [[ -d "internal/services/$service_name" ]]; then
        print_error "Service '$service_name' already exists"
        return 1
    fi
    
    return 0
}

# Function to gather service context interactively
gather_service_context() {
    local service_name="$1"
    
    print_status "Gathering context for service: $service_name"
    
    # Create temporary context file
    local context_file="$TEMP_DIR/${service_name}-context.yaml"
    mkdir -p "$TEMP_DIR"
    
    cat > "$context_file" << EOF
# Service Context for $service_name
service:
  name: $service_name
  purpose: ""
  domain: ""
  
business:
  entities: []
  rules: []
  relationships: []
  lifecycle: ""
  
technical:
  storage: "postgresql"
  external_dependencies: []
  performance_requirements: ""
  security_requirements: ""
  
api:
  endpoints: []
  authentication: ""
  rate_limiting: ""
  versioning: "v1"
  
integration:
  event_publishing: false
  event_consumption: false
  monitoring: ""
  logging: ""
EOF

    print_status "Context file created: $context_file"
    print_status "Please edit this file with service details, then run:"
    print_status "  ./scripts/create-service.sh $service_name --context $context_file"
    
    return 0
}

# Function to load and validate context
load_context() {
    local context_file="$1"
    
    if [[ ! -f "$context_file" ]]; then
        print_error "Context file not found: $context_file"
        return 1
    fi
    
    # Load context using yq (if available) or basic parsing
    if command -v yq &> /dev/null; then
        # Use yq for YAML parsing
        SERVICE_PURPOSE=$(yq eval '.service.purpose' "$context_file")
        SERVICE_DOMAIN=$(yq eval '.service.domain' "$context_file")
        BUSINESS_ENTITIES=$(yq eval '.business.entities[]' "$context_file" | tr '\n' ',' | sed 's/,$//')
        BUSINESS_RULES=$(yq eval '.business.rules[]' "$context_file" | tr '\n' ',' | sed 's/,$//')
        STORAGE_TYPE=$(yq eval '.technical.storage' "$context_file")
        API_ENDPOINTS=$(yq eval '.api.endpoints[]' "$context_file" | tr '\n' ',' | sed 's/,$//')
    else
        # Basic parsing for common YAML structure
        print_warning "yq not found, using basic YAML parsing"
        SERVICE_PURPOSE=$(grep -A1 "purpose:" "$context_file" | tail -1 | sed 's/^[[:space:]]*//')
        SERVICE_DOMAIN=$(grep -A1 "domain:" "$context_file" | tail -1 | sed 's/^[[:space:]]*//')
        STORAGE_TYPE=$(grep -A1 "storage:" "$context_file" | tail -1 | sed 's/^[[:space:]]*//')
    fi
    
    # Set defaults if not provided
    SERVICE_PURPOSE=${SERVICE_PURPOSE:-"Service for managing $service_name"}
    SERVICE_DOMAIN=${SERVICE_DOMAIN:-"general"}
    STORAGE_TYPE=${STORAGE_TYPE:-"postgresql"}
    
    return 0
}

# Function to generate service using templates
generate_service() {
    local service_name="$1"
    local context_file="$2"
    
    print_status "Generating service: $service_name"
    
    # Load context
    load_context "$context_file"
    
    # Convert service name to various formats
    local service_snake=$(echo "$service_name" | sed 's/-/_/g')
    local service_pascal=$(echo "$service_name" | sed 's/-\([a-z]\)/\U\1/g' | sed 's/^\([a-z]\)/\U\1/')
    local service_camel=$(echo "$service_name" | sed 's/-\([a-z]\)/\U\1/g')
    
    # Create service directory
    local service_dir="internal/services/$service_snake"
    mkdir -p "$service_dir"
    
    # Generate service structure using existing create.sh script
    print_status "Using existing template system for base structure"
    ../create.sh service "$service_name"
    
    # Apply context-based customizations
    customize_service "$service_dir" "$context_file"
    
    print_success "Service '$service_name' generated successfully"
    print_status "Next steps:"
    print_status "  1. Review generated code in $service_dir"
    print_status "  2. Update business logic in domain layer"
    print_status "  3. Implement application layer use cases"
    print_status "  4. Add API endpoints in delivery layer"
    print_status "  5. Configure infrastructure layer"
    
    return 0
}

# Function to customize service based on context
customize_service() {
    local service_dir="$1"
    local context_file="$2"
    
    print_status "Applying context-based customizations"
    
    # Read context for customization
    if command -v yq &> /dev/null; then
        local entities=$(yq eval '.business.entities[]' "$context_file" 2>/dev/null || echo "")
        local rules=$(yq eval '.business.rules[]' "$context_file" 2>/dev/null || echo "")
        local endpoints=$(yq eval '.api.endpoints[]' "$context_file" 2>/dev/null || echo "")
    else
        local entities=""
        local rules=""
        local endpoints=""
    fi
    
    # Customize domain entities if specified
    if [[ -n "$entities" ]]; then
        customize_domain_entities "$service_dir" "$entities"
    fi
    
    # Customize business rules if specified
    if [[ -n "$rules" ]]; then
        customize_business_rules "$service_dir" "$rules"
    fi
    
    # Customize API endpoints if specified
    if [[ -n "$endpoints" ]]; then
        customize_api_endpoints "$service_dir" "$endpoints"
    fi
    
    return 0
}

# Function to customize domain entities
customize_domain_entities() {
    local service_dir="$1"
    local entities="$2"
    
    print_status "Customizing domain entities"
    
    # Parse entities (assuming comma-separated)
    IFS=',' read -ra ENTITY_ARRAY <<< "$entities"
    
    for entity in "${ENTITY_ARRAY[@]}"; do
        entity=$(echo "$entity" | xargs) # trim whitespace
        if [[ -n "$entity" ]]; then
            print_status "Adding entity: $entity"
            # Here you would add entity-specific code generation
            # For now, we'll just log the entity
        fi
    done
}

# Function to customize business rules
customize_business_rules() {
    local service_dir="$1"
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
    local service_dir="$1"
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

# Function to validate generated service
validate_service() {
    local service_name="$1"
    local service_dir="internal/services/$(echo "$service_name" | sed 's/-/_/g')"
    
    print_status "Validating generated service"
    
    # Check if service directory exists
    if [[ ! -d "$service_dir" ]]; then
        print_error "Service directory not found: $service_dir"
        return 1
    fi
    
    # Check for required files
    local required_files=(
        "domain/entity/entity.go"
        "domain/repository/repository.go"
        "application/command.go"
        "application/query.go"
        "application/dto.go"
        "delivery/http/handler.go"
        "delivery/http/router.go"
        "infrastructure/postgres/repository.go"
        "config/config.go"
        "init/init.go"
        "module.go"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$service_dir/$file" ]]; then
            print_warning "Required file missing: $file"
        else
            print_success "✓ $file"
        fi
    done
    
    # Check for Go compilation
    print_status "Checking Go compilation..."
    if cd "$service_dir" && go build . 2>/dev/null; then
        print_success "Service compiles successfully"
    else
        print_error "Service compilation failed"
        return 1
    fi
    
    return 0
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <service-name> [options]"
    echo ""
    echo "Options:"
    echo "  --context <file>     Use context file for service generation"
    echo "  --interactive        Run in interactive mode"
    echo "  --validate           Validate generated service"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 user-service"
    echo "  $0 user-service --context context.yaml"
    echo "  $0 user-service --interactive"
    echo "  $0 user-service --validate"
}

# Main function
main() {
    local service_name=""
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
                if [[ -z "$service_name" ]]; then
                    service_name="$1"
                else
                    print_error "Multiple service names provided"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check if service name is provided
    if [[ -z "$service_name" ]]; then
        print_error "Service name is required"
        show_usage
        exit 1
    fi
    
    # Validate service name
    if ! validate_service_name "$service_name"; then
        exit 1
    fi
    
    # Handle validation only mode
    if [[ "$validate_only" == true ]]; then
        validate_service "$service_name"
        exit $?
    fi
    
    # Handle interactive mode
    if [[ "$interactive" == true ]]; then
        gather_service_context "$service_name"
        exit 0
    fi
    
    # Handle context file mode
    if [[ -n "$context_file" ]]; then
        if ! generate_service "$service_name" "$context_file"; then
            print_error "Failed to generate service"
            exit 1
        fi
        
        # Validate generated service
        if ! validate_service "$service_name"; then
            print_error "Service validation failed"
            exit 1
        fi
        
        print_success "Service '$service_name' created and validated successfully"
        exit 0
    fi
    
    # Default mode: create context file and exit
    gather_service_context "$service_name"
    exit 0
}

# Run main function
main "$@"
