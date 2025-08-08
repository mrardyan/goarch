#!/bin/bash

# Prompt-Based Subdomain Creation Script
# Creates subdomains within existing services using context and rules

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

# Function to validate subdomain parameters
validate_subdomain_params() {
    local subdomain_name="$1"
    local service_name="$2"
    
    # Check if subdomain name is provided
    if [[ -z "$subdomain_name" ]]; then
        print_error "Subdomain name is required"
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
    
    # Check if subdomain already exists
    local subdomain_dir="$service_dir/application/$subdomain_name"
    if [[ -d "$subdomain_dir" ]]; then
        print_error "Subdomain '$subdomain_name' already exists in service '$service_name'"
        return 1
    fi
    
    # Validate subdomain name format
    if [[ ! "$subdomain_name" =~ ^[a-z][a-z0-9_]*[a-z0-9]$ ]]; then
        print_error "Subdomain name must be in snake_case (e.g., user_profile, order_management)"
        return 1
    fi
    
    return 0
}

# Function to gather subdomain context interactively
gather_subdomain_context() {
    local subdomain_name="$1"
    local service_name="$2"
    
    print_status "Gathering context for subdomain: $subdomain_name in service: $service_name"
    
    # Create temporary context file
    local context_file="$TEMP_DIR/${service_name}-${subdomain_name}-context.yaml"
    mkdir -p "$TEMP_DIR"
    
    cat > "$context_file" << EOF
# Subdomain Context for $subdomain_name in $service_name
subdomain:
  name: $subdomain_name
  service: $service_name
  purpose: ""
  
business:
  operations: []
  rules: []
  validations: []
  
integration:
  entity_relationships: []
  data_flow: ""
  api_integration: ""
  
api:
  endpoints: []
  methods: []
  authentication: ""
  
database:
  tables: []
  migrations: []
  indexes: []
EOF

    print_status "Context file created: $context_file"
    print_status "Please edit this file with subdomain details, then run:"
    print_status "  ./scripts/create-subdomain.sh $subdomain_name $service_name --context $context_file"
    
    return 0
}

# Function to load and validate context
load_subdomain_context() {
    local context_file="$1"
    
    if [[ ! -f "$context_file" ]]; then
        print_error "Context file not found: $context_file"
        return 1
    fi
    
    # Load context using yq (if available) or basic parsing
    if command -v yq &> /dev/null; then
        # Use yq for YAML parsing
        SUBDOMAIN_PURPOSE=$(yq eval '.subdomain.purpose' "$context_file")
        BUSINESS_OPERATIONS=$(yq eval '.business.operations[]' "$context_file" | tr '\n' ',' | sed 's/,$//')
        BUSINESS_RULES=$(yq eval '.business.rules[]' "$context_file" | tr '\n' ',' | sed 's/,$//')
        API_ENDPOINTS=$(yq eval '.api.endpoints[]' "$context_file" | tr '\n' ',' | sed 's/,$//')
        API_METHODS=$(yq eval '.api.methods[]' "$context_file" | tr '\n' ',' | sed 's/,$//')
    else
        # Basic parsing for common YAML structure
        print_warning "yq not found, using basic YAML parsing"
        SUBDOMAIN_PURPOSE=$(grep -A1 "purpose:" "$context_file" | tail -1 | sed 's/^[[:space:]]*//')
        BUSINESS_OPERATIONS=$(grep -A1 "operations:" "$context_file" | tail -1 | sed 's/^[[:space:]]*//')
        API_ENDPOINTS=$(grep -A1 "endpoints:" "$context_file" | tail -1 | sed 's/^[[:space:]]*//')
    fi
    
    # Set defaults if not provided
    SUBDOMAIN_PURPOSE=${SUBDOMAIN_PURPOSE:-"Subdomain for managing $subdomain_name"}
    BUSINESS_OPERATIONS=${BUSINESS_OPERATIONS:-"create,read,update,delete"}
    API_METHODS=${API_METHODS:-"GET,POST,PUT,DELETE"}
    
    return 0
}

# Function to generate subdomain using existing create.sh script
generate_subdomain() {
    local subdomain_name="$1"
    local service_name="$2"
    local context_file="$3"
    
    print_status "Generating subdomain: $subdomain_name in service: $service_name"
    
    # Load context
    load_subdomain_context "$context_file"
    
    # Generate subdomain using existing create.sh script
    print_status "Using existing template system for base structure"
    ../create.sh subdomain "$subdomain_name" "$service_name"
    
    # Apply context-based customizations
    customize_subdomain "$service_name" "$subdomain_name" "$context_file"
    
    print_success "Subdomain '$subdomain_name' generated successfully in service '$service_name'"
    print_status "Next steps:"
    print_status "  1. Review generated code in internal/services/$(echo "$service_name" | sed 's/-/_/g')/application/$subdomain_name"
    print_status "  2. Update business logic in command.go and query.go"
    print_status "  3. Add DTOs in dto.go"
    print_status "  4. Integrate with existing domain entities"
    print_status "  5. Add API endpoints in delivery layer"
    
    return 0
}

