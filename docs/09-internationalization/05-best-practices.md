# Internationalization Best Practices

This guide provides best practices for effectively using the internationalization domain types in your Go applications.

## Core Principles

### 1. Always Use Domain Types

**✅ Good:**
```go
func ProcessPayment(amount *intl.Money) error {
    if amount.IsNegative() {
        return errors.New("cannot process negative payment")
    }
    // Process payment...
}
```

**❌ Bad:**
```go
func ProcessPayment(amount float64, currency string) error {
    // No type safety, prone to errors
}
```

### 2. Validate Early and Often

**✅ Good:**
```go
func CreateUser(name string, phone *intl.LocalizedPhone) (*User, error) {
    // Validate domain types first
    if err := phone.Validate(); err != nil {
        return nil, fmt.Errorf("invalid phone: %w", err)
    }
    
    // Then validate business rules
    if !phone.IsValidForRegistration() {
        return nil, errors.New("phone not suitable for registration")
    }
    
    // Create user...
}
```

### 3. Use Primitive Conversion for Database Operations

**✅ Good:**
```go
func (r *Repository) SaveTransaction(money *intl.Money) error {
    amount, currencyCode := money.ToPrimitive()
    
    _, err := r.db.Exec(
        "INSERT INTO transactions (amount, currency_code) VALUES ($1, $2)",
        amount, currencyCode,
    )
    return err
}
```

**❌ Bad:**
```go
// Don't store complex objects directly
_, err := r.db.Exec("INSERT INTO transactions (money) VALUES ($1)", money)
```

## Error Handling Patterns

### 1. Structured Error Messages

```go
func ValidatePayment(payment *Payment) error {
    if err := payment.Amount.Validate(); err != nil {
        return fmt.Errorf("payment validation failed: %w", err)
    }
    
    if err := payment.DateTime.Validate(); err != nil {
        return fmt.Errorf("datetime validation failed: %w", err)
    }
    
    return nil
}
```

### 2. Domain-Specific Errors

```go
type PaymentError struct {
    Code    string
    Message string
    Field   string
}

func (e *PaymentError) Error() string {
    return fmt.Sprintf("%s: %s (field: %s)", e.Code, e.Message, e.Field)
}

func ValidatePaymentAmount(money *intl.Money) error {
    if money.IsNegative() {
        return &PaymentError{
            Code:    "INVALID_AMOUNT",
            Message: "payment amount cannot be negative",
            Field:   "amount",
        }
    }
    
    return nil
}
```

## Performance Best Practices

### 1. Cache Common Values

```go
var (
    // Cache common currencies
    USD *intl.Currency
    EUR *intl.Currency
    GBP *intl.Currency
    
    // Cache common timezones
    UTC *intl.Timezone
    EST *intl.Timezone
    PST *intl.Timezone
)

func init() {
    var err error
    
    USD, err = intl.NewCurrencyFromCode("USD")
    if err != nil {
        panic(err)
    }
    
    EUR, err = intl.NewCurrencyFromCode("EUR")
    if err != nil {
        panic(err)
    }
    
    // Initialize other common values...
}
```

### 2. Use Efficient Database Queries

```go
// ✅ Good: Query on primitive values
func (r *Repository) GetTransactionsByCurrency(currencyCode string) ([]*intl.Money, error) {
    query := `
        SELECT amount, currency_code 
        FROM transactions 
        WHERE currency_code = $1
        ORDER BY created_at DESC
    `
    
    rows, err := r.db.Query(query, currencyCode)
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    var results []*intl.Money
    for rows.Next() {
        var amount float64
        var code string
        
        if err := rows.Scan(&amount, &code); err != nil {
            return nil, err
        }
        
        money, err := intl.NewMoneyFromPrimitive(amount, code)
        if err != nil {
            return nil, err
        }
        
        results = append(results, money)
    }
    
    return results, nil
}
```

## API Design Best Practices

### 1. Consistent JSON Serialization

