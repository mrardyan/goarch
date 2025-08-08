# Internationalization Database Storage Guide

This guide provides comprehensive information about database storage considerations when using the internationalization domain types and composite types.

## Overview

The internationalization domain types are designed for efficient database storage using primitive values. This approach provides:
- **Type safety** at the application level
- **Efficient database queries** using simple data types
- **Cross-database compatibility** with standard SQL types
- **Optimal performance** for indexing and joins

## Storage Strategy

### Primitive Storage Pattern

All domain types follow a primitive storage pattern:

```go
// Domain Type → Primitive Values → Database Storage
type Money struct {
    Amount   float64  // → stored as DECIMAL(10,2)
    Currency Currency // → stored as VARCHAR(3)
}

// Conversion methods
func (m *Money) ToPrimitive() (float64, string) {
    return m.Amount, m.Currency.ToPrimitive()
}

func NewMoneyFromPrimitive(amount float64, currencyCode string) (*Money, error) {
    currency, err := NewCurrencyFromCode(currencyCode)
    if err != nil {
        return nil, err
    }
    	return NewMoneyFromDecimal(amount, *currency)
}
```

## Database Schema Design

### PostgreSQL Schema

```sql
-- Money storage
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    amount DECIMAL(10,2) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- LocalizedDateTime storage
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    epoch_time BIGINT NOT NULL,
    timezone_id VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- LocalizedPhone storage
CREATE TABLE contacts (
    id SERIAL PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    timezone_id VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_transactions_currency ON transactions(currency_code);
CREATE INDEX idx_transactions_amount ON transactions(amount);
CREATE INDEX idx_events_epoch_time ON events(epoch_time);
CREATE INDEX idx_events_timezone ON events(timezone_id);
CREATE INDEX idx_contacts_country ON contacts(country);
CREATE INDEX idx_contacts_phone ON contacts(phone_number);
```

### MySQL Schema

```sql
-- Money storage
CREATE TABLE transactions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    amount DECIMAL(10,2) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- LocalizedDateTime storage
CREATE TABLE events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    epoch_time BIGINT NOT NULL,
    timezone_id VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- LocalizedPhone storage
CREATE TABLE contacts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    timezone_id VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_transactions_currency ON transactions(currency_code);
CREATE INDEX idx_transactions_amount ON transactions(amount);
CREATE INDEX idx_events_epoch_time ON events(epoch_time);
CREATE INDEX idx_events_timezone ON events(timezone_id);
CREATE INDEX idx_contacts_country ON contacts(country);
CREATE INDEX idx_contacts_phone ON contacts(phone_number);
```

## Repository Pattern Implementation

### Base Repository Interface

```go
package repository

import (
    "context"
    intl "golang-arch/internal/shared/domain/internationalization"
)

// MoneyRepository defines operations for Money composite types
type MoneyRepository interface {
    Save(ctx context.Context, money *intl.Money) error
    GetByID(ctx context.Context, id int) (*intl.Money, error)
    GetByCurrency(ctx context.Context, currencyCode string) ([]*intl.Money, error)
    GetByAmountRange(ctx context.Context, min, max float64) ([]*intl.Money, error)
}

// LocalizedDateTimeRepository defines operations for LocalizedDateTime composite types
type LocalizedDateTimeRepository interface {
    Save(ctx context.Context, ldt *intl.LocalizedDateTime) error
    GetByID(ctx context.Context, id int) (*intl.LocalizedDateTime, error)
    GetByTimeRange(ctx context.Context, start, end int64) ([]*intl.LocalizedDateTime, error)
    GetByTimezone(ctx context.Context, timezoneID string) ([]*intl.LocalizedDateTime, error)
}

// LocalizedPhoneRepository defines operations for LocalizedPhone composite types
type LocalizedPhoneRepository interface {
    Save(ctx context.Context, lp *intl.LocalizedPhone) error
    GetByID(ctx context.Context, id int) (*intl.LocalizedPhone, error)
    GetByCountry(ctx context.Context, country string) ([]*intl.LocalizedPhone, error)
    GetByRegion(ctx context.Context, region string) ([]*intl.LocalizedPhone, error)
}
```

### PostgreSQL Implementation

