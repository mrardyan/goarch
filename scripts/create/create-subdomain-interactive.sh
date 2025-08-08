#!/bin/bash

# Interactive Subdomain Creation Script
# This script provides an interactive interface for creating subdomains with guided prompts

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

# Function to validate subdomain name
validate_subdomain_name() {
    local subdomain_name=$1
    
    # Check if subdomain name is provided
    if [[ -z "$subdomain_name" ]]; then
        print_error "Subdomain name is required"
        return 1
    fi
    
    # Check if subdomain name follows naming convention
    if [[ ! "$subdomain_name" =~ ^[a-z][a-z0-9_]*$ ]]; then
        print_error "Subdomain name must be lowercase with underscores (e.g., user_profile)"
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

# Function to gather subdomain information interactively
gather_subdomain_info() {
    print_info "Starting interactive subdomain creation..."
    echo
    
    # List available services
    list_available_services
    
    # Service name
    SERVICE_NAME=$(prompt_input "Enter parent service name" validate_service_name)
    print_success "Parent service: $SERVICE_NAME"
    echo
    
    # Subdomain name
    SUBDOMAIN_NAME=$(prompt_input "Enter subdomain name (e.g., user_profile)" validate_subdomain_name)
    print_success "Subdomain name: $SUBDOMAIN_NAME"
    echo
    
    # Check if subdomain already exists
    if [[ -d "internal/services/$SERVICE_NAME/application/$SUBDOMAIN_NAME" ]]; then
        print_error "Subdomain '$SUBDOMAIN_NAME' already exists in service '$SERVICE_NAME'"
        exit 1
    fi
    echo
    
    # Subdomain purpose
    SUBDOMAIN_PURPOSE=$(prompt_input "Describe the specific purpose of this subdomain")
    print_success "Subdomain purpose: $SUBDOMAIN_PURPOSE"
    echo
    
    # Operations needed
    print_info "Select operations needed for this subdomain:"
    OPERATIONS=$(prompt_choice "Operations:" "Create" "Read" "Update" "Delete" "Search" "All (CRUD + Search)")
    print_success "Operations: $OPERATIONS"
    echo
    
    # Business rules
    print_info "Enter specific business rules for this subdomain:"
    BUSINESS_RULES=$(prompt_input "Business rules (e.g., Profile must have at least one contact method)")
    print_success "Business rules: $BUSINESS_RULES"
    echo
    
    # Entity relationships
    print_info "How does this subdomain relate to existing entities?"
    ENTITY_RELATIONSHIPS=$(prompt_input "Entity relationships (e.g., Belongs to User, Has many Preferences)")
    print_success "Entity relationships: $ENTITY_RELATIONSHIPS"
    echo
    
    # Data flow
    print_info "Describe the data flow for this subdomain:"
    DATA_FLOW=$(prompt_input "Data flow (e.g., Create profile → Validate → Save → Notify user)")
    print_success "Data flow: $DATA_FLOW"
    echo
    
    # API integration
    API_INTEGRATION=$(prompt_choice "How should this subdomain be exposed via API?" "Separate endpoints" "Nested under parent" "Custom routing" "Internal only")
    print_success "API integration: $API_INTEGRATION"
    echo
    
    # Validation rules
    print_info "Enter validation rules specific to this subdomain:"
    VALIDATION_RULES=$(prompt_input "Validation rules (e.g., Email must be valid format, Phone must be 10 digits)")
    print_success "Validation rules: $VALIDATION_RULES"
    echo
    
    # Error handling
    ERROR_HANDLING=$(prompt_choice "Select error handling approach:" "Standard" "Detailed" "Custom" "Minimal")
    print_success "Error handling: $ERROR_HANDLING"
    echo
    
    # Testing requirements
    TESTING_REQUIREMENTS=$(prompt_choice "Select testing requirements:" "Basic" "Comprehensive" "Integration" "Performance")
    print_success "Testing: $TESTING_REQUIREMENTS"
    echo
    
    # Documentation
    if prompt_yes_no "Generate documentation for this subdomain?" "y"; then
        DOCUMENTATION="yes"
    else
        DOCUMENTATION="no"
    fi
    echo
}

# Function to create context file
create_context_file() {
    local context_file="$TEMP_DIR/${SERVICE_NAME}-${SUBDOMAIN_NAME}-context.yaml"
    
    cat > "$context_file" << EOF
# Subdomain Context: $SERVICE_NAME/$SUBDOMAIN_NAME
# Generated on: $(date)

subdomain:
  name: $SUBDOMAIN_NAME
  service: $SERVICE_NAME
  purpose: $SUBDOMAIN_PURPOSE

operations:
  type: $OPERATIONS
  business_rules: $BUSINESS_RULES
  validation_rules: $VALIDATION_RULES

relationships:
  entities: $ENTITY_RELATIONSHIPS
  data_flow: $DATA_FLOW

api:
  integration: $API_INTEGRATION
  error_handling: $ERROR_HANDLING

technical:
  testing: $TESTING_REQUIREMENTS
  documentation: $DOCUMENTATION

# Additional configuration can be added here
EOF
    
    print_success "Context file created: $context_file"
}

# Function to generate subdomain
generate_subdomain() {
    print_info "Generating subdomain using context file..."
    
    # Call the main subdomain creation script
    if ./scripts/create-subdomain.sh "$SUBDOMAIN_NAME" "$SERVICE_NAME" --context-file "$TEMP_DIR/${SERVICE_NAME}-${SUBDOMAIN_NAME}-context.yaml"; then
        print_success "Subdomain '$SUBDOMAIN_NAME' generated successfully in service '$SERVICE_NAME'!"
    else
        print_error "Failed to generate subdomain"
        return 1
    fi
}

# Function to validate generated subdomain
validate_generated_subdomain() {
    print_info "Validating generated subdomain..."
    
    # Check if subdomain directory exists
    if [[ ! -d "internal/services/$SERVICE_NAME/application/$SUBDOMAIN_NAME" ]]; then
        print_error "Subdomain directory not found"
        return 1
    fi
    
    # Check if main files exist
    local required_files=(
        "internal/services/$SERVICE_NAME/application/$SUBDOMAIN_NAME/command.go"
        "internal/services/$SERVICE_NAME/application/$SUBDOMAIN_NAME/query.go"
        "internal/services/$SERVICE_NAME/application/$SUBDOMAIN_NAME/dto.go"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Required file not found: $file"
            return 1
        fi
    done
    
    print_success "Subdomain validation passed!"
    return 0
}

# Function to compile and test
compile_and_test() {
    print_info "Compiling and testing generated subdomain..."
    
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
    print_info "Next steps for your new subdomain:"
    echo
    echo "1. Review generated code:"
    echo "   - internal/services/$SERVICE_NAME/application/$SUBDOMAIN_NAME/"
    echo
    echo "2. Customize business logic:"
    echo "   - Update command handlers in command.go"
    echo "   - Update query handlers in query.go"
    echo "   - Add validation in dto.go"
    echo
    echo "3. Integrate with existing entities:"
    echo "   - Update domain entities if needed"
    echo "   - Add repository methods if needed"
    echo "   - Update service layer if needed"
    echo
    echo "4. Add API endpoints:"
    echo "   - Update handlers in delivery/http/"
    echo "   - Add routes in delivery/http/router.go"
    echo "   - Register routes in bootstrap/di.go"
    echo
    echo "5. Test your subdomain:"
    echo "   - Run: go test ./internal/services/$SERVICE_NAME/..."
    echo "   - Start server: make run"
    echo "   - Test endpoints with curl or Postman"
    echo
    echo "6. Add features if needed:"
    echo "   - ./scripts/create-feature.sh <feature> $SERVICE_NAME --subdomain $SUBDOMAIN_NAME"
    echo
}

# Main function
main() {
    echo "=========================================="
    echo "Interactive Subdomain Creation"
    echo "=========================================="
    echo
    
    # Check if we're in the project root
    if [[ ! -f "go.mod" ]]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Check if required files exist
    if [[ ! -f "scripts/create-subdomain.sh" ]]; then
        print_error "create-subdomain.sh script not found"
        exit 1
    fi
    
    # Gather subdomain information
    gather_subdomain_info
    
    # Show summary
    echo
    echo "=========================================="
    echo "Subdomain Creation Summary"
    echo "=========================================="
    echo "Parent Service: $SERVICE_NAME"
    echo "Subdomain Name: $SUBDOMAIN_NAME"
    echo "Purpose: $SUBDOMAIN_PURPOSE"
    echo "Operations: $OPERATIONS"
    echo "Business Rules: $BUSINESS_RULES"
    echo "Entity Relationships: $ENTITY_RELATIONSHIPS"
    echo "Data Flow: $DATA_FLOW"
    echo "API Integration: $API_INTEGRATION"
    echo "Error Handling: $ERROR_HANDLING"
    echo "Testing: $TESTING_REQUIREMENTS"
    echo "Documentation: $DOCUMENTATION"
    echo
    
    # Confirm generation
    if prompt_yes_no "Proceed with subdomain generation?" "y"; then
        echo
        
        # Create context file
        create_context_file
        
        # Generate subdomain
        if generate_subdomain; then
            
            # Validate generated subdomain
            if validate_generated_subdomain; then
                
                # Compile and test
                if compile_and_test; then
                    print_success "Subdomain creation completed successfully!"
                    show_next_steps
                else
                    print_warning "Subdomain created but compilation/testing had issues"
                    show_next_steps
                fi
            else
                print_error "Subdomain generation validation failed"
                exit 1
            fi
        else
            print_error "Subdomain generation failed"
            exit 1
        fi
    else
        print_info "Subdomain creation cancelled"
        exit 0
    fi
}

# Run main function
main "$@"
