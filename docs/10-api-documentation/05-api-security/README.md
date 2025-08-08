# API Security Documentation

## Overview

This document outlines the security measures, best practices, and guidelines for securing the golang-arch API. It covers authentication, authorization, data protection, and security monitoring.

## Security Architecture

### Security Layers

1. **Network Security**: HTTPS, TLS, WAF
2. **Authentication**: JWT tokens, API keys
3. **Authorization**: Role-based access control (RBAC)
4. **Data Protection**: Encryption, input validation
5. **Monitoring**: Logging, alerting, audit trails

### Security Principles

- **Defense in Depth**: Multiple security layers
- **Least Privilege**: Minimal required permissions
- **Zero Trust**: Verify everything, trust nothing
- **Security by Design**: Built-in from the start

## Authentication

### JWT Token Authentication

#### Token Structure

```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "role": "user",
    "permissions": ["read:users", "write:orders"],
    "iat": 1640995200,
    "exp": 1640998800,
    "iss": "golang-arch-api",
    "aud": "golang-arch-client"
  }
}
```

#### Token Implementation

```go
// internal/auth/jwt.go
package auth

import (
    "time"
    "github.com/golang-jwt/jwt/v4"
)

type Claims struct {
    UserID      string   `json:"sub"`
    Email       string   `json:"email"`
    Role        string   `json:"role"`
    Permissions []string `json:"permissions"`
    jwt.RegisteredClaims
}

func GenerateToken(user *User, secret string) (string, error) {
    claims := Claims{
        UserID:      user.ID,
        Email:       user.Email,
        Role:        user.Role,
        Permissions: user.Permissions,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
            IssuedAt:  jwt.NewNumericDate(time.Now()),
            Issuer:    "golang-arch-api",
            Audience:  []string{"golang-arch-client"},
        },
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(secret))
}

func ValidateToken(tokenString, secret string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
        return []byte(secret), nil
    })
    
    if err != nil {
        return nil, err
    }
    
    if claims, ok := token.Claims.(*Claims); ok && token.Valid {
        return claims, nil
    }
    
    return nil, jwt.ErrSignatureInvalid
}
```

### API Key Authentication

#### API Key Structure

```go
// internal/auth/api_key.go
type APIKey struct {
    ID          string    `json:"id"`
    Key         string    `json:"key"`
    Name        string    `json:"name"`
    UserID      string    `json:"user_id"`
    Permissions []string  `json:"permissions"`
    ExpiresAt   time.Time `json:"expires_at"`
    CreatedAt   time.Time `json:"created_at"`
}
```

#### API Key Validation

```go
func ValidateAPIKey(key string) (*APIKey, error) {
    // Hash the provided key
    hashedKey := hashAPIKey(key)
    
    // Look up in database
    apiKey, err := repository.GetAPIKeyByHash(hashedKey)
    if err != nil {
        return nil, err
    }
    
    // Check expiration
    if time.Now().After(apiKey.ExpiresAt) {
        return nil, errors.New("API key expired")
    }
    
    return apiKey, nil
}
```

## Authorization

### Role-Based Access Control (RBAC)

#### Role Definitions

```go
// internal/auth/rbac.go
type Role struct {
    ID          string       `json:"id"`
    Name        string       `json:"name"`
    Permissions []Permission `json:"permissions"`
}

type Permission struct {
    Resource string   `json:"resource"`
    Actions  []string `json:"actions"`
}

var Roles = map[string]Role{
    "user": {
        ID:   "user",
        Name: "User",
        Permissions: []Permission{
            {Resource: "users", Actions: []string{"read:own"}},
            {Resource: "orders", Actions: []string{"read:own", "write:own"}},
            {Resource: "products", Actions: []string{"read"}},
        },
    },
    "admin": {
        ID:   "admin",
        Name: "Administrator",
        Permissions: []Permission{
            {Resource: "users", Actions: []string{"read", "write", "delete"}},
            {Resource: "orders", Actions: []string{"read", "write", "delete"}},
            {Resource: "products", Actions: []string{"read", "write", "delete"}},
            {Resource: "system", Actions: []string{"read", "write"}},
        },
    },
}
```

#### Permission Checking

```go
func CheckPermission(user *User, resource, action string) bool {
    for _, permission := range user.Permissions {
        if permission.Resource == resource {
            for _, allowedAction := range permission.Actions {
                if allowedAction == action || allowedAction == "*" {
                    return true
                }
            }
        }
    }
    return false
}

func CheckResourceOwnership(user *User, resourceID, resourceType string) bool {
    // Check if user owns the resource
    switch resourceType {
    case "users":
        return user.ID == resourceID
    case "orders":
        return user.ID == getOrderUserID(resourceID)
    default:
        return false
    }
}
```

### Authorization Middleware

