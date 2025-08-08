#!/bin/bash

# Interactive Service Creation Script
# This script provides an interactive interface for creating services with guided prompts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEMP_DIR="docs/03-development/prompt-generation/contexts"
RULES_FILE="docs/03-development/prompt-generation/rules/service-generation-rules.yaml"
QUESTION_FRAMEWORK="docs/03-development/prompt-generation/frameworks/service-context-questions.yaml"
VALIDATION_SYSTEM="docs/03-development/prompt-generation/validation/service-code-validation.yaml"

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

# Function to validate service name
validate_service_name() {
    local service_name=$1
    
    # Check if service name is provided
    if [[ -z "$service_name" ]]; then
        print_error "Service name is required"
        return 1
    fi
    
    # Check if service name follows naming convention
    if [[ ! "$service_name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        print_error "Service name must be lowercase with hyphens (e.g., user-service)"
        return 1
    fi
    
    # Check if service already exists
    if [[ -d "internal/services/$service_name" ]]; then
        print_error "Service '$service_name' already exists"
        return 1
    fi
    
    return 0
}

# Function to prompt for input with validation
prompt_input() {
    local prompt=$1
    local validation_func=$2
    local default_value=$3
    
    while true; do
        if [[ -n "$default_value" ]]; then
            read -p "$prompt [$default_value]: " input
            input=${input:-$default_value}
        else
            read -p "$prompt: " input
        fi
        
        if [[ -n "$validation_func" ]]; then
            if $validation_func "$input"; then
                echo "$input"
                return 0
            fi
        else
            echo "$input"
            return 0
        fi
    done
}

# Function to prompt for yes/no
prompt_yes_no() {
    local prompt=$1
    local default=${2:-"n"}
    
    while true; do
        read -p "$prompt (y/n) [$default]: " yn
        yn=${yn:-$default}
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) print_warning "Please answer yes or no.";;
        esac
    done
}

# Function to prompt for multiple choice
prompt_choice() {
    local prompt=$1
    shift
    local options=("$@")
    
    echo "$prompt"
    for i in "${!options[@]}"; do
        echo "  $((i+1)). ${options[$i]}"
    done
    
    while true; do
        read -p "Enter your choice (1-${#options[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#options[@]}" ]]; then
            echo "${options[$((choice-1))]}"
            return 0
        else
            print_warning "Please enter a valid choice (1-${#options[@]})"
        fi
    done
}

