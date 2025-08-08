# Deployment Guide

## Overview

This section covers deployment strategies, automation, and best practices for deploying the Go application to different environments. The deployment process is designed to be reliable, repeatable, and scalable.

## Deployment Architecture

### Environment Strategy
```
┌─────────────────────────────────────┐
│         Load Balancer              │ ← Traffic distribution
├─────────────────────────────────────┤
│         Application Servers        │ ← Multiple instances
├─────────────────────────────────────┤
│         Database Cluster           │ ← Primary + replicas
├─────────────────────────────────────┤
│         Cache Layer                │ ← Redis cluster
└─────────────────────────────────────┘
```

### Deployment Environments
- **Development**: Local development environment
- **Staging**: Pre-production validation environment
- **Production**: Live application environment

## Environment Configuration

### Development Environment
```bash
# Development configuration
ENV=development
LOG_LEVEL=debug
DB_HOST=localhost
DB_PORT=5432
DB_NAME=app_dev
DB_USER=app_user
DB_PASSWORD=app_password
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=dev-secret-key
```

### Staging Environment
```bash
# Staging configuration
ENV=staging
LOG_LEVEL=info
DB_HOST=staging-db.example.com
DB_PORT=5432
DB_NAME=app_staging
DB_USER=app_user
DB_PASSWORD=staging-password
REDIS_HOST=staging-redis.example.com
REDIS_PORT=6379
JWT_SECRET=staging-secret-key
```

### Production Environment
```bash
# Production configuration
ENV=production
LOG_LEVEL=warn
DB_HOST=production-db.example.com
DB_PORT=5432
DB_NAME=app_production
DB_USER=app_user
DB_PASSWORD=production-password
REDIS_HOST=production-redis.example.com
REDIS_PORT=6379
JWT_SECRET=production-secret-key
```

## Containerization

### Dockerfile
```dockerfile
# Multi-stage build for production
FROM golang:1.21-alpine AS builder

# Install dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main cmd/main/main.go

# Production stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates tzdata

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/main .

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run application
CMD ["./main"]
```

### Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - ENV=development
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=app_dev
      - DB_USER=app_user
      - DB_PASSWORD=app_password
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      - postgres
      - redis
    networks:
      - app-network

  postgres:
    image: postgres:13-alpine
    environment:
      - POSTGRES_DB=app_dev
      - POSTGRES_USER=app_user
      - POSTGRES_PASSWORD=app_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

  redis:
    image: redis:6-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

## Deployment Strategies

### Blue-Green Deployment
```bash
#!/bin/bash
# scripts/deploy-blue-green.sh

# Deploy to blue environment
echo "Deploying to blue environment..."
docker-compose -f docker-compose.blue.yml up -d

# Run health checks
echo "Running health checks..."
for i in {1..30}; do
    if curl -f http://blue-app:8080/health; then
        echo "Blue deployment healthy"
        break
    fi
    sleep 2
done

# Switch traffic to blue
echo "Switching traffic to blue..."
# Update load balancer configuration

# Deploy to green environment
echo "Deploying to green environment..."
docker-compose -f docker-compose.green.yml up -d

# Run health checks
echo "Running health checks..."
for i in {1..30}; do
    if curl -f http://green-app:8080/health; then
        echo "Green deployment healthy"
        break
    fi
    sleep 2
done

# Switch traffic to green
echo "Switching traffic to green..."
# Update load balancer configuration

# Clean up old deployment
echo "Cleaning up old deployment..."
docker-compose -f docker-compose.blue.yml down
```

### Rolling Deployment
```bash
#!/bin/bash
# scripts/deploy-rolling.sh

# Get current deployment
CURRENT_DEPLOYMENT=$(kubectl get deployment app -o jsonpath='{.spec.replicas}')

# Scale up new deployment
echo "Scaling up new deployment..."
kubectl scale deployment app --replicas=$((CURRENT_DEPLOYMENT + 1))

# Wait for new pod to be ready
echo "Waiting for new pod to be ready..."
kubectl rollout status deployment/app

# Scale down old deployment
echo "Scaling down old deployment..."
kubectl scale deployment app --replicas=$CURRENT_DEPLOYMENT

# Wait for rollout to complete
echo "Waiting for rollout to complete..."
kubectl rollout status deployment/app
```

## Kubernetes Deployment

### Deployment Manifest
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  labels:
    app: app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
      - name: app
        image: app:latest
        ports:
        - containerPort: 8080
        env:
        - name: ENV
          value: "production"
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: db-host
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: db-password
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Service Manifest
```yaml
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
```

