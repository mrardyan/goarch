package internationalization_test

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"golang-arch/internal/shared/domain/internationalization"
)

func TestNewLocalizedDateTime(t *testing.T) {
	validTime, err := internationalization.NewTime(1703500200) // 2023-12-25 10:30:00 UTC
	require.NoError(t, err)

	validTimezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	// Test valid creation
	ldt, err := internationalization.NewLocalizedDateTime(*validTime, *validTimezone)
	assert.NoError(t, err)
	assert.NotNil(t, ldt)
	assert.Equal(t, *validTime, ldt.Time)
	assert.Equal(t, *validTimezone, ldt.Timezone)

	// Test invalid time
	invalidTime := internationalization.Time{Epoch: -1}
	_, err = internationalization.NewLocalizedDateTime(invalidTime, *validTimezone)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "invalid time in localized datetime")

	// Test invalid timezone
	invalidTimezone := internationalization.Timezone{ID: ""}
	_, err = internationalization.NewLocalizedDateTime(*validTime, invalidTimezone)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "invalid timezone in localized datetime")
}

func TestNewLocalizedDateTimeFromPrimitive(t *testing.T) {
	tests := []struct {
		name        string
		epoch       int64
		timezoneID  string
		expectError bool
		errorMsg    string
	}{
		{
			name:        "valid primitive values",
			epoch:       1703500200, // 2023-12-25 10:30:00 UTC
			timezoneID:  "America/New_York",
			expectError: false,
		},
		{
			name:        "invalid epoch time",
			epoch:       -1,
			timezoneID:  "America/New_York",
			expectError: true,
			errorMsg:    "failed to create localized datetime from primitive",
		},
		{
			name:        "invalid timezone ID",
			epoch:       1703500200,
			timezoneID:  "Invalid/Timezone",
			expectError: true,
			errorMsg:    "failed to create localized datetime from primitive",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ldt, err := internationalization.NewLocalizedDateTimeFromPrimitive(tt.epoch, tt.timezoneID)

			if tt.expectError {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.errorMsg)
				assert.Nil(t, ldt)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, ldt)
				assert.Equal(t, tt.epoch, ldt.Time.Epoch)
				assert.Equal(t, tt.timezoneID, ldt.Timezone.ID)
			}
		})
	}
}

func TestLocalizedDateTime_ToPrimitive(t *testing.T) {
	time, err := internationalization.NewTime(1703500200)
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	ldt, err := internationalization.NewLocalizedDateTime(*time, *timezone)
	require.NoError(t, err)

	epoch, timezoneID := ldt.ToPrimitive()
	assert.Equal(t, int64(1703500200), epoch)
	assert.Equal(t, "America/New_York", timezoneID)
}

func TestLocalizedDateTime_Validate(t *testing.T) {
	validTime, err := internationalization.NewTime(1703500200)
	require.NoError(t, err)

	validTimezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	ldt, err := internationalization.NewLocalizedDateTime(*validTime, *validTimezone)
	require.NoError(t, err)

	// Test valid localized datetime
	assert.NoError(t, ldt.Validate())

	// Test invalid time
	ldt.Time.Epoch = -1
	assert.Error(t, ldt.Validate())
	assert.Contains(t, ldt.Validate().Error(), "invalid time in localized datetime")

	// Test invalid timezone
	ldt.Time.Epoch = 1703500200 // Reset to valid
	ldt.Timezone.ID = ""
	assert.Error(t, ldt.Validate())
	assert.Contains(t, ldt.Validate().Error(), "invalid timezone in localized datetime")
}

func TestLocalizedDateTime_Format(t *testing.T) {
	time, err := internationalization.NewTime(1703500200) // 2023-12-25 10:30:00 UTC
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	ldt, err := internationalization.NewLocalizedDateTime(*time, *timezone)
	require.NoError(t, err)

	// Format in timezone (should be 5:30 AM EST)
	formatted := ldt.Format("2006-01-02 15:04:05")
	expected := "2023-12-25 05:30:00" // 10:30 UTC - 5 hours = 5:30 EST
	assert.Equal(t, expected, formatted)
}

