# Performance Optimization

## Overview

This section covers performance optimization strategies, monitoring, profiling, and best practices for the Go project. Performance is critical for user experience and system scalability, requiring careful attention to both application and infrastructure optimization.

## Performance Architecture

### Performance Layers
```
┌─────────────────────────────────────┐
│         Load Balancer              │ ← Traffic distribution
├─────────────────────────────────────┤
│         Application Layer          │ ← Caching, optimization
├─────────────────────────────────────┤
│         Database Layer             │ ← Query optimization
├─────────────────────────────────────┤
│         Infrastructure             │ ← Resource management
└─────────────────────────────────────┘
```

### Performance Metrics
- **Response Time**: Time to complete a request
- **Throughput**: Requests per second (RPS)
- **Latency**: Time for data to travel
- **Resource Utilization**: CPU, memory, disk, network
- **Error Rate**: Percentage of failed requests

## Application Performance

### Memory Management
```go
// Object pooling for frequently allocated objects
type ObjectPool struct {
    pool sync.Pool
}

func NewObjectPool() *ObjectPool {
    return &ObjectPool{
        pool: sync.Pool{
            New: func() interface{} {
                return &User{}
            },
        },
    }
}

func (p *ObjectPool) Get() *User {
    return p.pool.Get().(*User)
}

func (p *ObjectPool) Put(user *User) {
    // Reset object state
    user.ID = 0
    user.Name = ""
    user.Email = ""
    p.pool.Put(user)
}

// Usage example
func ProcessUsers(users []User) {
    pool := NewObjectPool()
    
    for _, userData := range users {
        user := pool.Get()
        // Process user
        pool.Put(user)
    }
}
```

### Goroutine Management
```go
// Worker pool for concurrent processing
type WorkerPool struct {
    workers    int
    jobQueue   chan Job
    resultChan chan Result
    wg         sync.WaitGroup
}

func NewWorkerPool(workers int) *WorkerPool {
    return &WorkerPool{
        workers:    workers,
        jobQueue:   make(chan Job, workers*2),
        resultChan: make(chan Result, workers*2),
    }
}

func (wp *WorkerPool) Start() {
    for i := 0; i < wp.workers; i++ {
        wp.wg.Add(1)
        go wp.worker()
    }
}

func (wp *WorkerPool) worker() {
    defer wp.wg.Done()
    
    for job := range wp.jobQueue {
        result := processJob(job)
        wp.resultChan <- result
    }
}

func (wp *WorkerPool) Submit(job Job) {
    wp.jobQueue <- job
}

func (wp *WorkerPool) Close() {
    close(wp.jobQueue)
    wp.wg.Wait()
    close(wp.resultChan)
}
```

### Connection Pooling
```go
// Database connection pool
type DBConfig struct {
    MaxOpenConns    int
    MaxIdleConns    int
    ConnMaxLifetime time.Duration
}

func SetupDBPool(db *sql.DB, config DBConfig) {
    db.SetMaxOpenConns(config.MaxOpenConns)
    db.SetMaxIdleConns(config.MaxIdleConns)
    db.SetConnMaxLifetime(config.ConnMaxLifetime)
}

// Redis connection pool
func SetupRedisPool(addr string) *redis.Client {
    return redis.NewClient(&redis.Options{
        Addr:         addr,
        PoolSize:     10,
        MinIdleConns: 5,
        MaxRetries:   3,
        DialTimeout:  5 * time.Second,
        ReadTimeout:  3 * time.Second,
        WriteTimeout: 3 * time.Second,
    })
}
```

## Caching Strategies