```go
package postgres

import (
    "context"
    "database/sql"
    "fmt"
    intl "golang-arch/internal/shared/domain/internationalization"
)

type MoneyRepository struct {
    db *sql.DB
}

func NewMoneyRepository(db *sql.DB) *MoneyRepository {
    return &MoneyRepository{db: db}
}

func (r *MoneyRepository) Save(ctx context.Context, money *intl.Money) error {
    amount, currencyCode := money.ToPrimitive()
    
    query := `
        INSERT INTO transactions (amount, currency_code, created_at, updated_at)
        VALUES ($1, $2, NOW(), NOW())
        RETURNING id
    `
    
    var id int
    err := r.db.QueryRowContext(ctx, query, amount, currencyCode).Scan(&id)
    if err != nil {
        return fmt.Errorf("failed to save money: %w", err)
    }
    
    return nil
}

func (r *MoneyRepository) GetByID(ctx context.Context, id int) (*intl.Money, error) {
    query := `
        SELECT amount, currency_code
        FROM transactions
        WHERE id = $1
    `
    
    var amount float64
    var currencyCode string
    
    err := r.db.QueryRowContext(ctx, query, id).Scan(&amount, &currencyCode)
    if err != nil {
        return nil, fmt.Errorf("failed to get money by id: %w", err)
    }
    
    return intl.NewMoneyFromPrimitive(amount, currencyCode)
}

func (r *MoneyRepository) GetByCurrency(ctx context.Context, currencyCode string) ([]*intl.Money, error) {
    query := `
        SELECT amount, currency_code
        FROM transactions
        WHERE currency_code = $1
        ORDER BY created_at DESC
    `
    
    rows, err := r.db.QueryContext(ctx, query, currencyCode)
    if err != nil {
        return nil, fmt.Errorf("failed to get money by currency: %w", err)
    }
    defer rows.Close()
    
    var results []*intl.Money
    for rows.Next() {
        var amount float64
        var code string
        
        err := rows.Scan(&amount, &code)
        if err != nil {
            return nil, fmt.Errorf("failed to scan money row: %w", err)
        }
        
        money, err := intl.NewMoneyFromPrimitive(amount, code)
        if err != nil {
            return nil, fmt.Errorf("failed to create money from primitive: %w", err)
        }
        
        results = append(results, money)
    }
    
    return results, nil
}

func (r *MoneyRepository) GetByAmountRange(ctx context.Context, min, max float64) ([]*intl.Money, error) {
    query := `
        SELECT amount, currency_code
        FROM transactions
        WHERE amount BETWEEN $1 AND $2
        ORDER BY amount ASC
    `
    
    rows, err := r.db.QueryContext(ctx, query, min, max)
    if err != nil {
        return nil, fmt.Errorf("failed to get money by amount range: %w", err)
    }
    defer rows.Close()
    
    var results []*intl.Money
    for rows.Next() {
        var amount float64
        var currencyCode string
        
        err := rows.Scan(&amount, &currencyCode)
        if err != nil {
            return nil, fmt.Errorf("failed to scan money row: %w", err)
        }
        
        money, err := intl.NewMoneyFromPrimitive(amount, currencyCode)
        if err != nil {
            return nil, fmt.Errorf("failed to create money from primitive: %w", err)
        }
        
        results = append(results, money)
    }
    
    return results, nil
}
```

### LocalizedDateTime Repository

```go
type LocalizedDateTimeRepository struct {
    db *sql.DB
}

func NewLocalizedDateTimeRepository(db *sql.DB) *LocalizedDateTimeRepository {
    return &LocalizedDateTimeRepository{db: db}
}

func (r *LocalizedDateTimeRepository) Save(ctx context.Context, ldt *intl.LocalizedDateTime) error {
    epoch, timezoneID := ldt.ToPrimitive()
    
    query := `
        INSERT INTO events (epoch_time, timezone_id, title, created_at)
        VALUES ($1, $2, $3, NOW())
        RETURNING id
    `
    
    var id int
    err := r.db.QueryRowContext(ctx, query, epoch, timezoneID, "Event Title").Scan(&id)
    if err != nil {
        return fmt.Errorf("failed to save localized datetime: %w", err)
    }
    
    return nil
}

func (r *LocalizedDateTimeRepository) GetByTimeRange(ctx context.Context, start, end int64) ([]*intl.LocalizedDateTime, error) {
    query := `
        SELECT epoch_time, timezone_id
        FROM events
        WHERE epoch_time BETWEEN $1 AND $2
        ORDER BY epoch_time ASC
    `
    
    rows, err := r.db.QueryContext(ctx, query, start, end)
    if err != nil {
        return nil, fmt.Errorf("failed to get localized datetime by time range: %w", err)
    }
    defer rows.Close()
    
    var results []*intl.LocalizedDateTime
    for rows.Next() {
        var epoch int64
        var timezoneID string
        
        err := rows.Scan(&epoch, &timezoneID)
        if err != nil {
            return nil, fmt.Errorf("failed to scan localized datetime row: %w", err)
        }
        
        ldt, err := intl.NewLocalizedDateTimeFromPrimitive(epoch, timezoneID)
        if err != nil {
            return nil, fmt.Errorf("failed to create localized datetime from primitive: %w", err)
        }
        
        results = append(results, ldt)
    }
    
    return results, nil
}
```