```go
// internal/middleware/auth.go
func RequireAuth() gin.HandlerFunc {
    return func(c *gin.Context) {
        token := extractToken(c)
        if token == "" {
            c.JSON(http.StatusUnauthorized, gin.H{
                "success": false,
                "message": "Authentication required",
                "errors": []gin.H{
                    {"code": "AUTHENTICATION_ERROR", "message": "No token provided"},
                },
            })
            c.Abort()
            return
        }
        
        claims, err := ValidateToken(token, config.JWTSecret)
        if err != nil {
            c.JSON(http.StatusUnauthorized, gin.H{
                "success": false,
                "message": "Invalid token",
                "errors": []gin.H{
                    {"code": "AUTHENTICATION_ERROR", "message": "Invalid token"},
                },
            })
            c.Abort()
            return
        }
        
        c.Set("user", claims)
        c.Next()
    }
}

func RequirePermission(resource, action string) gin.HandlerFunc {
    return func(c *gin.Context) {
        user := c.MustGet("user").(*Claims)
        
        if !CheckPermission(user, resource, action) {
            c.JSON(http.StatusForbidden, gin.H{
                "success": false,
                "message": "Insufficient permissions",
                "errors": []gin.H{
                    {"code": "AUTHORIZATION_ERROR", "message": "Access denied"},
                },
            })
            c.Abort()
            return
        }
        
        c.Next()
    }
}
```

## Data Protection

### Input Validation

#### Request Validation

```go
// internal/validation/request.go
type ValidationRule struct {
    Field   string `json:"field"`
    Rule    string `json:"rule"`
    Message string `json:"message"`
}

func ValidateUserRequest(req *CreateUserRequest) []ValidationRule {
    var errors []ValidationRule
    
    // Email validation
    if !isValidEmail(req.Email) {
        errors = append(errors, ValidationRule{
            Field:   "email",
            Rule:    "email",
            Message: "Invalid email format",
        })
    }
    
    // Password validation
    if !isValidPassword(req.Password) {
        errors = append(errors, ValidationRule{
            Field:   "password",
            Rule:    "password",
            Message: "Password must be at least 8 characters with mixed case and numbers",
        })
    }
    
    return errors
}

func isValidEmail(email string) bool {
    emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
    return emailRegex.MatchString(email)
}

func isValidPassword(password string) bool {
    // At least 8 characters, mixed case, numbers, special characters
    if len(password) < 8 {
        return false
    }
    
    hasUpper := regexp.MustCompile(`[A-Z]`).MatchString(password)
    hasLower := regexp.MustCompile(`[a-z]`).MatchString(password)
    hasNumber := regexp.MustCompile(`[0-9]`).MatchString(password)
    hasSpecial := regexp.MustCompile(`[!@#$%^&*]`).MatchString(password)
    
    return hasUpper && hasLower && hasNumber && hasSpecial
}
```

### SQL Injection Prevention

```go
// internal/repository/user_repository.go
func (r *UserRepository) GetUserByEmail(email string) (*User, error) {
    query := "SELECT id, email, name, password_hash FROM users WHERE email = $1"
    
    var user User
    err := r.db.QueryRow(query, email).Scan(
        &user.ID,
        &user.Email,
        &user.Name,
        &user.PasswordHash,
    )
    
    if err != nil {
        return nil, err
    }
    
    return &user, nil
}
```

### XSS Prevention

```go
// internal/middleware/security.go
func XSSProtection() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Header("X-XSS-Protection", "1; mode=block")
        c.Header("X-Content-Type-Options", "nosniff")
        c.Header("X-Frame-Options", "DENY")
        c.Next()
    }
}

func SanitizeInput(input string) string {
    // Remove potentially dangerous characters
    sanitized := html.EscapeString(input)
    return sanitized
}
```

## Rate Limiting

### Rate Limiter Implementation

```go
// internal/middleware/rate_limit.go
import (
    "golang.org/x/time/rate"
    "sync"
)

type RateLimiter struct {
    limiters map[string]*rate.Limiter
    mu       sync.RWMutex
}

func NewRateLimiter() *RateLimiter {
    return &RateLimiter{
        limiters: make(map[string]*rate.Limiter),
    }
}

func (rl *RateLimiter) GetLimiter(key string) *rate.Limiter {
    rl.mu.Lock()
    defer rl.mu.Unlock()
    
    limiter, exists := rl.limiters[key]
    if !exists {
        limiter = rate.NewLimiter(rate.Every(1*time.Second), 10) // 10 requests per second
        rl.limiters[key] = limiter
    }
    
    return limiter
}

