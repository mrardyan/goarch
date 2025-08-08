// Package internationalization provides domain types for handling internationalization
// concerns such as time, currency, timezone, and phone number formatting.
//
// The Time type represents a point in time using epoch time (Unix timestamp)
// for efficient database storage and timezone-aware operations.
package internationalization

import (
	"fmt"
	"time"
)

// Time represents a point in time using epoch time (Unix timestamp in seconds).
// This type is designed for efficient database storage and provides timezone-aware
// formatting capabilities.
//
// Database Storage: Stored as int64 (epoch time)
// Validation: Epoch time must be within reasonable range (1970-2100)
// Usage: Use for all time-related operations across the application
type Time struct {
	Epoch int64 `json:"epoch"` // Unix timestamp in seconds
}

// NewTime creates a new Time instance from epoch time with validation.
func NewTime(epoch int64) (*Time, error) {
	t := &Time{Epoch: epoch}
	if err := t.Validate(); err != nil {
		return nil, fmt.Errorf("invalid time: %w", err)
	}
	return t, nil
}

// NewTimeFromTime creates a new Time instance from time.Time.
func NewTimeFromTime(t time.Time) *Time {
	return &Time{Epoch: t.Unix()}
}

// ToTime converts Time to time.Time.
func (t *Time) ToTime() time.Time {
	return time.Unix(t.Epoch, 0)
}

// ToPrimitive returns the primitive value for database storage.
func (t *Time) ToPrimitive() int64 {
	return t.Epoch
}

// FromPrimitive creates a Time instance from primitive database value.
func FromPrimitive(epoch int64) (*Time, error) {
	return NewTime(epoch)
}

// Validate ensures the epoch time is within a reasonable range.
func (t *Time) Validate() error {
	// Check if epoch is within reasonable range (1970-2100)
	minEpoch := time.Date(1970, 1, 1, 0, 0, 0, 0, time.UTC).Unix()
	maxEpoch := time.Date(2100, 12, 31, 23, 59, 59, 0, time.UTC).Unix()

	if t.Epoch < minEpoch {
		return fmt.Errorf("epoch time too early: %d (minimum: %d)", t.Epoch, minEpoch)
	}
	if t.Epoch > maxEpoch {
		return fmt.Errorf("epoch time too late: %d (maximum: %d)", t.Epoch, maxEpoch)
	}

	return nil
}

// Format formats the time according to the specified layout and timezone.
// If timezone is nil, UTC is used.
func (t *Time) Format(layout string, tz *Timezone) string {
	timeValue := t.ToTime()

	if tz != nil {
		// Create a fixed timezone using the offset
		loc := time.FixedZone(tz.ID, tz.Offset*60) // Convert minutes to seconds
		timeValue = timeValue.In(loc)
	} else {
		// Use UTC when timezone is nil
		timeValue = timeValue.UTC()
	}

	return timeValue.Format(layout)
}

// FormatUTC formats the time in UTC timezone.
func (t *Time) FormatUTC(layout string) string {
	return t.ToTime().UTC().Format(layout)
}

// FormatLocal formats the time in local timezone.
func (t *Time) FormatLocal(layout string) string {
	return t.ToTime().Local().Format(layout)
}

// IsZero returns true if the time is zero (epoch 0).
func (t *Time) IsZero() bool {
	return t.Epoch == 0
}

// Equal returns true if two Time instances represent the same moment.
func (t *Time) Equal(other *Time) bool {
	if t == nil || other == nil {
		return t == other
	}
	return t.Epoch == other.Epoch
}

// Before returns true if this time is before the other time.
func (t *Time) Before(other *Time) bool {
	return t.Epoch < other.Epoch
}

// After returns true if this time is after the other time.
func (t *Time) After(other *Time) bool {
	return t.Epoch > other.Epoch
}

// Add adds a duration to the time.
func (t *Time) Add(d time.Duration) *Time {
	newTime := t.ToTime().Add(d)
	return NewTimeFromTime(newTime)
}

// Sub returns the duration between this time and another time.
func (t *Time) Sub(other *Time) time.Duration {
	return t.ToTime().Sub(other.ToTime())
}

// String returns the time formatted as RFC3339 string.
func (t *Time) String() string {
	return t.Format(time.RFC3339, nil)
}

// MarshalJSON implements json.Marshaler interface.
func (t *Time) MarshalJSON() ([]byte, error) {
	return []byte(fmt.Sprintf("%d", t.Epoch)), nil
}

// UnmarshalJSON implements json.Unmarshaler interface.
func (t *Time) UnmarshalJSON(data []byte) error {
	// Remove quotes if present
	epochStr := string(data)
	if len(epochStr) >= 2 && epochStr[0] == '"' && epochStr[len(epochStr)-1] == '"' {
		epochStr = epochStr[1 : len(epochStr)-1]
	}

	var epoch int64
	_, err := fmt.Sscanf(epochStr, "%d", &epoch)
	if err != nil {
		return fmt.Errorf("invalid epoch time: %s", string(data))
	}

	t.Epoch = epoch
	return t.Validate()
}