### Ingress Manifest
```yaml
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

## CI/CD Pipeline

### GitHub Actions
```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Go
      uses: actions/setup-go@v2
      with:
        go-version: '1.21'
    
    - name: Run tests
      run: go test -v ./...
    
    - name: Run linter
      run: golangci-lint run
    
    - name: Build
      run: go build -o bin/app cmd/main/main.go

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1
    
    - name: Login to Docker Hub
      uses: docker/login-action@v1
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    
    - name: Build and push
      uses: docker/build-push-action@v2
      with:
        push: true
        tags: |
          your-registry/app:latest
          your-registry/app:${{ github.sha }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy-staging:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: staging
    steps:
    - name: Deploy to staging
      run: |
        echo "Deploying to staging..."
        # Deploy to staging environment

  deploy-production:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: production
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Deploy to production
      run: |
        echo "Deploying to production..."
        # Deploy to production environment
```

### GitLab CI
```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  DOCKER_DRIVER: overlay2

test:
  stage: test
  image: golang:1.21
  script:
    - go test -v ./...
    - golangci-lint run
  only:
    - main
    - merge_requests

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t app:$CI_COMMIT_SHA .
    - docker push app:$CI_COMMIT_SHA
  only:
    - main

deploy-staging:
  stage: deploy
  image: alpine:latest
  script:
    - echo "Deploying to staging..."
    # Deploy to staging
  environment:
    name: staging
  only:
    - main

deploy-production:
  stage: deploy
  image: alpine:latest
  script:
    - echo "Deploying to production..."
    # Deploy to production
  environment:
    name: production
  when: manual
  only:
    - main
```

## Database Migration

### Migration Strategy
```bash
#!/bin/bash
# scripts/migrate.sh

# Run migrations
echo "Running database migrations..."
migrate -path src/migrations -database "$DATABASE_URL" up

# Check migration status
echo "Migration status:"
migrate -path src/migrations -database "$DATABASE_URL" version
```

### Migration Script
```go
// internal/bootstrap/migration.go
package bootstrap

import (
    "database/sql"
    "fmt"
    "log"
    
    "github.com/golang-migrate/migrate"
    "github.com/golang-migrate/migrate/database/postgres"
    _ "github.com/golang-migrate/migrate/source/file"
)

func RunMigrations(db *sql.DB, migrationsPath string) error {
    driver, err := postgres.WithInstance(db, &postgres.Config{})
    if err != nil {
        return fmt.Errorf("failed to create migration driver: %w", err)
    }
    
    m, err := migrate.NewWithDatabaseInstance(
        fmt.Sprintf("file://%s", migrationsPath),
        "postgres", driver,
    )
    if err != nil {
        return fmt.Errorf("failed to create migration instance: %w", err)
    }
    
    if err := m.Up(); err != nil && err != migrate.ErrNoChange {
        return fmt.Errorf("failed to run migrations: %w", err)
    }
    
    log.Println("Migrations completed successfully")
    return nil
}
```

## Monitoring and Logging

### Health Checks
```go
// Health check endpoint
func HealthCheck(c *gin.Context) {
    health := gin.H{
        "status":    "healthy",
        "timestamp": time.Now(),
        "version":   "1.0.0",
    }
    
    // Check database
    if err := db.Ping(); err != nil {
        health["status"] = "unhealthy"
        health["database"] = "disconnected"
        c.JSON(http.StatusServiceUnavailable, health)
        return
    }
    
    // Check Redis
    if err := redisClient.Ping(context.Background()).Err(); err != nil {
        health["status"] = "unhealthy"
        health["redis"] = "disconnected"
        c.JSON(http.StatusServiceUnavailable, health)
        return
    }
    
    health["database"] = "connected"
    health["redis"] = "connected"
    
    c.JSON(http.StatusOK, health)
}
```

### Logging Configuration
```go
// Structured logging
func SetupLogging(config *Config) (*zap.Logger, error) {
    var logger *zap.Logger
    var err error
    
    switch config.Log.Level {
    case "debug":
        logger, err = zap.NewDevelopment()
    case "info":
        logger, err = zap.NewProduction()
    default:
        logger, err = zap.NewProduction()
    }
    
    if err != nil {
        return nil, err
    }
    
    return logger, nil
}
```

## Security Considerations

### Secrets Management
```yaml
# Kubernetes secrets
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  db-host: <base64-encoded-host>
  db-password: <base64-encoded-password>
  jwt-secret: <base64-encoded-secret>
```

### Network Security
```yaml
# Network policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-network-policy
spec:
  podSelector:
    matchLabels:
      app: app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: database
    ports:
    - protocol: TCP
      port: 5432
```

## Backup and Recovery

### Database Backup
```bash
#!/bin/bash
# scripts/backup.sh

# Create backup directory
BACKUP_DIR="/backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup database
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME > $BACKUP_DIR/database.sql

# Compress backup
gzip $BACKUP_DIR/database.sql

# Upload to cloud storage
aws s3 cp $BACKUP_DIR/database.sql.gz s3://backups/

# Clean up old backups (keep last 7 days)
find /backups -type d -mtime +7 -exec rm -rf {} \;
```

### Recovery Script
```bash
#!/bin/bash
# scripts/recover.sh

# Download backup
aws s3 cp s3://backups/database.sql.gz /tmp/

# Decompress backup
gunzip /tmp/database.sql.gz

# Restore database
psql -h $DB_HOST -U $DB_USER -d $DB_NAME < /tmp/database.sql

# Clean up
rm /tmp/database.sql
```

## Performance Optimization

### Resource Limits
```yaml
# Resource configuration
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

### Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Code review completed
- [ ] Security scan passed
- [ ] Performance tests completed
- [ ] Database migrations ready
- [ ] Configuration updated
- [ ] Monitoring configured

### Deployment
- [ ] Backup current deployment
- [ ] Deploy to staging first
- [ ] Run smoke tests
- [ ] Deploy to production
- [ ] Verify health checks
- [ ] Monitor metrics
- [ ] Update DNS/load balancer

### Post-Deployment
- [ ] Verify application functionality
- [ ] Check error rates
- [ ] Monitor performance
- [ ] Update documentation
- [ ] Notify stakeholders

## Related Documentation

- [Architecture Documentation](../02-architecture/) - System architecture
- [Development Guide](../03-development/) - Development practices
- [Security Guidelines](../06-security/) - Security considerations
- [Performance Optimization](../07-performance/) - Performance tuning
