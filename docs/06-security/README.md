# Security Guidelines

## Overview

This section covers security best practices, authentication, authorization, and data protection strategies for the Go project. Security is implemented at multiple layers to ensure comprehensive protection of the application and its data.

## Security Architecture

### Defense in Depth
- **Network Security**: Firewalls, VPNs, secure communication
- **Application Security**: Input validation, authentication, authorization
- **Data Security**: Encryption, access controls, audit logging
- **Infrastructure Security**: Secure configurations, monitoring

### Security Layers
```
┌─────────────────────────────────────┐
│           API Gateway              │ ← Rate limiting, SSL termination
├─────────────────────────────────────┤
│         Application Layer          │ ← Authentication, authorization
├─────────────────────────────────────┤
│         Service Layer              │ ← Input validation, sanitization
├─────────────────────────────────────┤
│         Data Layer                 │ ← Encryption, access controls
└─────────────────────────────────────┘
```

## Authentication

### JWT Token Authentication
```go
// JWT token structure
type Claims struct {
    UserID   uint   `json:"user_id"`
    Email    string `json:"email"`
    Role     string `json:"role"`
    jwt.RegisteredClaims
}

// Token generation
func GenerateToken(user *User, secret string) (string, error) {
    claims := &Claims{
        UserID: user.ID,
        Email:  user.Email,
        Role:   user.Role,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
            IssuedAt:  jwt.NewNumericDate(time.Now()),
            NotBefore: jwt.NewNumericDate(time.Now()),
        },
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(secret))
}

// Token validation
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
    
    return nil, errors.New("invalid token")
}
```

### Password Security
```go
// Password hashing with bcrypt
func HashPassword(password string) (string, error) {
    bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    return string(bytes), err
}

// Password verification
func CheckPassword(password, hash string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    return err == nil
}

// Password validation
func ValidatePassword(password string) error {
    if len(password) < 8 {
        return errors.New("password must be at least 8 characters long")
    }
    
    var (
        hasUpper   bool
        hasLower   bool
        hasNumber  bool
        hasSpecial bool
    )
    
    for _, char := range password {
        switch {
        case unicode.IsUpper(char):
            hasUpper = true
        case unicode.IsLower(char):
            hasLower = true
        case unicode.IsNumber(char):
            hasNumber = true
        case unicode.IsPunct(char) || unicode.IsSymbol(char):
            hasSpecial = true
        }
    }
    
    if !hasUpper || !hasLower || !hasNumber || !hasSpecial {
        return errors.New("password must contain uppercase, lowercase, number, and special character")
    }
    
    return nil
}
```

### Multi-Factor Authentication (MFA)
```go
// TOTP (Time-based One-Time Password)
func GenerateTOTPSecret() (string, error) {
    secret := make([]byte, 32)
    _, err := rand.Read(secret)
    if err != nil {
        return "", err
    }
    return base32.StdEncoding.EncodeToString(secret), nil
}

func GenerateTOTPCode(secret string) (string, error) {
    key, err := base32.StdEncoding.DecodeString(secret)
    if err != nil {
        return "", err
    }
    
    now := time.Now().Unix()
    counter := now / 30 // 30-second window
    
    hmac := hmac.New(sha1.New, key)
    binary.Write(hmac, binary.BigEndian, counter)
    hash := hmac.Sum(nil)
    
    offset := hash[len(hash)-1] & 0xf
    code := ((int(hash[offset]) & 0x7f) << 24) |
        ((int(hash[offset+1]) & 0xff) << 16) |
        ((int(hash[offset+2]) & 0xff) << 8) |
        (int(hash[offset+3]) & 0xff)
    
    return fmt.Sprintf("%06d", code%1000000), nil
}
```

## Authorization

### Role-Based Access Control (RBAC)
```go
// User roles
const (
    RoleAdmin    = "admin"
    RoleManager  = "manager"
    RoleUser     = "user"
    RoleGuest    = "guest"
)

// Permission definitions
type Permission struct {
    Resource string
    Action   string
}

// Role permissions mapping
var RolePermissions = map[string][]Permission{
    RoleAdmin: {
        {Resource: "*", Action: "*"},
    },
    RoleManager: {
        {Resource: "users", Action: "read"},
        {Resource: "users", Action: "write"},
        {Resource: "reports", Action: "read"},
    },
    RoleUser: {
        {Resource: "users", Action: "read"},
        {Resource: "profile", Action: "write"},
    },
    RoleGuest: {
        {Resource: "public", Action: "read"},
    },
}

// Authorization middleware
func RequirePermission(resource, action string) gin.HandlerFunc {
    return func(c *gin.Context) {
        claims, exists := c.Get("claims")
        if !exists {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
            c.Abort()
            return
        }
        
        userClaims := claims.(*Claims)
        if !hasPermission(userClaims.Role, resource, action) {
            c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
            c.Abort()
            return
        }
        
        c.Next()
    }
}

func hasPermission(role, resource, action string) bool {
    permissions, exists := RolePermissions[role]
    if !exists {
        return false
    }
    
    for _, perm := range permissions {
        if (perm.Resource == "*" || perm.Resource == resource) &&
           (perm.Action == "*" || perm.Action == action) {
            return true
        }
    }
    
    return false
}
```

