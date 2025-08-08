# API Versioning Strategy

## Overview

This document outlines the API versioning strategy for the golang-arch project. It defines how API versions are managed, how backward compatibility is maintained, and how version transitions are handled.

## Versioning Strategy

### URL Path Versioning

We use URL path versioning for clear and explicit version identification:

```
https://api.example.com/v1/users
https://api.example.com/v2/users
https://api.example.com/v3/users
```

### Version Format

- **Major Version**: `v1`, `v2`, `v3` - Breaking changes
- **Minor Version**: `v1.1`, `v1.2` - New features (backward compatible)
- **Patch Version**: `v1.1.1` - Bug fixes (backward compatible)

## Version Lifecycle

### Version States

1. **Current**: Latest stable version (v2)
2. **Supported**: Previous versions still supported (v1)
3. **Deprecated**: Versions marked for removal (v0)
4. **Retired**: Versions no longer available

### Version Timeline

```
v1 (Current) → v2 (Beta) → v2 (Current) → v3 (Beta) → v3 (Current)
     ↓              ↓            ↓            ↓            ↓
  v0 (Deprecated) v1 (Supported) v1 (Deprecated) v2 (Supported) v2 (Deprecated)
```

## Breaking Changes

### What Constitutes a Breaking Change

1. **Removing endpoints**: DELETE `/v1/users/{id}`
2. **Changing response structure**: Adding/removing fields
3. **Changing request structure**: Required fields become optional or vice versa
4. **Changing data types**: String to integer, etc.
5. **Changing authentication**: New required headers
6. **Changing error codes**: New error responses

### Examples of Breaking Changes

#### v1 to v2 - User Model Change

**v1 Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**v2 Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "full_name": "John Doe"
}
```

#### v1 to v2 - Endpoint Removal

**v1:**
```
GET /v1/users/{id}/profile
```

**v2:**
```
GET /v2/users/{id}  # Profile data included in main response
```

## Backward Compatibility

### Guidelines

1. **Additive Changes**: New fields should be optional
2. **Default Values**: Provide sensible defaults for new fields
3. **Deprecation Warnings**: Include deprecation notices in responses
4. **Migration Path**: Provide clear migration documentation

### Response Headers

```http
X-API-Version: v2
X-Deprecation-Warning: "v1 will be deprecated on 2024-12-31"
X-Sunset-Date: "2024-12-31"
```

### Deprecation Response

```json
{
  "success": true,
  "data": {...},
  "warnings": [
    {
      "code": "DEPRECATED_ENDPOINT",
      "message": "This endpoint will be removed in v3",
      "sunset_date": "2024-12-31",
      "migration_url": "https://docs.example.com/migration/v2-to-v3"
    }
  ],
  "meta": {
    "version": "v2",
    "deprecated": false
  }
}
```

## Version Management

### Version Announcement

1. **Beta Release**: 6 months before stable
2. **Release Candidate**: 1 month before stable
3. **Stable Release**: Production ready
4. **Deprecation Notice**: 12 months before removal
5. **End of Life**: Version removed

### Communication Timeline

```
Beta Release (v2.0.0-beta)     → 6 months before stable
Release Candidate (v2.0.0-rc)   → 1 month before stable
Stable Release (v2.0.0)        → Production ready
Deprecation Notice (v1)         → 12 months before removal
End of Life (v1)               → Version removed
```

## Implementation Examples

### Go Router Setup

```go
// internal/bootstrap/router.go
func setupRoutes(router *gin.Engine) {
    // v1 routes
    v1 := router.Group("/v1")
    {
        v1.GET("/users", v1Handlers.GetUsers)
        v1.GET("/users/:id", v1Handlers.GetUser)
        v1.POST("/users", v1Handlers.CreateUser)
    }
    
    // v2 routes
    v2 := router.Group("/v2")
    {
        v2.GET("/users", v2Handlers.GetUsers)
        v2.GET("/users/:id", v2Handlers.GetUser)
        v2.POST("/users", v2Handlers.CreateUser)
    }
}
```

### Version-Specific Handlers

```go
// internal/delivery/http/v1/user_handler.go
package v1

type UserHandler struct {
    userService services.UserService
}

func (h *UserHandler) GetUser(c *gin.Context) {
    userID := c.Param("id")
    user, err := h.userService.GetUser(userID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "success": false,
            "message": "User not found",
            "errors": []gin.H{
                {"field": "id", "message": "User not found"},
            },
        })
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "data": gin.H{
            "id":    user.ID,
            "email": user.Email,
            "name":  user.Name, // v1 format
        },
        "message": "User retrieved successfully",
        "meta": gin.H{
            "version": "v1",
            "deprecated": true,
        },
    })
}
```

```go
// internal/delivery/http/v2/user_handler.go
package v2

type UserHandler struct {
    userService services.UserService
}

