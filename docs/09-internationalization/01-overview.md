# Internationalization Overview

This section provides comprehensive documentation for the internationalization domain types and composite types used throughout the application.

## Overview

The internationalization package (`internal/shared/domain/internationalization`) provides type-safe domain types for handling internationalized data in a Go application. These types ensure consistency, type safety, and proper handling of international data across all services.

## Core Domain Types

### 1. Time
- **Purpose**: Represents a point in time using epoch time (Unix timestamp)
- **Benefits**: Efficient database storage, timezone-agnostic representation
- **Usage**: All time-based operations throughout the application

### 2. Currency
- **Purpose**: Represents currencies using ISO 4217 codes
- **Benefits**: Type-safe currency operations, standardized formatting
- **Usage**: Financial transactions, monetary calculations

### 3. Timezone
- **Purpose**: Represents timezones using IANA identifiers
- **Benefits**: Accurate timezone calculations, offset handling
- **Usage**: Timezone-aware operations, scheduling

### 4. Phone
- **Purpose**: Represents international phone numbers
- **Benefits**: Country code validation, standardized formatting
- **Usage**: Contact information, communication systems

## Composite Types

### 1. Money (`money.go`)
- **Composition**: Amount (int64) + Currency
- **Purpose**: Type-safe monetary operations with integer-based storage
- **Benefits**: Prevents currency mixing errors, eliminates floating-point precision issues
- **Database Storage**: (amount int64, currency_code string)

### 2. LocalizedDateTime (`localized_datetime.go`)
- **Composition**: Time + Timezone
- **Purpose**: Timezone-aware datetime operations
- **Benefits**: Accurate timezone conversions, localized formatting
- **Database Storage**: (epoch int64, timezone_id string)

### 3. LocalizedPhone (`localized_phone.go`)
- **Composition**: Phone + Country + Region + Timezone
- **Purpose**: Location-aware phone number handling
- **Benefits**: Geographic context, timezone-aware communication
- **Database Storage**: (phone_number string, country string, region string, timezone_id string)

## Architecture Benefits

### 1. Type Safety
- Prevents runtime errors through compile-time type checking
- Ensures consistent data handling across services
- Reduces bugs related to data type mismatches

### 2. Database Efficiency
- Primitive storage for optimal database performance
- Efficient indexing on simple data types
- Cross-database compatibility

### 3. Domain-Driven Design
- Rich domain models with business logic
- Clear separation of concerns
- Immutable composite types

### 4. Internationalization Support
- Built-in support for multiple currencies
- Timezone-aware operations
- Localized formatting and validation

## Usage Patterns

### 1. Service Integration
All services can use these domain types for consistent data handling:
- User service for contact information
- Payment service for monetary operations
- Scheduling service for timezone-aware operations

### 2. API Design
- Consistent JSON serialization/deserialization
- Type-safe request/response handling
- Proper validation and error handling

### 3. Database Operations
- Efficient storage using primitive values
- Type-safe repository patterns
- Optimized query performance

## Documentation Structure

This section contains the following guides:

1. **[Usage Guide](02-usage-guide.md)**: Comprehensive examples and best practices
2. **[Database Storage](03-database-storage.md)**: Database schema and repository patterns
3. **[Interoperability](04-interoperability.md)**: Cross-type operations and external integrations
4. **[Best Practices](05-best-practices.md)**: Guidelines for effective usage

## Quick Start

```go
package main

import (
    intl "golang-arch/internal/shared/domain/internationalization"
)

func main() {
    // Create money
    usd, _ := intl.NewCurrencyFromCode("USD")
    money, _ := intl.NewMoneyFromDecimal(100.50, *usd)
    
    // Create localized datetime
    timeValue := intl.NewTimeFromTime(time.Now())
    timezone, _ := intl.NewTimezoneFromID("America/New_York")
    ldt, _ := intl.NewLocalizedDateTime(*timeValue, *timezone)
    
    // Create localized phone
    phone, _ := intl.NewPhone("1", "5551234567")
    lp, _ := intl.NewLocalizedPhone(*phone, "United States", "New York", *timezone)
    
    // Use in business logic
    fmt.Println(money.Format())           // "$100.50"
    fmt.Println(ldt.Format("2006-01-02")) // "2023-12-25"
    fmt.Println(lp.Format())              // "+1 5551234567"
}
```

## Migration from Primitive Types

If you're migrating from primitive types to domain types:

```go
// Before
type Transaction struct {
    Amount   float64 `json:"amount"`
    Currency string  `json:"currency"`
    Time     time.Time `json:"time"`
}

// After
type Transaction struct {
    Money *intl.Money `json:"money"`
    DateTime *intl.LocalizedDateTime `json:"datetime"`
}
```

This internationalization package provides a solid foundation for handling internationalized data in a type-safe, efficient, and maintainable way throughout the application using composite types from `money.go`, `localized_datetime.go`, and `localized_phone.go`.
