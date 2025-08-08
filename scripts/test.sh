#!/bin/bash

# Comprehensive Testing Framework
# This script provides comprehensive testing for the Go architecture project
# including syntax checks, compilation, unit tests, integration tests,
# performance tests, security checks, and architecture validation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEST_REPORTS_DIR=".temp/test-reports"
COVERAGE_DIR=".temp/coverage"

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

# Function to create test directories
setup_test_environment() {
    print_info "Setting up test environment..."
    
    mkdir -p "$TEST_REPORTS_DIR"
    mkdir -p "$COVERAGE_DIR"
    
    print_success "Test environment ready"
}

# Function to run syntax check
run_syntax_check() {
    print_info "Running syntax check..."
    
    local errors=0
    
    # Check Go syntax
    if ! go vet ./... 2>/dev/null; then
        print_error "Go syntax errors found"
        errors=$((errors + 1))
    fi
    
    # Check for unused imports
    if ! goimports -l . | grep -q .; then
        print_warning "Unused imports found"
    fi
    
    # Check for formatting issues
    if ! gofmt -l . | grep -q .; then
        print_warning "Code formatting issues found"
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_success "Syntax check passed"
        return 0
    else
        print_error "Syntax check failed"
        return 1
    fi
}

# Function to run compilation test
run_compilation_test() {
    print_info "Running compilation test..."
    
    if go build ./...; then
        print_success "Compilation successful"
        return 0
    else
        print_error "Compilation failed"
        return 1
    fi
}

# Function to run unit tests
run_unit_tests() {
    local target=${1:-"./..."}
    local coverage_file=${2:-""}
    
    print_info "Running unit tests for: $target"
    
    local test_args=("-v" "$target")
    
    if [[ -n "$coverage_file" ]]; then
        test_args+=("-coverprofile" "$coverage_file")
        test_args+=("-covermode" "atomic")
    fi
    
    if go test "${test_args[@]}"; then
        print_success "Unit tests passed"
        return 0
    else
        print_error "Unit tests failed"
        return 1
    fi
}

# Function to run integration tests
run_integration_tests() {
    print_info "Running integration tests..."
    
    if [[ -d "tests/integration" ]]; then
        if go test -v ./tests/integration/...; then
            print_success "Integration tests passed"
            return 0
        else
            print_error "Integration tests failed"
            return 1
        fi
    else
        print_warning "No integration tests found"
        return 0
    fi
}

# Function to run performance tests
run_performance_tests() {
    print_info "Running performance tests..."
    
    if [[ -d "tests/performance" ]]; then
        if go test -v -bench=. ./tests/performance/...; then
            print_success "Performance tests passed"
            return 0
        else
            print_error "Performance tests failed"
            return 1
        fi
    else
        print_warning "No performance tests found"
        return 0
    fi
}

# Function to check test coverage
check_test_coverage() {
    local coverage_file=$1
    local min_coverage=${2:-80}
    
    if [[ -f "$coverage_file" ]]; then
        local coverage=$(go tool cover -func="$coverage_file" | tail -1 | awk '{print $3}' | sed 's/%//')
        
        print_info "Test coverage: ${coverage}% (minimum: ${min_coverage}%)"
        
        if (( $(echo "$coverage >= $min_coverage" | bc -l) )); then
            print_success "Test coverage meets minimum requirement"
            return 0
        else
            print_warning "Test coverage below minimum requirement"
            return 1
        fi
    else
        print_warning "No coverage file found"
        return 1
    fi
}

# Function to run linting
run_linting() {
    print_info "Running linting..."
    
    # Check if golangci-lint is available
    if command -v golangci-lint >/dev/null 2>&1; then
        if golangci-lint run; then
            print_success "Linting passed"
            return 0
        else
            print_error "Linting failed"
            return 1
        fi
    else
        print_warning "golangci-lint not found, skipping linting"
        return 0
    fi
}

