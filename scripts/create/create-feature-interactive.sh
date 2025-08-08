#!/bin/bash

# Interactive Feature Creation Script
# This script provides an interactive interface for creating features with guided prompts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEMP_DIR="docs/03-development/prompt-generation/contexts"

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

# Function to validate feature name
validate_feature_name() {
    local feature_name=$1
    
    # Check if feature name is provided
    if [[ -z "$feature_name" ]]; then
        print_error "Feature name is required"
        return 1
    fi
    
    # Check if feature name follows naming convention
    if [[ ! "$feature_name" =~ ^[a-z][a-z0-9_]*$ ]]; then
        print_error "Feature name must be lowercase with underscores (e.g., user_registration)"
        return 1
    fi
    
    return 0
}

# Function to validate service name
validate_service_name() {
    local service_name=$1
    
    # Check if service name is provided
    if [[ -z "$service_name" ]]; then
        print_error "Service name is required"
        return 1
    fi
    
    # Check if service exists
    if [[ ! -d "internal/services/$service_name" ]]; then
        print_error "Service '$service_name' does not exist"
        return 1
    fi
    
    return 0
}

# Function to validate subdomain name
validate_subdomain_name() {
    local subdomain_name=$1
    local service_name=$2
    
    # Check if subdomain name is provided
    if [[ -z "$subdomain_name" ]]; then
        return 0  # Subdomain is optional
    fi
    
    # Check if subdomain exists
    if [[ ! -d "internal/services/$service_name/application/$subdomain_name" ]]; then
        print_error "Subdomain '$subdomain_name' does not exist in service '$service_name'"
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

# Function to list available services
list_available_services() {
    print_info "Available services:"
    if [[ -d "internal/services" ]]; then
        for service in internal/services/*/; do
            if [[ -d "$service" ]]; then
                service_name=$(basename "$service")
                echo "  - $service_name"
            fi
        done
    else
        print_warning "No services found in internal/services/"
    fi
    echo
}

# Function to list available subdomains
list_available_subdomains() {
    local service_name=$1
    
    print_info "Available subdomains in service '$service_name':"
    if [[ -d "internal/services/$service_name/application" ]]; then
        for subdomain in internal/services/$service_name/application/*/; do
            if [[ -d "$subdomain" ]]; then
                subdomain_name=$(basename "$subdomain")
                echo "  - $subdomain_name"
            fi
        done
    else
        print_warning "No subdomains found in service '$service_name'"
    fi
    echo
}

# Function to gather feature information interactively
gather_feature_info() {
    print_info "Starting interactive feature creation..."
    echo
    
    # List available services
    list_available_services
    
    # Service name
    SERVICE_NAME=$(prompt_input "Enter parent service name" validate_service_name)
    print_success "Parent service: $SERVICE_NAME"
    echo
    
    # List available subdomains
    list_available_subdomains "$SERVICE_NAME"
    
    # Subdomain name (optional)
    if prompt_yes_no "Does this feature belong to a specific subdomain?" "n"; then
        SUBDOMAIN_NAME=$(prompt_input "Enter subdomain name" "validate_subdomain_name $SERVICE_NAME")
        print_success "Subdomain: $SUBDOMAIN_NAME"
    else
        SUBDOMAIN_NAME=""
        print_info "No specific subdomain selected"
    fi
    echo
    
    # Feature name
    FEATURE_NAME=$(prompt_input "Enter feature name (e.g., user_registration)" validate_feature_name)
    print_success "Feature name: $FEATURE_NAME"
    echo
    
    # Feature purpose
    FEATURE_PURPOSE=$(prompt_input "Describe the specific purpose of this feature")
    print_success "Feature purpose: $FEATURE_PURPOSE"
    echo
    
    # User stories
    print_info "Enter user stories this feature addresses:"
    USER_STORIES=$(prompt_input "User stories (e.g., As a user, I want to register so that I can access the system)")
    print_success "User stories: $USER_STORIES"
    echo
    
    # Business rules
    print_info "Enter business rules for this feature:"
    BUSINESS_RULES=$(prompt_input "Business rules (e.g., Email must be unique, Password must be strong)")
    print_success "Business rules: $BUSINESS_RULES"
    echo
    
    # Validation rules
    print_info "Enter validation rules for this feature:"
    VALIDATION_RULES=$(prompt_input "Validation rules (e.g., Email format validation, Password strength check)")
    print_success "Validation rules: $VALIDATION_RULES"
    echo
    
    # API endpoints
    print_info "Enter API endpoints needed for this feature:"
    API_ENDPOINTS=$(prompt_input "API endpoints (e.g., POST /register, GET /verify-email)")
    print_success "API endpoints: $API_ENDPOINTS"
    echo
    
    # Database changes
    if prompt_yes_no "Does this feature require database schema changes?" "y"; then
        DATABASE_CHANGES="yes"
        print_info "Enter database changes needed:"
        DB_CHANGES=$(prompt_input "Database changes (e.g., Add users table, Add verification_tokens table)")
        print_success "Database changes: $DB_CHANGES"
    else
        DATABASE_CHANGES="no"
        DB_CHANGES=""
    fi
    echo
    
    # External dependencies
    print_info "Enter external services or APIs needed (comma-separated, or 'none'):"
    EXTERNAL_DEPS=$(prompt_input "External dependencies (e.g., email-service, sms-gateway, payment-gateway)")
    print_success "External dependencies: $EXTERNAL_DEPS"
    echo
    
    # Security requirements
    SECURITY_REQUIREMENTS=$(prompt_choice "Select security requirements:" "None" "Basic" "Enhanced" "Enterprise" "Compliance")
    print_success "Security: $SECURITY_REQUIREMENTS"
    echo
    
    # Error handling
    ERROR_HANDLING=$(prompt_choice "Select error handling approach:" "Standard" "Detailed" "Custom" "Minimal")
    print_success "Error handling: $ERROR_HANDLING"
    echo
    
    # Event publishing
    if prompt_yes_no "Does this feature need to publish events?" "n"; then
        EVENT_PUBLISHING="yes"
        print_info "Enter events to publish (comma-separated):"
        EVENTS_TO_PUBLISH=$(prompt_input "Events to publish (e.g., user.registered, email.sent)")
    else
        EVENT_PUBLISHING="no"
        EVENTS_TO_PUBLISH=""
    fi
    echo
    
    # Event consumption
    if prompt_yes_no "Does this feature need to consume events?" "n"; then
        EVENT_CONSUMPTION="yes"
        print_info "Enter events to consume (comma-separated):"
        EVENTS_TO_CONSUME=$(prompt_input "Events to consume (e.g., email.sent, payment.completed)")
    else
        EVENT_CONSUMPTION="no"
        EVENTS_TO_CONSUME=""
    fi
    echo
    
    # UI/UX requirements
    if prompt_yes_no "Does this feature have UI/UX requirements?" "n"; then
        UI_UX_REQUIREMENTS="yes"
        print_info "Enter UI/UX requirements:"
        UI_UX_DETAILS=$(prompt_input "UI/UX requirements (e.g., Responsive design, Mobile-friendly, Accessibility)")
    else
        UI_UX_REQUIREMENTS="no"
        UI_UX_DETAILS=""
    fi
    echo
    
    # Testing requirements
    TESTING_REQUIREMENTS=$(prompt_choice "Select testing requirements:" "Basic" "Comprehensive" "Integration" "Performance" "Security")
    print_success "Testing: $TESTING_REQUIREMENTS"
    echo
    
    # Documentation
    if prompt_yes_no "Generate documentation for this feature?" "y"; then
        DOCUMENTATION="yes"
    else
        DOCUMENTATION="no"
    fi
    echo
}

# Function to create context file
create_context_file() {
    local context_file="$TEMP_DIR/${SERVICE_NAME}-${FEATURE_NAME}-context.yaml"
    
    cat > "$context_file" << EOF
# Feature Context: $SERVICE_NAME/$FEATURE_NAME
# Generated on: $(date)

feature:
  name: $FEATURE_NAME
  service: $SERVICE_NAME
  subdomain: $SUBDOMAIN_NAME
  purpose: $FEATURE_PURPOSE

user_stories:
  description: $USER_STORIES

business:
  rules: $BUSINESS_RULES
  validation: $VALIDATION_RULES

api:
  endpoints: [$API_ENDPOINTS]
  error_handling: $ERROR_HANDLING

database:
  changes_required: $DATABASE_CHANGES
  changes: $DB_CHANGES

integration:
  external_dependencies: [$EXTERNAL_DEPS]
  event_publishing: $EVENT_PUBLISHING
  events_to_publish: [$EVENTS_TO_PUBLISH]
  event_consumption: $EVENT_CONSUMPTION
  events_to_consume: [$EVENTS_TO_CONSUME]

security:
  requirements: $SECURITY_REQUIREMENTS

ui_ux:
  required: $UI_UX_REQUIREMENTS
  details: $UI_UX_DETAILS

technical:
  testing: $TESTING_REQUIREMENTS
  documentation: $DOCUMENTATION

# Additional configuration can be added here
EOF
    
    print_success "Context file created: $context_file"
}

# Function to generate feature
generate_feature() {
    print_info "Generating feature using context file..."
    
    # Build command arguments
    local cmd_args=("$FEATURE_NAME" "$SERVICE_NAME")
    
    if [[ -n "$SUBDOMAIN_NAME" ]]; then
        cmd_args+=("--subdomain" "$SUBDOMAIN_NAME")
    fi
    
    cmd_args+=("--context-file" "$TEMP_DIR/${SERVICE_NAME}-${FEATURE_NAME}-context.yaml")
    
    # Call the main feature creation script
    if ./scripts/create-feature.sh "${cmd_args[@]}"; then
        print_success "Feature '$FEATURE_NAME' generated successfully in service '$SERVICE_NAME'!"
    else
        print_error "Failed to generate feature"
        return 1
    fi
}

# Function to validate generated feature
validate_generated_feature() {
    print_info "Validating generated feature..."
    
    # Check if feature files exist
    local base_path="internal/services/$SERVICE_NAME"
    local feature_files=()
    
    if [[ -n "$SUBDOMAIN_NAME" ]]; then
        # Feature in subdomain
        feature_files=(
            "$base_path/application/$SUBDOMAIN_NAME/command.go"
            "$base_path/application/$SUBDOMAIN_NAME/query.go"
            "$base_path/application/$SUBDOMAIN_NAME/dto.go"
        )
    else
        # Feature at service level
        feature_files=(
            "$base_path/application/command.go"
            "$base_path/application/query.go"
            "$base_path/application/dto.go"
        )
    fi
    
    for file in "${feature_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_warning "Feature file not found: $file"
        fi
    done
    
    print_success "Feature validation completed!"
    return 0
}

# Function to compile and test
compile_and_test() {
    print_info "Compiling and testing generated feature..."
    
    # Compile the project
    if go build ./...; then
        print_success "Compilation successful!"
    else
        print_error "Compilation failed"
        return 1
    fi
    
    # Run tests for the parent service
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
    print_info "Next steps for your new feature:"
    echo
    echo "1. Review generated code:"
    if [[ -n "$SUBDOMAIN_NAME" ]]; then
        echo "   - internal/services/$SERVICE_NAME/application/$SUBDOMAIN_NAME/"
    else
        echo "   - internal/services/$SERVICE_NAME/application/"
    fi
    echo
    echo "2. Customize business logic:"
    echo "   - Update command handlers for your feature"
    echo "   - Update query handlers for your feature"
    echo "   - Add validation rules in dto.go"
    echo
    echo "3. Implement API endpoints:"
    echo "   - Update handlers in delivery/http/"
    echo "   - Add routes in delivery/http/router.go"
    echo "   - Register routes in bootstrap/di.go"
    echo
    echo "4. Database changes:"
    if [[ "$DATABASE_CHANGES" == "yes" ]]; then
        echo "   - Create migration files in src/migrations/"
        echo "   - Run: make migrate-create NAME=add_${FEATURE_NAME}_tables"
        echo "   - Update repository implementations"
    else
        echo "   - No database changes required"
    fi
    echo
    echo "5. External integrations:"
    if [[ "$EXTERNAL_DEPS" != "none" ]]; then
        echo "   - Implement external service clients"
        echo "   - Add configuration for external services"
        echo "   - Update dependency injection"
    else
        echo "   - No external dependencies required"
    fi
    echo
    echo "6. Event handling:"
    if [[ "$EVENT_PUBLISHING" == "yes" ]] || [[ "$EVENT_CONSUMPTION" == "yes" ]]; then
        echo "   - Implement event publishers/consumers"
        echo "   - Add event handlers"
        echo "   - Configure event routing"
    else
        echo "   - No event handling required"
    fi
    echo
    echo "7. Test your feature:"
    echo "   - Run: go test ./internal/services/$SERVICE_NAME/..."
    echo "   - Start server: make run"
    echo "   - Test endpoints with curl or Postman"
    echo
    echo "8. Security implementation:"
    if [[ "$SECURITY_REQUIREMENTS" != "None" ]]; then
        echo "   - Implement security measures"
        echo "   - Add authentication/authorization"
        echo "   - Configure security middleware"
    else
        echo "   - Basic security only"
    fi
    echo
}

# Main function
main() {
    echo "=========================================="
    echo "Interactive Feature Creation"
    echo "=========================================="
    echo
    
    # Check if we're in the project root
    if [[ ! -f "go.mod" ]]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Check if required files exist
    if [[ ! -f "scripts/create-feature.sh" ]]; then
        print_error "create-feature.sh script not found"
        exit 1
    fi
    
    # Gather feature information
    gather_feature_info
    
    # Show summary
    echo
    echo "=========================================="
    echo "Feature Creation Summary"
    echo "=========================================="
    echo "Parent Service: $SERVICE_NAME"
    if [[ -n "$SUBDOMAIN_NAME" ]]; then
        echo "Parent Subdomain: $SUBDOMAIN_NAME"
    else
        echo "Parent Subdomain: None (service-level feature)"
    fi
    echo "Feature Name: $FEATURE_NAME"
    echo "Purpose: $FEATURE_PURPOSE"
    echo "User Stories: $USER_STORIES"
    echo "Business Rules: $BUSINESS_RULES"
    echo "Validation Rules: $VALIDATION_RULES"
    echo "API Endpoints: $API_ENDPOINTS"
    echo "Database Changes: $DATABASE_CHANGES"
    if [[ "$DATABASE_CHANGES" == "yes" ]]; then
        echo "Database Changes Details: $DB_CHANGES"
    fi
    echo "External Dependencies: $EXTERNAL_DEPS"
    echo "Security: $SECURITY_REQUIREMENTS"
    echo "Error Handling: $ERROR_HANDLING"
    echo "Event Publishing: $EVENT_PUBLISHING"
    if [[ "$EVENT_PUBLISHING" == "yes" ]]; then
        echo "Events to Publish: $EVENTS_TO_PUBLISH"
    fi
    echo "Event Consumption: $EVENT_CONSUMPTION"
    if [[ "$EVENT_CONSUMPTION" == "yes" ]]; then
        echo "Events to Consume: $EVENTS_TO_CONSUME"
    fi
    echo "UI/UX Required: $UI_UX_REQUIREMENTS"
    if [[ "$UI_UX_REQUIREMENTS" == "yes" ]]; then
        echo "UI/UX Details: $UI_UX_DETAILS"
    fi
    echo "Testing: $TESTING_REQUIREMENTS"
    echo "Documentation: $DOCUMENTATION"
    echo
    
    # Confirm generation
    if prompt_yes_no "Proceed with feature generation?" "y"; then
        echo
        
        # Create context file
        create_context_file
        
        # Generate feature
        if generate_feature; then
            
            # Validate generated feature
            if validate_generated_feature; then
                
                # Compile and test
                if compile_and_test; then
                    print_success "Feature creation completed successfully!"
                    show_next_steps
                else
                    print_warning "Feature created but compilation/testing had issues"
                    show_next_steps
                fi
            else
                print_error "Feature generation validation failed"
                exit 1
            fi
        else
            print_error "Feature generation failed"
            exit 1
        fi
    else
        print_info "Feature creation cancelled"
        exit 0
    fi
}

# Run main function
main "$@"