### Resource-Based Authorization
```go
// Resource ownership check
func RequireOwnership(resourceType string) gin.HandlerFunc {
    return func(c *gin.Context) {
        claims := c.MustGet("claims").(*Claims)
        resourceID := c.Param("id")
        
        if !isOwner(claims.UserID, resourceType, resourceID) {
            c.JSON(http.StatusForbidden, gin.H{"error": "access denied"})
            c.Abort()
            return
        }
        
        c.Next()
    }
}

func isOwner(userID uint, resourceType, resourceID string) bool {
    // Implementation depends on resource type
    switch resourceType {
    case "users":
        return uint(userID) == parseUint(resourceID)
    case "posts":
        return isPostOwner(userID, resourceID)
    default:
        return false
    }
}
```

## Input Validation and Sanitization

### Request Validation
```go
// Validation structs
type CreateUserRequest struct {
    Name     string `json:"name" binding:"required,min=2,max=50"`
    Email    string `json:"email" binding:"required,email"`
    Password string `json:"password" binding:"required,min=8"`
    Age      int    `json:"age" binding:"gte=13,lte=120"`
}

// Custom validation
func ValidateCreateUserRequest(req *CreateUserRequest) error {
    if err := validate.Struct(req); err != nil {
        return err
    }
    
    // Custom business logic validation
    if strings.Contains(strings.ToLower(req.Name), "admin") {
        return errors.New("name cannot contain 'admin'")
    }
    
    return nil
}
```

### SQL Injection Prevention
```go
// Use parameterized queries
func FindUserByEmail(db *sql.DB, email string) (*User, error) {
    query := "SELECT id, name, email FROM users WHERE email = $1"
    row := db.QueryRow(query, email)
    
    var user User
    err := row.Scan(&user.ID, &user.Name, &user.Email)
    if err != nil {
        return nil, err
    }
    
    return &user, nil
}

// Use prepared statements for repeated queries
func CreateUserPrepared(db *sql.DB) (*sql.Stmt, error) {
    return db.Prepare("INSERT INTO users (name, email, password_hash) VALUES ($1, $2, $3)")
}
```

### XSS Prevention
```go
// HTML escaping
func SanitizeHTML(input string) string {
    return html.EscapeString(input)
}

// Template sanitization
func RenderTemplate(w http.ResponseWriter, templateName string, data interface{}) {
    tmpl := template.Must(template.New(templateName).Parse(`
        <h1>{{.Title}}</h1>
        <p>{{.Content}}</p>
    `))
    
    // Template automatically escapes content
    tmpl.Execute(w, data)
}
```

## Data Protection

### Encryption at Rest
```go
// AES encryption for sensitive data
type EncryptedData struct {
    Data      []byte `json:"data"`
    IV        []byte `json:"iv"`
    Algorithm string `json:"algorithm"`
}

func EncryptData(data []byte, key []byte) (*EncryptedData, error) {
    block, err := aes.NewCipher(key)
    if err != nil {
        return nil, err
    }
    
    iv := make([]byte, aes.BlockSize)
    if _, err := io.ReadFull(rand.Reader, iv); err != nil {
        return nil, err
    }
    
    mode := cipher.NewCBCEncrypter(block, iv)
    paddedData := pkcs7Padding(data, aes.BlockSize)
    encrypted := make([]byte, len(paddedData))
    mode.CryptBlocks(encrypted, paddedData)
    
    return &EncryptedData{
        Data:      encrypted,
        IV:        iv,
        Algorithm: "AES-256-CBC",
    }, nil
}

func DecryptData(encryptedData *EncryptedData, key []byte) ([]byte, error) {
    block, err := aes.NewCipher(key)
    if err != nil {
        return nil, err
    }
    
    mode := cipher.NewCBCDecrypter(block, encryptedData.IV)
    decrypted := make([]byte, len(encryptedData.Data))
    mode.CryptBlocks(decrypted, encryptedData.Data)
    
    return pkcs7Unpadding(decrypted)
}
```

