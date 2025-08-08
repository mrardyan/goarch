# Internationalization Usage Guide

This guide provides comprehensive examples and best practices for using the internationalization domain types and composite types in the Go architecture project.

## Overview

The internationalization package provides type-safe domain types for handling internationalized data:
- **Time**: Epoch-based time with timezone support
- **Currency**: ISO 4217 currency codes with formatting
- **Timezone**: IANA timezone identifiers with offset calculations
- **Phone**: International phone numbers with country codes
- **Composite Types**: Types combining multiple domain types (`money.go`, `localized_datetime.go`, `localized_phone.go`)

## Basic Types

### Time Type

The Time type represents a point in time using epoch time (Unix timestamp) for efficient database storage.

```go
package main

import (
    "time"
    intl "golang-arch/internal/shared/domain/internationalization"
)

func main() {
    // Create from epoch time
    timeValue, err := intl.NewTime(1703520000)
    if err != nil {
        panic(err)
    }

    // Create from time.Time
    now := intl.NewTimeFromTime(time.Now())

    // Convert to time.Time
    goTime := timeValue.ToTime()

    // Format with timezone
    timezone, _ := intl.NewTimezoneFromID("America/New_York")
    formatted := timeValue.Format("2006-01-02 15:04:05", timezone)

    // Database storage
    epoch := timeValue.ToPrimitive() // int64
    fromDB, _ := intl.FromPrimitive(epoch)
}
```

### Currency Type

The Currency type represents a currency using ISO 4217 codes.

```go
package main

import (
    intl "golang-arch/internal/shared/domain/internationalization"
)

func main() {
    // Create from code
    usd, err := intl.NewCurrencyFromCode("USD")
    if err != nil {
        panic(err)
    }

    // Create with custom values
    custom, err := intl.NewCurrency("EUR", "€", "Euro")
    if err != nil {
        panic(err)
    }

    // Format amount
    formatted := usd.Format(1234.56) // "$1,234.56"

    // Database storage
    code := usd.ToPrimitive() // "USD"
    fromDB, _ := intl.NewCurrencyFromCode(code)
}
```

### Timezone Type

The Timezone type represents a timezone using IANA identifiers.

```go
package main

import (
    "time"
    intl "golang-arch/internal/shared/domain/internationalization"
)

func main() {
    // Create from IANA ID
    tz, err := intl.NewTimezoneFromID("America/New_York")
    if err != nil {
        panic(err)
    }

    // Get offset
    offset := tz.GetOffset() // time.Duration

    // Get location
    loc, err := tz.GetLocation()
    if err != nil {
        panic(err)
    }

    // Format offset
    formatted := tz.FormatOffset() // "-05:00"

    // Database storage
    id := tz.ToPrimitive() // "America/New_York"
    fromDB, _ := intl.NewTimezoneFromID(id)
}
```

### Phone Type

The Phone type represents an international phone number.

```go
package main

import (
    intl "golang-arch/internal/shared/domain/internationalization"
)

func main() {
    // Create from components
    phone, err := intl.NewPhone("1", "5551234567")
    if err != nil {
        panic(err)
    }

    // Create from string
    fromString, err := intl.NewPhoneFromString("+1 555-123-4567")
    if err != nil {
        panic(err)
    }

    // Format
    formatted := phone.Format() // "+1 5551234567"
    compact := phone.FormatCompact() // "+15551234567"

    // Database storage
    phoneStr := phone.ToPrimitive() // "+1 5551234567"
    fromDB, _ := intl.FromPrimitivePhone(phoneStr)
}
```

## Composite Types

### Money (`money.go`)

The Money value object combines an amount with a currency for type-safe monetary operations.

