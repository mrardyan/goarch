// Package internationalization provides domain types and composite types for handling
// internationalized data such as time, currency, timezone, and phone numbers.
// This file contains the LocalizedPhone composite type for phone number localization.
//
// LocalizedPhone Composite Type:
//   - Combines phone with country information and timezone
//   - Phone number validation and formatting
//   - Country and region information
//   - Associated timezone for call timing
//   - Location-based comparisons and grouping
//
// Database Storage: (phone string, country string, region string, timezone_id string)
// JSON Format: {"phone": {"country_code": "1", "number": "5551234567"}, "country": "United States", "region": "New York", "timezone": {"id": "America/New_York", "name": "Eastern Time", "offset": -300}}
//
// Usage Examples:
//
//	phone, _ := NewPhone("1", "5551234567")
//	timezone, _ := NewTimezoneFromID("America/New_York")
//	lp, err := NewLocalizedPhone(*phone, "United States", "New York", *timezone)
//	formatted := lp.Format() // "+1 5551234567"
//	location := lp.GetFullLocation() // "New York, United States"
package internationalization

import (
	"fmt"
)

// LocalizedPhone represents a phone number with country information.
// This composite type combines a Phone type with additional localization
// information for better phone number handling.
//
// Features:
//   - Phone number validation and formatting
//   - Country and region information
//   - Associated timezone for call timing
//   - Location-based comparisons and grouping
//   - Database storage as primitive values
//
// Database Storage: (phone string, country string, region string, timezone_id string)
// JSON Format: {"phone": {"country_code": "1", "number": "5551234567"}, "country": "United States", "region": "New York", "timezone": {"id": "America/New_York", "name": "Eastern Time", "offset": -300}}
//
// Example:
//
//	phone, _ := NewPhone("1", "5551234567")
//	timezone, _ := NewTimezoneFromID("America/New_York")
//	lp, err := NewLocalizedPhone(*phone, "United States", "New York", *timezone)
//	formatted := lp.Format() // "+1 5551234567"
//	location := lp.GetFullLocation() // "New York, United States"
type LocalizedPhone struct {
	Phone    Phone    `json:"phone"`    // The phone number
	Country  string   `json:"country"`  // Country name
	Region   string   `json:"region"`   // Region/state (optional)
	Timezone Timezone `json:"timezone"` // Associated timezone
}

// NewLocalizedPhone creates a new LocalizedPhone composite type.
// Returns an error if the phone or timezone is invalid.
func NewLocalizedPhone(phone Phone, country string, region string, timezone Timezone) (*LocalizedPhone, error) {
	if err := phone.Validate(); err != nil {
		return nil, fmt.Errorf("invalid phone in localized phone: %w", err)
	}

	if err := timezone.Validate(); err != nil {
		return nil, fmt.Errorf("invalid timezone in localized phone: %w", err)
	}

	if country == "" {
		return nil, fmt.Errorf("country cannot be empty")
	}

	return &LocalizedPhone{
		Phone:    phone,
		Country:  country,
		Region:   region,
		Timezone: timezone,
	}, nil
}

// NewLocalizedPhoneFromPrimitive creates a LocalizedPhone from primitive database values.
func NewLocalizedPhoneFromPrimitive(phoneStr, country, region, timezoneID string) (*LocalizedPhone, error) {
	phone, err := FromPrimitivePhone(phoneStr)
	if err != nil {
		return nil, fmt.Errorf("failed to create localized phone from primitive: %w", err)
	}

	timezone, err := NewTimezoneFromID(timezoneID)
	if err != nil {
		return nil, fmt.Errorf("failed to create localized phone from primitive: %w", err)
	}

	return NewLocalizedPhone(*phone, country, region, *timezone)
}

// ToPrimitive converts the LocalizedPhone to primitive database values.
func (lp *LocalizedPhone) ToPrimitive() (string, string, string, string) {
	return lp.Phone.ToPrimitive(), lp.Country, lp.Region, lp.Timezone.ToPrimitive()
}

// Validate ensures the LocalizedPhone composite type is valid.
func (lp *LocalizedPhone) Validate() error {
	if err := lp.Phone.Validate(); err != nil {
		return fmt.Errorf("invalid phone in localized phone: %w", err)
	}

	if err := lp.Timezone.Validate(); err != nil {
		return fmt.Errorf("invalid timezone in localized phone: %w", err)
	}

	if lp.Country == "" {
		return fmt.Errorf("country cannot be empty")
	}

	return nil
}

// Format returns a formatted string representation of the localized phone.
func (lp *LocalizedPhone) Format() string {
	return lp.Phone.Format()
}

// GetFullLocation returns the full location string (Country, Region).
func (lp *LocalizedPhone) GetFullLocation() string {
	if lp.Region != "" {
		return fmt.Sprintf("%s, %s", lp.Region, lp.Country)
	}
	return lp.Country
}

// IsSameCountry returns true if this phone is from the same country as the other.
func (lp *LocalizedPhone) IsSameCountry(other *LocalizedPhone) bool {
	if other == nil {
		return false
	}
	return lp.Country == other.Country
}

// IsSameRegion returns true if this phone is from the same region as the other.
func (lp *LocalizedPhone) IsSameRegion(other *LocalizedPhone) bool {
	if other == nil {
		return false
	}
	return lp.Country == other.Country && lp.Region == other.Region
}
