package internationalization_test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"golang-arch/internal/shared/domain/internationalization"
)

func TestNewPhone(t *testing.T) {
	tests := []struct {
		name        string
		countryCode string
		number      string
		expectError bool
		errorMsg    string
	}{
		{
			name:        "valid US phone",
			countryCode: "1",
			number:      "5551234567",
			expectError: false,
		},
		{
			name:        "valid UK phone",
			countryCode: "44",
			number:      "2071234567",
			expectError: false,
		},
		{
			name:        "valid India phone",
			countryCode: "91",
			number:      "9876543210",
			expectError: false,
		},
		{
			name:        "empty country code",
			countryCode: "",
			number:      "5551234567",
			expectError: true,
			errorMsg:    "country code cannot be empty",
		},
		{
			name:        "empty number",
			countryCode: "1",
			number:      "",
			expectError: true,
			errorMsg:    "phone number cannot be empty",
		},
		{
			name:        "invalid country code - starts with 0",
			countryCode: "01",
			number:      "5551234567",
			expectError: true,
			errorMsg:    "invalid country code",
		},
		{
			name:        "invalid country code - too long",
			countryCode: "1234",
			number:      "5551234567",
			expectError: true,
			errorMsg:    "invalid country code",
		},
		{
			name:        "invalid number - too short",
			countryCode: "1",
			number:      "123456",
			expectError: true,
			errorMsg:    "invalid phone number format",
		},
		{
			name:        "invalid number - too long",
			countryCode: "1",
			number:      "12345678901234567890",
			expectError: true,
			errorMsg:    "invalid phone number format",
		},
		{
			name:        "invalid number - contains letters",
			countryCode: "1",
			number:      "555ABC123",
			expectError: true,
			errorMsg:    "invalid phone number format",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			phone, err := internationalization.NewPhone(tt.countryCode, tt.number)

			if tt.expectError {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.errorMsg)
				assert.Nil(t, phone)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, phone)
				assert.Equal(t, tt.countryCode, phone.CountryCode)
				assert.Equal(t, tt.number, phone.Number)
			}
		})
	}
}

func TestNewPhoneFromString(t *testing.T) {
	tests := []struct {
		name        string
		phoneStr    string
		expectError bool
		expected    *internationalization.Phone
	}{
		{
			name:        "international format with +",
			phoneStr:    "+1 555 123 4567",
			expectError: false,
			expected: &internationalization.Phone{
				CountryCode: "1",
				Number:      "5551234567",
			},
		},
		{
			name:        "international format with 00",
			phoneStr:    "001 555 123 4567",
			expectError: false,
			expected: &internationalization.Phone{
				CountryCode: "1",
				Number:      "5551234567",
			},
		},
		{
			name:        "compact international format",
			phoneStr:    "+15551234567",
			expectError: false,
			expected: &internationalization.Phone{
				CountryCode: "1",
				Number:      "5551234567",
			},
		},
		{
			name:        "local format with spaces",
			phoneStr:    "555 123 4567",
			expectError: false,
			expected: &internationalization.Phone{
				CountryCode: "1", // Default to US
				Number:      "5551234567",
			},
		},
		{
			name:        "invalid format",
			phoneStr:    "invalid-phone",
			expectError: true,
		},
		{
			name:        "empty string",
			phoneStr:    "",
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			phone, err := internationalization.NewPhoneFromString(tt.phoneStr)

			if tt.expectError {
				assert.Error(t, err)
				assert.Nil(t, phone)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, phone)
				if tt.expected != nil {
					assert.Equal(t, tt.expected.CountryCode, phone.CountryCode)
					assert.Equal(t, tt.expected.Number, phone.Number)
				}
			}
		})
	}
}

func TestPhone_ToPrimitive(t *testing.T) {
	phone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	primitive := phone.ToPrimitive()
	expected := "+1 5551234567"
	assert.Equal(t, expected, primitive)
}

func TestFromPrimitivePhone(t *testing.T) {
	phoneStr := "+1 5551234567"
	phone, err := internationalization.FromPrimitivePhone(phoneStr)

	assert.NoError(t, err)
	assert.NotNil(t, phone)
	assert.Equal(t, "1", phone.CountryCode)
	assert.Equal(t, "5551234567", phone.Number)
}