# Function to gather service information interactively
gather_service_info() {
    print_info "Starting interactive service creation..."
    echo
    
    # Service name
    SERVICE_NAME=$(prompt_input "Enter service name (e.g., user-service)" validate_service_name)
    print_success "Service name: $SERVICE_NAME"
    echo
    
    # Service purpose
    SERVICE_PURPOSE=$(prompt_input "Describe the primary purpose of this service")
    print_success "Service purpose: $SERVICE_PURPOSE"
    echo
    
    # Domain context
    DOMAIN_CONTEXT=$(prompt_input "What business domain does this service belong to?")
    print_success "Domain context: $DOMAIN_CONTEXT"
    echo
    
    # Core entities
    print_info "Enter the main business entities this service will manage (comma-separated):"
    CORE_ENTITIES=$(prompt_input "Core entities (e.g., User, Product, Order)")
    print_success "Core entities: $CORE_ENTITIES"
    echo
    
    # Business rules
    print_info "Enter key business rules and validations:"
    BUSINESS_RULES=$(prompt_input "Business rules (e.g., User email must be unique, Product price must be positive)")
    print_success "Business rules: $BUSINESS_RULES"
    echo
    
    # Data storage
    STORAGE_TYPE=$(prompt_choice "Select primary data storage type:" "PostgreSQL" "Redis" "MongoDB" "Hybrid (PostgreSQL + Redis)")
    print_success "Storage type: $STORAGE_TYPE"
    echo
    
    # External dependencies
    print_info "Enter external services or APIs this service will interact with (comma-separated, or 'none'):"
    EXTERNAL_DEPS=$(prompt_input "External dependencies (e.g., email-service, payment-gateway, auth-service)")
    print_success "External dependencies: $EXTERNAL_DEPS"
    echo
    
    # API endpoints
    print_info "Enter main API endpoints needed (comma-separated):"
    API_ENDPOINTS=$(prompt_input "API endpoints (e.g., /users, /users/{id}, /users/{id}/profile)")
    print_success "API endpoints: $API_ENDPOINTS"
    echo
    
    # Authentication
    AUTH_TYPE=$(prompt_choice "Select authentication type:" "None" "JWT" "OAuth" "API Key" "Custom")
    print_success "Authentication: $AUTH_TYPE"
    echo
    
    # Event publishing
    if prompt_yes_no "Does this service need to publish events?" "n"; then
        EVENT_PUBLISHING="yes"
        print_info "Enter events to publish (comma-separated):"
        EVENTS_TO_PUBLISH=$(prompt_input "Events to publish (e.g., user.created, user.updated, user.deleted)")
    else
        EVENT_PUBLISHING="no"
        EVENTS_TO_PUBLISH=""
    fi
    echo
    
    # Event consumption
    if prompt_yes_no "Does this service need to consume events?" "n"; then
        EVENT_CONSUMPTION="yes"
        print_info "Enter events to consume (comma-separated):"
        EVENTS_TO_CONSUME=$(prompt_input "Events to consume (e.g., order.created, payment.completed)")
    else
        EVENT_CONSUMPTION="no"
        EVENTS_TO_CONSUME=""
    fi
    echo
    
    # Performance requirements
    PERFORMANCE=$(prompt_choice "Select performance requirements:" "Standard" "High Performance" "Real-time" "Batch Processing")
    print_success "Performance: $PERFORMANCE"
    echo
    
    # Security requirements
    SECURITY=$(prompt_choice "Select security requirements:" "Basic" "Enhanced" "Enterprise" "Compliance")
    print_success "Security: $SECURITY"
    echo
    
    # Monitoring
    if prompt_yes_no "Include monitoring and metrics?" "y"; then
        MONITORING="yes"
    else
        MONITORING="no"
    fi
    echo
    
    # Logging
    if prompt_yes_no "Include structured logging?" "y"; then
        LOGGING="yes"
    else
        LOGGING="no"
    fi
    echo
    
    # Testing
    TESTING_LEVEL=$(prompt_choice "Select testing level:" "Basic" "Comprehensive" "TDD" "BDD")
    print_success "Testing: $TESTING_LEVEL"
    echo
    
    # Documentation
    if prompt_yes_no "Generate comprehensive documentation?" "y"; then
        DOCUMENTATION="yes"
    else
        DOCUMENTATION="no"
    fi
    echo
}

# Function to create context file
create_context_file() {
    local context_file="$TEMP_DIR/${SERVICE_NAME}-context.yaml"
    
    cat > "$context_file" << EOF
# Service Context: $SERVICE_NAME
# Generated on: $(date)

service:
  name: $SERVICE_NAME
  purpose: $SERVICE_PURPOSE
  domain: $DOMAIN_CONTEXT

business:
  entities: [$CORE_ENTITIES]
  rules: $BUSINESS_RULES
  storage: $STORAGE_TYPE
  performance: $PERFORMANCE
  security: $SECURITY

api:
  endpoints: [$API_ENDPOINTS]
  authentication: $AUTH_TYPE

integration:
  external_dependencies: [$EXTERNAL_DEPS]
  event_publishing: $EVENT_PUBLISHING
  events_to_publish: [$EVENTS_TO_PUBLISH]
  event_consumption: $EVENT_CONSUMPTION
  events_to_consume: [$EVENTS_TO_CONSUME]

technical:
  monitoring: $MONITORING
  logging: $LOGGING
  testing: $TESTING_LEVEL
  documentation: $DOCUMENTATION

# Additional configuration can be added here
EOF
    
    print_success "Context file created: $context_file"
}

# Function to generate service
generate_service() {
    print_info "Generating service using context file..."
    
    # Call the main service creation script
    if ./scripts/create-service.sh "$SERVICE_NAME" --context-file "$TEMP_DIR/${SERVICE_NAME}-context.yaml"; then
        print_success "Service '$SERVICE_NAME' generated successfully!"
    else
        print_error "Failed to generate service"
        return 1
    fi
}