### Application-Level Caching
```go
// In-memory cache with TTL
type Cache struct {
    data map[string]cacheItem
    mu   sync.RWMutex
}

type cacheItem struct {
    value      interface{}
    expiration time.Time
}

func NewCache() *Cache {
    cache := &Cache{
        data: make(map[string]cacheItem),
    }
    
    // Start cleanup goroutine
    go cache.cleanup()
    
    return cache
}

func (c *Cache) Set(key string, value interface{}, ttl time.Duration) {
    c.mu.Lock()
    defer c.mu.Unlock()
    
    c.data[key] = cacheItem{
        value:      value,
        expiration: time.Now().Add(ttl),
    }
}

func (c *Cache) Get(key string) (interface{}, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    
    item, exists := c.data[key]
    if !exists {
        return nil, false
    }
    
    if time.Now().After(item.expiration) {
        delete(c.data, key)
        return nil, false
    }
    
    return item.value, true
}

func (c *Cache) cleanup() {
    ticker := time.NewTicker(time.Minute)
    defer ticker.Stop()
    
    for range ticker.C {
        c.mu.Lock()
        now := time.Now()
        for key, item := range c.data {
            if now.After(item.expiration) {
                delete(c.data, key)
            }
        }
        c.mu.Unlock()
    }
}
```

### Distributed Caching
```go
// Redis cache wrapper
type RedisCache struct {
    client *redis.Client
}

func NewRedisCache(client *redis.Client) *RedisCache {
    return &RedisCache{client: client}
}

func (rc *RedisCache) Set(key string, value interface{}, ttl time.Duration) error {
    data, err := json.Marshal(value)
    if err != nil {
        return err
    }
    
    return rc.client.Set(context.Background(), key, data, ttl).Err()
}

func (rc *RedisCache) Get(key string, dest interface{}) error {
    data, err := rc.client.Get(context.Background(), key).Bytes()
    if err != nil {
        return err
    }
    
    return json.Unmarshal(data, dest)
}

// Cache middleware
func CacheMiddleware(cache *RedisCache, ttl time.Duration) gin.HandlerFunc {
    return func(c *gin.Context) {
        // Generate cache key
        cacheKey := fmt.Sprintf("cache:%s:%s", c.Request.Method, c.Request.URL.Path)
        
        // Try to get from cache
        var cachedResponse map[string]interface{}
        if err := cache.Get(cacheKey, &cachedResponse); err == nil {
            c.JSON(http.StatusOK, cachedResponse)
            c.Abort()
            return
        }
        
        // Process request and cache response
        c.Next()
        
        if c.Writer.Status() == http.StatusOK {
            // Cache successful responses
            response := c.Writer.Body()
            cache.Set(cacheKey, response, ttl)
        }
    }
}
```

## Database Performance

### Query Optimization
```go
// Optimized query with proper indexing
func FindUsersByRole(db *sql.DB, role string) ([]User, error) {
    query := `
        SELECT id, name, email, role, created_at 
        FROM users 
        WHERE role = $1 
        ORDER BY created_at DESC 
        LIMIT 100
    `
    
    rows, err := db.Query(query, role)
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    var users []User
    for rows.Next() {
        var user User
        err := rows.Scan(&user.ID, &user.Name, &user.Email, &user.Role, &user.CreatedAt)
        if err != nil {
            return nil, err
        }
        users = append(users, user)
    }
    
    return users, nil
}

// Batch operations
func CreateUsersBatch(db *sql.DB, users []User) error {
    tx, err := db.Begin()
    if err != nil {
        return err
    }
    defer tx.Rollback()
    
    stmt, err := tx.Prepare(`
        INSERT INTO users (name, email, password_hash, role) 
        VALUES ($1, $2, $3, $4)
    `)
    if err != nil {
        return err
    }
    defer stmt.Close()
    
    for _, user := range users {
        _, err := stmt.Exec(user.Name, user.Email, user.PasswordHash, user.Role)
        if err != nil {
            return err
        }
    }
    
    return tx.Commit()
}
```

### Database Connection Optimization
```go
// Connection pool configuration
func OptimizeDBConnections(db *sql.DB) {
    // Set optimal pool size based on CPU cores
    maxOpen := runtime.NumCPU() * 4
    maxIdle := runtime.NumCPU() * 2
    
    db.SetMaxOpenConns(maxOpen)
    db.SetMaxIdleConns(maxIdle)
    db.SetConnMaxLifetime(time.Hour)
    db.SetConnMaxIdleTime(time.Minute * 30)
}

// Query timeout
func QueryWithTimeout(ctx context.Context, db *sql.DB, query string, args ...interface{}) (*sql.Rows, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    
    return db.QueryContext(ctx, query, args...)
}
```

