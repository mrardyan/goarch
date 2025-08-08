// Package internationalization provides domain types and composite types for handling
// internationalized data such as time, currency, timezone, and phone numbers.
// This file contains the Money composite type for type-safe monetary operations.
//
// Money Composite Type:
//   - Combines amount with currency for type-safe monetary operations
//   - Integer-based storage for financial precision
//   - Currency validation and formatting
//   - Database storage as primitive values
//
// Database Storage: (amount int64, currency_code string)
// JSON Format: {"amount": 10050, "currency": {"code": "USD", "symbol": "$", "name": "US Dollar", "decimal_places": 2}}
//
// Usage Examples:
//
//	usd, _ := NewCurrencyFromCode("USD")
//	money, err := NewMoneyFromDecimal(100.50, *usd)
//	formatted := money.Format() // "$100.50"
//	integer := money.ToInteger() // 10050 (cents)
package internationalization

import (
	"encoding/json"
	"fmt"
	"math"
)

// Money represents a monetary value with an associated currency.
// This composite type combines an amount with a currency type for type-safe
// monetary operations and database storage using integer-based storage
// to eliminate floating-point precision errors.
//
// Features:
//   - Type-safe monetary operations (add, subtract, multiply)
//   - Currency validation and formatting
//   - Database storage as primitive values
//   - Integer-based storage for financial precision
//   - Decimal conversion utilities for API compatibility
//
// Database Storage: (amount int64, currency_code string)
// JSON Format: {"amount": 10050, "currency": {"code": "USD", "symbol": "$", "name": "US Dollar", "decimal_places": 2}}
//
// Example:
//
//	usd, _ := NewCurrencyFromCode("USD")
//	money, err := NewMoneyFromDecimal(100.50, *usd)
//	formatted := money.Format() // "$100.50"
//	integer := money.ToInteger() // 10050 (cents)
type Money struct {
	Amount   int64    `json:"amount"`   // Amount in smallest currency unit (e.g., cents)
	Currency Currency `json:"currency"` // Associated currency
}

// NewMoneyFromDecimal creates a new Money composite type from a decimal amount.
// The decimal amount is converted to the integer representation based on the currency's decimal places.
// Returns an error if the currency is invalid or if the conversion would cause overflow.
func NewMoneyFromDecimal(decimal float64, currency Currency) (*Money, error) {
	if err := currency.Validate(); err != nil {
		return nil, fmt.Errorf("invalid currency for money: %w", err)
	}

	// Convert decimal to integer based on currency decimal places
	multiplier := math.Pow10(currency.DecimalPlaces)
	integerAmount := int64(math.Round(decimal * multiplier))

	// Check for overflow
	if currency.DecimalPlaces > 0 {
		// Verify the conversion is accurate
		convertedBack := float64(integerAmount) / multiplier
		if math.Abs(convertedBack-decimal) > 0.000001 {
			return nil, fmt.Errorf("decimal conversion would lose precision: %f", decimal)
		}
	}

	return &Money{
		Amount:   integerAmount,
		Currency: currency,
	}, nil
}

// NewMoneyFromInteger creates a new Money composite type from an integer amount.
// The integer amount should be in the smallest currency unit (e.g., cents for USD).
func NewMoneyFromInteger(amount int64, currency Currency) (*Money, error) {
	if err := currency.Validate(); err != nil {
		return nil, fmt.Errorf("invalid currency for money: %w", err)
	}

	return &Money{
		Amount:   amount,
		Currency: currency,
	}, nil
}

// NewMoneyFromPrimitive creates a Money composite type from primitive database values.
// The amount is stored as an int64 and currency as a string code.
func NewMoneyFromPrimitive(amount int64, currencyCode string) (*Money, error) {
	currency, err := NewCurrencyFromCode(currencyCode)
	if err != nil {
		return nil, fmt.Errorf("failed to create money from primitive: %w", err)
	}

	return &Money{
		Amount:   amount,
		Currency: *currency,
	}, nil
}

// ToPrimitive converts the Money composite type to primitive database values.
// Returns the amount as int64 and currency code as string.
func (m *Money) ToPrimitive() (int64, string) {
	return m.Amount, m.Currency.ToPrimitive()
}

// ToDecimal converts the integer amount to a decimal representation.
// This is useful for API responses and display purposes.
func (m *Money) ToDecimal() float64 {
	if m.Currency.DecimalPlaces == 0 {
		return float64(m.Amount)
	}
	return float64(m.Amount) / math.Pow10(m.Currency.DecimalPlaces)
}

// ToInteger returns the integer amount in the smallest currency unit.
func (m *Money) ToInteger() int64 {
	return m.Amount
}

// Validate ensures the Money composite type is valid.
func (m *Money) Validate() error {
	if err := m.Currency.Validate(); err != nil {
		return fmt.Errorf("invalid currency in money: %w", err)
	}

	return nil
}

// Format returns a formatted string representation of the money value.
func (m *Money) Format() string {
	return m.Currency.Format(m.Amount)
}

// FormatDecimal returns a formatted string with decimal representation.
// This is useful for API responses and backward compatibility.
func (m *Money) FormatDecimal() string {
	return m.Currency.FormatDecimal(m.ToDecimal())
}

