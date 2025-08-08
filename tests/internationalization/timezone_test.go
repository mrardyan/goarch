package internationalization_test

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"

	i18n "golang-arch/internal/shared/domain/internationalization"
)

func TestNewTimezone(t *testing.T) {
	tests := []struct {
		name          string
		id            string
		timezoneName  string
		offset        int
		expectError   bool
		expectedError string
	}{
		{
			name:         "Valid timezone",
			id:           "America/New_York",
			timezoneName: "Eastern Time",
			offset:       -300, // -5 hours in minutes
			expectError:  false,
		},
		{
			name:         "Valid UTC timezone",
			id:           "UTC",
			timezoneName: "Coordinated Universal Time",
			offset:       0,
			expectError:  false,
		},
		{
			name:         "Valid positive offset",
			id:           "Asia/Tokyo",
			timezoneName: "Japan Standard Time",
			offset:       540, // +9 hours in minutes
			expectError:  false,
		},
		{
			name:          "Empty timezone ID",
			id:            "",
			timezoneName:  "Test Timezone",
			offset:        0,
			expectError:   true,
			expectedError: "timezone ID cannot be empty",
		},
		{
			name:          "Empty timezone name",
			id:            "America/New_York",
			timezoneName:  "",
			offset:        0,
			expectError:   true,
			expectedError: "timezone name cannot be empty",
		},
		{
			name:          "Invalid offset (too large)",
			id:            "America/New_York",
			timezoneName:  "Eastern Time",
			offset:        1440, // 24 hours in minutes
			expectError:   true,
			expectedError: "timezone offset must be between -1440 and 1440 minutes",
		},
		{
			name:          "Invalid offset (too small)",
			id:            "America/New_York",
			timezoneName:  "Eastern Time",
			offset:        -1441, // -24 hours 1 minute in minutes
			expectError:   true,
			expectedError: "timezone offset must be between -1440 and 1440 minutes",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			timezone, err := i18n.NewTimezone(tt.id, tt.timezoneName, tt.offset)

			if tt.expectError {
				assert.Error(t, err)
				if tt.expectedError != "" {
					assert.Contains(t, err.Error(), tt.expectedError)
				}
				return
			}

			assert.NoError(t, err)
			assert.NotNil(t, timezone)
			assert.Equal(t, tt.id, timezone.ID)
			assert.Equal(t, tt.timezoneName, timezone.Name)
			assert.Equal(t, tt.offset, timezone.Offset)
		})
	}
}

func TestNewTimezoneFromID(t *testing.T) {
	tests := []struct {
		name          string
		id            string
		expectError   bool
		expectedError string
	}{
		{
			name:        "Valid timezone ID",
			id:          "America/New_York",
			expectError: false,
		},
		{
			name:        "Valid UTC timezone",
			id:          "UTC",
			expectError: false,
		},
		{
			name:        "Valid Asia timezone",
			id:          "Asia/Tokyo",
			expectError: false,
		},
		{
			name:        "Valid Europe timezone",
			id:          "Europe/London",
			expectError: false,
		},
		{
			name:          "Invalid timezone ID",
			id:            "Invalid/Timezone",
			expectError:   true,
			expectedError: "unsupported timezone ID: Invalid/Timezone",
		},
		{
			name:          "Empty timezone ID",
			id:            "",
			expectError:   true,
			expectedError: "timezone ID cannot be empty",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			timezone, err := i18n.NewTimezoneFromID(tt.id)

			if tt.expectError {
				assert.Error(t, err)
				if tt.expectedError != "" {
					assert.Contains(t, err.Error(), tt.expectedError)
				}
				return
			}

			assert.NoError(t, err)
			assert.NotNil(t, timezone)
			assert.Equal(t, tt.id, timezone.ID)
			assert.NotEmpty(t, timezone.Name)
			// Offset should be within valid range
			assert.GreaterOrEqual(t, timezone.Offset, -1440)
			assert.LessOrEqual(t, timezone.Offset, 1440)
		})
	}
}

func TestTimezone_Validate(t *testing.T) {
	tests := []struct {
		name          string
		timezone      i18n.Timezone
		expectError   bool
		expectedError string
	}{
		{
			name: "Valid timezone",
			timezone: i18n.Timezone{
				ID:     "America/New_York",
				Name:   "Eastern Time",
				Offset: -300,
			},
			expectError: false,
		},
		{
			name: "Valid UTC timezone",
			timezone: i18n.Timezone{
				ID:     "UTC",
				Name:   "Coordinated Universal Time",
				Offset: 0,
			},
			expectError: false,
		},
		{
			name: "Empty ID",
			timezone: i18n.Timezone{
				ID:     "",
				Name:   "Eastern Time",
				Offset: -300,
			},
			expectError:   true,
			expectedError: "timezone ID cannot be empty",
		},
		{
			name: "Empty name",
			timezone: i18n.Timezone{
				ID:     "America/New_York",
				Name:   "",
				Offset: -300,
			},
			expectError:   true,
			expectedError: "timezone name cannot be empty",
		},
		{
			name: "Invalid offset (too large)",
			timezone: i18n.Timezone{
				ID:     "America/New_York",
				Name:   "Eastern Time",
				Offset: 1440,
			},
			expectError:   true,
			expectedError: "timezone offset must be between -1440 and 1440 minutes",
		},
		{
			name: "Invalid offset (too small)",
			timezone: i18n.Timezone{
				ID:     "America/New_York",
				Name:   "Eastern Time",
				Offset: -1441,
			},
			expectError:   true,
			expectedError: "timezone offset must be between -1440 and 1440 minutes",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.timezone.Validate()

			if tt.expectError {
				assert.Error(t, err)
				if tt.expectedError != "" {
					assert.Contains(t, err.Error(), tt.expectedError)
				}
				return
			}

			assert.NoError(t, err)
		})
	}
}