func TestLocalizedDateTime_ToTime(t *testing.T) {
	timeValue, err := internationalization.NewTime(1703500200) // 2023-12-25 10:30:00 UTC
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	ldt, err := internationalization.NewLocalizedDateTime(*timeValue, *timezone)
	require.NoError(t, err)

	// Should return the time in the specified timezone
	result := ldt.ToTime()
	expected := time.Date(2023, 12, 25, 5, 30, 0, 0, time.FixedZone("EST", -5*3600))
	assert.Equal(t, expected.Year(), result.Year())
	assert.Equal(t, expected.Month(), result.Month())
	assert.Equal(t, expected.Day(), result.Day())
	assert.Equal(t, expected.Hour(), result.Hour())
	assert.Equal(t, expected.Minute(), result.Minute())
}

func TestLocalizedDateTime_ToUTC(t *testing.T) {
	timeValue, err := internationalization.NewTime(1703500200) // 2023-12-25 10:30:00 UTC
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	ldt, err := internationalization.NewLocalizedDateTime(*timeValue, *timezone)
	require.NoError(t, err)

	// Should return the time in UTC
	result := ldt.ToUTC()
	expected := time.Date(2023, 12, 25, 10, 30, 0, 0, time.UTC)
	assert.Equal(t, expected, result)
}

func TestLocalizedDateTime_Add(t *testing.T) {
	timeValue, err := internationalization.NewTime(1703500200) // 2023-12-25 10:30:00 UTC
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	ldt, err := internationalization.NewLocalizedDateTime(*timeValue, *timezone)
	require.NoError(t, err)

	// Add 1 hour
	result := ldt.Add(time.Hour)
	expectedEpoch := int64(1703503800) // 1703500200 + 3600
	assert.Equal(t, expectedEpoch, result.Time.Epoch)
	assert.Equal(t, ldt.Timezone, result.Timezone)
}

func TestLocalizedDateTime_Subtract(t *testing.T) {
	timeValue, err := internationalization.NewTime(1703500200) // 2023-12-25 10:30:00 UTC
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	ldt, err := internationalization.NewLocalizedDateTime(*timeValue, *timezone)
	require.NoError(t, err)

	// Subtract 1 hour
	result := ldt.Subtract(time.Hour)
	expectedEpoch := int64(1703496600) // 1703500200 - 3600
	assert.Equal(t, expectedEpoch, result.Time.Epoch)
	assert.Equal(t, ldt.Timezone, result.Timezone)
}

func TestLocalizedDateTime_IsBefore(t *testing.T) {
	time1, err := internationalization.NewTime(1703500200) // 2023-12-25 10:30:00 UTC
	require.NoError(t, err)

	time2, err := internationalization.NewTime(1703503800) // 2023-12-25 11:30:00 UTC
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	ldt1, err := internationalization.NewLocalizedDateTime(*time1, *timezone)
	require.NoError(t, err)

	ldt2, err := internationalization.NewLocalizedDateTime(*time2, *timezone)
	require.NoError(t, err)

	assert.True(t, ldt1.IsBefore(ldt2))
	assert.False(t, ldt2.IsBefore(ldt1))
	assert.False(t, ldt1.IsBefore(ldt1))
}

func TestLocalizedDateTime_IsAfter(t *testing.T) {
	time1, err := internationalization.NewTime(1703500200) // 2023-12-25 10:30:00 UTC
	require.NoError(t, err)

	time2, err := internationalization.NewTime(1703503800) // 2023-12-25 11:30:00 UTC
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	ldt1, err := internationalization.NewLocalizedDateTime(*time1, *timezone)
	require.NoError(t, err)

	ldt2, err := internationalization.NewLocalizedDateTime(*time2, *timezone)
	require.NoError(t, err)

	assert.False(t, ldt1.IsAfter(ldt2))
	assert.True(t, ldt2.IsAfter(ldt1))
	assert.False(t, ldt1.IsAfter(ldt1))
}