func RateLimit() gin.HandlerFunc {
    limiter := NewRateLimiter()
    
    return func(c *gin.Context) {
        key := getClientIP(c)
        if !limiter.GetLimiter(key).Allow() {
            c.JSON(http.StatusTooManyRequests, gin.H{
                "success": false,
                "message": "Rate limit exceeded",
                "errors": []gin.H{
                    {"code": "RATE_LIMIT_ERROR", "message": "Too many requests"},
                },
            })
            c.Abort()
            return
        }
        
        c.Next()
    }
}
```

## Security Headers

### Security Middleware

```go
// internal/middleware/security.go
func SecurityHeaders() gin.HandlerFunc {
    return func(c *gin.Context) {
        // Prevent XSS attacks
        c.Header("X-XSS-Protection", "1; mode=block")
        
        // Prevent MIME type sniffing
        c.Header("X-Content-Type-Options", "nosniff")
        
        // Prevent clickjacking
        c.Header("X-Frame-Options", "DENY")
        
        // Content Security Policy
        c.Header("Content-Security-Policy", "default-src 'self'")
        
        // Strict Transport Security
        c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
        
        // Referrer Policy
        c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
        
        c.Next()
    }
}
```

## Logging and Monitoring

### Security Logging

```go
// internal/logger/security.go
type SecurityEvent struct {
    Timestamp   time.Time `json:"timestamp"`
    EventType   string    `json:"event_type"`
    UserID      string    `json:"user_id"`
    IPAddress   string    `json:"ip_address"`
    UserAgent   string    `json:"user_agent"`
    Resource    string    `json:"resource"`
    Action      string    `json:"action"`
    Success     bool      `json:"success"`
    Error       string    `json:"error,omitempty"`
}

func LogSecurityEvent(event SecurityEvent) {
    logger.WithFields(log.Fields{
        "event_type": event.EventType,
        "user_id":    event.UserID,
        "ip_address": event.IPAddress,
        "resource":   event.Resource,
        "action":     event.Action,
        "success":    event.Success,
    }).Info("Security event")
}
```

### Audit Trail

```go
// internal/middleware/audit.go
func AuditLog() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        
        c.Next()
        
        // Log the request
        duration := time.Since(start)
        userID := getUserID(c)
        
        LogSecurityEvent(SecurityEvent{
            Timestamp: time.Now(),
            EventType: "api_request",
            UserID:    userID,
            IPAddress: getClientIP(c),
            UserAgent: c.Request.UserAgent(),
            Resource:  c.Request.URL.Path,
            Action:    c.Request.Method,
            Success:   c.Writer.Status() < 400,
        })
    }
}
```

## Error Handling

### Secure Error Responses

```go
// internal/api/errors.go
func HandleError(c *gin.Context, err error) {
    // Don't expose internal errors to clients
    var response ErrorResponse
    
    switch e := err.(type) {
    case *ValidationError:
        response = ErrorResponse{
            Success: false,
            Message: "Validation failed",
            Errors:  e.Errors,
        }
        c.JSON(http.StatusBadRequest, response)
        
    case *AuthenticationError:
        response = ErrorResponse{
            Success: false,
            Message: "Authentication failed",
            Errors: []Error{
                {Code: "AUTHENTICATION_ERROR", Message: "Invalid credentials"},
            },
        }
        c.JSON(http.StatusUnauthorized, response)
        
    case *AuthorizationError:
        response = ErrorResponse{
            Success: false,
            Message: "Access denied",
            Errors: []Error{
                {Code: "AUTHORIZATION_ERROR", Message: "Insufficient permissions"},
            },
        }
        c.JSON(http.StatusForbidden, response)
        
    default:
        // Log the actual error internally
        logger.Error("Internal server error", "error", err)
        
        // Return generic error to client
        response = ErrorResponse{
            Success: false,
            Message: "Internal server error",
            Errors: []Error{
                {Code: "INTERNAL_ERROR", Message: "An unexpected error occurred"},
            },
        }
        c.JSON(http.StatusInternalServerError, response)
    }
}
```

## Security Testing

### Security Test Examples

```go
// tests/security/auth_test.go
func TestAuthentication(t *testing.T) {
    // Test invalid tokens
    req, _ := http.NewRequest("GET", "/v1/users/profile", nil)
    req.Header.Set("Authorization", "Bearer invalid-token")
    
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    
    assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestAuthorization(t *testing.T) {
    // Test user accessing admin endpoint
    req, _ := http.NewRequest("GET", "/v1/admin/users", nil)
    req.Header.Set("Authorization", "Bearer "+userToken)
    
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    
    assert.Equal(t, http.StatusForbidden, w.Code)
}

func TestRateLimiting(t *testing.T) {
    // Test rate limiting
    for i := 0; i < 15; i++ {
        req, _ := http.NewRequest("GET", "/v1/users", nil)
        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)
        
        if i >= 10 {
            assert.Equal(t, http.StatusTooManyRequests, w.Code)
        }
    }
}
```

## Security Checklist

### Implementation Checklist

- [ ] HTTPS/TLS enabled
- [ ] JWT tokens with proper expiration
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention
- [ ] XSS protection headers
- [ ] Rate limiting implemented
- [ ] Role-based access control
- [ ] Security logging enabled
- [ ] Error handling without information leakage
- [ ] Regular security updates
- [ ] Security monitoring and alerting

### Deployment Checklist

- [ ] Environment variables for secrets
- [ ] Database connection encryption
- [ ] API keys rotated regularly
- [ ] SSL certificates valid
- [ ] Security headers configured
- [ ] Logging and monitoring setup
- [ ] Backup and recovery procedures
- [ ] Incident response plan
