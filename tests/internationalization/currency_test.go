package internationalization_test

import (
	"testing"

	"github.com/stretchr/testify/assert"

	i18n "golang-arch/internal/shared/domain/internationalization"
)

func TestNewCurrency(t *testing.T) {
	tests := []struct {
		name          string
		code          string
		symbol        string
		currencyName  string
		decimalPlaces int
		expectError   bool
		expectedError string
	}{
		{
			name:          "Valid USD currency",
			code:          "USD",
			symbol:        "$",
			currencyName:  "US Dollar",
			decimalPlaces: 2,
			expectError:   false,
		},
		{
			name:          "Valid JPY currency (no decimals)",
			code:          "JPY",
			symbol:        "¥",
			currencyName:  "Japanese Yen",
			decimalPlaces: 0,
			expectError:   false,
		},
		{
			name:          "Valid BTC currency (8 decimals)",
			code:          "BTC",
			symbol:        "₿",
			currencyName:  "Bitcoin",
			decimalPlaces: 8,
			expectError:   false,
		},
		{
			name:          "Invalid currency code (too short)",
			code:          "US",
			symbol:        "$",
			currencyName:  "US Dollar",
			decimalPlaces: 2,
			expectError:   true,
			expectedError: "currency code must be exactly 3 characters",
		},
		{
			name:          "Invalid currency code (too long)",
			code:          "USDD",
			symbol:        "$",
			currencyName:  "US Dollar",
			decimalPlaces: 2,
			expectError:   true,
			expectedError: "currency code must be exactly 3 characters",
		},
		{
			name:          "Invalid decimal places (negative)",
			code:          "USD",
			symbol:        "$",
			currencyName:  "US Dollar",
			decimalPlaces: -1,
			expectError:   true,
			expectedError: "decimal places must be between 0 and 18",
		},
		{
			name:          "Invalid decimal places (too high)",
			code:          "USD",
			symbol:        "$",
			currencyName:  "US Dollar",
			decimalPlaces: 19,
			expectError:   true,
			expectedError: "decimal places must be between 0 and 18",
		},
		{
			name:          "Empty symbol",
			code:          "USD",
			symbol:        "",
			currencyName:  "US Dollar",
			decimalPlaces: 2,
			expectError:   true,
			expectedError: "currency symbol cannot be empty",
		},
		{
			name:          "Empty name",
			code:          "USD",
			symbol:        "$",
			currencyName:  "",
			decimalPlaces: 2,
			expectError:   true,
			expectedError: "currency name cannot be empty",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			currency, err := i18n.NewCurrency(tt.code, tt.symbol, tt.currencyName, tt.decimalPlaces)

			if tt.expectError {
				assert.Error(t, err)
				if tt.expectedError != "" {
					assert.Contains(t, err.Error(), tt.expectedError)
				}
				return
			}

			assert.NoError(t, err)
			assert.NotNil(t, currency)
			assert.Equal(t, tt.code, currency.Code)
			assert.Equal(t, tt.symbol, currency.Symbol)
			assert.Equal(t, tt.currencyName, currency.Name)
			assert.Equal(t, tt.decimalPlaces, currency.DecimalPlaces)
		})
	}
}

func TestNewCurrencyFromCode(t *testing.T) {
	tests := []struct {
		name          string
		code          string
		expectError   bool
		expectedError string
	}{
		{
			name:        "Valid USD currency",
			code:        "USD",
			expectError: false,
		},
		{
			name:        "Valid EUR currency",
			code:        "EUR",
			expectError: false,
		},
		{
			name:        "Valid JPY currency",
			code:        "JPY",
			expectError: false,
		},
		{
			name:        "Valid BTC currency",
			code:        "BTC",
			expectError: false,
		},
		{
			name:          "Invalid currency code",
			code:          "INVALID",
			expectError:   true,
			expectedError: "unsupported currency code: INVALID",
		},
		{
			name:          "Empty currency code",
			code:          "",
			expectError:   true,
			expectedError: "unsupported currency code: ",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			currency, err := i18n.NewCurrencyFromCode(tt.code)

			if tt.expectError {
				assert.Error(t, err)
				if tt.expectedError != "" {
					assert.Contains(t, err.Error(), tt.expectedError)
				}
				return
			}

			assert.NoError(t, err)
			assert.NotNil(t, currency)
			assert.Equal(t, tt.code, currency.Code)

			// Verify that the currency has the correct decimal places
			expectedDecimalPlaces := i18n.CurrencyPrecisions[tt.code]
			assert.Equal(t, expectedDecimalPlaces, currency.DecimalPlaces)
		})
	}
}

