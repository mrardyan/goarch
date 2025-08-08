// Package internationalization provides domain types and composite types for handling
// internationalized data such as time, currency, timezone, and phone numbers.
// This file contains the LocalizedDateTime composite type for timezone-aware operations.
//
// LocalizedDateTime Composite Type:
//   - Combines time with timezone for timezone-aware operations
//   - Duration calculations and comparisons
//   - Database storage as primitive values
//   - Automatic timezone conversion and validation
//
// Database Storage: (epoch int64, timezone_id string)
// JSON Format: {"time": {"epoch": 1703520000}, "timezone": {"id": "America/New_York", "name": "Eastern Time", "offset": -300}}
//
// Usage Examples:
//
//	timeValue := NewTimeFromTime(time.Now())
//	timezone, _ := NewTimezoneFromID("America/New_York")
//	ldt, err := NewLocalizedDateTime(*timeValue, *timezone)
//	formatted := ldt.Format("2006-01-02 15:04:05") // "2023-12-25 10:30:00"
package internationalization

import (
	"fmt"
	"time"
)

// LocalizedDateTime represents a date and time with an associated timezone.
// This composite type combines a Time type with a Timezone for timezone-aware
// datetime operations and display formatting.
//
// Features:
//   - Timezone-aware time operations and formatting
//   - Duration calculations and comparisons
//   - Database storage as primitive values
//   - Automatic timezone conversion and validation
//
// Database Storage: (epoch int64, timezone_id string)
// JSON Format: {"time": {"epoch": 1703520000}, "timezone": {"id": "America/New_York", "name": "Eastern Time", "offset": -300}}
//
// Example:
//
//	timeValue := NewTimeFromTime(time.Now())
//	timezone, _ := NewTimezoneFromID("America/New_York")
//	ldt, err := NewLocalizedDateTime(*timeValue, *timezone)
//	formatted := ldt.Format("2006-01-02 15:04:05") // "2023-12-25 10:30:00"
type LocalizedDateTime struct {
	Time     Time     `json:"time"`     // The time value
	Timezone Timezone `json:"timezone"` // Associated timezone
}

// NewLocalizedDateTime creates a new LocalizedDateTime composite type.
// Returns an error if the time or timezone is invalid.
func NewLocalizedDateTime(time Time, timezone Timezone) (*LocalizedDateTime, error) {
	if err := time.Validate(); err != nil {
		return nil, fmt.Errorf("invalid time in localized datetime: %w", err)
	}

	if err := timezone.Validate(); err != nil {
		return nil, fmt.Errorf("invalid timezone in localized datetime: %w", err)
	}

	return &LocalizedDateTime{
		Time:     time,
		Timezone: timezone,
	}, nil
}

// NewLocalizedDateTimeFromPrimitive creates a LocalizedDateTime from primitive database values.
// The time is stored as epoch int64 and timezone as string ID.
func NewLocalizedDateTimeFromPrimitive(epoch int64, timezoneID string) (*LocalizedDateTime, error) {
	time, err := FromPrimitive(epoch)
	if err != nil {
		return nil, fmt.Errorf("failed to create localized datetime from primitive: %w", err)
	}

	timezone, err := NewTimezoneFromID(timezoneID)
	if err != nil {
		return nil, fmt.Errorf("failed to create localized datetime from primitive: %w", err)
	}

	return &LocalizedDateTime{
		Time:     *time,
		Timezone: *timezone,
	}, nil
}

// ToPrimitive converts the LocalizedDateTime to primitive database values.
// Returns the time as epoch int64 and timezone as string ID.
func (ldt *LocalizedDateTime) ToPrimitive() (int64, string) {
	return ldt.Time.ToPrimitive(), ldt.Timezone.ToPrimitive()
}

// Validate ensures the LocalizedDateTime composite type is valid.
func (ldt *LocalizedDateTime) Validate() error {
	if err := ldt.Time.Validate(); err != nil {
		return fmt.Errorf("invalid time in localized datetime: %w", err)
	}

	if err := ldt.Timezone.Validate(); err != nil {
		return fmt.Errorf("invalid timezone in localized datetime: %w", err)
	}

	return nil
}

// Format returns a formatted string representation of the localized datetime.
// Uses the provided layout string and the associated timezone.
func (ldt *LocalizedDateTime) Format(layout string) string {
	return ldt.Time.Format(layout, &ldt.Timezone)
}

// ToTime returns the time.Time representation in the associated timezone.
func (ldt *LocalizedDateTime) ToTime() time.Time {
	// Create a fixed timezone using the offset
	loc := time.FixedZone(ldt.Timezone.ID, ldt.Timezone.Offset*60) // Convert minutes to seconds
	return ldt.Time.ToTime().In(loc)
}

// ToUTC returns the time.Time representation in UTC.
func (ldt *LocalizedDateTime) ToUTC() time.Time {
	return ldt.Time.ToTime().UTC()
}

// Add adds a duration to the localized datetime and returns a new LocalizedDateTime.
func (ldt *LocalizedDateTime) Add(duration time.Duration) *LocalizedDateTime {
	newTime := ldt.Time.ToTime().Add(duration)
	newTimeValue := NewTimeFromTime(newTime)

	return &LocalizedDateTime{
		Time:     *newTimeValue,
		Timezone: ldt.Timezone,
	}
}

// Subtract subtracts a duration from the localized datetime and returns a new LocalizedDateTime.
func (ldt *LocalizedDateTime) Subtract(duration time.Duration) *LocalizedDateTime {
	return ldt.Add(-duration)
}

// IsBefore returns true if this localized datetime is before the other.
func (ldt *LocalizedDateTime) IsBefore(other *LocalizedDateTime) bool {
	return ldt.Time.ToTime().Before(other.Time.ToTime())
}

// IsAfter returns true if this localized datetime is after the other.
func (ldt *LocalizedDateTime) IsAfter(other *LocalizedDateTime) bool {
	return ldt.Time.ToTime().After(other.Time.ToTime())
}

// IsEqual returns true if this localized datetime equals the other.
func (ldt *LocalizedDateTime) IsEqual(other *LocalizedDateTime) bool {
	if other == nil {
		return false
	}
	return ldt.Time.ToTime().Equal(other.Time.ToTime())
}

// Duration returns the duration between this localized datetime and another.
func (ldt *LocalizedDateTime) Duration(other *LocalizedDateTime) time.Duration {
	return ldt.Time.ToTime().Sub(other.Time.ToTime())
}