## Migration Strategies

### From Existing Schema

If you have existing tables with primitive types, you can migrate gradually:

```sql
-- Step 1: Add new columns
ALTER TABLE transactions ADD COLUMN currency_code VARCHAR(3);
ALTER TABLE events ADD COLUMN timezone_id VARCHAR(50);

-- Step 2: Migrate existing data
UPDATE transactions SET currency_code = 'USD' WHERE currency_code IS NULL;
UPDATE events SET timezone_id = 'UTC' WHERE timezone_id IS NULL;

-- Step 3: Make columns NOT NULL
ALTER TABLE transactions ALTER COLUMN currency_code SET NOT NULL;
ALTER TABLE events ALTER COLUMN timezone_id SET NOT NULL;

-- Step 4: Add indexes
CREATE INDEX idx_transactions_currency ON transactions(currency_code);
CREATE INDEX idx_events_timezone ON events(timezone_id);
```

### Data Migration Script

```go
package migration

import (
    "database/sql"
    "fmt"
    intl "golang-arch/internal/shared/domain/internationalization"
)

func MigrateToInternationalization(db *sql.DB) error {
    // Migrate money data
    if err := migrateMoneyData(db); err != nil {
        return fmt.Errorf("failed to migrate money data: %w", err)
    }
    
    // Migrate datetime data
    if err := migrateDateTimeData(db); err != nil {
        return fmt.Errorf("failed to migrate datetime data: %w", err)
    }
    
    return nil
}

func migrateMoneyData(db *sql.DB) error {
    // Example: Migrate from old amount/currency format to new format
    query := `
        UPDATE transactions 
        SET currency_code = CASE 
            WHEN currency = 'dollar' THEN 'USD'
            WHEN currency = 'euro' THEN 'EUR'
            WHEN currency = 'pound' THEN 'GBP'
            ELSE 'USD'
        END
        WHERE currency_code IS NULL
    `
    
    _, err := db.Exec(query)
    return err
}

func migrateDateTimeData(db *sql.DB) error {
    // Example: Migrate from timestamp to epoch/timezone format
    query := `
        UPDATE events 
        SET epoch_time = EXTRACT(EPOCH FROM event_time),
            timezone_id = COALESCE(timezone, 'UTC')
        WHERE epoch_time IS NULL
    `
    
    _, err := db.Exec(query)
    return err
}
```

## Performance Considerations

### Indexing Strategy

```sql
-- Primary indexes for common queries
CREATE INDEX idx_transactions_currency_amount ON transactions(currency_code, amount);
CREATE INDEX idx_events_timezone_epoch ON events(timezone_id, epoch_time);
CREATE INDEX idx_contacts_country_region ON contacts(country, region);

-- Composite indexes for complex queries
CREATE INDEX idx_transactions_created_currency ON transactions(created_at, currency_code);
CREATE INDEX idx_events_epoch_timezone ON events(epoch_time, timezone_id);
```

### Query Optimization

```go
// Efficient query with proper indexing
func (r *MoneyRepository) GetByCurrencyAndAmountRange(
    ctx context.Context, 
    currencyCode string, 
    minAmount, maxAmount float64,
) ([]*intl.Money, error) {
    query := `
        SELECT amount, currency_code
        FROM transactions
        WHERE currency_code = $1 
        AND amount BETWEEN $2 AND $3
        ORDER BY amount ASC
    `
    
    rows, err := r.db.QueryContext(ctx, query, currencyCode, minAmount, maxAmount)
    if err != nil {
        return nil, fmt.Errorf("failed to get money by currency and amount range: %w", err)
    }
    defer rows.Close()
    
    var results []*intl.Money
    for rows.Next() {
        var amount float64
        var code string
        
        err := rows.Scan(&amount, &code)
        if err != nil {
            return nil, fmt.Errorf("failed to scan money row: %w", err)
        }
        
        money, err := intl.NewMoneyFromPrimitive(amount, code)
        if err != nil {
            return nil, fmt.Errorf("failed to create money from primitive: %w", err)
        }
        
        results = append(results, money)
    }
    
    return results, nil
}
```