```go
package main

import (
    intl "golang-arch/internal/shared/domain/internationalization"
)

func main() {
    // Create money
    usd, _ := intl.NewCurrencyFromCode("USD")
    	money, err := intl.NewMoneyFromDecimal(100.50, *usd)
    if err != nil {
        panic(err)
    }

    // Format
    formatted := money.Format() // "$100.50"

    // Mathematical operations
    eur, _ := intl.NewCurrencyFromCode("EUR")
    	money2, _ := intl.NewMoneyFromDecimal(50.25, *eur)

    // Add (same currency only)
    result, err := money.Add(money2)
    if err != nil {
        // Error: different currencies
    }

    // Subtract
    difference, err := money.Subtract(money2)
    if err != nil {
        // Error: different currencies
    }

    // Multiply
    doubled, err := money.Multiply(2.0)

    // Database storage
    amount, currencyCode := money.ToPrimitive()
    // amount = 100.50, currencyCode = "USD"

    // From database
    fromDB, err := intl.NewMoneyFromPrimitive(amount, currencyCode)
}
```

### LocalizedDateTime (`localized_datetime.go`)

The LocalizedDateTime value object combines time with timezone for timezone-aware operations.

```go
package main

import (
    "time"
    intl "golang-arch/internal/shared/domain/internationalization"
)

func main() {
    // Create localized datetime
    timeValue := intl.NewTimeFromTime(time.Now())
    timezone, _ := intl.NewTimezoneFromID("America/New_York")
    
    ldt, err := intl.NewLocalizedDateTime(*timeValue, *timezone)
    if err != nil {
        panic(err)
    }

    // Format with timezone
    formatted := ldt.Format("2006-01-02 15:04:05")

    // Convert to time.Time in timezone
    localTime := ldt.ToTime()

    // Add duration
    tomorrow := ldt.Add(24 * time.Hour)

    // Compare
    isBefore := ldt.IsBefore(tomorrow) // true

    // Calculate duration
    duration := ldt.Duration(tomorrow)

    // Database storage
    epoch, timezoneID := ldt.ToPrimitive()
    // epoch = 1703520000, timezoneID = "America/New_York"

    // From database
    fromDB, err := intl.NewLocalizedDateTimeFromPrimitive(epoch, timezoneID)
}
```

### LocalizedPhone (`localized_phone.go`)

The LocalizedPhone value object combines phone number with location and timezone information.

```go
package main

import (
    intl "golang-arch/internal/shared/domain/internationalization"
)

func main() {
    // Create localized phone
    phone, _ := intl.NewPhone("1", "5551234567")
    timezone, _ := intl.NewTimezoneFromID("America/New_York")
    
    lp, err := intl.NewLocalizedPhone(*phone, "United States", "New York", *timezone)
    if err != nil {
        panic(err)
    }

    // Format phone
    formatted := lp.Format() // "+1 5551234567"

    // Get location
    location := lp.GetFullLocation() // "New York, United States"

    // Compare locations
    otherPhone, _ := intl.NewPhone("1", "5559876543")
    otherLP, _ := intl.NewLocalizedPhone(*otherPhone, "United States", "California", *timezone)
    
    sameCountry := lp.IsSameCountry(otherLP) // true
    sameRegion := lp.IsSameRegion(otherLP)   // false

    // Database storage
    phoneStr, country, region, timezoneID := lp.ToPrimitive()
    // phoneStr = "+1 5551234567"
    // country = "United States"
    // region = "New York"
    // timezoneID = "America/New_York"

    // From database
    fromDB, err := intl.NewLocalizedPhoneFromPrimitive(phoneStr, country, region, timezoneID)
}
```

## Database Integration

### PostgreSQL Schema

```sql
-- Money storage
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    amount DECIMAL(10,2) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    created_at TIMESTAMP NOT NULL
);

-- LocalizedDateTime storage
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    epoch_time BIGINT NOT NULL,
    timezone_id VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL
);

-- LocalizedPhone storage
CREATE TABLE contacts (
    id SERIAL PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    timezone_id VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL
);
```

### Go Database Operations