## API Performance

### Response Optimization
```go
// Compressed responses
func CompressMiddleware() gin.HandlerFunc {
    return gin.WrapF(func(w http.ResponseWriter, r *http.Request) {
        if strings.Contains(r.Header.Get("Accept-Encoding"), "gzip") {
            gzipWriter := gzip.NewWriter(w)
            defer gzipWriter.Close()
            
            w.Header().Set("Content-Encoding", "gzip")
            w = &gzipResponseWriter{ResponseWriter: w, Writer: gzipWriter}
        }
        
        // Continue with original handler
    })
}

// Pagination for large datasets
type PaginationParams struct {
    Page     int `form:"page" binding:"min=1"`
    PageSize int `form:"page_size" binding:"min=1,max=100"`
}

func GetUsersPaginated(c *gin.Context) {
    var params PaginationParams
    if err := c.ShouldBindQuery(&params); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    offset := (params.Page - 1) * params.PageSize
    
    users, total, err := userService.GetUsersPaginated(offset, params.PageSize)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "data": users,
        "pagination": gin.H{
            "page":       params.Page,
            "page_size":  params.PageSize,
            "total":      total,
            "total_pages": (total + params.PageSize - 1) / params.PageSize,
        },
    })
}
```

### Rate Limiting
```go
// Token bucket rate limiter
type TokenBucket struct {
    tokens    chan struct{}
    rate      time.Duration
    capacity  int
}

func NewTokenBucket(capacity int, rate time.Duration) *TokenBucket {
    tb := &TokenBucket{
        tokens:   make(chan struct{}, capacity),
        rate:     rate,
        capacity: capacity,
    }
    
    // Fill bucket initially
    for i := 0; i < capacity; i++ {
        tb.tokens <- struct{}{}
    }
    
    // Start refilling
    go tb.refill()
    
    return tb
}

func (tb *TokenBucket) refill() {
    ticker := time.NewTicker(tb.rate)
    defer ticker.Stop()
    
    for range ticker.C {
        select {
        case tb.tokens <- struct{}{}:
        default:
            // Bucket is full
        }
    }
}

func (tb *TokenBucket) Take() bool {
    select {
    case <-tb.tokens:
        return true
    default:
        return false
    }
}

// Rate limiting middleware
func RateLimitMiddleware(bucket *TokenBucket) gin.HandlerFunc {
    return func(c *gin.Context) {
        if !bucket.Take() {
            c.JSON(http.StatusTooManyRequests, gin.H{"error": "rate limit exceeded"})
            c.Abort()
            return
        }
        c.Next()
    }
}
```

## Monitoring and Profiling

### Application Metrics
```go
// Prometheus metrics
var (
    httpRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )
    
    httpRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_seconds",
            Help:    "HTTP request duration in seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "endpoint"},
    )
    
    activeConnections = prometheus.NewGauge(
        prometheus.GaugeOpts{
            Name: "active_connections",
            Help: "Number of active connections",
        },
    )
)

func init() {
    prometheus.MustRegister(httpRequestsTotal)
    prometheus.MustRegister(httpRequestDuration)
    prometheus.MustRegister(activeConnections)
}

// Metrics middleware
func MetricsMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        
        c.Next()
        
        duration := time.Since(start).Seconds()
        
        httpRequestsTotal.WithLabelValues(
            c.Request.Method,
            c.Request.URL.Path,
            strconv.Itoa(c.Writer.Status()),
        ).Inc()
        
        httpRequestDuration.WithLabelValues(
            c.Request.Method,
            c.Request.URL.Path,
        ).Observe(duration)
    }
}
```

### Performance Profiling
```go
// CPU profiling
func EnableCPUProfiling(router *gin.Engine) {
    router.GET("/debug/pprof/profile", gin.WrapF(pprof.Profile))
    router.GET("/debug/pprof/heap", gin.WrapF(pprof.Handler("heap").ServeHTTP))
    router.GET("/debug/pprof/goroutine", gin.WrapF(pprof.Handler("goroutine").ServeHTTP))
    router.GET("/debug/pprof/block", gin.WrapF(pprof.Handler("block").ServeHTTP))
}

// Custom profiling
func ProfileFunction(name string, fn func()) {
    f, err := os.Create(fmt.Sprintf("%s.prof", name))
    if err != nil {
        log.Fatal(err)
    }
    defer f.Close()
    
    pprof.StartCPUProfile(f)
    defer pprof.StopCPUProfile()
    
    fn()
}
```