### Connection Pooling

```go
import (
    "database/sql"
    _ "github.com/lib/pq"
)

func NewDatabaseConnection() (*sql.DB, error) {
    db, err := sql.Open("postgres", "postgres://user:password@localhost/dbname?sslmode=disable")
    if err != nil {
        return nil, err
    }
    
    // Configure connection pool
    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(5)
    db.SetConnMaxLifetime(5 * time.Minute)
    
    return db, nil
}
```

## Error Handling

### Database-Specific Errors

```go
import (
    "database/sql"
    "github.com/lib/pq"
)

func handleDatabaseError(err error) error {
    if err == nil {
        return nil
    }
    
    // Check for PostgreSQL-specific errors
    if pgErr, ok := err.(*pq.Error); ok {
        switch pgErr.Code {
        case "23505": // unique_violation
            return fmt.Errorf("duplicate entry: %w", err)
        case "23503": // foreign_key_violation
            return fmt.Errorf("referenced record not found: %w", err)
        case "23514": // check_violation
            return fmt.Errorf("constraint violation: %w", err)
        default:
            return fmt.Errorf("database error: %w", err)
        }
    }
    
    // Check for common SQL errors
    if err == sql.ErrNoRows {
        return fmt.Errorf("record not found: %w", err)
    }
    
    return fmt.Errorf("unexpected error: %w", err)
}
```

### Validation in Repository Layer

```go
func (r *MoneyRepository) Save(ctx context.Context, money *intl.Money) error {
    // Validate before saving
    if err := money.Validate(); err != nil {
        return fmt.Errorf("invalid money: %w", err)
    }
    
    amount, currencyCode := money.ToPrimitive()
    
    // Additional database-specific validation
    if amount < 0 {
        return fmt.Errorf("negative amounts not allowed")
    }
    
    if len(currencyCode) != 3 {
        return fmt.Errorf("invalid currency code length")
    }
    
    query := `
        INSERT INTO transactions (amount, currency_code, created_at, updated_at)
        VALUES ($1, $2, NOW(), NOW())
    `
    
    _, err := r.db.ExecContext(ctx, query, amount, currencyCode)
    if err != nil {
        return handleDatabaseError(err)
    }
    
    return nil
}
```

## Testing Database Operations

### Integration Tests

```go
package repository_test

import (
    "context"
    "database/sql"
    "testing"
    "time"
    
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    intl "golang-arch/internal/shared/domain/internationalization"
)

func setupTestDB(t *testing.T) *sql.DB {
    db, err := sql.Open("postgres", "postgres://test:test@localhost/testdb?sslmode=disable")
    require.NoError(t, err)
    
    // Create test tables
    _, err = db.Exec(`
        CREATE TABLE IF NOT EXISTS transactions (
            id SERIAL PRIMARY KEY,
            amount DECIMAL(10,2) NOT NULL,
            currency_code VARCHAR(3) NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT NOW()
        )
    `)
    require.NoError(t, err)
    
    return db
}

func TestMoneyRepository_SaveAndGet(t *testing.T) {
    db := setupTestDB(t)
    defer db.Close()
    
    repo := NewMoneyRepository(db)
    
    // Create money
    usd, err := intl.NewCurrencyFromCode("USD")
    require.NoError(t, err)
    
    	money, err := intl.NewMoneyFromDecimal(100.50, *usd)
    require.NoError(t, err)
    
    // Save to database
    err = repo.Save(context.Background(), money)
    require.NoError(t, err)
    
    // Retrieve from database (using a different approach for testing)
    var amount float64
    var currencyCode string
    
    err = db.QueryRow("SELECT amount, currency_code FROM transactions LIMIT 1").
        Scan(&amount, &currencyCode)
    require.NoError(t, err)
    
    // Reconstruct money
    retrievedMoney, err := intl.NewMoneyFromPrimitive(amount, currencyCode)
    require.NoError(t, err)
    
    // Verify
    assert.Equal(t, money.Amount, retrievedMoney.Amount)
    assert.Equal(t, money.Currency.Code, retrievedMoney.Currency.Code)
}
```

## Best Practices Summary

1. **Always use primitive conversion methods** for database storage
2. **Validate domain objects** before saving to database
3. **Use proper indexing** for performance-critical queries
4. **Handle database-specific errors** appropriately
5. **Use connection pooling** for production applications
6. **Write integration tests** for database operations
7. **Plan migration strategies** for existing data
8. **Monitor query performance** in production

This guide ensures efficient and reliable database storage for internationalization domain types while maintaining type safety and performance.