```go
package main

import (
    "database/sql"
    intl "golang-arch/internal/shared/domain/internationalization"
)

type TransactionRepository struct {
    db *sql.DB
}

func (r *TransactionRepository) SaveTransaction(money *intl.Money) error {
    amount, currencyCode := money.ToPrimitive()
    
    _, err := r.db.Exec(
        "INSERT INTO transactions (amount, currency_code, created_at) VALUES ($1, $2, $3)",
        amount, currencyCode, time.Now(),
    )
    return err
}

func (r *TransactionRepository) GetTransaction(id int) (*intl.Money, error) {
    var amount float64
    var currencyCode string
    
    err := r.db.QueryRow(
        "SELECT amount, currency_code FROM transactions WHERE id = $1",
        id,
    ).Scan(&amount, &currencyCode)
    if err != nil {
        return nil, err
    }
    
    return intl.NewMoneyFromPrimitive(amount, currencyCode)
}
```

## Best Practices

### 1. Error Handling

Always check for errors when creating domain types:

```go
// ✅ Good
	money, err := intl.NewMoneyFromDecimal(100.50, currency)
if err != nil {
    return fmt.Errorf("invalid money: %w", err)
}

// ❌ Bad
	money, _ := intl.NewMoneyFromDecimal(100.50, currency) // Ignoring errors
```

### 2. Validation

Use the Validate() method to ensure data integrity:

```go
// ✅ Good
if err := money.Validate(); err != nil {
    return fmt.Errorf("invalid money: %w", err)
}

// ❌ Bad
// No validation
```

### 3. Database Storage

Always use primitive conversion methods for database storage:

```go
// ✅ Good
amount, currencyCode := money.ToPrimitive()
_, err := db.Exec("INSERT INTO transactions (amount, currency_code) VALUES ($1, $2)", 
    amount, currencyCode)

// ❌ Bad
// Storing complex objects directly
```

### 4. Type Safety

Use the domain types instead of primitive values:

```go
// ✅ Good
func ProcessPayment(amount *intl.Money) error {
    if amount.IsNegative() {
        return errors.New("cannot process negative payment")
    }
    // ...
}

// ❌ Bad
func ProcessPayment(amount float64, currency string) error {
    // No type safety
}
```

### 5. Timezone Awareness

Always consider timezones when working with dates and times:

```go
// ✅ Good
ldt, _ := intl.NewLocalizedDateTime(timeValue, timezone)
formatted := ldt.Format("2006-01-02 15:04:05")

// ❌ Bad
// Using time.Time directly without timezone consideration
```

## Common Patterns

### 1. Factory Functions

Create factory functions for common use cases:

```go
func NewUSD(amount float64) (*intl.Money, error) {
    usd, err := intl.NewCurrencyFromCode("USD")
    if err != nil {
        return nil, err
    }
    	return intl.NewMoneyFromDecimal(amount, *usd)
}

func NewLocalTime(time time.Time, timezoneID string) (*intl.LocalizedDateTime, error) {
    timeValue := intl.NewTimeFromTime(time)
    timezone, err := intl.NewTimezoneFromID(timezoneID)
    if err != nil {
        return nil, err
    }
    return intl.NewLocalizedDateTime(*timeValue, *timezone)
}
```

### 2. Validation Helpers

Create validation helpers for complex business rules:

```go
func ValidatePaymentAmount(money *intl.Money) error {
    if money.IsZero() {
        return errors.New("payment amount cannot be zero")
    }
    
    if money.IsNegative() {
        return errors.New("payment amount cannot be negative")
    }
    
    // Business rule: maximum payment amount
    	maxPayment, _ := intl.NewMoneyFromDecimal(10000.0, money.Currency)
    if money.Amount > maxPayment.Amount {
        return errors.New("payment amount exceeds maximum")
    }
    
    return nil
}
```

### 3. Formatting Helpers

Create consistent formatting across the application:

```go
func FormatMoneyForDisplay(money *intl.Money) string {
    return money.Format()
}

func FormatDateTimeForDisplay(ldt *intl.LocalizedDateTime) string {
    return ldt.Format("January 2, 2006 at 3:04 PM")
}

func FormatPhoneForDisplay(lp *intl.LocalizedPhone) string {
    return fmt.Sprintf("%s (%s)", lp.Format(), lp.GetFullLocation())
}
```

## Testing

### Unit Tests

