package internationalization

import (
	"encoding/json"
	"math"
	"testing"

	"golang-arch/internal/shared/domain/internationalization"
)

func TestNewMoneyFromDecimal(t *testing.T) {
	tests := []struct {
		name        string
		decimal     float64
		currency    internationalization.Currency
		expectError bool
		expected    int64
	}{
		{
			name:     "USD 100.50",
			decimal:  100.50,
			currency: internationalization.Currency{Code: "USD", Symbol: "$", Name: "US Dollar", DecimalPlaces: 2},
			expected: 10050, // 100.50 * 100
		},
		{
			name:     "JPY 1000",
			decimal:  1000.0,
			currency: internationalization.Currency{Code: "JPY", Symbol: "¥", Name: "Japanese Yen", DecimalPlaces: 0},
			expected: 1000, // 1000 * 1
		},
		{
			name:     "EUR 99.99",
			decimal:  99.99,
			currency: internationalization.Currency{Code: "EUR", Symbol: "€", Name: "Euro", DecimalPlaces: 2},
			expected: 9999, // 99.99 * 100
		},
		{
			name:     "BTC 0.00000001",
			decimal:  0.00000001,
			currency: internationalization.Currency{Code: "BTC", Symbol: "₿", Name: "Bitcoin", DecimalPlaces: 8},
			expected: 1, // 0.00000001 * 100000000
		},
		{
			name:        "invalid currency",
			decimal:     100.0,
			currency:    internationalization.Currency{Code: "", Symbol: "", Name: "", DecimalPlaces: 2},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			money, err := internationalization.NewMoneyFromDecimal(tt.decimal, tt.currency)
			if tt.expectError {
				if err == nil {
					t.Errorf("expected error but got none")
				}
				return
			}
			if err != nil {
				t.Errorf("unexpected error: %v", err)
				return
			}
			if money.Amount != tt.expected {
				t.Errorf("expected amount %d, got %d", tt.expected, money.Amount)
			}
		})
	}
}

func TestNewMoneyFromInteger(t *testing.T) {
	tests := []struct {
		name        string
		amount      int64
		currency    internationalization.Currency
		expectError bool
	}{
		{
			name:     "USD 10050 cents",
			amount:   10050,
			currency: internationalization.Currency{Code: "USD", Symbol: "$", Name: "US Dollar", DecimalPlaces: 2},
		},
		{
			name:     "JPY 1000 yen",
			amount:   1000,
			currency: internationalization.Currency{Code: "JPY", Symbol: "¥", Name: "Japanese Yen", DecimalPlaces: 0},
		},
		{
			name:        "invalid currency",
			amount:      1000,
			currency:    internationalization.Currency{Code: "", Symbol: "", Name: "", DecimalPlaces: 2},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			money, err := internationalization.NewMoneyFromInteger(tt.amount, tt.currency)
			if tt.expectError {
				if err == nil {
					t.Errorf("expected error but got none")
				}
				return
			}
			if err != nil {
				t.Errorf("unexpected error: %v", err)
				return
			}
			if money.Amount != tt.amount {
				t.Errorf("expected amount %d, got %d", tt.amount, money.Amount)
			}
		})
	}
}

func TestMoney_ToDecimal(t *testing.T) {
	tests := []struct {
		name     string
		amount   int64
		currency internationalization.Currency
		expected float64
	}{
		{
			name:     "USD 10050 cents to decimal",
			amount:   10050,
			currency: internationalization.Currency{Code: "USD", Symbol: "$", Name: "US Dollar", DecimalPlaces: 2},
			expected: 100.50,
		},
		{
			name:     "JPY 1000 yen to decimal",
			amount:   1000,
			currency: internationalization.Currency{Code: "JPY", Symbol: "¥", Name: "Japanese Yen", DecimalPlaces: 0},
			expected: 1000.0,
		},
		{
			name:     "BTC 1 satoshi to decimal",
			amount:   1,
			currency: internationalization.Currency{Code: "BTC", Symbol: "₿", Name: "Bitcoin", DecimalPlaces: 8},
			expected: 0.00000001,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			money := &internationalization.Money{
				Amount:   tt.amount,
				Currency: tt.currency,
			}
			result := money.ToDecimal()
			if math.Abs(result-tt.expected) > 0.000001 {
				t.Errorf("expected %f, got %f", tt.expected, result)
			}
		})
	}
}