func (h *UserHandler) GetUser(c *gin.Context) {
    userID := c.Param("id")
    user, err := h.userService.GetUser(userID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "success": false,
            "message": "User not found",
            "errors": []gin.H{
                {"field": "id", "message": "User not found", "code": "NOT_FOUND_ERROR"},
            },
        })
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "data": gin.H{
            "id":         user.ID,
            "email":      user.Email,
            "first_name": user.FirstName, // v2 format
            "last_name":  user.LastName,
            "full_name":  user.FullName(),
        },
        "message": "User retrieved successfully",
        "meta": gin.H{
            "version": "v2",
            "deprecated": false,
        },
    })
}
```

### Version Middleware

```go
// internal/middleware/version.go
package middleware

import (
    "github.com/gin-gonic/gin"
    "net/http"
)

func VersionMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        // Set version in context
        version := c.Param("version")
        c.Set("api_version", version)
        
        // Add version headers
        c.Header("X-API-Version", version)
        
        // Add deprecation warnings for old versions
        if version == "v1" {
            c.Header("X-Deprecation-Warning", "v1 will be deprecated on 2024-12-31")
            c.Header("X-Sunset-Date", "2024-12-31")
        }
        
        c.Next()
    }
}
```

## Migration Guide

### v1 to v2 Migration

#### User Model Changes

**v1 Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**v2 Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "full_name": "John Doe"
}
```

#### Migration Steps

1. **Update API calls**: Change from `/v1/users` to `/v2/users`
2. **Update response parsing**: Handle new field structure
3. **Update error handling**: New error codes and messages
4. **Test thoroughly**: Ensure all functionality works

#### Code Example

```javascript
// v1 code
const getUser = async (userId) => {
    const response = await fetch(`/v1/users/${userId}`);
    const data = await response.json();
    return {
        id: data.data.id,
        email: data.data.email,
        name: data.data.name
    };
};

// v2 code
const getUser = async (userId) => {
    const response = await fetch(`/v2/users/${userId}`);
    const data = await response.json();
    return {
        id: data.data.id,
        email: data.data.email,
        firstName: data.data.first_name,
        lastName: data.data.last_name,
        fullName: data.data.full_name
    };
};
```

## Version Documentation

### API Documentation Structure

```
docs/10-api-documentation/
├── 02-api-specs/
│   ├── v1/
│   │   ├── auth-service/
│   │   ├── user-service/
│   │   ├── product-service/
│   │   └── order-service/
│   └── v2/
│       ├── auth-service/
│       ├── user-service/
│       ├── product-service/
│       └── order-service/
└── migration-guides/
    ├── v1-to-v2.md
    └── v2-to-v3.md
```

### Changelog Format

```markdown
# API Changelog

## v2.0.0 (2024-01-01)

### Breaking Changes
- Changed user model structure (name → first_name, last_name)
- Removed `/users/{id}/profile` endpoint
- Updated error response format

### New Features
- Added user preferences endpoint
- Added bulk operations for products
- Enhanced search functionality

### Deprecations
- `/v1/users/{id}/profile` will be removed in v3.0.0
- `name` field in user responses will be removed in v3.0.0

## v1.2.0 (2023-12-01)

### New Features
- Added pagination to user list endpoint
- Added filtering by user status
- Enhanced error messages

### Bug Fixes
- Fixed issue with user creation validation
- Improved error handling for invalid tokens
```

## Best Practices

### Version Management

1. **Plan Ahead**: Design APIs with future extensibility in mind
2. **Document Changes**: Maintain detailed changelogs
3. **Test Thoroughly**: Test all versions in parallel
4. **Monitor Usage**: Track version adoption rates
5. **Communicate Early**: Notify users of upcoming changes

### Backward Compatibility

1. **Additive Changes**: Only add new fields, don't remove
2. **Optional Fields**: Make new fields optional with defaults
3. **Deprecation Warnings**: Include warnings in responses
4. **Migration Tools**: Provide tools to help with migration

### Testing Strategy

1. **Version-Specific Tests**: Test each version independently
2. **Migration Tests**: Test migration paths between versions
3. **Compatibility Tests**: Ensure old clients work with new versions
4. **Performance Tests**: Ensure no performance regression

## Monitoring and Analytics

### Version Usage Tracking

```go
// internal/middleware/analytics.go
func VersionAnalytics() gin.HandlerFunc {
    return func(c *gin.Context) {
        version := c.Param("version")
        endpoint := c.Request.URL.Path
        method := c.Request.Method
        
        // Track version usage
        metrics.Increment("api_requests_total", map[string]string{
            "version":  version,
            "endpoint": endpoint,
            "method":   method,
        })
        
        c.Next()
    }
}
```

### Version Adoption Metrics

- **Usage by version**: Track which versions are most used
- **Migration rates**: Monitor migration from old to new versions
- **Error rates**: Track errors by version
- **Performance metrics**: Compare performance across versions
