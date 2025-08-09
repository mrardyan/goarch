# Runtime-Only Secrets Management Guide

## Overview

This guide explains how to properly manage secrets as runtime-only variables in the Go Architecture project, ensuring that sensitive information is never embedded in container images or build artifacts.

## Security Principles

### 1. Runtime-Only Variables
- **Available only when container is running**
- **Never embedded in container images**
- **Injected securely at container startup**
- **Perfect for secrets and sensitive data**

### 2. Build-Time Variables
- **Available during build and runtime**
- **Embedded in container image**
- **Suitable for configuration and feature flags**
- **Never use for secrets**

## Variable Classification

### Runtime-Only Secrets (RUN_TIME scope)

#### Authentication & Security
```bash
# JWT Secrets
JWT_SECRET=your-super-secret-jwt-key
JWT_REFRESH_SECRET=your-refresh-secret-key

# Password Hashing
BCRYPT_COST=12
```

#### Database & External Services
```bash
# Database Connection
DATABASE_URL=postgresql://user:pass@host:port/db

# Redis Configuration
REDIS_HOST=your-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
REDIS_DB=0
REDIS_TIMEOUT=5s
REDIS_POOL_SIZE=10

# Email Service
EMAIL_SMTP_USERNAME=your-smtp-username
EMAIL_SMTP_PASSWORD=your-smtp-password
```

#### External API Keys
```bash
# Payment Processing
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Communication Services
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_ACCOUNT_SID=your-twilio-sid

# Cloud Services
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
AWS_REGION=us-east-1

# Other Services
SENTRY_DSN=https://your-sentry-dsn
```

#### Deployment Configuration
```bash
# DigitalOcean App Platform
DO_APP_ID=your-app-id
DO_APP_NAME=your-app-name

# Load Balancer
TRUSTED_PROXIES=10.0.0.0/8,172.16.0.0/12
```

### Build-Time Configuration (RUN_AND_BUILD_TIME scope)

#### Application Configuration
```bash
# Environment
ENVIRONMENT=production
SERVER_PORT=8080
LOG_LEVEL=info

# Feature Flags
FEATURE_USER_REGISTRATION=true
FEATURE_EMAIL_VERIFICATION=true
FEATURE_MULTI_TENANCY=false

# Security Settings (Non-sensitive)
JWT_EXPIRATION=24h
SESSION_EXPIRATION=168h
CORS_ALLOWED_ORIGINS=https://app.com

# Rate Limiting
RATE_LIMIT_REQUESTS=1000
RATE_LIMIT_WINDOW=1m
```

#### Internationalization
```bash
# Localization
DEFAULT_TIMEZONE=UTC
DEFAULT_CURRENCY=USD
DEFAULT_LOCALE=en_US
SUPPORTED_LOCALES=en_US,es_ES,fr_FR
SUPPORTED_CURRENCIES=USD,EUR,GBP,JPY
SUPPORTED_TIMEZONES=UTC,America/New_York
```

## Implementation in Your Project

### 1. Environment File Structure

Your environment files are organized with clear separation:

```bash
# =============================================================================
# RUNTIME-ONLY SECRETS (RUN_TIME SCOPE)
# =============================================================================
JWT_SECRET=your-secret-key
DATABASE_URL=your-database-url
# ... other secrets

# =============================================================================
# BUILD-TIME CONFIGURATION (RUN_AND_BUILD_TIME SCOPE)
# =============================================================================
ENVIRONMENT=production
SERVER_PORT=8080
# ... other configuration
```

### 2. Deployment Script Logic

The deployment script automatically categorizes variables:

```bash
# Build-time variables (embedded in container)
ENVIRONMENT|HTTP_PORT|SERVER_HOST|...|SUPPORTED_TIMEZONES|DEBUG_MODE)
    scope="RUN_AND_BUILD_TIME"

# Runtime-only variables (injected at startup)
JWT_SECRET|JWT_REFRESH_SECRET|DATABASE_URL|REDIS_*|STRIPE_SECRET_KEY|...)
    scope="RUN_TIME"
```

### 3. DigitalOcean App Platform Integration

The generated app spec includes proper scoping:

```yaml
envs:
  - key: JWT_SECRET
    scope: RUN_TIME
    value: "your-secret-key"
  - key: ENVIRONMENT
    scope: RUN_AND_BUILD_TIME
    value: "production"
```

## Security Best Practices

### 1. Secret Management

#### **Never Commit Secrets**
```bash
# ✅ Good - Use environment files
JWT_SECRET=your-actual-secret

# ❌ Bad - Never hardcode in source
JWT_SECRET=hardcoded-secret-in-code
```

#### **Use Strong Secrets**
```bash
# ✅ Good - Strong, random secrets
JWT_SECRET=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# ❌ Bad - Weak, predictable secrets
JWT_SECRET=my-secret-key
```

### 2. Environment-Specific Secrets

#### **Development**
```bash
JWT_SECRET=dev-jwt-secret-key-change-in-production
DATABASE_URL=postgresql://dev:dev@localhost:5432/dev_db
```