# Function to customize subdomain based on context
customize_subdomain() {
    local service_name="$1"
    local subdomain_name="$2"
    local context_file="$3"
    
    print_status "Applying context-based customizations"
    
    local service_dir="internal/services/$(echo "$service_name" | sed 's/-/_/g')"
    local subdomain_dir="$service_dir/application/$subdomain_name"
    
    # Read context for customization
    if command -v yq &> /dev/null; then
        local operations=$(yq eval '.business.operations[]' "$context_file" 2>/dev/null || echo "")
        local rules=$(yq eval '.business.rules[]' "$context_file" 2>/dev/null || echo "")
        local endpoints=$(yq eval '.api.endpoints[]' "$context_file" 2>/dev/null || echo "")
        local methods=$(yq eval '.api.methods[]' "$context_file" 2>/dev/null || echo "")
    else
        local operations=""
        local rules=""
        local endpoints=""
        local methods=""
    fi
    
    # Customize operations if specified
    if [[ -n "$operations" ]]; then
        customize_operations "$subdomain_dir" "$operations"
    fi
    
    # Customize business rules if specified
    if [[ -n "$rules" ]]; then
        customize_business_rules "$subdomain_dir" "$rules"
    fi
    
    # Customize API endpoints if specified
    if [[ -n "$endpoints" ]]; then
        customize_api_endpoints "$subdomain_dir" "$endpoints" "$methods"
    fi
    
    return 0
}

# Function to customize operations
customize_operations() {
    local subdomain_dir="$1"
    local operations="$2"
    
    print_status "Customizing operations"
    
    # Parse operations (assuming comma-separated)
    IFS=',' read -ra OPERATION_ARRAY <<< "$operations"
    
    for operation in "${OPERATION_ARRAY[@]}"; do
        operation=$(echo "$operation" | xargs) # trim whitespace
        if [[ -n "$operation" ]]; then
            print_status "Adding operation: $operation"
            # Here you would add operation-specific code generation
            # For now, we'll just log the operation
        fi
    done
}

# Function to customize business rules
customize_business_rules() {
    local subdomain_dir="$1"
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
    local subdomain_dir="$1"
    local endpoints="$2"
    local methods="$3"
    
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

# Function to validate generated subdomain
validate_subdomain() {
    local subdomain_name="$1"
    local service_name="$2"
    
    print_status "Validating generated subdomain"
    
    local service_dir="internal/services/$(echo "$service_name" | sed 's/-/_/g')"
    local subdomain_dir="$service_dir/application/$subdomain_name"
    
    # Check if subdomain directory exists
    if [[ ! -d "$subdomain_dir" ]]; then
        print_error "Subdomain directory not found: $subdomain_dir"
        return 1
    fi
    
    # Check for required files
    local required_files=(
        "command.go"
        "query.go"
        "dto.go"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$subdomain_dir/$file" ]]; then
            print_warning "Required file missing: $file"
        else
            print_success "✓ $file"
        fi
    done
    
    # Check for Go compilation
    print_status "Checking Go compilation..."
    if cd "$service_dir" && go build . 2>/dev/null; then
        print_success "Subdomain compiles successfully"
    else
        print_error "Subdomain compilation failed"
        return 1
    fi
    
    return 0
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <subdomain-name> <service-name> [options]"
    echo ""
    echo "Options:"
    echo "  --context <file>     Use context file for subdomain generation"
    echo "  --interactive        Run in interactive mode"
    echo "  --validate           Validate generated subdomain"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 user_profile user-service"
    echo "  $0 user_profile user-service --context context.yaml"
    echo "  $0 user_profile user-service --interactive"
    echo "  $0 user_profile user-service --validate"
}

# Main function
main() {
    local subdomain_name=""
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
                if [[ -z "$subdomain_name" ]]; then
                    subdomain_name="$1"
                elif [[ -z "$service_name" ]]; then
                    service_name="$1"
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
    if [[ -z "$subdomain_name" ]] || [[ -z "$service_name" ]]; then
        print_error "Subdomain name and service name are required"
        show_usage
        exit 1
    fi
    
    # Validate parameters
    if ! validate_subdomain_params "$subdomain_name" "$service_name"; then
        exit 1
    fi
    
    # Handle validation only mode
    if [[ "$validate_only" == true ]]; then
        validate_subdomain "$subdomain_name" "$service_name"
        exit $?
    fi
    
    # Handle interactive mode
    if [[ "$interactive" == true ]]; then
        gather_subdomain_context "$subdomain_name" "$service_name"
        exit 0
    fi
    
    # Handle context file mode
    if [[ -n "$context_file" ]]; then
        if ! generate_subdomain "$subdomain_name" "$service_name" "$context_file"; then
            print_error "Failed to generate subdomain"
            exit 1
        fi
        
        # Validate generated subdomain
        if ! validate_subdomain "$subdomain_name" "$service_name"; then
            print_error "Subdomain validation failed"
            exit 1
        fi
        
        print_success "Subdomain '$subdomain_name' created and validated successfully in service '$service_name'"
        exit 0
    fi
    
    # Default mode: create context file and exit
    gather_subdomain_context "$subdomain_name" "$service_name"
    exit 0
}

# Run main function
main "$@"
