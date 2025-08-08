#!/bin/bash

# Golang Architecture Template Setup Script
# This script sets up the development environment and initializes the project

set -e

# Helper functions for better output formatting
print_header() {
    echo ""
    echo "🔹 $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_status() {
    echo "  📋 $1"
}

print_success() {
    echo "  ✅ $1"
}

print_warning() {
    echo "  ⚠️  $1"
}

print_error() {
    echo "  ❌ $1"
}

setup_env_files() {
    local environment="$1"
    local template_file=""
    local env_file=""
    
    case "$environment" in
        "dev")
            template_file="templates/env/env.development.template"
            env_file=".env.development"
            ;;
        "staging")
            template_file="templates/env/env.staging.template"
            env_file=".env.staging"
            ;;
        "prod")
            template_file="templates/env/env.production.template"
            env_file=".env.production"
            ;;
    esac
    
    print_header "Setting up environment files for $environment"
    
    # Check if template exists
    if [ ! -f "$template_file" ]; then
        print_error "Template file not found: $template_file"
        exit 1
    fi
    
    # Copy template to env file if it doesn't exist
    if [ ! -f "$env_file" ]; then
        print_status "Creating $env_file from template..."
        cp "$template_file" "$env_file"
        print_success "Created $env_file"
        print_warning "Please edit $env_file with your actual values before deploying"
    else
        print_status "$env_file already exists"
    fi
}

echo "🚀 Setting up Golang Architecture Template..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.21 or later."
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
if [[ $(echo "$GO_VERSION 1.21" | tr " " "\n" | sort -V | head -n 1) != "1.21" ]]; then
    echo "❌ Go version $GO_VERSION is too old. Please upgrade to Go 1.21 or later."
    exit 1
fi

echo "✅ Go version $GO_VERSION detected"

# Initialize Go module if not already done
if [ ! -f "go.mod" ]; then
    echo "📦 Initializing Go module..."
    go mod init golang-arch
fi

# Download dependencies
echo "📥 Downloading dependencies..."
go mod tidy

# Create necessary directories if they don't exist
echo "📁 Creating directory structure..."
mkdir -p config
mkdir -p internal/services
mkdir -p src/migrations
mkdir -p src/email-templates
mkdir -p tests/services

# Create default config file if it doesn't exist
if [ ! -f "config.yaml" ]; then
    echo "⚙️ Creating default configuration..."
    cat > config.yaml << EOF
server:
  port: 8080
  host: "0.0.0.0"

database:
  host: "localhost"
  port: 5432
  name: "golang_arch"
  user: "postgres"
  password: "password"
  ssl_mode: "disable"

redis:
  host: "localhost"
  port: 6379
  password: ""
  db: 0

log:
  level: "info"
  format: "json"
EOF
fi

# Note: The application uses Viper for configuration and reads from:
# 1. Environment variables (highest priority)
# 2. config.yaml file
# 3. Default values (lowest priority)
#
# The environment-specific files (.env.development, .env.staging, .env.production)
# are used by deployment scripts and DigitalOcean App Platform.

# Setup environment files for all environments
setup_env_files "dev"
setup_env_files "staging"
setup_env_files "prod"

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    echo "📝 Creating .gitignore..."
    cat > .gitignore << EOF
# Binaries for programs and plugins
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test binary, built with \`go test -c\`
*.test

# Output of the go coverage tool, specifically when used with LiteIDE
*.out

# Dependency directories (remove the comment below to include it)
# vendor/

# Go workspace file
go.work

# Environment variables
.env.local
.env.*.local
.env.development
.env.staging
.env.production

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs
*.log

# Build artifacts
build/
dist/

# Database files
*.db
*.sqlite

# Temporary files
tmp/
temp/
EOF
else
    # Update existing .gitignore to include environment files
    if ! grep -q "\.env\.development" .gitignore; then
        echo "📝 Updating .gitignore to include environment files..."
        cat >> .gitignore << EOF

# Environment files
.env.development
.env.staging
.env.production
EOF
    fi
fi

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x scripts/*.sh

echo "✅ Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Review and update config.yaml with your settings"
echo "2. Edit environment files (.env.development, .env.staging, .env.production) with your actual values"
echo "3. Set up your database (PostgreSQL recommended)"
echo "4. Run 'go run cmd/main/main.go' to start the server"
echo "5. Run 'go test ./...' to run tests"
echo ""
echo "📚 For more information, see docs/development/" 