### Encryption in Transit
```go
// HTTPS configuration
func SetupHTTPS(router *gin.Engine) {
    // TLS configuration
    tlsConfig := &tls.Config{
        MinVersion: tls.VersionTLS12,
        CipherSuites: []uint16{
            tls.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
            tls.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
        },
    }
    
    server := &http.Server{
        Addr:      ":443",
        Handler:   router,
        TLSConfig: tlsConfig,
    }
    
    log.Fatal(server.ListenAndServeTLS("cert.pem", "key.pem"))
}
```

## Audit Logging

### Security Event Logging
```go
// Audit log entry
type AuditLog struct {
    ID        uint      `json:"id"`
    UserID    uint      `json:"user_id"`
    Action    string    `json:"action"`
    Resource  string    `json:"resource"`
    ResourceID string   `json:"resource_id"`
    IPAddress string    `json:"ip_address"`
    UserAgent string    `json:"user_agent"`
    Timestamp time.Time `json:"timestamp"`
    Details   string    `json:"details"`
}

// Audit logging middleware
func AuditLogMiddleware(action string) gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        
        c.Next()
        
        // Log after request is processed
        claims, exists := c.Get("claims")
        var userID uint
        if exists {
            userClaims := claims.(*Claims)
            userID = userClaims.UserID
        }
        
        auditLog := &AuditLog{
            UserID:     userID,
            Action:     action,
            Resource:   c.Request.URL.Path,
            ResourceID: c.Param("id"),
            IPAddress:  c.ClientIP(),
            UserAgent:  c.Request.UserAgent(),
            Timestamp:  time.Now(),
            Details:    fmt.Sprintf("Duration: %v", time.Since(start)),
        }
        
        logAuditEvent(auditLog)
    }
}
```

## Rate Limiting

### API Rate Limiting
```go
// Rate limiter using Redis
type RateLimiter struct {
    redis *redis.Client
}

func NewRateLimiter(redisClient *redis.Client) *RateLimiter {
    return &RateLimiter{redis: redisClient}
}

func (rl *RateLimiter) IsAllowed(key string, limit int, window time.Duration) bool {
    current := rl.redis.Incr(key).Val()
    
    if current == 1 {
        rl.redis.Expire(key, window)
    }
    
    return current <= int64(limit)
}

// Rate limiting middleware
func RateLimit(limit int, window time.Duration) gin.HandlerFunc {
    limiter := NewRateLimiter(redisClient)
    
    return func(c *gin.Context) {
        key := fmt.Sprintf("rate_limit:%s", c.ClientIP())
        
        if !limiter.IsAllowed(key, limit, window) {
            c.JSON(http.StatusTooManyRequests, gin.H{
                "error": "rate limit exceeded",
                "retry_after": window.Seconds(),
            })
            c.Abort()
            return
        }
        
        c.Next()
    }
}
```

## Security Headers

### Security Headers Middleware
```go
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

## Security Configuration

### Environment Variables
```bash
# Security configuration
JWT_SECRET=your-super-secret-jwt-key
ENCRYPTION_KEY=your-32-byte-encryption-key
BCRYPT_COST=12
SESSION_SECRET=your-session-secret
CORS_ORIGIN=https://yourdomain.com
```

### Security Checklist
- [ ] HTTPS enabled for all communications
- [ ] JWT tokens with appropriate expiration
- [ ] Password hashing with bcrypt
- [ ] Input validation and sanitization
- [ ] SQL injection prevention
- [ ] XSS protection
- [ ] CSRF protection
- [ ] Rate limiting implemented
- [ ] Security headers configured
- [ ] Audit logging enabled
- [ ] Error messages don't leak sensitive information
- [ ] Regular security updates
- [ ] Penetration testing performed

## Security Monitoring

### Security Alerts
```go
// Security event monitoring
type SecurityEvent struct {
    Type      string    `json:"type"`
    Severity  string    `json:"severity"`
    Message   string    `json:"message"`
    UserID    uint      `json:"user_id"`
    IPAddress string    `json:"ip_address"`
    Timestamp time.Time `json:"timestamp"`
}

func LogSecurityEvent(eventType, severity, message string, userID uint, ipAddress string) {
    event := &SecurityEvent{
        Type:      eventType,
        Severity:  severity,
        Message:   message,
        UserID:    userID,
        IPAddress: ipAddress,
        Timestamp: time.Now(),
    }
    
    // Log to security monitoring system
    logSecurityEvent(event)
    
    // Send alert for high severity events
    if severity == "high" || severity == "critical" {
        sendSecurityAlert(event)
    }
}
```

## Related Documentation

- [Architecture Documentation](../02-architecture/) - Security architecture
- [API Documentation](../10-api-documentation/) - API security
- [Development Guide](../03-development/) - Secure development practices
- [Testing Strategy](../05-testing/) - Security testing
