# Deployment Script Documentation

## Overview

The deployment script (`scripts/deploy.sh`) is a unified tool for deploying the Golang Architecture project to DigitalOcean App Platform. It handles environment variable management, app spec generation, and deployment operations.

## Features

- **Environment Management**: Supports dev, staging, and production environments
- **App Spec Generation**: Automatically generates DigitalOcean app specs from `.env` files
- **Secret Management**: Properly scopes environment variables as build-time or runtime
- **Deployment Operations**: Create, update, and manage apps on DigitalOcean
- **Health Monitoring**: View logs and check app status

## Prerequisites

### Required Tools

1. **doctl** - DigitalOcean CLI tool
   ```bash
   brew install doctl
   ```

2. **yq** - YAML processor
   ```bash
   brew install yq
   ```

3. **Authentication**
   ```bash
   doctl auth init
   ```

### Environment Setup

Before using the deployment script, run the setup script to create environment files:

```bash
./scripts/setup.sh
```

This creates:
- `.env.development`
- `.env.staging` 
- `.env.production`

## Usage

### Basic Syntax

```bash
./scripts/deploy.sh [environment] [action]
```

### Environments

- `dev` - Development environment
- `staging` - Staging environment  
- `prod` - Production environment

### Actions

- `deploy` - Deploy/update existing app
- `create` - Create new app
- `generate` - Generate app spec only
- `logs` - View app logs
- `status` - Check app status
- `list` - List all apps
- `help` - Show help message

## Examples

### Generate App Spec

Generate the app specification file for development:

```bash
./scripts/deploy.sh dev generate
```

This creates `.do/app-development.yaml` with environment variables from `.env.development`.

### Deploy to Development

Deploy to development environment:

```bash
./scripts/deploy.sh dev deploy
```

### Create Production App

Create a new production app:

```bash
./scripts/deploy.sh prod create
```

### View Logs

View logs for development app:

```bash
./scripts/deploy.sh dev logs
```

### Check Status

Check status of staging app:

```bash
./scripts/deploy.sh staging status
```

## Environment Variables

The script automatically processes environment variables from `.env` files and injects them into the DigitalOcean app spec.

### Variable Scoping

The script categorizes environment variables into two scopes:

#### Build-Time Variables (`RUN_AND_BUILD_TIME`)
These can be included in the app spec and are available during build:

- `ENVIRONMENT`
- `HTTP_PORT`
- `SERVER_HOST`
- `SERVER_PORT`
- `LOG_LEVEL`
- `LOG_FORMAT`
- `HEALTH_CHECK_PATH`
- `FEATURE_*` flags
- `EMAIL_*` configuration
- `JWT_EXPIRATION`
- `SESSION_EXPIRATION`
- `BCRYPT_COST`
- `CORS_ALLOWED_ORIGINS`
- `RATE_LIMIT_*`

#### Runtime Variables (`RUN_TIME`)
These are treated as secrets and only available at runtime:

- `JWT_SECRET`
- `EMAIL_SMTP_USERNAME`
- `EMAIL_SMTP_PASSWORD`
- `DATABASE_URL`
- `REDIS_*` variables
- `DO_APP_ID`
- `DO_APP_NAME`
- `TRUSTED_PROXIES`

## App Configuration

### App Names

- Development: `golang-arch-dev`
- Staging: `golang-arch-staging`
- Production: `golang-arch-prod`

### Domains

- Development: `api.dev.golang-arch.app`
- Staging: `api.staging.golang-arch.app`
- Production: `api.golang-arch.app`

### Database Configuration

Each environment has its own PostgreSQL database:

- Development: `golang_arch_dev`
- Staging: `golang_arch_staging`
- Production: `golang_arch_prod`

## File Structure

```
├── scripts/
│   ├── deploy.sh          # Main deployment script
│   └── setup.sh           # Environment setup script
├── templates/
│   ├── do/                # DigitalOcean app templates
│   │   ├── app-development.template.yaml
│   │   ├── app-staging.template.yaml
│   │   └── app-production.template.yaml
│   └── env/               # Environment file templates
│       ├── env.development.template
│       ├── env.staging.template
│       └── env.production.template
├── .do/                   # Generated app specs
│   ├── app-development.yaml
│   ├── app-staging.yaml
│   └── app-production.yaml
└── .env.*                 # Environment files (created by setup)
```

## Workflow

### Initial Setup

1. **Install prerequisites**:
   ```bash
   brew install doctl yq
   doctl auth init
   ```

2. **Run setup script**:
   ```bash
   ./scripts/setup.sh
   ```

3. **Configure environment files**:
   Edit `.env.development`, `.env.staging`, and `.env.production` with your actual values.

### Deployment Workflow

1. **Generate app spec**:
   ```bash
   ./scripts/deploy.sh dev generate
   ```

2. **Create app** (first time):
   ```bash
   ./scripts/deploy.sh dev create
   ```

3. **Deploy updates**:
   ```bash
   ./scripts/deploy.sh dev deploy
   ```

4. **Monitor deployment**:
   ```bash
   ./scripts/deploy.sh dev status
   ./scripts/deploy.sh dev logs
   ```

## Troubleshooting

### Common Issues

#### "Environment file not found"
**Solution**: Run the setup script first:
```bash
./scripts/setup.sh
```

#### "doctl is not installed"
**Solution**: Install doctl:
```bash
brew install doctl
```

#### "Not authenticated with DigitalOcean"
**Solution**: Authenticate with DigitalOcean:
```bash
doctl auth init
```

#### "Template file not found"
**Solution**: Ensure template files exist in `templates/do/` directory.

### Debugging

#### View Generated Spec
Check the generated app spec file:
```bash
cat .do/app-development.yaml
```

#### Test Template Generation
Generate spec without deploying:
```bash
./scripts/deploy.sh dev generate
```

#### Check App Status
View all apps:
```bash
./scripts/deploy.sh list
```

## Security Considerations

### Environment Variables

- **Never commit `.env.*` files** to version control
- **Use strong secrets** for production environments
- **Rotate secrets** regularly
- **Use different secrets** for each environment

### DigitalOcean Configuration

- **Enable alerts** for deployment failures
- **Use production databases** for staging and production
- **Configure proper health checks**
- **Set up monitoring** and logging

## Best Practices

### Environment Management

1. **Use different values** for each environment
2. **Keep secrets secure** and rotate regularly
3. **Test deployments** in staging before production
4. **Monitor deployments** and check logs

### Deployment Strategy

1. **Generate specs** before deploying
2. **Test in staging** before production
3. **Monitor health** after deployment
4. **Keep backups** of configuration

### Configuration Management

1. **Version control** template files
2. **Document changes** to configuration
3. **Test configuration** changes
4. **Backup environment** files

## Integration with CI/CD

The deployment script can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Deploy to Development
  run: |
    ./scripts/deploy.sh dev deploy
  env:
    DOCTL_TOKEN: ${{ secrets.DOCTL_TOKEN }}
```

## Support

For issues with the deployment script:

1. Check the help message: `./scripts/deploy.sh help`
2. Verify prerequisites are installed
3. Check environment files are configured
4. Review generated app specs
5. Check DigitalOcean app logs