func TestMoney_Add(t *testing.T) {
	usd := internationalization.Currency{Code: "USD", Symbol: "$", Name: "US Dollar", DecimalPlaces: 2}
	eur := internationalization.Currency{Code: "EUR", Symbol: "€", Name: "Euro", DecimalPlaces: 2}

	tests := []struct {
		name        string
		money1      *internationalization.Money
		money2      *internationalization.Money
		expectError bool
		expected    int64
	}{
		{
			name: "add USD amounts",
			money1: &internationalization.Money{
				Amount:   10050, // $100.50
				Currency: usd,
			},
			money2: &internationalization.Money{
				Amount:   2500, // $25.00
				Currency: usd,
			},
			expected: 12550, // $125.50
		},
		{
			name: "different currencies",
			money1: &internationalization.Money{
				Amount:   10050,
				Currency: usd,
			},
			money2: &internationalization.Money{
				Amount:   2500,
				Currency: eur,
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := tt.money1.Add(tt.money2)
			if tt.expectError {
				if err == nil {
					t.Errorf("expected error but got none")
				}
				return
			}
			if err != nil {
				t.Errorf("unexpected error: %v", err)
				return
			}
			if result.Amount != tt.expected {
				t.Errorf("expected amount %d, got %d", tt.expected, result.Amount)
			}
		})
	}
}

func TestMoney_Subtract(t *testing.T) {
	usd := internationalization.Currency{Code: "USD", Symbol: "$", Name: "US Dollar", DecimalPlaces: 2}

	tests := []struct {
		name        string
		money1      *internationalization.Money
		money2      *internationalization.Money
		expectError bool
		expected    int64
	}{
		{
			name: "subtract USD amounts",
			money1: &internationalization.Money{
				Amount:   10050, // $100.50
				Currency: usd,
			},
			money2: &internationalization.Money{
				Amount:   2500, // $25.00
				Currency: usd,
			},
			expected: 7550, // $75.50
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := tt.money1.Subtract(tt.money2)
			if tt.expectError {
				if err == nil {
					t.Errorf("expected error but got none")
				}
				return
			}
			if err != nil {
				t.Errorf("unexpected error: %v", err)
				return
			}
			if result.Amount != tt.expected {
				t.Errorf("expected amount %d, got %d", tt.expected, result.Amount)
			}
		})
	}
}

func TestMoney_Multiply(t *testing.T) {
	usd := internationalization.Currency{Code: "USD", Symbol: "$", Name: "US Dollar", DecimalPlaces: 2}

	tests := []struct {
		name        string
		money       *internationalization.Money
		factor      int64
		expectError bool
		expected    int64
	}{
		{
			name: "multiply USD amount by 2",
			money: &internationalization.Money{
				Amount:   10050, // $100.50
				Currency: usd,
			},
			factor:   2,
			expected: 20100, // $201.00
		},
		{
			name: "multiply USD amount by 0",
			money: &internationalization.Money{
				Amount:   10050,
				Currency: usd,
			},
			factor:   0,
			expected: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := tt.money.Multiply(tt.factor)
			if tt.expectError {
				if err == nil {
					t.Errorf("expected error but got none")
				}
				return
			}
			if err != nil {
				t.Errorf("unexpected error: %v", err)
				return
			}
			if result.Amount != tt.expected {
				t.Errorf("expected amount %d, got %d", tt.expected, result.Amount)
			}
		})
	}
}

func TestMoney_Format(t *testing.T) {
	tests := []struct {
		name     string
		money    *internationalization.Money
		expected string
	}{
		{
			name: "format USD",
			money: &internationalization.Money{
				Amount:   10050, // $100.50
				Currency: internationalization.Currency{Code: "USD", Symbol: "$", Name: "US Dollar", DecimalPlaces: 2},
			},
			expected: "$100.50",
		},
		{
			name: "format JPY",
			money: &internationalization.Money{
				Amount:   1000, // ¥1000
				Currency: internationalization.Currency{Code: "JPY", Symbol: "¥", Name: "Japanese Yen", DecimalPlaces: 0},
			},
			expected: "¥1000",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := tt.money.Format()
			if result != tt.expected {
				t.Errorf("expected %s, got %s", tt.expected, result)
			}
		})
	}
}

