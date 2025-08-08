// Package internationalization provides domain types for handling internationalization
// concerns such as time, currency, timezone, and phone number formatting.
//
// The Currency type represents a currency using ISO 4217 codes for consistent
// currency handling across the application. Now includes decimal places for
// integer-based money storage to eliminate floating-point precision errors.
//
// Database Storage: Stored as string (ISO 4217 code)
// Validation: Must be a valid 3-character ISO 4217 code with valid decimal places
// Usage: Use for currency-related operations across the application
package internationalization

import (
	"fmt"
	"strings"
)

// Currency represents a currency using ISO 4217 code with decimal precision.
// This type provides currency formatting and validation capabilities for
// integer-based money storage to ensure financial precision.
type Currency struct {
	Code          string `json:"code"`           // ISO 4217 code (e.g., "USD")
	Symbol        string `json:"symbol"`         // Display symbol (e.g., "$")
	Name          string `json:"name"`           // Full name (e.g., "US Dollar")
	DecimalPlaces int    `json:"decimal_places"` // Number of decimal places (e.g., 2 for USD)
}

// CurrencyPrecisions defines the decimal places for common currencies.
// This mapping is used for integer-based money storage where amounts are
// stored in the smallest currency unit (e.g., cents for USD).
var CurrencyPrecisions = map[string]int{
	"USD": 2,  // $1.00 = 100 cents
	"EUR": 2,  // €1.00 = 100 cents
	"GBP": 2,  // £1.00 = 100 pence
	"JPY": 0,  // ¥100 = 100 yen (no decimals)
	"CAD": 2,  // C$1.00 = 100 cents
	"AUD": 2,  // A$1.00 = 100 cents
	"CHF": 2,  // CHF 1.00 = 100 centimes
	"CNY": 2,  // ¥1.00 = 100 fen
	"INR": 2,  // ₹1.00 = 100 paise
	"BRL": 2,  // R$1.00 = 100 centavos
	"KRW": 0,  // ₩100 = 100 won (no decimals)
	"MXN": 2,  // $1.00 = 100 centavos
	"SGD": 2,  // S$1.00 = 100 cents
	"HKD": 2,  // HK$1.00 = 100 cents
	"NZD": 2,  // NZ$1.00 = 100 cents
	"SEK": 2,  // kr 1.00 = 100 öre
	"NOK": 2,  // kr 1.00 = 100 øre
	"DKK": 2,  // kr 1.00 = 100 øre
	"PLN": 2,  // zł 1.00 = 100 groszy
	"CZK": 2,  // Kč 1.00 = 100 haléřů
	"HUF": 0,  // Ft 100 = 100 forint (no decimals)
	"RUB": 2,  // ₽1.00 = 100 kopecks
	"TRY": 2,  // ₺1.00 = 100 kuruş
	"ZAR": 2,  // R 1.00 = 100 cents
	"ILS": 2,  // ₪1.00 = 100 agorot
	"SAR": 2,  // ﷼1.00 = 100 halalas
	"AED": 2,  // د.إ1.00 = 100 fils
	"THB": 2,  // ฿1.00 = 100 satang
	"MYR": 2,  // RM 1.00 = 100 sen
	"IDR": 0,  // Rp 100 = 100 rupiah (no decimals)
	"PHP": 2,  // ₱1.00 = 100 centavos
	"VND": 0,  // ₫100 = 100 dong (no decimals)
	"BTC": 8,  // 1 BTC = 100,000,000 satoshis
	"ETH": 18, // 1 ETH = 1,000,000,000,000,000,000 wei
}

// NewCurrency creates a new Currency instance with validation.
func NewCurrency(code, symbol, name string, decimalPlaces int) (*Currency, error) {
	currency := &Currency{
		Code:          strings.ToUpper(code),
		Symbol:        symbol,
		Name:          name,
		DecimalPlaces: decimalPlaces,
	}

	if err := currency.Validate(); err != nil {
		return nil, fmt.Errorf("invalid currency: %w", err)
	}

	return currency, nil
}

// NewCurrencyFromCode creates a Currency instance from ISO 4217 code.
func NewCurrencyFromCode(code string) (*Currency, error) {
	code = strings.ToUpper(code)

	// Common currencies with their symbols, names, and decimal places
	currencies := map[string]struct {
		symbol        string
		name          string
		decimalPlaces int
	}{
		"USD": {"$", "US Dollar", 2},
		"EUR": {"€", "Euro", 2},
		"GBP": {"£", "British Pound", 2},
		"JPY": {"¥", "Japanese Yen", 0},
		"CAD": {"C$", "Canadian Dollar", 2},
		"AUD": {"A$", "Australian Dollar", 2},
		"CHF": {"CHF", "Swiss Franc", 2},
		"CNY": {"¥", "Chinese Yuan", 2},
		"INR": {"₹", "Indian Rupee", 2},
		"BRL": {"R$", "Brazilian Real", 2},
		"KRW": {"₩", "South Korean Won", 0},
		"MXN": {"$", "Mexican Peso", 2},
		"SGD": {"S$", "Singapore Dollar", 2},
		"HKD": {"HK$", "Hong Kong Dollar", 2},
		"NZD": {"NZ$", "New Zealand Dollar", 2},
		"SEK": {"kr", "Swedish Krona", 2},
		"NOK": {"kr", "Norwegian Krone", 2},
		"DKK": {"kr", "Danish Krone", 2},
		"PLN": {"zł", "Polish Złoty", 2},
		"CZK": {"Kč", "Czech Koruna", 2},
		"HUF": {"Ft", "Hungarian Forint", 0},
		"RUB": {"₽", "Russian Ruble", 2},
		"TRY": {"₺", "Turkish Lira", 2},
		"ZAR": {"R", "South African Rand", 2},
		"ILS": {"₪", "Israeli Shekel", 2},
		"SAR": {"", "Saudi Riyal", 2},
		"AED": {"د.إ", "UAE Dirham", 2},
		"THB": {"฿", "Thai Baht", 2},
		"MYR": {"RM", "Malaysian Ringgit", 2},
		"IDR": {"Rp", "Indonesian Rupiah", 0},
		"PHP": {"₱", "Philippine Peso", 2},
		"VND": {"₫", "Vietnamese Dong", 0},
		"BTC": {"₿", "Bitcoin", 8},
		"ETH": {"Ξ", "Ethereum", 18},
	}

	currencyInfo, exists := currencies[code]
	if !exists {
		return nil, fmt.Errorf("unsupported currency code: %s", code)
	}

	return &Currency{
		Code:          code,
		Symbol:        currencyInfo.symbol,
		Name:          currencyInfo.name,
		DecimalPlaces: currencyInfo.decimalPlaces,
	}, nil
}