func TestTimezone_ToPrimitive(t *testing.T) {
	timezone := i18n.Timezone{
		ID:     "America/New_York",
		Name:   "Eastern Time",
		Offset: -300,
	}

	primitive := timezone.ToPrimitive()
	expected := "America/New_York"

	assert.Equal(t, expected, primitive)
}

func TestTimezone_FromPrimitive(t *testing.T) {
	tests := []struct {
		name          string
		id            string
		expectError   bool
		expectedError string
	}{
		{
			name:        "Valid timezone ID",
			id:          "America/New_York",
			expectError: false,
		},
		{
			name:        "Valid UTC timezone",
			id:          "UTC",
			expectError: false,
		},
		{
			name:          "Invalid timezone ID",
			id:            "Invalid/Timezone",
			expectError:   true,
			expectedError: "unsupported timezone ID: Invalid/Timezone",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			timezone, err := i18n.FromPrimitiveTimezone(tt.id)

			if tt.expectError {
				assert.Error(t, err)
				if tt.expectedError != "" {
					assert.Contains(t, err.Error(), tt.expectedError)
				}
				return
			}

			assert.NoError(t, err)
			assert.NotNil(t, timezone)
			assert.Equal(t, tt.id, timezone.ID)
		})
	}
}

func TestTimezone_GetOffset(t *testing.T) {
	tests := []struct {
		name           string
		timezone       i18n.Timezone
		expectedOffset time.Duration
	}{
		{
			name: "Negative offset",
			timezone: i18n.Timezone{
				ID:     "America/New_York",
				Name:   "Eastern Time",
				Offset: -300,
			},
			expectedOffset: -5 * time.Hour,
		},
		{
			name: "Positive offset",
			timezone: i18n.Timezone{
				ID:     "Asia/Tokyo",
				Name:   "Japan Standard Time",
				Offset: 540,
			},
			expectedOffset: 9 * time.Hour,
		},
		{
			name: "Zero offset",
			timezone: i18n.Timezone{
				ID:     "UTC",
				Name:   "Coordinated Universal Time",
				Offset: 0,
			},
			expectedOffset: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			offset := tt.timezone.GetOffset()
			assert.Equal(t, tt.expectedOffset, offset)
		})
	}
}

func TestTimezone_GetLocation(t *testing.T) {
	tests := []struct {
		name        string
		timezone    i18n.Timezone
		expectError bool
	}{
		{
			name: "Valid timezone",
			timezone: i18n.Timezone{
				ID:     "America/New_York",
				Name:   "Eastern Time",
				Offset: -300,
			},
			expectError: false,
		},
		{
			name: "Valid UTC timezone",
			timezone: i18n.Timezone{
				ID:     "UTC",
				Name:   "Coordinated Universal Time",
				Offset: 0,
			},
			expectError: false,
		},
		{
			name: "Valid Asia timezone",
			timezone: i18n.Timezone{
				ID:     "Asia/Tokyo",
				Name:   "Japan Standard Time",
				Offset: 540,
			},
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			location, err := tt.timezone.GetLocation()

			if tt.expectError {
				assert.Error(t, err)
				return
			}

			assert.NoError(t, err)
			assert.NotNil(t, location)
			assert.Equal(t, tt.timezone.ID, location.String())
		})
	}
}

func TestTimezone_FormatOffset(t *testing.T) {
	tests := []struct {
		name     string
		timezone i18n.Timezone
		expected string
	}{
		{
			name: "Negative offset",
			timezone: i18n.Timezone{
				ID:     "America/New_York",
				Name:   "Eastern Time",
				Offset: -300,
			},
			expected: "-05:00",
		},
		{
			name: "Positive offset",
			timezone: i18n.Timezone{
				ID:     "Asia/Tokyo",
				Name:   "Japan Standard Time",
				Offset: 540,
			},
			expected: "+09:00",
		},
		{
			name: "Zero offset",
			timezone: i18n.Timezone{
				ID:     "UTC",
				Name:   "Coordinated Universal Time",
				Offset: 0,
			},
			expected: "+00:00",
		},
		{
			name: "Half hour offset",
			timezone: i18n.Timezone{
				ID:     "Asia/Kolkata",
				Name:   "India Standard Time",
				Offset: 330,
			},
			expected: "+05:30",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			formatted := tt.timezone.FormatOffset()
			assert.Equal(t, tt.expected, formatted)
		})
	}
}

func TestTimezone_String(t *testing.T) {
	timezone := i18n.Timezone{
		ID:     "America/New_York",
		Name:   "Eastern Time",
		Offset: -300,
	}

	expected := "America/New_York (Eastern Time) -05:00"
	actual := timezone.String()

	assert.Equal(t, expected, actual)
}