# Function to check for security issues
run_security_check() {
    print_info "Running security check..."
    
    # Check for common security issues
    local security_issues=0
    
    # Check for hardcoded secrets
    if grep -r "password\|secret\|key" --include="*.go" . | grep -v "//" | grep -v "TODO" | grep -q .; then
        print_warning "Potential hardcoded secrets found"
        security_issues=$((security_issues + 1))
    fi
    
    # Check for SQL injection vulnerabilities
    if grep -r "fmt.Sprintf.*SELECT\|fmt.Sprintf.*INSERT\|fmt.Sprintf.*UPDATE\|fmt.Sprintf.*DELETE" --include="*.go" . | grep -q .; then
        print_warning "Potential SQL injection vulnerabilities found"
        security_issues=$((security_issues + 1))
    fi
    
    # Check for proper error handling
    if grep -r "if err != nil" --include="*.go" . | wc -l | grep -q "^0$"; then
        print_warning "No error handling found"
        security_issues=$((security_issues + 1))
    fi
    
    if [[ $security_issues -eq 0 ]]; then
        print_success "Security check passed"
        return 0
    else
        print_warning "Security issues found: $security_issues"
        return 1
    fi
}

# Function to validate service structure
validate_service_structure() {
    local service_name=$1
    
    print_info "Validating service structure for: $service_name"
    
    local required_dirs=(
        "internal/services/$service_name/domain/entity"
        "internal/services/$service_name/domain/repository"
        "internal/services/$service_name/application"
        "internal/services/$service_name/delivery/http"
        "internal/services/$service_name/infrastructure/postgres"
    )
    
    local required_files=(
        "internal/services/$service_name/domain/entity/entity.go"
        "internal/services/$service_name/domain/repository/repository.go"
        "internal/services/$service_name/application/command.go"
        "internal/services/$service_name/application/query.go"
        "internal/services/$service_name/application/dto.go"
        "internal/services/$service_name/delivery/http/handler.go"
        "internal/services/$service_name/infrastructure/postgres/repository.go"
    )
    
    local errors=0
    
    # Check directories
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            print_error "Required directory not found: $dir"
            errors=$((errors + 1))
        fi
    done
    
    # Check files
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Required file not found: $file"
            errors=$((errors + 1))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        print_success "Service structure validation passed"
        return 0
    else
        print_error "Service structure validation failed: $errors errors"
        return 1
    fi
}

# Function to validate subdomain structure
validate_subdomain_structure() {
    local service_name=$1
    local subdomain_name=$2
    
    print_info "Validating subdomain structure for: $service_name/$subdomain_name"
    
    local required_files=(
        "internal/services/$service_name/application/$subdomain_name/command.go"
        "internal/services/$service_name/application/$subdomain_name/query.go"
        "internal/services/$service_name/application/$subdomain_name/dto.go"
    )
    
    local errors=0
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Required file not found: $file"
            errors=$((errors + 1))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        print_success "Subdomain structure validation passed"
        return 0
    else
        print_error "Subdomain structure validation failed: $errors errors"
        return 1
    fi
}

# Function to generate test report
generate_test_report() {
    local report_file="$TEST_REPORTS_DIR/test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    print_info "Generating test report: $report_file"
    
    {
        echo "Test Report - $(date)"
        echo "=========================================="
        echo
        echo "Test Results:"
        echo "-------------"
        echo "Syntax Check: $SYNTAX_RESULT"
        echo "Compilation: $COMPILATION_RESULT"
        echo "Unit Tests: $UNIT_TEST_RESULT"
        echo "Integration Tests: $INTEGRATION_RESULT"
        echo "Performance Tests: $PERFORMANCE_RESULT"
        echo "Linting: $LINTING_RESULT"
        echo "Security Check: $SECURITY_RESULT"
        echo
        echo "Coverage: $COVERAGE_RESULT"
        echo
        echo "Structure Validation:"
        echo "--------------------"
        for service in "${SERVICES[@]}"; do
            echo "$service: ${SERVICE_VALIDATION_RESULTS[$service]}"
        done
        for subdomain in "${SUBDOMAINS[@]}"; do
            echo "$subdomain: ${SUBDOMAIN_VALIDATION_RESULTS[$subdomain]}"
        done
        echo
        echo "Summary:"
        echo "--------"
        echo "Total Tests: $TOTAL_TESTS"
        echo "Passed: $PASSED_TESTS"
        echo "Failed: $FAILED_TESTS"
        echo "Success Rate: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
    } > "$report_file"
    
    print_success "Test report generated: $report_file"
}