```go
type PaymentRequest struct {
    Amount   float64 `json:"amount"`
    Currency string  `json:"currency"`
    Phone    string  `json:"phone"`
    Country  string  `json:"country"`
}

type PaymentResponse struct {
    ID              string `json:"id"`
    FormattedAmount string `json:"formatted_amount"`
    ProcessedAt     string `json:"processed_at"`
    Status          string `json:"status"`
}

func (h *Handler) ProcessPayment(w http.ResponseWriter, r *http.Request) {
    var req PaymentRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request", http.StatusBadRequest)
        return
    }
    
    // Convert to domain types
    currency, err := intl.NewCurrencyFromCode(req.Currency)
    if err != nil {
        http.Error(w, "Invalid currency", http.StatusBadRequest)
        return
    }
    
    	money, err := intl.NewMoneyFromDecimal(req.Amount, *currency)
    if err != nil {
        http.Error(w, "Invalid amount", http.StatusBadRequest)
        return
    }
    
    // Process payment...
    
    // Return formatted response
    response := PaymentResponse{
        ID:              paymentID,
        FormattedAmount: money.Format(),
        ProcessedAt:     time.Now().Format(time.RFC3339),
        Status:          "completed",
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}
```

### 2. Proper Validation in Handlers

```go
func (h *Handler) ValidatePaymentRequest(req *PaymentRequest) error {
    // Validate currency
    if req.Currency == "" {
        return errors.New("currency is required")
    }
    
    if _, err := intl.NewCurrencyFromCode(req.Currency); err != nil {
        return fmt.Errorf("invalid currency: %s", req.Currency)
    }
    
    // Validate amount
    if req.Amount <= 0 {
        return errors.New("amount must be positive")
    }
    
    // Validate phone
    if req.Phone != "" {
        if _, err := intl.NewPhoneFromString(req.Phone); err != nil {
            return fmt.Errorf("invalid phone number: %s", req.Phone)
        }
    }
    
    return nil
}
```

## Testing Best Practices

### 1. Use Table-Driven Tests

```go
func TestMoneyOperations(t *testing.T) {
    tests := []struct {
        name     string
        amount1  float64
        currency1 string
        amount2  float64
        currency2 string
        wantErr  bool
        wantAmount float64
    }{
        {
            name:      "add same currency",
            amount1:   100.0,
            currency1: "USD",
            amount2:   50.0,
            currency2: "USD",
            wantErr:   false,
            wantAmount: 150.0,
        },
        {
            name:      "add different currencies",
            amount1:   100.0,
            currency1: "USD",
            amount2:   50.0,
            currency2: "EUR",
            wantErr:   true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            currency1, _ := intl.NewCurrencyFromCode(tt.currency1)
            	money1, _ := intl.NewMoneyFromDecimal(tt.amount1, *currency1)
	
	currency2, _ := intl.NewCurrencyFromCode(tt.currency2)
	money2, _ := intl.NewMoneyFromDecimal(tt.amount2, *currency2)
            
            result, err := money1.Add(money2)
            
            if tt.wantErr {
                assert.Error(t, err)
            } else {
                assert.NoError(t, err)
                assert.Equal(t, tt.wantAmount, result.Amount)
            }
        })
    }
}
```

### 2. Test Edge Cases

```go
func TestLocalizedDateTimeEdgeCases(t *testing.T) {
    // Test invalid timezone
    _, err := intl.NewTimezoneFromID("Invalid/Timezone")
    assert.Error(t, err)
    
    // Test epoch time boundaries
    minTime, err := intl.NewTime(0)
    assert.NoError(t, err)
    
    maxTime, err := intl.NewTime(253402300799) // Year 9999
    assert.NoError(t, err)
    
    // Test timezone conversion edge cases
    timeValue := intl.NewTimeFromTime(time.Date(2023, 12, 25, 23, 59, 59, 0, time.UTC))
    timezone, _ := intl.NewTimezoneFromID("America/New_York")
    
    ldt, err := intl.NewLocalizedDateTime(*timeValue, *timezone)
    assert.NoError(t, err)
    
    // Verify timezone conversion
    localTime := ldt.ToTime()
    assert.NotEqual(t, timeValue.ToTime(), localTime)
}
```

## Business Logic Patterns

### 1. Currency-Specific Business Rules

```go
type PaymentValidator struct{}

func (v *PaymentValidator) ValidatePayment(payment *Payment) error {
    // Currency-specific validation
    switch payment.Amount.Currency.Code {
    case "USD":
        return v.validateUSDPayment(payment)
    case "EUR":
        return v.validateEURPayment(payment)
    case "JPY":
        return v.validateJPYPayment(payment)
    default:
        return v.validateGenericPayment(payment)
    }
}

func (v *PaymentValidator) validateUSDPayment(payment *Payment) error {
    // USD-specific rules
    if payment.Amount.Amount > 10000.0 {
        return errors.New("USD payment exceeds maximum limit")
    }
    
    return nil
}
```

### 2. Timezone-Aware Business Logic