func TestLocalizedDateTime_IsEqual(t *testing.T) {
	time1, err := internationalization.NewTime(1703500200) // 2023-12-25 10:30:00 UTC
	require.NoError(t, err)

	time2, err := internationalization.NewTime(1703503800) // 2023-12-25 11:30:00 UTC
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	ldt1, err := internationalization.NewLocalizedDateTime(*time1, *timezone)
	require.NoError(t, err)

	ldt2, err := internationalization.NewLocalizedDateTime(*time2, *timezone)
	require.NoError(t, err)

	ldt3, err := internationalization.NewLocalizedDateTime(*time1, *timezone)
	require.NoError(t, err)

	assert.True(t, ldt1.IsEqual(ldt3))
	assert.False(t, ldt1.IsEqual(ldt2))
	assert.False(t, ldt1.IsEqual(nil))
}

func TestLocalizedDateTime_Duration(t *testing.T) {
	time1, err := internationalization.NewTime(1703500200) // 2023-12-25 10:30:00 UTC
	require.NoError(t, err)

	time2, err := internationalization.NewTime(1703503800) // 2023-12-25 11:30:00 UTC
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	ldt1, err := internationalization.NewLocalizedDateTime(*time1, *timezone)
	require.NoError(t, err)

	ldt2, err := internationalization.NewLocalizedDateTime(*time2, *timezone)
	require.NoError(t, err)

	// ldt1 is earlier than ldt2, so duration should be negative
	duration := ldt1.Duration(ldt2)
	expected := -time.Hour
	assert.Equal(t, expected, duration)

	// Test reverse duration - ldt2 is later than ldt1, so duration should be positive
	duration2 := ldt2.Duration(ldt1)
	expected2 := time.Hour
	assert.Equal(t, expected2, duration2)
}

func TestLocalizedDateTime_EdgeCases(t *testing.T) {
	t.Run("zero time", func(t *testing.T) {
		time, err := internationalization.NewTime(0) // Unix epoch start
		require.NoError(t, err)

		timezone, err := internationalization.NewTimezone("UTC", "UTC", 0)
		require.NoError(t, err)

		ldt, err := internationalization.NewLocalizedDateTime(*time, *timezone)
		assert.NoError(t, err)
		assert.Equal(t, int64(0), ldt.Time.Epoch)
	})

	t.Run("different timezones", func(t *testing.T) {
		time, err := internationalization.NewTime(1703500200) // 2023-12-25 10:30:00 UTC
		require.NoError(t, err)

		timezone1, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
		require.NoError(t, err)

		timezone2, err := internationalization.NewTimezone("Europe/London", "GMT", 0)
		require.NoError(t, err)

		ldt1, err := internationalization.NewLocalizedDateTime(*time, *timezone1)
		require.NoError(t, err)

		ldt2, err := internationalization.NewLocalizedDateTime(*time, *timezone2)
		require.NoError(t, err)

		// Same UTC time, different timezone display
		assert.Equal(t, ldt1.Time.Epoch, ldt2.Time.Epoch)
		assert.NotEqual(t, ldt1.Format("15:04"), ldt2.Format("15:04"))
	})

	t.Run("large duration", func(t *testing.T) {
		time1, err := internationalization.NewTime(1703500200) // 2023-12-25 10:30:00 UTC
		require.NoError(t, err)

		time2, err := internationalization.NewTime(1703500200 + 86400*365) // 1 year later
		require.NoError(t, err)

		timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
		require.NoError(t, err)

		ldt1, err := internationalization.NewLocalizedDateTime(*time1, *timezone)
		require.NoError(t, err)

		ldt2, err := internationalization.NewLocalizedDateTime(*time2, *timezone)
		require.NoError(t, err)

		// ldt1 is earlier than ldt2, so duration should be negative
		duration := ldt1.Duration(ldt2)
		expected := -time.Duration(86400*365) * time.Second
		assert.Equal(t, expected, duration)
	})
}