# Function to validate generated service
validate_generated_service() {
    print_info "Validating generated service..."
    
    # Check if service directory exists
    if [[ ! -d "internal/services/$SERVICE_NAME" ]]; then
        print_error "Service directory not found"
        return 1
    fi
    
    # Check if main files exist
    local required_files=(
        "internal/services/$SERVICE_NAME/domain/entity/entity.go"
        "internal/services/$SERVICE_NAME/domain/repository/repository.go"
        "internal/services/$SERVICE_NAME/application/command.go"
        "internal/services/$SERVICE_NAME/application/query.go"
        "internal/services/$SERVICE_NAME/delivery/http/handler.go"
        "internal/services/$SERVICE_NAME/infrastructure/postgres/repository.go"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Required file not found: $file"
            return 1
        fi
    done
    
    print_success "Service validation passed!"
    return 0
}

# Function to compile and test
compile_and_test() {
    print_info "Compiling and testing generated service..."
    
    # Compile the project
    if go build ./...; then
        print_success "Compilation successful!"
    else
        print_error "Compilation failed"
        return 1
    fi
    
    # Run tests for the new service
    if go test "./internal/services/$SERVICE_NAME/..."; then
        print_success "Tests passed!"
    else
        print_warning "Some tests failed - review the generated code"
    fi
    
    return 0
}

# Function to show next steps
show_next_steps() {
    echo
    print_info "Next steps for your new service:"
    echo
    echo "1. Review generated code:"
    echo "   - internal/services/$SERVICE_NAME/"
    echo "   - src/migrations/ (database schema)"
    echo
    echo "2. Customize business logic:"
    echo "   - Update domain entities in domain/entity/"
    echo "   - Implement business rules in domain/service/"
    echo "   - Add validation in application/dto.go"
    echo
    echo "3. Configure database:"
    echo "   - Review migration files"
    echo "   - Update database connection settings"
    echo "   - Run migrations: make migrate-up"
    echo
    echo "4. Add API endpoints:"
    echo "   - Update handlers in delivery/http/"
    echo "   - Add routes in delivery/http/router.go"
    echo "   - Register routes in bootstrap/di.go"
    echo
    echo "5. Test your service:"
    echo "   - Run: go test ./internal/services/$SERVICE_NAME/..."
    echo "   - Start server: make run"
    echo "   - Test endpoints with curl or Postman"
    echo
    echo "6. Add subdomains if needed:"
    echo "   - ./scripts/create-subdomain.sh <subdomain> $SERVICE_NAME"
    echo
    echo "7. Add features if needed:"
    echo "   - ./scripts/create-feature.sh <feature> $SERVICE_NAME"
    echo
}

# Main function
main() {
    echo "=========================================="
    echo "Interactive Service Creation"
    echo "=========================================="
    echo
    
    # Check if we're in the project root
    if [[ ! -f "go.mod" ]]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Check if required files exist
    if [[ ! -f "scripts/create-service.sh" ]]; then
        print_error "create-service.sh script not found"
        exit 1
    fi
    
    # Gather service information
    gather_service_info
    
    # Show summary
    echo
    echo "=========================================="
    echo "Service Creation Summary"
    echo "=========================================="
    echo "Service Name: $SERVICE_NAME"
    echo "Purpose: $SERVICE_PURPOSE"
    echo "Domain: $DOMAIN_CONTEXT"
    echo "Entities: $CORE_ENTITIES"
    echo "Storage: $STORAGE_TYPE"
    echo "API Endpoints: $API_ENDPOINTS"
    echo "Authentication: $AUTH_TYPE"
    echo "Performance: $PERFORMANCE"
    echo "Security: $SECURITY"
    echo "Monitoring: $MONITORING"
    echo "Logging: $LOGGING"
    echo "Testing: $TESTING_LEVEL"
    echo "Documentation: $DOCUMENTATION"
    echo
    
    # Confirm generation
    if prompt_yes_no "Proceed with service generation?" "y"; then
        echo
        
        # Create context file
        create_context_file
        
        # Generate service
        if generate_service; then
            
            # Validate generated service
            if validate_generated_service; then
                
                # Compile and test
                if compile_and_test; then
                    print_success "Service creation completed successfully!"
                    show_next_steps
                else
                    print_warning "Service created but compilation/testing had issues"
                    show_next_steps
                fi
            else
                print_error "Service generation validation failed"
                exit 1
            fi
        else
            print_error "Service generation failed"
            exit 1
        fi
    else
        print_info "Service creation cancelled"
        exit 0
    fi
}

# Run main function
main "$@"