### Health Checks
```go
// Health check endpoint
func HealthCheck(c *gin.Context) {
    health := gin.H{
        "status": "healthy",
        "timestamp": time.Now(),
        "version": "1.0.0",
    }
    
    // Check database connectivity
    if err := db.Ping(); err != nil {
        health["status"] = "unhealthy"
        health["database"] = "disconnected"
        c.JSON(http.StatusServiceUnavailable, health)
        return
    }
    
    // Check Redis connectivity
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

## Load Testing

### Load Test Implementation
```go
// Load test framework
type LoadTest struct {
    concurrency int
    duration    time.Duration
    requests    chan Request
    results     chan Result
}

type Request struct {
    Method  string
    URL     string
    Headers map[string]string
    Body    []byte
}

type Result struct {
    StatusCode int
    Duration   time.Duration
    Error      error
}

func NewLoadTest(concurrency int, duration time.Duration) *LoadTest {
    return &LoadTest{
        concurrency: concurrency,
        duration:    duration,
        requests:    make(chan Request, concurrency*10),
        results:     make(chan Result, concurrency*10),
    }
}

func (lt *LoadTest) Run() {
    // Start workers
    for i := 0; i < lt.concurrency; i++ {
        go lt.worker()
    }
    
    // Generate requests
    go lt.generateRequests()
    
    // Collect results
    go lt.collectResults()
    
    // Run for specified duration
    time.Sleep(lt.duration)
    close(lt.requests)
}

func (lt *LoadTest) worker() {
    client := &http.Client{
        Timeout: 10 * time.Second,
    }
    
    for req := range lt.requests {
        start := time.Now()
        
        httpReq, err := http.NewRequest(req.Method, req.URL, bytes.NewReader(req.Body))
        if err != nil {
            lt.results <- Result{Error: err}
            continue
        }
        
        for key, value := range req.Headers {
            httpReq.Header.Set(key, value)
        }
        
        resp, err := client.Do(httpReq)
        duration := time.Since(start)
        
        if err != nil {
            lt.results <- Result{Error: err, Duration: duration}
            continue
        }
        
        lt.results <- Result{
            StatusCode: resp.StatusCode,
            Duration:   duration,
        }
        
        resp.Body.Close()
    }
}
```

## Performance Best Practices

### Code Optimization
1. **Avoid allocations in hot paths**
2. **Use sync.Pool for frequently allocated objects**
3. **Prefer value types over pointers when possible**
4. **Use buffered channels for better performance**
5. **Profile before optimizing**

### Database Optimization
1. **Use proper indexes**
2. **Avoid N+1 queries**
3. **Use connection pooling**
4. **Implement query caching**
5. **Monitor slow queries**

### API Optimization
1. **Implement pagination**
2. **Use compression**
3. **Cache responses**
4. **Implement rate limiting**
5. **Use CDN for static assets**

### Infrastructure Optimization
1. **Horizontal scaling**
2. **Load balancing**
3. **Resource monitoring**
4. **Auto-scaling**
5. **Performance alerts**

## Performance Configuration

### Environment Variables
```bash
# Performance configuration
MAX_CONNECTIONS=100
CACHE_TTL=300
RATE_LIMIT=1000
WORKER_POOL_SIZE=10
DB_POOL_SIZE=20
```

### Performance Monitoring
```bash
# Enable profiling
export GODEBUG=pprof=1

# Run with profiling
go run -cpuprofile=cpu.prof -memprofile=mem.prof main.go

# Analyze profiles
go tool pprof cpu.prof
go tool pprof mem.prof
```

## Related Documentation

- [Architecture Documentation](../02-architecture/) - Performance architecture
- [Testing Strategy](../05-testing/) - Performance testing
- [Security Guidelines](../06-security/) - Security performance
- [API Documentation](../10-api-documentation/) - API performance