// Add adds another Money value and returns a new Money value.
// Both values must have the same currency.
func (m *Money) Add(other *Money) (*Money, error) {
	if m.Currency.Code != other.Currency.Code {
		return nil, fmt.Errorf("cannot add money with different currencies: %s and %s",
			m.Currency.Code, other.Currency.Code)
	}

	// Check for integer overflow
	if (other.Amount > 0 && m.Amount > math.MaxInt64-other.Amount) ||
		(other.Amount < 0 && m.Amount < math.MinInt64-other.Amount) {
		return nil, fmt.Errorf("integer overflow in money addition")
	}

	return NewMoneyFromInteger(m.Amount+other.Amount, m.Currency)
}

// Subtract subtracts another Money value and returns a new Money value.
// Both values must have the same currency.
func (m *Money) Subtract(other *Money) (*Money, error) {
	if m.Currency.Code != other.Currency.Code {
		return nil, fmt.Errorf("cannot subtract money with different currencies: %s and %s",
			m.Currency.Code, other.Currency.Code)
	}

	// Check for integer overflow
	if (other.Amount > 0 && m.Amount < math.MinInt64+other.Amount) ||
		(other.Amount < 0 && m.Amount > math.MaxInt64+other.Amount) {
		return nil, fmt.Errorf("integer overflow in money subtraction")
	}

	return NewMoneyFromInteger(m.Amount-other.Amount, m.Currency)
}

// Multiply multiplies the money amount by a factor and returns a new Money value.
// The factor should be an integer to maintain precision.
func (m *Money) Multiply(factor int64) (*Money, error) {
	// Check for integer overflow
	if factor != 0 && (m.Amount > math.MaxInt64/factor || m.Amount < math.MinInt64/factor) {
		return nil, fmt.Errorf("integer overflow in money multiplication")
	}

	return NewMoneyFromInteger(m.Amount*factor, m.Currency)
}

// MultiplyDecimal multiplies the money amount by a decimal factor.
// This method converts to decimal, multiplies, then converts back to integer.
func (m *Money) MultiplyDecimal(factor float64) (*Money, error) {
	decimal := m.ToDecimal()
	result := decimal * factor
	return NewMoneyFromDecimal(result, m.Currency)
}

// IsZero returns true if the money amount is zero.
func (m *Money) IsZero() bool {
	return m.Amount == 0
}

// IsPositive returns true if the money amount is positive.
func (m *Money) IsPositive() bool {
	return m.Amount > 0
}

// IsNegative returns true if the money amount is negative.
func (m *Money) IsNegative() bool {
	return m.Amount < 0
}

// Equal returns true if two Money values are equal.
func (m *Money) Equal(other *Money) bool {
	if m == nil || other == nil {
		return m == other
	}
	return m.Amount == other.Amount && m.Currency.Code == other.Currency.Code
}

// String returns a string representation of the money value.
func (m *Money) String() string {
	return m.Format()
}

// MarshalJSON implements json.Marshaler interface.
func (m *Money) MarshalJSON() ([]byte, error) {
	// For JSON serialization, we can include both integer and decimal representations
	type MoneyJSON struct {
		Amount   int64    `json:"amount"`   // Integer amount
		Decimal  float64  `json:"decimal"`  // Decimal representation
		Currency Currency `json:"currency"` // Currency information
	}

	moneyJSON := MoneyJSON{
		Amount:   m.Amount,
		Decimal:  m.ToDecimal(),
		Currency: m.Currency,
	}

	return json.Marshal(moneyJSON)
}

// UnmarshalJSON implements json.Unmarshaler interface.
func (m *Money) UnmarshalJSON(data []byte) error {
	// Try the custom format first (with both amount and decimal fields)
	var customMoney struct {
		Amount   int64    `json:"amount"`
		Decimal  float64  `json:"decimal"`
		Currency Currency `json:"currency"`
	}

	if err := json.Unmarshal(data, &customMoney); err == nil {
		// Use the integer amount directly
		newMoney, err := NewMoneyFromInteger(customMoney.Amount, customMoney.Currency)
		if err != nil {
			return err
		}
		*m = *newMoney
		return nil
	}

	// For backward compatibility, try to unmarshal as decimal first
	var decimalMoney struct {
		Amount   float64  `json:"amount"`
		Currency Currency `json:"currency"`
	}

	if err := json.Unmarshal(data, &decimalMoney); err == nil {
		// Convert from decimal format
		newMoney, err := NewMoneyFromDecimal(decimalMoney.Amount, decimalMoney.Currency)
		if err != nil {
			return err
		}
		*m = *newMoney
		return nil
	}

	// Try integer format
	var integerMoney struct {
		Amount   int64    `json:"amount"`
		Currency Currency `json:"currency"`
	}

	if err := json.Unmarshal(data, &integerMoney); err != nil {
		return fmt.Errorf("failed to unmarshal money: %w", err)
	}

	newMoney, err := NewMoneyFromInteger(integerMoney.Amount, integerMoney.Currency)
	if err != nil {
		return err
	}
	*m = *newMoney
	return nil
}
