package internationalization_test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"golang-arch/internal/shared/domain/internationalization"
)

func TestNewLocalizedPhone(t *testing.T) {
	validPhone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	validTimezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	tests := []struct {
		name        string
		phone       internationalization.Phone
		country     string
		region      string
		timezone    internationalization.Timezone
		expectError bool
		errorMsg    string
	}{
		{
			name:        "valid localized phone",
			phone:       *validPhone,
			country:     "United States",
			region:      "New York",
			timezone:    *validTimezone,
			expectError: false,
		},
		{
			name:        "valid localized phone without region",
			phone:       *validPhone,
			country:     "United States",
			region:      "",
			timezone:    *validTimezone,
			expectError: false,
		},
		{
			name:        "invalid phone",
			phone:       internationalization.Phone{CountryCode: "", Number: "5551234567"},
			country:     "United States",
			region:      "New York",
			timezone:    *validTimezone,
			expectError: true,
			errorMsg:    "invalid phone in localized phone",
		},
		{
			name:        "invalid timezone",
			phone:       *validPhone,
			country:     "United States",
			region:      "New York",
			timezone:    internationalization.Timezone{ID: ""},
			expectError: true,
			errorMsg:    "invalid timezone in localized phone",
		},
		{
			name:        "empty country",
			phone:       *validPhone,
			country:     "",
			region:      "New York",
			timezone:    *validTimezone,
			expectError: true,
			errorMsg:    "country cannot be empty",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			lp, err := internationalization.NewLocalizedPhone(tt.phone, tt.country, tt.region, tt.timezone)

			if tt.expectError {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.errorMsg)
				assert.Nil(t, lp)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, lp)
				assert.Equal(t, tt.phone, lp.Phone)
				assert.Equal(t, tt.country, lp.Country)
				assert.Equal(t, tt.region, lp.Region)
				assert.Equal(t, tt.timezone, lp.Timezone)
			}
		})
	}
}

func TestNewLocalizedPhoneFromPrimitive(t *testing.T) {
	tests := []struct {
		name        string
		phoneStr    string
		country     string
		region      string
		timezoneID  string
		expectError bool
		errorMsg    string
	}{
		{
			name:        "valid primitive values",
			phoneStr:    "+1 5551234567",
			country:     "United States",
			region:      "New York",
			timezoneID:  "America/New_York",
			expectError: false,
		},
		{
			name:        "invalid phone string",
			phoneStr:    "invalid-phone",
			country:     "United States",
			region:      "New York",
			timezoneID:  "America/New_York",
			expectError: true,
			errorMsg:    "failed to create localized phone from primitive",
		},
		{
			name:        "invalid timezone ID",
			phoneStr:    "+1 5551234567",
			country:     "United States",
			region:      "New York",
			timezoneID:  "Invalid/Timezone",
			expectError: true,
			errorMsg:    "failed to create localized phone from primitive",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			lp, err := internationalization.NewLocalizedPhoneFromPrimitive(tt.phoneStr, tt.country, tt.region, tt.timezoneID)

			if tt.expectError {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.errorMsg)
				assert.Nil(t, lp)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, lp)
				assert.Equal(t, tt.country, lp.Country)
				assert.Equal(t, tt.region, lp.Region)
				assert.Equal(t, tt.timezoneID, lp.Timezone.ID)
			}
		})
	}
}

func TestLocalizedPhone_ToPrimitive(t *testing.T) {
	phone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	lp, err := internationalization.NewLocalizedPhone(*phone, "United States", "New York", *timezone)
	require.NoError(t, err)

	phoneStr, country, region, timezoneID := lp.ToPrimitive()
	assert.Equal(t, "+1 5551234567", phoneStr)
	assert.Equal(t, "United States", country)
	assert.Equal(t, "New York", region)
	assert.Equal(t, "America/New_York", timezoneID)
}

