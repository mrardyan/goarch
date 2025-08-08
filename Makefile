.PHONY: help build run test clean docker-build docker-run setup create-service

# Default target
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development
setup: ## Setup the development environment
	@echo "Setting up development environment..."
	./scripts/setup.sh

build: ## Build the application
	@echo "Building application..."
	go build -o bin/server cmd/main/main.go
	go build -o bin/worker cmd/worker/main.go

run: ## Run the main server
	@echo "Running main server..."
	go run cmd/main/main.go

run-worker: ## Run the worker
	@echo "Running worker..."
	go run cmd/worker/main.go

test: ## Run all tests
	@echo "Running tests..."
	go test ./...

test-coverage: ## Run tests with coverage
	@echo "Running tests with coverage..."
	go test -cover ./...

test-race: ## Run tests with race detection
	@echo "Running tests with race detection..."
	go test -race ./...

# Service management
create-service: ## Create a new service (usage: make create-service NAME=service-name)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME parameter is required"; \
		echo "Usage: make create-service NAME=user-service"; \
		exit 1; \
	fi
	./scripts/create.sh service $(NAME)

# Docker
docker-build: ## Build Docker image
	@echo "Building Docker image..."
	docker build -t golang-arch .

docker-run: ## Run with Docker Compose
	@echo "Starting services with Docker Compose..."
	docker-compose up -d

docker-stop: ## Stop Docker Compose services
	@echo "Stopping Docker Compose services..."
	docker-compose down

docker-logs: ## Show Docker Compose logs
	@echo "Showing Docker Compose logs..."
	docker-compose logs -f

# Database
migrate-up: ## Run database migrations up
	@echo "Running database migrations..."
	migrate -path src/migrations -database "postgres://postgres:password@localhost:5432/golang_arch?sslmode=disable" up

migrate-down: ## Run database migrations down
	@echo "Rolling back database migrations..."
	migrate -path src/migrations -database "postgres://postgres:password@localhost:5432/golang_arch?sslmode=disable" down

migrate-create: ## Create a new migration (usage: make migrate-create NAME=migration-name)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME parameter is required"; \
		echo "Usage: make migrate-create NAME=create_users_table"; \
		exit 1; \
	fi
	migrate create -ext sql -dir src/migrations -seq $(NAME)

# Code quality
lint: ## Run linter
	@echo "Running linter..."
	golangci-lint run

fmt: ## Format code
	@echo "Formatting code..."
	go fmt ./...

vet: ## Run go vet
	@echo "Running go vet..."
	go vet ./...

# Dependencies
deps: ## Download dependencies
	@echo "Downloading dependencies..."
	go mod download

deps-update: ## Update dependencies
	@echo "Updating dependencies..."
	go get -u ./...
	go mod tidy

# Cleanup
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	rm -rf bin/
	go clean -cache

# Development helpers
dev: ## Start development environment
	@echo "Starting development environment..."
	docker-compose up -d postgres redis
	@echo "Waiting for services to be ready..."
	@sleep 5
	@echo "Running migrations..."
	$(MAKE) migrate-up
	@echo "Starting application..."
	$(MAKE) run

dev-stop: ## Stop development environment
	@echo "Stopping development environment..."
	docker-compose down
	@echo "Cleaning up..."
	$(MAKE) clean

# Production
prod-build: ## Build for production
	@echo "Building for production..."
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o bin/server cmd/main/main.go

# Documentation
docs-serve: ## Serve documentation (requires mkdocs)
	@if command -v mkdocs >/dev/null 2>&1; then \
		mkdocs serve; \
	else \
		echo "mkdocs not found. Install with: pip install mkdocs"; \
	fi

# Health checks
health: ## Check application health
	@echo "Checking application health..."
	@curl -f http://localhost:8080/health || echo "Application is not running"

# Performance
bench: ## Run benchmarks
	@echo "Running benchmarks..."
	go test -bench=. ./...

# Security
security-scan: ## Run security scan (requires gosec)
	@if command -v gosec >/dev/null 2>&1; then \
		gosec ./...; \
	else \
		echo "gosec not found. Install with: go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest"; \
	fi 