```go
func TestMoneyOperations(t *testing.T) {
    usd, _ := intl.NewCurrencyFromCode("USD")
    	money1, _ := intl.NewMoneyFromDecimal(100.0, *usd)
	money2, _ := intl.NewMoneyFromDecimal(50.0, *usd)
    
    result, err := money1.Add(money2)
    require.NoError(t, err)
    assert.Equal(t, 150.0, result.Amount)
}

func TestLocalizedDateTimeFormatting(t *testing.T) {
    timeValue := intl.NewTimeFromTime(time.Date(2023, 12, 25, 15, 30, 0, 0, time.UTC))
    timezone, _ := intl.NewTimezoneFromID("America/New_York")
    
    ldt, err := intl.NewLocalizedDateTime(*timeValue, *timezone)
    require.NoError(t, err)
    
    formatted := ldt.Format("2006-01-02 15:04:05")
    assert.Contains(t, formatted, "2023-12-25")
}
```

### Integration Tests

```go
func TestDatabaseIntegration(t *testing.T) {
    // Setup test database
    db := setupTestDB(t)
    defer db.Close()
    
    // Create money
    	usd, _ := intl.NewCurrencyFromCode("USD")
	money, _ := intl.NewMoneyFromDecimal(100.50, *usd)
    
    // Save to database
    amount, currencyCode := money.ToPrimitive()
    _, err := db.Exec("INSERT INTO transactions (amount, currency_code) VALUES ($1, $2)", 
        amount, currencyCode)
    require.NoError(t, err)
    
    // Retrieve from database
    var retrievedAmount float64
    var retrievedCurrencyCode string
    err = db.QueryRow("SELECT amount, currency_code FROM transactions LIMIT 1").
        Scan(&retrievedAmount, &retrievedCurrencyCode)
    require.NoError(t, err)
    
    // Reconstruct money
    retrievedMoney, err := intl.NewMoneyFromPrimitive(retrievedAmount, retrievedCurrencyCode)
    require.NoError(t, err)
    
    // Verify
    assert.Equal(t, money.Amount, retrievedMoney.Amount)
    assert.Equal(t, money.Currency.Code, retrievedMoney.Currency.Code)
}
```

## Performance Considerations

### 1. Memory Usage

Domain types are lightweight and efficient:

```go
// Time: 8 bytes (int64)
// Currency: ~50 bytes (string fields)
// Timezone: ~100 bytes (string fields + int)
// Phone: ~50 bytes (string fields)
// Money: ~60 bytes (float64 + Currency)
// LocalizedDateTime: ~120 bytes (Time + Timezone)
// LocalizedPhone: ~200 bytes (Phone + strings + Timezone)
```

### 2. Database Performance

Primitive storage enables efficient queries:

```sql
-- Fast queries on primitive values
SELECT * FROM transactions WHERE currency_code = 'USD' AND amount > 100.0;
SELECT * FROM events WHERE epoch_time > 1703520000;
SELECT * FROM contacts WHERE country = 'United States';
```

### 3. Caching

Domain types are immutable and can be safely cached:

```go
// Cache common currencies
var (
    USD *intl.Currency
    EUR *intl.Currency
    GBP *intl.Currency
)

func init() {
    USD, _ = intl.NewCurrencyFromCode("USD")
    EUR, _ = intl.NewCurrencyFromCode("EUR")
    GBP, _ = intl.NewCurrencyFromCode("GBP")
}
```

## Migration Guide

### From Primitive Types

If you're migrating from primitive types to domain types:

```go
// Before
type Transaction struct {
    Amount   float64 `json:"amount"`
    Currency string  `json:"currency"`
}

// After
type Transaction struct {
    Money *intl.Money `json:"money"`
}
```

### From time.Time

If you're migrating from time.Time to domain types:

```go
// Before
type Event struct {
    Time     time.Time `json:"time"`
    Timezone string    `json:"timezone"`
}

// After
type Event struct {
    DateTime *intl.LocalizedDateTime `json:"datetime"`
}
```

This guide provides comprehensive examples and best practices for using the internationalization domain types effectively in your Go applications.
