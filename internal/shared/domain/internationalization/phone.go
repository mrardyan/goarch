// Package internationalization provides domain types for handling internationalization
// concerns such as time, currency, timezone, and phone number formatting.
//
// The Phone type represents a phone number with country code for consistent
// phone number handling across the application.
//
// Database Storage: Stored as string (formatted phone number)
// Validation: Must have valid country code and number format
// Usage: Use for phone number operations across the application
package internationalization

import (
	"fmt"
	"regexp"
	"strings"
)

// Phone represents a phone number with country code.
// This type provides phone number formatting and validation capabilities.
type Phone struct {
	CountryCode string `json:"country_code"` // Country code (e.g., "1" for US)
	Number      string `json:"number"`       // Phone number without country code
}

// NewPhone creates a new Phone instance with validation.
func NewPhone(countryCode, number string) (*Phone, error) {
	phone := &Phone{
		CountryCode: strings.TrimSpace(countryCode),
		Number:      strings.TrimSpace(number),
	}

	if err := phone.Validate(); err != nil {
		return nil, fmt.Errorf("invalid phone number: %w", err)
	}

	return phone, nil
}

// NewPhoneFromString creates a Phone instance from a formatted string.
func NewPhoneFromString(phoneStr string) (*Phone, error) {
	// Remove all spaces and trim
	cleanStr := strings.ReplaceAll(strings.TrimSpace(phoneStr), " ", "")

	// Handle different formats
	if strings.HasPrefix(cleanStr, "+") {
		// International format: +1234567890
		return parseInternationalFormat(cleanStr)
	} else if strings.HasPrefix(cleanStr, "00") {
		// International format with 00: 001234567890
		return parseInternationalFormat("+" + cleanStr[2:])
	} else {
		// Assume local format, try to detect country code
		return parseLocalFormat(cleanStr)
	}
}

// ToPrimitive returns the primitive value for database storage.
func (p *Phone) ToPrimitive() string {
	return p.Format()
}

// FromPrimitive creates a Phone instance from primitive database value.
func FromPrimitivePhone(phoneStr string) (*Phone, error) {
	return NewPhoneFromString(phoneStr)
}

// Validate ensures the phone number has valid country code and number format.
func (p *Phone) Validate() error {
	if p.CountryCode == "" {
		return fmt.Errorf("country code cannot be empty")
	}

	if p.Number == "" {
		return fmt.Errorf("phone number cannot be empty")
	}

	// Validate country code (1-3 digits)
	countryCodeRegex := regexp.MustCompile(`^[1-9]\d{0,2}$`)
	if !countryCodeRegex.MatchString(p.CountryCode) {
		return fmt.Errorf("invalid country code: %s", p.CountryCode)
	}

	// Validate phone number (7-15 digits)
	numberRegex := regexp.MustCompile(`^\d{7,15}$`)
	if !numberRegex.MatchString(p.Number) {
		return fmt.Errorf("invalid phone number format: %s", p.Number)
	}

	return nil
}

// Format returns the phone number in international format.
func (p *Phone) Format() string {
	return fmt.Sprintf("+%s %s", p.CountryCode, p.Number)
}

// FormatCompact returns the phone number in compact international format.
func (p *Phone) FormatCompact() string {
	return fmt.Sprintf("+%s%s", p.CountryCode, p.Number)
}

// FormatLocal returns the phone number in local format (with dashes for US numbers).
func (p *Phone) FormatLocal() string {
	// For US numbers (country code 1), format with dashes
	if p.CountryCode == "1" && len(p.Number) == 10 {
		return fmt.Sprintf("%s-%s-%s", p.Number[:3], p.Number[3:6], p.Number[6:])
	}

	// For other numbers, just return the number
	return p.Number
}

// Equal returns true if two Phone instances represent the same phone number.
func (p *Phone) Equal(other *Phone) bool {
	if p == nil || other == nil {
		return p == other
	}
	return p.CountryCode == other.CountryCode && p.Number == other.Number
}

// String returns the phone number in international format.
func (p *Phone) String() string {
	return p.Format()
}

// GetCountryCode returns the country code.
func (p *Phone) GetCountryCode() string {
	return p.CountryCode
}

// GetNumber returns the phone number without country code.
func (p *Phone) GetNumber() string {
	return p.Number
}

// parseInternationalFormat parses phone number in international format (+1234567890).
func parseInternationalFormat(phoneStr string) (*Phone, error) {
	// Remove the + sign
	phoneStr = strings.TrimPrefix(phoneStr, "+")

	// Try to match country codes from longest to shortest
	// This ensures we don't match "155" when we should match "1"
	countryCodes := []string{"852", "972", "966", "971", "420", "1", "44", "33", "49", "81", "86", "91", "55", "61", "7", "82", "52", "65", "64", "46", "47", "45", "48", "36", "90", "27", "66", "60", "62", "63", "84"}

	for _, code := range countryCodes {
		if strings.HasPrefix(phoneStr, code) {
			number := phoneStr[len(code):]
			if len(number) >= 7 && len(number) <= 15 {
				return NewPhone(code, number)
			}
		}
	}

	return nil, fmt.Errorf("invalid international phone format: %s", phoneStr)
}

// parseLocalFormat attempts to parse local format and detect country code.
func parseLocalFormat(phoneStr string) (*Phone, error) {
	// Remove all non-digit characters
	digits := regexp.MustCompile(`\D`).ReplaceAllString(phoneStr, "")

	if len(digits) < 7 || len(digits) > 15 {
		return nil, fmt.Errorf("invalid phone number length: %d", len(digits))
	}

	// For 10-digit numbers, assume US (+1) as they are typically US numbers
	if len(digits) == 10 {
		return NewPhone("1", digits)
	}

	// Try common country codes
	commonCountryCodes := []string{"1", "44", "33", "49", "81", "86", "91", "55", "61", "7"}

	for _, code := range commonCountryCodes {
		if strings.HasPrefix(digits, code) {
			number := digits[len(code):]
			if len(number) >= 7 {
				return NewPhone(code, number)
			}
		}
	}

	// If no common country code matches, assume US (+1)
	if len(digits) >= 10 {
		return NewPhone("1", digits)
	}

	return nil, fmt.Errorf("unable to parse phone number: %s", phoneStr)
}

// IsValidPhoneNumber checks if a string is a valid phone number.
func IsValidPhoneNumber(phoneStr string) bool {
	_, err := NewPhoneFromString(phoneStr)
	return err == nil
}

// GetSupportedCountryCodes returns a list of supported country codes.
func GetSupportedCountryCodes() []string {
	return []string{
		"1",   // US/Canada
		"44",  // UK
		"33",  // France
		"49",  // Germany
		"81",  // Japan
		"86",  // China
		"91",  // India
		"55",  // Brazil
		"61",  // Australia
		"7",   // Russia
		"82",  // South Korea
		"52",  // Mexico
		"65",  // Singapore
		"852", // Hong Kong
		"64",  // New Zealand
		"46",  // Sweden
		"47",  // Norway
		"45",  // Denmark
		"48",  // Poland
		"420", // Czech Republic
		"36",  // Hungary
		"90",  // Turkey
		"27",  // South Africa
		"972", // Israel
		"966", // Saudi Arabia
		"971", // UAE
		"66",  // Thailand
		"60",  // Malaysia
		"62",  // Indonesia
		"63",  // Philippines
		"84",  // Vietnam
	}
}