// ToPrimitive returns the primitive value for database storage.
func (c *Currency) ToPrimitive() string {
	return c.Code
}

// FromPrimitive creates a Currency instance from primitive database value.
func FromPrimitiveCurrency(code string) (*Currency, error) {
	return NewCurrencyFromCode(code)
}

// Validate ensures the currency code is valid and follows ISO 4217 standard.
func (c *Currency) Validate() error {
	if c.Code == "" {
		return fmt.Errorf("currency code cannot be empty")
	}

	if len(c.Code) != 3 {
		return fmt.Errorf("currency code must be exactly 3 characters, got %d", len(c.Code))
	}

	// Check if code contains only letters
	for _, char := range c.Code {
		if char < 'A' || char > 'Z' {
			return fmt.Errorf("currency code must contain only uppercase letters, got %c", char)
		}
	}

	if c.Symbol == "" {
		return fmt.Errorf("currency symbol cannot be empty")
	}

	if c.Name == "" {
		return fmt.Errorf("currency name cannot be empty")
	}

	// Validate decimal places
	if c.DecimalPlaces < 0 || c.DecimalPlaces > 18 {
		return fmt.Errorf("decimal places must be between 0 and 18, got %d", c.DecimalPlaces)
	}

	return nil
}

// GetDecimalPlaces returns the number of decimal places for this currency.
func (c *Currency) GetDecimalPlaces() int {
	return c.DecimalPlaces
}

// Format formats an amount with the currency symbol using integer-based storage.
// The amount parameter should be the integer value in the smallest currency unit.
func (c *Currency) Format(amount int64) string {
	if c.DecimalPlaces == 0 {
		return fmt.Sprintf("%s%d", c.Symbol, amount)
	}

	// Convert integer to decimal representation
	decimal := float64(amount) / float64(pow10(c.DecimalPlaces))
	return fmt.Sprintf("%s%.*f", c.Symbol, c.DecimalPlaces, decimal)
}

// FormatWithCode formats an amount with the currency code using integer-based storage.
func (c *Currency) FormatWithCode(amount int64) string {
	if c.DecimalPlaces == 0 {
		return fmt.Sprintf("%d %s", amount, c.Code)
	}

	decimal := float64(amount) / float64(pow10(c.DecimalPlaces))
	return fmt.Sprintf("%.*f %s", c.DecimalPlaces, decimal, c.Code)
}

// FormatWithName formats an amount with the currency name using integer-based storage.
func (c *Currency) FormatWithName(amount int64) string {
	if c.DecimalPlaces == 0 {
		return fmt.Sprintf("%d %s", amount, c.Name)
	}

	decimal := float64(amount) / float64(pow10(c.DecimalPlaces))
	return fmt.Sprintf("%.*f %s", c.DecimalPlaces, decimal, c.Name)
}

// FormatDecimal formats a decimal amount with the currency symbol.
// This is for backward compatibility and external API usage.
func (c *Currency) FormatDecimal(amount float64) string {
	return fmt.Sprintf("%s%.*f", c.Symbol, c.DecimalPlaces, amount)
}

// Equal returns true if two Currency instances represent the same currency.
func (c *Currency) Equal(other *Currency) bool {
	if c == nil || other == nil {
		return c == other
	}
	return c.Code == other.Code
}

// String returns the currency code.
func (c *Currency) String() string {
	return c.Code
}

// IsSupported returns true if the currency code is supported.
func IsSupported(code string) bool {
	_, err := NewCurrencyFromCode(code)
	return err == nil
}

// GetSupportedCurrencies returns a list of supported currency codes.
func GetSupportedCurrencies() []string {
	return []string{
		"USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "BRL",
		"KRW", "MXN", "SGD", "HKD", "NZD", "SEK", "NOK", "DKK", "PLN", "CZK",
		"HUF", "RUB", "TRY", "ZAR", "ILS", "SAR", "AED", "THB", "MYR", "IDR",
		"PHP", "VND", "BTC", "ETH",
	}
}

// pow10 returns 10 raised to the power of n.
// This is used for decimal place calculations in integer-based money.
func pow10(n int) int64 {
	result := int64(1)
	for i := 0; i < n; i++ {
		result *= 10
	}
	return result
}
