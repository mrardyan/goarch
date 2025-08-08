# Internationalization Documentation

This section provides comprehensive documentation for the internationalization domain types and composite types used throughout the application.

## Overview

The internationalization package (`internal/shared/domain/internationalization`) provides type-safe domain types for handling internationalized data in a Go application. These types ensure consistency, type safety, and proper handling of international data across all services.

## Documentation Structure

### 1. [Overview](01-overview.md)
Comprehensive introduction to the internationalization domain types, their purpose, and architectural benefits.

### 2. [Usage Guide](02-usage-guide.md)
Detailed examples and best practices for using the internationalization domain types in your applications.

### 3. [Database Storage](03-database-storage.md)
Database schema design, repository patterns, and storage strategies for internationalization types.

### 4. [Interoperability](04-interoperability.md)
Cross-type operations, external API integration, and serialization patterns.

### 5. [Best Practices](05-best-practices.md)
Guidelines for effective usage, performance optimization, and security considerations.

## Quick Reference

### Core Domain Types
- **Time**: Epoch-based time with timezone support
- **Currency**: ISO 4217 currency codes with formatting
- **Timezone**: IANA timezone identifiers with offset calculations
- **Phone**: International phone numbers with country codes

### Composite Types
- **Money** (`money.go`): Amount + Currency for type-safe monetary operations
- **LocalizedDateTime** (`localized_datetime.go`): Time + Timezone for timezone-aware operations
- **LocalizedPhone** (`localized_phone.go`): Phone + Country + Region + Timezone for location-aware communication

### Key Benefits
- **Type Safety**: Compile-time error detection
- **Database Efficiency**: Primitive storage for optimal performance
- **Domain-Driven Design**: Rich domain models with business logic
- **Internationalization Support**: Built-in support for multiple currencies and timezones

## Getting Started

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
    
    // Use in business logic
    fmt.Println(money.Format())           // "$100.50"
    fmt.Println(ldt.Format("2006-01-02")) // "2023-12-25"
}
```

## Related Documentation

- [Architecture Overview](../02-architecture/01-service-structure.md)
- [Development Guidelines](../03-development/README.md)
- [Testing Strategies](../05-testing/README.md)

This internationalization package provides a solid foundation for handling internationalized data in a type-safe, efficient, and maintainable way throughout the application using composite types from `money.go`, `localized_datetime.go`, and `localized_phone.go`.