func TestPhone_Validate(t *testing.T) {
	tests := []struct {
		name        string
		phone       *internationalization.Phone
		expectError bool
		errorMsg    string
	}{
		{
			name: "valid phone",
			phone: &internationalization.Phone{
				CountryCode: "1",
				Number:      "5551234567",
			},
			expectError: false,
		},
		{
			name: "empty country code",
			phone: &internationalization.Phone{
				CountryCode: "",
				Number:      "5551234567",
			},
			expectError: true,
			errorMsg:    "country code cannot be empty",
		},
		{
			name: "empty number",
			phone: &internationalization.Phone{
				CountryCode: "1",
				Number:      "",
			},
			expectError: true,
			errorMsg:    "phone number cannot be empty",
		},
		{
			name: "invalid country code - starts with 0",
			phone: &internationalization.Phone{
				CountryCode: "01",
				Number:      "5551234567",
			},
			expectError: true,
			errorMsg:    "invalid country code",
		},
		{
			name: "invalid number - too short",
			phone: &internationalization.Phone{
				CountryCode: "1",
				Number:      "123456",
			},
			expectError: true,
			errorMsg:    "invalid phone number format",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.phone.Validate()

			if tt.expectError {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.errorMsg)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestPhone_Format(t *testing.T) {
	phone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	formatted := phone.Format()
	expected := "+1 5551234567"
	assert.Equal(t, expected, formatted)
}

func TestPhone_FormatCompact(t *testing.T) {
	phone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	formatted := phone.FormatCompact()
	expected := "+15551234567"
	assert.Equal(t, expected, formatted)
}

func TestPhone_FormatLocal(t *testing.T) {
	phone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	formatted := phone.FormatLocal()
	expected := "555-123-4567"
	assert.Equal(t, expected, formatted)
}

func TestPhone_Equal(t *testing.T) {
	phone1, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	phone2, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	phone3, err := internationalization.NewPhone("44", "2071234567")
	require.NoError(t, err)

	assert.True(t, phone1.Equal(phone2))
	assert.False(t, phone1.Equal(phone3))
	assert.False(t, phone1.Equal(nil))
}

func TestPhone_String(t *testing.T) {
	phone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	str := phone.String()
	expected := "+1 5551234567"
	assert.Equal(t, expected, str)
}

func TestPhone_GetCountryCode(t *testing.T) {
	phone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	countryCode := phone.GetCountryCode()
	assert.Equal(t, "1", countryCode)
}

func TestPhone_GetNumber(t *testing.T) {
	phone, err := internationalization.NewPhone("1", "5551234567")
	require.NoError(t, err)

	number := phone.GetNumber()
	assert.Equal(t, "5551234567", number)
}

func TestIsValidPhoneNumber(t *testing.T) {
	tests := []struct {
		name     string
		phoneStr string
		expected bool
	}{
		{
			name:     "valid international format",
			phoneStr: "+1 555 123 4567",
			expected: true,
		},
		{
			name:     "valid compact format",
			phoneStr: "+15551234567",
			expected: true,
		},
		{
			name:     "invalid format",
			phoneStr: "invalid-phone",
			expected: false,
		},
		{
			name:     "empty string",
			phoneStr: "",
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := internationalization.IsValidPhoneNumber(tt.phoneStr)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestGetSupportedCountryCodes(t *testing.T) {
	codes := internationalization.GetSupportedCountryCodes()

	assert.NotEmpty(t, codes)
	assert.Contains(t, codes, "1")  // US
	assert.Contains(t, codes, "44") // UK
	assert.Contains(t, codes, "91") // India
	assert.Contains(t, codes, "86") // China
	assert.Contains(t, codes, "81") // Japan
}

func TestPhone_EdgeCases(t *testing.T) {
	t.Run("whitespace handling", func(t *testing.T) {
		phone, err := internationalization.NewPhone("  1  ", "  5551234567  ")
		assert.NoError(t, err)
		assert.Equal(t, "1", phone.CountryCode)
		assert.Equal(t, "5551234567", phone.Number)
	})

	t.Run("very long number", func(t *testing.T) {
		phone, err := internationalization.NewPhone("1", "123456789012345")
		assert.NoError(t, err)
		assert.Equal(t, "123456789012345", phone.Number)
	})

	t.Run("single digit country code", func(t *testing.T) {
		phone, err := internationalization.NewPhone("1", "5551234567")
		assert.NoError(t, err)
		assert.Equal(t, "1", phone.CountryCode)
	})

	t.Run("three digit country code", func(t *testing.T) {
		phone, err := internationalization.NewPhone("123", "5551234567")
		assert.NoError(t, err)
		assert.Equal(t, "123", phone.CountryCode)
	})
}