func TestCurrency_Validate(t *testing.T) {
	tests := []struct {
		name          string
		currency      i18n.Currency
		expectError   bool
		expectedError string
	}{
		{
			name: "Valid USD currency",
			currency: i18n.Currency{
				Code:          "USD",
				Symbol:        "$",
				Name:          "US Dollar",
				DecimalPlaces: 2,
			},
			expectError: false,
		},
		{
			name: "Valid JPY currency (no decimals)",
			currency: i18n.Currency{
				Code:          "JPY",
				Symbol:        "¥",
				Name:          "Japanese Yen",
				DecimalPlaces: 0,
			},
			expectError: false,
		},
		{
			name: "Invalid code (too short)",
			currency: i18n.Currency{
				Code:          "US",
				Symbol:        "$",
				Name:          "US Dollar",
				DecimalPlaces: 2,
			},
			expectError:   true,
			expectedError: "currency code must be exactly 3 characters",
		},
		{
			name: "Invalid code (too long)",
			currency: i18n.Currency{
				Code:          "USDD",
				Symbol:        "$",
				Name:          "US Dollar",
				DecimalPlaces: 2,
			},
			expectError:   true,
			expectedError: "currency code must be exactly 3 characters",
		},
		{
			name: "Invalid decimal places (negative)",
			currency: i18n.Currency{
				Code:          "USD",
				Symbol:        "$",
				Name:          "US Dollar",
				DecimalPlaces: -1,
			},
			expectError:   true,
			expectedError: "decimal places must be between 0 and 18",
		},
		{
			name: "Invalid decimal places (too high)",
			currency: i18n.Currency{
				Code:          "USD",
				Symbol:        "$",
				Name:          "US Dollar",
				DecimalPlaces: 19,
			},
			expectError:   true,
			expectedError: "decimal places must be between 0 and 18",
		},
		{
			name: "Empty symbol",
			currency: i18n.Currency{
				Code:          "USD",
				Symbol:        "",
				Name:          "US Dollar",
				DecimalPlaces: 2,
			},
			expectError:   true,
			expectedError: "currency symbol cannot be empty",
		},
		{
			name: "Empty name",
			currency: i18n.Currency{
				Code:          "USD",
				Symbol:        "$",
				Name:          "",
				DecimalPlaces: 2,
			},
			expectError:   true,
			expectedError: "currency name cannot be empty",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.currency.Validate()

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

func TestCurrency_ToPrimitive(t *testing.T) {
	currency := i18n.Currency{
		Code:          "USD",
		Symbol:        "$",
		Name:          "US Dollar",
		DecimalPlaces: 2,
	}

	primitive := currency.ToPrimitive()
	expected := "USD"

	assert.Equal(t, expected, primitive)
}

func TestCurrency_FromPrimitive(t *testing.T) {
	tests := []struct {
		name          string
		code          string
		expectError   bool
		expectedError string
	}{
		{
			name:        "Valid USD currency",
			code:        "USD",
			expectError: false,
		},
		{
			name:        "Valid EUR currency",
			code:        "EUR",
			expectError: false,
		},
		{
			name:          "Invalid currency code",
			code:          "INVALID",
			expectError:   true,
			expectedError: "unsupported currency code: INVALID",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			currency, err := i18n.FromPrimitiveCurrency(tt.code)

			if tt.expectError {
				assert.Error(t, err)
				if tt.expectedError != "" {
					assert.Contains(t, err.Error(), tt.expectedError)
				}
				return
			}

			assert.NoError(t, err)
			assert.NotNil(t, currency)
			assert.Equal(t, tt.code, currency.Code)
		})
	}
}

func TestCurrency_Format(t *testing.T) {
	tests := []struct {
		name     string
		currency i18n.Currency
		amount   int64
		expected string
	}{
		{
			name: "USD formatting (cents)",
			currency: i18n.Currency{
				Code:          "USD",
				Symbol:        "$",
				Name:          "US Dollar",
				DecimalPlaces: 2,
			},
			amount:   10050, // $100.50
			expected: "$100.50",
		},
		{
			name: "JPY formatting (no decimals)",
			currency: i18n.Currency{
				Code:          "JPY",
				Symbol:        "¥",
				Name:          "Japanese Yen",
				DecimalPlaces: 0,
			},
			amount:   1000, // ¥1000
			expected: "¥1000",
		},
		{
			name: "BTC formatting (8 decimals)",
			currency: i18n.Currency{
				Code:          "BTC",
				Symbol:        "₿",
				Name:          "Bitcoin",
				DecimalPlaces: 8,
			},
			amount:   100000000, // 1 BTC
			expected: "₿1.00000000",
		},
		{
			name: "Zero amount",
			currency: i18n.Currency{
				Code:          "USD",
				Symbol:        "$",
				Name:          "US Dollar",
				DecimalPlaces: 2,
			},
			amount:   0,
			expected: "$0.00",
		},
		{
			name: "Negative amount",
			currency: i18n.Currency{
				Code:          "USD",
				Symbol:        "$",
				Name:          "US Dollar",
				DecimalPlaces: 2,
			},
			amount:   -10050, // -$100.50
			expected: "$-100.50",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			formatted := tt.currency.Format(tt.amount)
			assert.Equal(t, tt.expected, formatted)
		})
	}
}

func TestCurrency_FormatDecimal(t *testing.T) {
	tests := []struct {
		name     string
		currency i18n.Currency
		amount   float64
		expected string
	}{
		{
			name: "USD formatting (decimal)",
			currency: i18n.Currency{
				Code:          "USD",
				Symbol:        "$",
				Name:          "US Dollar",
				DecimalPlaces: 2,
			},
			amount:   100.50,
			expected: "$100.50",
		},
		{
			name: "JPY formatting (no decimals)",
			currency: i18n.Currency{
				Code:          "JPY",
				Symbol:        "¥",
				Name:          "Japanese Yen",
				DecimalPlaces: 0,
			},
			amount:   1000.0,
			expected: "¥1000",
		},
		{
			name: "BTC formatting (8 decimals)",
			currency: i18n.Currency{
				Code:          "BTC",
				Symbol:        "₿",
				Name:          "Bitcoin",
				DecimalPlaces: 8,
			},
			amount:   1.0,
			expected: "₿1.00000000",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			formatted := tt.currency.FormatDecimal(tt.amount)
			assert.Equal(t, tt.expected, formatted)
		})
	}
}