```go
type SchedulingService struct{}

func (s *SchedulingService) IsBusinessHours(ldt *intl.LocalizedDateTime) bool {
    localTime := ldt.ToTime()
    hour := localTime.Hour()
    
    // Business hours: 9 AM to 5 PM
    return hour >= 9 && hour < 17
}

func (s *SchedulingService) GetNextBusinessDay(ldt *intl.LocalizedDateTime) *intl.LocalizedDateTime {
    nextDay := ldt.Add(24 * time.Hour)
    
    // Skip weekends
    for nextDay.ToTime().Weekday() == time.Saturday || nextDay.ToTime().Weekday() == time.Sunday {
        nextDay = nextDay.Add(24 * time.Hour)
    }
    
    return nextDay
}
```

## Migration Strategies

### 1. Gradual Migration

```go
// Phase 1: Add domain types alongside existing fields
type User struct {
    ID       string  `json:"id"`
    Name     string  `json:"name"`
    Phone    string  `json:"phone"`           // Old field
    PhoneObj *intl.LocalizedPhone `json:"-"`  // New field (not serialized yet)
}

// Phase 2: Update serialization
func (u *User) MarshalJSON() ([]byte, error) {
    type Alias User
    
    return json.Marshal(&struct {
        *Alias
        Phone string `json:"phone"`
    }{
        Alias: (*Alias)(u),
        Phone: u.PhoneObj.Format(),
    })
}

// Phase 3: Remove old field
type User struct {
    ID       string  `json:"id"`
    Name     string  `json:"name"`
    Phone    *intl.LocalizedPhone `json:"phone"`
}
```

### 2. Database Migration

```sql
-- Step 1: Add new columns
ALTER TABLE users ADD COLUMN phone_country VARCHAR(100);
ALTER TABLE users ADD COLUMN phone_region VARCHAR(100);
ALTER TABLE users ADD COLUMN phone_timezone_id VARCHAR(50);

-- Step 2: Migrate existing data
UPDATE users 
SET phone_country = 'United States',
    phone_region = 'Unknown',
    phone_timezone_id = 'America/New_York'
WHERE phone_country IS NULL;

-- Step 3: Make columns NOT NULL
ALTER TABLE users ALTER COLUMN phone_country SET NOT NULL;
ALTER TABLE users ALTER COLUMN phone_timezone_id SET NOT NULL;
```

## Security Considerations

### 1. Input Validation

```go
func ValidatePhoneInput(input string) error {
    // Sanitize input
    cleaned := strings.TrimSpace(input)
    
    // Validate format
    if !phoneRegex.MatchString(cleaned) {
        return errors.New("invalid phone number format")
    }
    
    // Check for suspicious patterns
    if strings.Contains(cleaned, "0000000000") {
        return errors.New("suspicious phone number pattern")
    }
    
    return nil
}
```

### 2. Currency Validation

```go
func ValidateCurrencyCode(code string) error {
    // Check against allowed currencies
    allowedCurrencies := map[string]bool{
        "USD": true, "EUR": true, "GBP": true, "JPY": true,
    }
    
    if !allowedCurrencies[code] {
        return fmt.Errorf("currency %s not supported", code)
    }
    
    return nil
}
```

## Monitoring and Observability

### 1. Structured Logging

```go
func (s *PaymentService) ProcessPayment(payment *Payment) error {
    logger.Info("processing payment",
        zap.String("currency", payment.Amount.Currency.Code),
        zap.Float64("amount", payment.Amount.Amount),
        zap.String("timezone", payment.DateTime.Timezone.ID),
    )
    
    // Process payment...
    
    logger.Info("payment processed successfully",
        zap.String("payment_id", payment.ID),
        zap.String("formatted_amount", payment.Amount.Format()),
    )
    
    return nil
}
```

### 2. Metrics Collection

```go
type PaymentMetrics struct {
    currencyCounter *prometheus.CounterVec
    amountHistogram *prometheus.HistogramVec
}

func (m *PaymentMetrics) RecordPayment(payment *Payment) {
    m.currencyCounter.WithLabelValues(payment.Amount.Currency.Code).Inc()
    m.amountHistogram.WithLabelValues(payment.Amount.Currency.Code).Observe(payment.Amount.Amount)
}
```

## Summary

Following these best practices ensures:

1. **Type Safety**: Compile-time error detection
2. **Performance**: Efficient database operations and caching
3. **Maintainability**: Clear patterns and consistent usage
4. **Security**: Proper validation and sanitization
5. **Observability**: Structured logging and metrics
6. **Testability**: Comprehensive test coverage

These patterns provide a solid foundation for building robust, internationalized applications with the domain types.