func TestMoney_MarshalJSON(t *testing.T) {
	money := &internationalization.Money{
		Amount:   10050, // $100.50
		Currency: internationalization.Currency{Code: "USD", Symbol: "$", Name: "US Dollar", DecimalPlaces: 2},
	}

	data, err := json.Marshal(money)
	if err != nil {
		t.Errorf("failed to marshal money: %v", err)
		return
	}

	// Verify the JSON contains both integer and decimal representations
	var result map[string]interface{}
	if err := json.Unmarshal(data, &result); err != nil {
		t.Errorf("failed to unmarshal JSON: %v", err)
		return
	}

	if result["amount"] != float64(10050) {
		t.Errorf("expected amount 10050, got %v", result["amount"])
	}

	if result["decimal"] != 100.5 {
		t.Errorf("expected decimal 100.5, got %v", result["decimal"])
	}
}

func TestMoney_UnmarshalJSON(t *testing.T) {
	tests := []struct {
		name        string
		json        string
		expectError bool
		expected    int64
	}{
		{
			name:     "unmarshal integer format",
			json:     `{"amount": 10050, "currency": {"code": "USD", "symbol": "$", "name": "US Dollar", "decimal_places": 2}}`,
			expected: 10050,
		},
		{
			name:     "unmarshal decimal format (backward compatibility)",
			json:     `{"amount": 100.50, "currency": {"code": "USD", "symbol": "$", "name": "US Dollar", "decimal_places": 2}}`,
			expected: 10050,
		},
		{
			name:     "unmarshal custom format with decimal field",
			json:     `{"amount": 10050, "decimal": 100.50, "currency": {"code": "USD", "symbol": "$", "name": "US Dollar", "decimal_places": 2}}`,
			expected: 10050,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var money internationalization.Money
			err := json.Unmarshal([]byte(tt.json), &money)
			if tt.expectError {
				if err == nil {
					t.Errorf("expected error but got none")
				}
				return
			}
			if err != nil {
				t.Errorf("unexpected error: %v", err)
				return
			}
			if money.Amount != tt.expected {
				t.Errorf("expected amount %d, got %d", tt.expected, money.Amount)
			}
		})
	}
}

func TestMoney_Validate(t *testing.T) {
	tests := []struct {
		name        string
		money       *internationalization.Money
		expectError bool
	}{
		{
			name: "valid money",
			money: &internationalization.Money{
				Amount:   10050,
				Currency: internationalization.Currency{Code: "USD", Symbol: "$", Name: "US Dollar", DecimalPlaces: 2},
			},
		},
		{
			name: "invalid currency",
			money: &internationalization.Money{
				Amount:   10050,
				Currency: internationalization.Currency{Code: "", Symbol: "", Name: "", DecimalPlaces: 2},
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.money.Validate()
			if tt.expectError {
				if err == nil {
					t.Errorf("expected error but got none")
				}
				return
			}
			if err != nil {
				t.Errorf("unexpected error: %v", err)
			}
		})
	}
}

func TestMoney_IsZero_IsPositive_IsNegative(t *testing.T) {
	usd := internationalization.Currency{Code: "USD", Symbol: "$", Name: "US Dollar", DecimalPlaces: 2}

	tests := []struct {
		name       string
		amount     int64
		isZero     bool
		isPositive bool
		isNegative bool
	}{
		{
			name:       "zero amount",
			amount:     0,
			isZero:     true,
			isPositive: false,
			isNegative: false,
		},
		{
			name:       "positive amount",
			amount:     10050,
			isZero:     false,
			isPositive: true,
			isNegative: false,
		},
		{
			name:       "negative amount",
			amount:     -10050,
			isZero:     false,
			isPositive: false,
			isNegative: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			money := &internationalization.Money{
				Amount:   tt.amount,
				Currency: usd,
			}

			if money.IsZero() != tt.isZero {
				t.Errorf("IsZero: expected %v, got %v", tt.isZero, money.IsZero())
			}

			if money.IsPositive() != tt.isPositive {
				t.Errorf("IsPositive: expected %v, got %v", tt.isPositive, money.IsPositive())
			}

			if money.IsNegative() != tt.isNegative {
				t.Errorf("IsNegative: expected %v, got %v", tt.isNegative, money.IsNegative())
			}
		})
	}
}