func TestCurrency_GetDecimalPlaces(t *testing.T) {
	tests := []struct {
		name           string
		currency       i18n.Currency
		expectedPlaces int
	}{
		{
			name: "USD (2 decimal places)",
			currency: i18n.Currency{
				Code:          "USD",
				Symbol:        "$",
				Name:          "US Dollar",
				DecimalPlaces: 2,
			},
			expectedPlaces: 2,
		},
		{
			name: "JPY (0 decimal places)",
			currency: i18n.Currency{
				Code:          "JPY",
				Symbol:        "¥",
				Name:          "Japanese Yen",
				DecimalPlaces: 0,
			},
			expectedPlaces: 0,
		},
		{
			name: "BTC (8 decimal places)",
			currency: i18n.Currency{
				Code:          "BTC",
				Symbol:        "₿",
				Name:          "Bitcoin",
				DecimalPlaces: 8,
			},
			expectedPlaces: 8,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			places := tt.currency.GetDecimalPlaces()
			assert.Equal(t, tt.expectedPlaces, places)
		})
	}
}

func TestCurrencyPrecisions(t *testing.T) {
	// Test that all predefined currencies have valid decimal places
	for code, places := range i18n.CurrencyPrecisions {
		t.Run("Currency "+code, func(t *testing.T) {
			assert.GreaterOrEqual(t, places, 0)
			assert.LessOrEqual(t, places, 18)

			// Test that we can create a currency with these decimal places
			currency := i18n.Currency{
				Code:          code,
				Symbol:        "TEST",
				Name:          "Test Currency",
				DecimalPlaces: places,
			}

			err := currency.Validate()
			assert.NoError(t, err, "Currency %s with %d decimal places failed validation", code, places)
		})
	}
}

func TestCurrency_String(t *testing.T) {
	currency := i18n.Currency{
		Code:          "USD",
		Symbol:        "$",
		Name:          "US Dollar",
		DecimalPlaces: 2,
	}

	expected := "USD"
	actual := currency.String()

	assert.Equal(t, expected, actual)
}