func TestLocalizedPhone_Validate(t *testing.T) {
	validPhone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	validTimezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	tests := []struct {
		name        string
		lp          *internationalization.LocalizedPhone
		expectError bool
		errorMsg    string
	}{
		{
			name: "valid localized phone",
			lp: &internationalization.LocalizedPhone{
				Phone:    *validPhone,
				Country:  "United States",
				Region:   "New York",
				Timezone: *validTimezone,
			},
			expectError: false,
		},
		{
			name: "invalid phone",
			lp: &internationalization.LocalizedPhone{
				Phone:    internationalization.Phone{CountryCode: "", Number: "5551234567"},
				Country:  "United States",
				Region:   "New York",
				Timezone: *validTimezone,
			},
			expectError: true,
			errorMsg:    "invalid phone in localized phone",
		},
		{
			name: "invalid timezone",
			lp: &internationalization.LocalizedPhone{
				Phone:    *validPhone,
				Country:  "United States",
				Region:   "New York",
				Timezone: internationalization.Timezone{ID: ""},
			},
			expectError: true,
			errorMsg:    "invalid timezone in localized phone",
		},
		{
			name: "empty country",
			lp: &internationalization.LocalizedPhone{
				Phone:    *validPhone,
				Country:  "",
				Region:   "New York",
				Timezone: *validTimezone,
			},
			expectError: true,
			errorMsg:    "country cannot be empty",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.lp.Validate()

			if tt.expectError {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.errorMsg)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestLocalizedPhone_Format(t *testing.T) {
	phone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	lp, err := internationalization.NewLocalizedPhone(*phone, "United States", "New York", *timezone)
	require.NoError(t, err)

	formatted := lp.Format()
	expected := "+1 5551234567"
	assert.Equal(t, expected, formatted)
}

func TestLocalizedPhone_GetFullLocation(t *testing.T) {
	phone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	tests := []struct {
		name     string
		country  string
		region   string
		expected string
	}{
		{
			name:     "with region",
			country:  "United States",
			region:   "New York",
			expected: "New York, United States",
		},
		{
			name:     "without region",
			country:  "United States",
			region:   "",
			expected: "United States",
		},
		{
			name:     "different country",
			country:  "Canada",
			region:   "Ontario",
			expected: "Ontario, Canada",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			lp, err := internationalization.NewLocalizedPhone(*phone, tt.country, tt.region, *timezone)
			require.NoError(t, err)

			location := lp.GetFullLocation()
			assert.Equal(t, tt.expected, location)
		})
	}
}

func TestLocalizedPhone_IsSameCountry(t *testing.T) {
	phone1, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	phone2, err := internationalization.NewPhone("44", "2071234567")
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	lp1, err := internationalization.NewLocalizedPhone(*phone1, "United States", "New York", *timezone)
	require.NoError(t, err)

	lp2, err := internationalization.NewLocalizedPhone(*phone1, "United States", "California", *timezone)
	require.NoError(t, err)

	lp3, err := internationalization.NewLocalizedPhone(*phone2, "United Kingdom", "London", *timezone)
	require.NoError(t, err)

	assert.True(t, lp1.IsSameCountry(lp2))
	assert.False(t, lp1.IsSameCountry(lp3))
	assert.False(t, lp1.IsSameCountry(nil))
}

func TestLocalizedPhone_IsSameRegion(t *testing.T) {
	phone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
	require.NoError(t, err)

	lp1, err := internationalization.NewLocalizedPhone(*phone, "United States", "New York", *timezone)
	require.NoError(t, err)

	lp2, err := internationalization.NewLocalizedPhone(*phone, "United States", "New York", *timezone)
	require.NoError(t, err)

	lp3, err := internationalization.NewLocalizedPhone(*phone, "United States", "California", *timezone)
	require.NoError(t, err)

	lp4, err := internationalization.NewLocalizedPhone(*phone, "United States", "", *timezone)
	require.NoError(t, err)

	assert.True(t, lp1.IsSameRegion(lp2))
	assert.False(t, lp1.IsSameRegion(lp3))
	assert.False(t, lp1.IsSameRegion(lp4)) // Empty region
	assert.False(t, lp1.IsSameRegion(nil))
}

func TestLocalizedPhone_EdgeCases(t *testing.T) {
	t.Run("whitespace handling", func(t *testing.T) {
		phone, err := internationalization.NewPhone("1", "5551234567")
		require.NoError(t, err)

		timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
		require.NoError(t, err)

		lp, err := internationalization.NewLocalizedPhone(*phone, "  United States  ", "  New York  ", *timezone)
		assert.NoError(t, err)
		assert.Equal(t, "  United States  ", lp.Country)
		assert.Equal(t, "  New York  ", lp.Region)
	})

	t.Run("very long country name", func(t *testing.T) {
		phone, err := internationalization.NewPhone("1", "5551234567")
		require.NoError(t, err)

		timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
		require.NoError(t, err)

		longCountryName := "The United Kingdom of Great Britain and Northern Ireland"
		lp, err := internationalization.NewLocalizedPhone(*phone, longCountryName, "London", *timezone)
		assert.NoError(t, err)
		assert.Equal(t, longCountryName, lp.Country)
	})

	t.Run("special characters in region", func(t *testing.T) {
		phone, err := internationalization.NewPhone("1", "5551234567")
		require.NoError(t, err)

		timezone, err := internationalization.NewTimezone("America/New_York", "Eastern Time", -300)
		require.NoError(t, err)

		regionWithSpecialChars := "São Paulo"
		lp, err := internationalization.NewLocalizedPhone(*phone, "Brazil", regionWithSpecialChars, *timezone)
		assert.NoError(t, err)
		assert.Equal(t, regionWithSpecialChars, lp.Region)
	})
}