#### **Staging**
```bash
JWT_SECRET=staging-jwt-secret-key-change-in-production
DATABASE_URL=postgresql://staging:staging@staging-db:5432/staging_db
```

#### **Production**
```bash
JWT_SECRET=production-jwt-secret-key-change-this-immediately
DATABASE_URL=postgresql://prod:prod@prod-db:5432/prod_db
```

### 3. Secret Rotation

#### **Regular Rotation**
- Rotate JWT secrets monthly
- Rotate database passwords quarterly
- Rotate API keys when compromised

#### **Zero-Downtime Rotation**
```bash
# Use multiple secrets for zero-downtime rotation
JWT_SECRET=current-secret
JWT_SECRET_PREVIOUS=previous-secret
```

## Deployment Workflow

### 1. Local Development

```bash
# Copy template
cp templates/env/env.development.template .env.development

# Edit with your secrets
nano .env.development

# Deploy
./scripts/deploy.sh dev deploy
```

### 2. Staging Deployment

```bash
# Copy template
cp templates/env/env.staging.template .env.staging

# Edit with staging secrets
nano .env.staging

# Deploy
./scripts/deploy.sh staging deploy
```

### 3. Production Deployment

```bash
# Copy template
cp templates/env/env.production.template .env.production

# Edit with production secrets
nano .env.production

# Deploy
./scripts/deploy.sh prod deploy
```

## Verification and Monitoring

### 1. Verify Secret Scoping

Check the generated app spec:

```bash
# Generate spec to verify scoping
./scripts/deploy.sh dev generate

# Check the generated file
cat .do/app-development.yaml
```

### 2. Monitor Secret Usage

```bash
# Check app logs for secret-related errors
./scripts/deploy.sh dev logs

# Verify app status
./scripts/deploy.sh dev status
```

### 3. Security Auditing

#### **Container Image Analysis**
```bash
# Check if secrets are embedded in image
docker history your-app-image

# Scan for secrets in layers
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image your-app-image
```

#### **Runtime Verification**
```bash
# Check environment variables at runtime
doctl apps get your-app-id --format EnvVars
```

## Troubleshooting

### Common Issues

#### **1. Secret Not Available at Runtime**
```bash
# Problem: Secret not injected
# Solution: Check variable name in deployment script
# Ensure it's in the RUN_TIME category
```

#### **2. Build-Time Variable Missing**
```bash
# Problem: Configuration not applied
# Solution: Check variable name in deployment script
# Ensure it's in the RUN_AND_BUILD_TIME category
```

#### **3. Secret in Container Image**
```bash
# Problem: Secret embedded in image
# Solution: Check variable scoping in deployment script
# Ensure secret variables are marked as RUN_TIME
```

### Debugging Commands

```bash
# Check app spec generation
./scripts/deploy.sh dev generate

# View app configuration
doctl apps get your-app-id

# Check environment variables
doctl apps get your-app-id --format EnvVars

# View deployment logs
./scripts/deploy.sh dev logs
```

## Advanced Topics

### 1. Secret Rotation Strategy

#### **Automated Rotation**
```bash
# Script to rotate secrets
#!/bin/bash
# Generate new secret
NEW_SECRET=$(openssl rand -base64 32)

# Update environment file
sed -i "s/JWT_SECRET=.*/JWT_SECRET=$NEW_SECRET/" .env.production

# Deploy with new secret
./scripts/deploy.sh prod deploy
```

#### **Gradual Rollout**
```bash
# Deploy with multiple secrets
JWT_SECRET=current-secret
JWT_SECRET_PREVIOUS=previous-secret

# Application validates against both
```

### 2. External Secret Management

#### **DigitalOcean Secrets**
```bash
# Store secrets in DigitalOcean
doctl secrets create jwt-secret --data-file jwt-secret.txt

# Reference in app spec
envs:
  - key: JWT_SECRET
    scope: RUN_TIME
    value: ${secrets.jwt-secret}
```

#### **HashiCorp Vault Integration**
```bash
# Configure Vault
VAULT_ADDR=https://your-vault.com
VAULT_TOKEN=your-vault-token

# Fetch secrets at runtime
JWT_SECRET=$(vault kv get -field=value secret/jwt-secret)
```

### 3. Compliance and Auditing

#### **Secret Audit Trail**
```bash
# Log secret access
LOG_SECRET_ACCESS=true
SECRET_AUDIT_LOG=/var/log/secret-access.log
```

#### **Compliance Reporting**
```bash
# Generate compliance report
./scripts/audit-secrets.sh

# Check for hardcoded secrets
./scripts/scan-secrets.sh
```

## Summary

Runtime-only secrets management ensures:

1. **Security**: Secrets never embedded in container images
2. **Flexibility**: Easy secret rotation and management
3. **Compliance**: Proper separation of concerns
4. **Auditability**: Clear tracking of secret usage

By following this guide, you maintain a secure, compliant, and maintainable secrets management strategy for your Go application.