# Function to run comprehensive testing
run_comprehensive_testing() {
    local target=${1:-"all"}
    
    print_info "Starting comprehensive testing for: $target"
    
    # Initialize counters
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
    
    # Setup test environment
    setup_test_environment
    
    # Initialize result variables
    SYNTAX_RESULT="FAILED"
    COMPILATION_RESULT="FAILED"
    UNIT_TEST_RESULT="FAILED"
    INTEGRATION_RESULT="FAILED"
    PERFORMANCE_RESULT="FAILED"
    LINTING_RESULT="FAILED"
    SECURITY_RESULT="FAILED"
    COVERAGE_RESULT="FAILED"
    
    # Initialize validation results
    declare -A SERVICE_VALIDATION_RESULTS
    declare -A SUBDOMAIN_VALIDATION_RESULTS
    
    # Run syntax check
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if run_syntax_check; then
        SYNTAX_RESULT="PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    # Run compilation test
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if run_compilation_test; then
        COMPILATION_RESULT="PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    # Run unit tests
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    local coverage_file="$COVERAGE_DIR/coverage.out"
    if run_unit_tests "./..." "$coverage_file"; then
        UNIT_TEST_RESULT="PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    # Check test coverage
    if check_test_coverage "$coverage_file"; then
        COVERAGE_RESULT="PASSED"
    fi
    
    # Run integration tests
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if run_integration_tests; then
        INTEGRATION_RESULT="PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    # Run performance tests
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if run_performance_tests; then
        PERFORMANCE_RESULT="PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    # Run linting
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if run_linting; then
        LINTING_RESULT="PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    # Run security check
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if run_security_check; then
        SECURITY_RESULT="PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    # Validate service structures
    SERVICES=()
    if [[ -d "internal/services" ]]; then
        for service in internal/services/*/; do
            if [[ -d "$service" ]]; then
                service_name=$(basename "$service")
                SERVICES+=("$service_name")
                
                TOTAL_TESTS=$((TOTAL_TESTS + 1))
                if validate_service_structure "$service_name"; then
                    SERVICE_VALIDATION_RESULTS["$service_name"]="PASSED"
                    PASSED_TESTS=$((PASSED_TESTS + 1))
                else
                    SERVICE_VALIDATION_RESULTS["$service_name"]="FAILED"
                    FAILED_TESTS=$((FAILED_TESTS + 1))
                fi
            fi
        done
    fi
    
    # Validate subdomain structures
    SUBDOMAINS=()
    for service in "${SERVICES[@]}"; do
        if [[ -d "internal/services/$service/application" ]]; then
            for subdomain in internal/services/$service/application/*/; do
                if [[ -d "$subdomain" ]]; then
                    subdomain_name=$(basename "$subdomain")
                    subdomain_key="$service/$subdomain_name"
                    SUBDOMAINS+=("$subdomain_key")
                    
                    TOTAL_TESTS=$((TOTAL_TESTS + 1))
                    if validate_subdomain_structure "$service" "$subdomain_name"; then
                        SUBDOMAIN_VALIDATION_RESULTS["$subdomain_key"]="PASSED"
                        PASSED_TESTS=$((PASSED_TESTS + 1))
                    else
                        SUBDOMAIN_VALIDATION_RESULTS["$subdomain_key"]="FAILED"
                        FAILED_TESTS=$((FAILED_TESTS + 1))
                    fi
                fi
            done
        fi
    done
    
    # Generate test report
    generate_test_report
    
    # Print summary
    echo
    echo "=========================================="
    echo "Testing Summary"
    echo "=========================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Success Rate: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
    echo
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        print_success "All tests passed!"
        return 0
    else
        print_error "Some tests failed. Check the test report for details."
        return 1
    fi
}

