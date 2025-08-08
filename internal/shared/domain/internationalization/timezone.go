// Package internationalization provides domain types for handling internationalization
// concerns such as time, currency, timezone, and phone number formatting.
//
// The Timezone type represents a timezone using IANA identifiers for accurate
// timezone calculations and formatting.
//
// Database Storage: Stored as string (IANA identifier)
// Validation: Must be a valid IANA timezone identifier
// Usage: Use for timezone-aware operations across the application
package internationalization

import (
	"fmt"
	"strings"
	"time"
)

// Timezone represents a timezone using IANA identifier.
// This type provides timezone-aware operations and offset calculations.
type Timezone struct {
	ID     string `json:"id"`     // IANA identifier (e.g., "America/New_York")
	Name   string `json:"name"`   // Display name (e.g., "Eastern Time")
	Offset int    `json:"offset"` // UTC offset in minutes
}

// NewTimezone creates a new Timezone instance with validation.
func NewTimezone(id, name string, offset int) (*Timezone, error) {
	tz := &Timezone{
		ID:     id,
		Name:   name,
		Offset: offset,
	}

	if err := tz.Validate(); err != nil {
		return nil, fmt.Errorf("invalid timezone: %w", err)
	}

	return tz, nil
}

// NewTimezoneFromID creates a Timezone instance from IANA identifier.
func NewTimezoneFromID(id string) (*Timezone, error) {
	if id == "" {
		return nil, fmt.Errorf("timezone ID cannot be empty")
	}

	// Try to load the location to validate it
	loc, err := time.LoadLocation(id)
	if err != nil {
		return nil, fmt.Errorf("unsupported timezone ID: %s", id)
	}

	// Get the offset for the current time
	now := time.Now()
	_, offset := now.In(loc).Zone()

	return &Timezone{
		ID:     id,
		Name:   getTimezoneDisplayName(id),
		Offset: offset / 60, // Convert seconds to minutes
	}, nil
}

// ToPrimitive returns the primitive value for database storage.
func (tz *Timezone) ToPrimitive() string {
	return tz.ID
}

// FromPrimitive creates a Timezone instance from primitive database value.
func FromPrimitiveTimezone(id string) (*Timezone, error) {
	return NewTimezoneFromID(id)
}

// Validate ensures the timezone ID is valid and offset is reasonable.
func (tz *Timezone) Validate() error {
	if tz.ID == "" {
		return fmt.Errorf("timezone ID cannot be empty")
	}

	if tz.Name == "" {
		return fmt.Errorf("timezone name cannot be empty")
	}

	// Try to load the location to validate it
	_, err := time.LoadLocation(tz.ID)
	if err != nil {
		return fmt.Errorf("unsupported timezone ID: %s", tz.ID)
	}

	// Validate offset range (-1440 to 1440 minutes = -24 to +24 hours, excluding the extremes)
	if tz.Offset <= -1440 || tz.Offset >= 1440 {
		return fmt.Errorf("timezone offset must be between -1440 and 1440 minutes, got %d", tz.Offset)
	}

	return nil
}

// GetOffset returns the timezone offset as time.Duration.
func (tz *Timezone) GetOffset() time.Duration {
	return time.Duration(tz.Offset) * time.Minute
}

// GetLocation returns the time.Location for this timezone.
func (tz *Timezone) GetLocation() (*time.Location, error) {
	return time.LoadLocation(tz.ID)
}

// FormatOffset returns the offset formatted as "+/-HH:MM".
func (tz *Timezone) FormatOffset() string {
	hours := tz.Offset / 60
	minutes := tz.Offset % 60

	if minutes < 0 {
		minutes = -minutes
	}

	if tz.Offset >= 0 {
		return fmt.Sprintf("+%02d:%02d", hours, minutes)
	}
	return fmt.Sprintf("-%02d:%02d", -hours, minutes)
}

// Equal returns true if two Timezone instances represent the same timezone.
func (tz *Timezone) Equal(other *Timezone) bool {
	if tz == nil || other == nil {
		return tz == other
	}
	return tz.ID == other.ID
}

// String returns a formatted string representation of the timezone.
func (tz *Timezone) String() string {
	return fmt.Sprintf("%s (%s) %s", tz.ID, tz.Name, tz.FormatOffset())
}

// getTimezoneDisplayName returns a human-readable name for the timezone.
func getTimezoneDisplayName(id string) string {
	// Common timezone display names
	displayNames := map[string]string{
		"UTC":                 "Coordinated Universal Time",
		"America/New_York":    "Eastern Time",
		"America/Chicago":     "Central Time",
		"America/Denver":      "Mountain Time",
		"America/Los_Angeles": "Pacific Time",
		"Europe/London":       "Greenwich Mean Time",
		"Europe/Paris":        "Central European Time",
		"Asia/Tokyo":          "Japan Standard Time",
		"Asia/Shanghai":       "China Standard Time",
		"Australia/Sydney":    "Australian Eastern Time",
	}

	if name, exists := displayNames[id]; exists {
		return name
	}

	// Fallback: convert ID to display name
	parts := strings.Split(id, "/")
	if len(parts) > 1 {
		return strings.ReplaceAll(parts[len(parts)-1], "_", " ")
	}

	return id
}