# Function to test specific service
test_service() {
    local service_name=$1
    
    print_info "Testing service: $service_name"
    
    if [[ ! -d "internal/services/$service_name" ]]; then
        print_error "Service '$service_name' not found"
        return 1
    fi
    
    # Run tests for specific service
    if go test -v "./internal/services/$service_name/..."; then
        print_success "Service '$service_name' tests passed"
        return 0
    else
        print_error "Service '$service_name' tests failed"
        return 1
    fi
}

# Function to test specific subdomain
test_subdomain() {
    local service_name=$1
    local subdomain_name=$2
    
    print_info "Testing subdomain: $service_name/$subdomain_name"
    
    if [[ ! -d "internal/services/$service_name/application/$subdomain_name" ]]; then
        print_error "Subdomain '$subdomain_name' not found in service '$service_name'"
        return 1
    fi
    
    # Run tests for specific subdomain
    if go test -v "./internal/services/$service_name/application/$subdomain_name/..."; then
        print_success "Subdomain '$service_name/$subdomain_name' tests passed"
        return 0
    else
        print_error "Subdomain '$service_name/$subdomain_name' tests failed"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [TARGET]"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -s, --service NAME      Test specific service"
    echo "  -d, --subdomain SVC/SUB Test specific subdomain"
    echo "  -c, --coverage          Generate coverage report"
    echo "  -r, --report            Generate detailed test report"
    echo "  -v, --verbose           Verbose output"
    echo
    echo "Targets:"
    echo "  all                     Test all services and subdomains (default)"
    echo "  services                 Test all services"
    echo "  subdomains              Test all subdomains"
    echo "  integration             Run integration tests only"
    echo "  performance             Run performance tests only"
    echo
    echo "Examples:"
    echo "  $0                      # Test everything"
    echo "  $0 -s user-service      # Test specific service"
    echo "  $0 -d user-service/profile # Test specific subdomain"
    echo "  $0 -c                   # Generate coverage report"
    echo "  $0 integration          # Run integration tests only"
    echo
    echo "Description:"
    echo "  This script provides comprehensive testing for the Go architecture project."
    echo "  It validates code quality, runs tests, checks architecture compliance,"
    echo "  and generates detailed reports."
}

# Main function
main() {
    local target="all"
    local service_name=""
    local subdomain_name=""
    local generate_coverage=false
    local generate_report=false
    local verbose=false
    
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
            -d|--subdomain)
                IFS='/' read -r service_name subdomain_name <<< "$2"
                shift 2
                ;;
            -c|--coverage)
                generate_coverage=true
                shift
                ;;
            -r|--report)
                generate_report=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            all|services|subdomains|integration|performance)
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
    
    # Run tests based on target
    case $target in
        all)
            if [[ -n "$service_name" ]]; then
                test_service "$service_name"
            elif [[ -n "$subdomain_name" ]]; then
                test_subdomain "$service_name" "$subdomain_name"
            else
                run_comprehensive_testing
            fi
            ;;
        services)
            if [[ -n "$service_name" ]]; then
                test_service "$service_name"
            else
                # Test all services
                for service in internal/services/*/; do
                    if [[ -d "$service" ]]; then
                        service_name=$(basename "$service")
                        test_service "$service_name"
                    fi
                done
            fi
            ;;
        subdomains)
            # Test all subdomains
            for service in internal/services/*/; do
                if [[ -d "$service" ]]; then
                    service_name=$(basename "$service")
                    if [[ -d "internal/services/$service_name/application" ]]; then
                        for subdomain in internal/services/$service_name/application/*/; do
                            if [[ -d "$subdomain" ]]; then
                                subdomain_name=$(basename "$subdomain")
                                test_subdomain "$service_name" "$subdomain_name"
                            fi
                        done
                    fi
                fi
            done
            ;;
        integration)
            run_integration_tests
            ;;
        performance)
            run_performance_tests
            ;;
        *)
            print_error "Unknown target: $target"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
