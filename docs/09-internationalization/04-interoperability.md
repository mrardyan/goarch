# Internationalization Interoperability Guide

This guide provides comprehensive examples of how the internationalization domain types work together and integrate with external systems.

## Overview

The internationalization domain types are designed to work seamlessly together and with external systems. This guide covers:
- **Cross-type operations** between different domain types
- **External API integration** with third-party services
- **Serialization/deserialization** for JSON, XML, and other formats
- **Validation chains** across multiple types
- **Business logic patterns** using multiple domain types

## Cross-Type Operations

### Money and Timezone Integration

```go
package main

import (
    "time"
    intl "golang-arch/internal/shared/domain/internationalization"
)

// PaymentWithTimezone represents a payment with timezone-aware processing
type PaymentWithTimezone struct {
    Money      *intl.Money
    ProcessedAt *intl.LocalizedDateTime
    Timezone   *intl.Timezone
}

// NewPaymentWithTimezone creates a payment with timezone information
func NewPaymentWithTimezone(amount float64, currencyCode, timezoneID string) (*PaymentWithTimezone, error) {
    // Create currency
    currency, err := intl.NewCurrencyFromCode(currencyCode)
    if err != nil {
        return nil, fmt.Errorf("invalid currency: %w", err)
    }
    
    // Create money
    	money, err := intl.NewMoneyFromDecimal(amount, *currency)
    if err != nil {
        return nil, fmt.Errorf("invalid money: %w", err)
    }
    
    // Create timezone
    timezone, err := intl.NewTimezoneFromID(timezoneID)
    if err != nil {
        return nil, fmt.Errorf("invalid timezone: %w", err)
    }
    
    // Create localized datetime
    now := intl.NewTimeFromTime(time.Now())
    processedAt, err := intl.NewLocalizedDateTime(*now, *timezone)
    if err != nil {
        return nil, fmt.Errorf("invalid localized datetime: %w", err)
    }
    
    return &PaymentWithTimezone{
        Money:       money,
        ProcessedAt: processedAt,
        Timezone:    timezone,
    }, nil
}

// IsBusinessHours checks if the payment was processed during business hours
func (p *PaymentWithTimezone) IsBusinessHours() bool {
    localTime := p.ProcessedAt.ToTime()
    hour := localTime.Hour()
    
    // Business hours: 9 AM to 5 PM
    return hour >= 9 && hour < 17
}

// GetFormattedAmount returns the amount formatted in the local timezone
func (p *PaymentWithTimezone) GetFormattedAmount() string {
    return fmt.Sprintf("%s processed at %s", 
        p.Money.Format(),
        p.ProcessedAt.Format("2006-01-02 15:04:05"))
}
```

### Phone and Timezone Integration

```go
package main

import (
    intl "golang-arch/internal/shared/domain/internationalization"
)

// ContactWithTimezone represents a contact with timezone-aware communication
type ContactWithTimezone struct {
    Phone    *intl.LocalizedPhone
    Timezone *intl.Timezone
}

// NewContactWithTimezone creates a contact with timezone information
func NewContactWithTimezone(phone *intl.LocalizedPhone, timezoneID string) (*ContactWithTimezone, error) {
    timezone, err := intl.NewTimezoneFromID(timezoneID)
    if err != nil {
        return nil, fmt.Errorf("invalid timezone: %w", err)
    }
    
    return &ContactWithTimezone{
        Phone:    phone,
        Timezone: timezone,
    }, nil
}

// IsCallableNow checks if it's appropriate to call this contact now
func (c *ContactWithTimezone) IsCallableNow() bool {
    now := time.Now()
    localTime := now.In(c.Timezone.ToLocation())
    hour := localTime.Hour()
    
    // Callable hours: 9 AM to 9 PM
    return hour >= 9 && hour < 21
}

// GetCallableWindow returns the callable time window for this contact
func (c *ContactWithTimezone) GetCallableWindow() string {
    return fmt.Sprintf("Callable between 9 AM and 9 PM %s time", c.Timezone.Name)
}
```

## External API Integration

### Currency Exchange API

```go
package main

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "time"
    intl "golang-arch/internal/shared/domain/internationalization"
)

// ExchangeRate represents an exchange rate from an external API
type ExchangeRate struct {
    FromCurrency string  `json:"from_currency"`
    ToCurrency   string  `json:"to_currency"`
    Rate         float64 `json:"rate"`
    Timestamp    int64   `json:"timestamp"`
}

// CurrencyExchangeService integrates with external exchange rate APIs
type CurrencyExchangeService struct {
    client *http.Client
    apiKey string
}

func NewCurrencyExchangeService(apiKey string) *CurrencyExchangeService {
    return &CurrencyExchangeService{
        client: &http.Client{Timeout: 10 * time.Second},
        apiKey: apiKey,
    }
}

// ConvertMoney converts money from one currency to another
func (s *CurrencyExchangeService) ConvertMoney(ctx context.Context, money *intl.Money, targetCurrencyCode string) (*intl.Money, error) {
    // Get exchange rate
    rate, err := s.getExchangeRate(ctx, money.Currency.Code, targetCurrencyCode)
    if err != nil {
        return nil, fmt.Errorf("failed to get exchange rate: %w", err)
    }
    
    // Create target currency
    targetCurrency, err := intl.NewCurrencyFromCode(targetCurrencyCode)
    if err != nil {
        return nil, fmt.Errorf("invalid target currency: %w", err)
    }
    
    // Calculate converted amount
    convertedAmount := money.Amount * rate
    
    // Create new money with converted amount
    	convertedMoney, err := intl.NewMoneyFromDecimal(convertedAmount, *targetCurrency)
    if err != nil {
        return nil, fmt.Errorf("failed to create converted money: %w", err)
    }
    
    return convertedMoney, nil
}

// getExchangeRate fetches exchange rate from external API
func (s *CurrencyExchangeService) getExchangeRate(ctx context.Context, from, to string) (float64, error) {
    url := fmt.Sprintf("https://api.exchangerate-api.com/v4/latest/%s", from)
    
    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return 0, err
    }
    
    resp, err := s.client.Do(req)
    if err != nil {
        return 0, err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        return 0, fmt.Errorf("API returned status: %d", resp.StatusCode)
    }
    
    var result struct {
        Rates map[string]float64 `json:"rates"`
    }
    
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return 0, err
    }
    
    rate, exists := result.Rates[to]
    if !exists {
        return 0, fmt.Errorf("exchange rate not found for %s to %s", from, to)
    }
    
    return rate, nil
}
```

### Timezone API Integration

```go
package main

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "time"
    intl "golang-arch/internal/shared/domain/internationalization"
)

// TimezoneAPIResponse represents response from timezone API
type TimezoneAPIResponse struct {
    TimezoneID string `json:"timezone_id"`
    Offset     int    `json:"offset_seconds"`
    Name       string `json:"timezone_name"`
}

// TimezoneService integrates with external timezone APIs
type TimezoneService struct {
    client *http.Client
}

func NewTimezoneService() *TimezoneService {
    return &TimezoneService{
        client: &http.Client{Timeout: 10 * time.Second},
    }
}

// GetTimezoneByLocation gets timezone information by coordinates
func (s *TimezoneService) GetTimezoneByLocation(ctx context.Context, lat, lng float64) (*intl.Timezone, error) {
    url := fmt.Sprintf("https://api.timezonedb.com/v2.1/get-time-zone?key=YOUR_API_KEY&format=json&by=position&lat=%.6f&lng=%.6f", lat, lng)
    
    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, err
    }
    
    resp, err := s.client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("API returned status: %d", resp.StatusCode)
    }
    
    var result TimezoneAPIResponse
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }
    
    return intl.NewTimezone(result.TimezoneID, result.Name, result.Offset/60)
}
```

## Serialization and Deserialization

### JSON Serialization

```go
package main

import (
    "encoding/json"
    "fmt"
    intl "golang-arch/internal/shared/domain/internationalization"
)

// InternationalizedUser represents a user with internationalized data
type InternationalizedUser struct {
    ID       string                `json:"id"`
    Name     string                `json:"name"`
    Money    *intl.Money           `json:"money"`
    Phone    *intl.LocalizedPhone  `json:"phone"`
    Created  *intl.LocalizedDateTime `json:"created"`
}

// MarshalJSON customizes JSON serialization
func (u *InternationalizedUser) MarshalJSON() ([]byte, error) {
    type Alias InternationalizedUser
    
    return json.Marshal(&struct {
        *Alias
        MoneyAmount   float64 `json:"money_amount"`
        MoneyCurrency string  `json:"money_currency"`
        PhoneNumber   string  `json:"phone_number"`
        CreatedEpoch  int64   `json:"created_epoch"`
        CreatedTZ     string  `json:"created_timezone"`
    }{
        Alias:         (*Alias)(u),
        MoneyAmount:   u.Money.Amount,
        MoneyCurrency: u.Money.Currency.Code,
        PhoneNumber:   u.Phone.Phone.Format(),
        CreatedEpoch:  u.Created.Time.Epoch,
        CreatedTZ:     u.Created.Timezone.ID,
    })
}

// UnmarshalJSON customizes JSON deserialization
func (u *InternationalizedUser) UnmarshalJSON(data []byte) error {
    type Alias InternationalizedUser
    
    aux := &struct {
        *Alias
        MoneyAmount   float64 `json:"money_amount"`
        MoneyCurrency string  `json:"money_currency"`
        PhoneNumber   string  `json:"phone_number"`
        CreatedEpoch  int64   `json:"created_epoch"`
        CreatedTZ     string  `json:"created_timezone"`
    }{
        Alias: (*Alias)(u),
    }
    
    if err := json.Unmarshal(data, &aux); err != nil {
        return err
    }
    
    // Reconstruct Money
    currency, err := intl.NewCurrencyFromCode(aux.MoneyCurrency)
    if err != nil {
        return fmt.Errorf("invalid currency: %w", err)
    }
    
    	money, err := intl.NewMoneyFromDecimal(aux.MoneyAmount, *currency)
    if err != nil {
        return fmt.Errorf("invalid money: %w", err)
    }
    u.Money = money
    
    // Reconstruct Phone
    phone, err := intl.NewPhoneFromString(aux.PhoneNumber)
    if err != nil {
        return fmt.Errorf("invalid phone: %w", err)
    }
    
    timezone, err := intl.NewTimezoneFromID("America/New_York") // Default timezone
    if err != nil {
        return fmt.Errorf("invalid timezone: %w", err)
    }
    
    localizedPhone, err := intl.NewLocalizedPhone(*phone, "United States", "", *timezone)
    if err != nil {
        return fmt.Errorf("invalid localized phone: %w", err)
    }
    u.Phone = localizedPhone
    
    // Reconstruct LocalizedDateTime
    timeValue, err := intl.FromPrimitive(aux.CreatedEpoch)
    if err != nil {
        return fmt.Errorf("invalid time: %w", err)
    }
    
    timezone, err = intl.NewTimezoneFromID(aux.CreatedTZ)
    if err != nil {
        return fmt.Errorf("invalid timezone: %w", err)
    }
    
    localizedDateTime, err := intl.NewLocalizedDateTime(*timeValue, *timezone)
    if err != nil {
        return fmt.Errorf("invalid localized datetime: %w", err)
    }
    u.Created = localizedDateTime
    
    return nil
}
```

### XML Serialization

```go
package main

import (
    "encoding/xml"
    "fmt"
    intl "golang-arch/internal/shared/domain/internationalization"
)

// InternationalizedOrder represents an order with internationalized data
type InternationalizedOrder struct {
    ID          string                `xml:"id"`
    CustomerID  string                `xml:"customer_id"`
    Amount      *intl.Money           `xml:"amount"`
    Phone       *intl.LocalizedPhone  `xml:"phone"`
    OrderTime   *intl.LocalizedDateTime `xml:"order_time"`
}

// MarshalXML customizes XML serialization
func (o *InternationalizedOrder) MarshalXML(e *xml.Encoder, start xml.StartElement) error {
    type Alias InternationalizedOrder
    
    return e.EncodeElement(&struct {
        *Alias
        AmountValue    float64 `xml:"amount_value"`
        AmountCurrency string  `xml:"amount_currency"`
        PhoneNumber    string  `xml:"phone_number"`
        OrderEpoch     int64   `xml:"order_epoch"`
        OrderTimezone  string  `xml:"order_timezone"`
    }{
        Alias:          (*Alias)(o),
        AmountValue:    o.Amount.Amount,
        AmountCurrency: o.Amount.Currency.Code,
        PhoneNumber:    o.Phone.Phone.Format(),
        OrderEpoch:     o.OrderTime.Time.Epoch,
        OrderTimezone:  o.OrderTime.Timezone.ID,
    }, start)
}
```

## Validation Chains

### Cross-Type Validation

```go
package main

import (
    "fmt"
    "time"
    intl "golang-arch/internal/shared/domain/internationalization"
)

// PaymentValidator validates payments with cross-type validation
type PaymentValidator struct{}

// ValidatePayment validates a payment with multiple domain types
func (v *PaymentValidator) ValidatePayment(payment *PaymentWithTimezone) error {
    // Validate individual types
    if err := payment.Money.Validate(); err != nil {
        return fmt.Errorf("invalid money: %w", err)
    }
    
    if err := payment.ProcessedAt.Validate(); err != nil {
        return fmt.Errorf("invalid processed time: %w", err)
    }
    
    if err := payment.Timezone.Validate(); err != nil {
        return fmt.Errorf("invalid timezone: %w", err)
    }
    
    // Cross-type validation: Check if payment is within business hours
    if !payment.IsBusinessHours() {
        return fmt.Errorf("payment processed outside business hours")
    }
    
    // Cross-type validation: Check if amount is reasonable for the timezone
    if err := v.validateAmountForTimezone(payment.Money, payment.Timezone); err != nil {
        return fmt.Errorf("amount validation failed: %w", err)
    }
    
    return nil
}

// validateAmountForTimezone validates amount based on timezone
func (v *PaymentValidator) validateAmountForTimezone(money *intl.Money, timezone *intl.Timezone) error {
    // Example: Different amount limits for different timezones
    switch timezone.ID {
    case "America/New_York":
        if money.Amount > 10000.0 {
            return fmt.Errorf("amount exceeds limit for Eastern timezone")
        }
    case "Europe/London":
        if money.Amount > 8000.0 {
            return fmt.Errorf("amount exceeds limit for London timezone")
        }
    case "Asia/Tokyo":
        if money.Amount > 12000.0 {
            return fmt.Errorf("amount exceeds limit for Tokyo timezone")
        }
    }
    
    return nil
}
```

### Business Rule Validation

```go
package main

import (
    "fmt"
    "time"
    intl "golang-arch/internal/shared/domain/internationalization"
)

// BusinessRuleValidator validates business rules across multiple domain types
type BusinessRuleValidator struct{}

// ValidateInternationalTransaction validates international transactions
func (v *BusinessRuleValidator) ValidateInternationalTransaction(
    amount *intl.Money,
    phone *intl.LocalizedPhone,
    time *intl.LocalizedDateTime,
) error {
    // Rule 1: Currency must match phone country
    if err := v.validateCurrencyForCountry(amount.Currency, phone.Country); err != nil {
        return fmt.Errorf("currency validation failed: %w", err)
    }
    
    // Rule 2: Transaction time must be within phone timezone business hours
    if err := v.validateTransactionTime(phone, time); err != nil {
        return fmt.Errorf("transaction time validation failed: %w", err)
    }
    
    // Rule 3: Amount limits based on phone region
    if err := v.validateAmountForRegion(amount, phone.Region); err != nil {
        return fmt.Errorf("amount validation failed: %w", err)
    }
    
    return nil
}

// validateCurrencyForCountry validates currency matches country
func (v *BusinessRuleValidator) validateCurrencyForCountry(currency *intl.Currency, country string) error {
    expectedCurrencies := map[string]string{
        "United States": "USD",
        "United Kingdom": "GBP",
        "Germany":       "EUR",
        "Japan":         "JPY",
    }
    
    expected, exists := expectedCurrencies[country]
    if !exists {
        return nil // Unknown country, skip validation
    }
    
    if currency.Code != expected {
        return fmt.Errorf("currency %s does not match country %s", currency.Code, country)
    }
    
    return nil
}

// validateTransactionTime validates transaction time for phone timezone
func (v *BusinessRuleValidator) validateTransactionTime(phone *intl.LocalizedPhone, time *intl.LocalizedDateTime) error {
    localTime := time.ToTime()
    hour := localTime.Hour()
    
    // Business hours: 9 AM to 5 PM
    if hour < 9 || hour >= 17 {
        return fmt.Errorf("transaction outside business hours for %s", phone.Country)
    }
    
    return nil
}

// validateAmountForRegion validates amount based on region
func (v *BusinessRuleValidator) validateAmountForRegion(amount *intl.Money, region string) error {
    limits := map[string]float64{
        "New York":    10000.0,
        "California":  8000.0,
        "London":      6000.0,
        "Berlin":      7000.0,
    }
    
    limit, exists := limits[region]
    if !exists {
        return nil // Unknown region, skip validation
    }
    
    if amount.Amount > limit {
        return fmt.Errorf("amount %.2f exceeds limit %.2f for region %s", amount.Amount, limit, region)
    }
    
    return nil
}
```

## Business Logic Patterns

### Multi-Currency Payment Processing

```go
package main

import (
    "context"
    "fmt"
    "time"
    intl "golang-arch/internal/shared/domain/internationalization"
)

// MultiCurrencyPaymentProcessor handles payments in multiple currencies
type MultiCurrencyPaymentProcessor struct {
    exchangeService *CurrencyExchangeService
    validator       *BusinessRuleValidator
}

func NewMultiCurrencyPaymentProcessor(apiKey string) *MultiCurrencyPaymentProcessor {
    return &MultiCurrencyPaymentProcessor{
        exchangeService: NewCurrencyExchangeService(apiKey),
        validator:       &BusinessRuleValidator{},
    }
}

// ProcessInternationalPayment processes an international payment
func (p *MultiCurrencyPaymentProcessor) ProcessInternationalPayment(
    ctx context.Context,
    amount *intl.Money,
    phone *intl.LocalizedPhone,
    targetCurrency string,
) (*PaymentResult, error) {
    // Validate the payment
    timeValue := intl.NewTimeFromTime(time.Now())
    timezone, err := intl.NewTimezoneFromID(phone.Timezone.ID)
    if err != nil {
        return nil, fmt.Errorf("invalid timezone: %w", err)
    }
    
    localizedTime, err := intl.NewLocalizedDateTime(*timeValue, *timezone)
    if err != nil {
        return nil, fmt.Errorf("invalid localized time: %w", err)
    }
    
    if err := p.validator.ValidateInternationalTransaction(amount, phone, localizedTime); err != nil {
        return nil, fmt.Errorf("validation failed: %w", err)
    }
    
    // Convert to target currency if different
    var convertedAmount *intl.Money
    if amount.Currency.Code != targetCurrency {
        convertedAmount, err = p.exchangeService.ConvertMoney(ctx, amount, targetCurrency)
        if err != nil {
            return nil, fmt.Errorf("currency conversion failed: %w", err)
        }
    } else {
        convertedAmount = amount
    }
    
    // Create payment result
    result := &PaymentResult{
        OriginalAmount: amount,
        ConvertedAmount: convertedAmount,
        Phone: phone,
        ProcessedAt: localizedTime,
        ExchangeRate: 1.0, // Will be calculated if conversion occurred
    }
    
    return result, nil
}

// PaymentResult represents the result of a payment processing
type PaymentResult struct {
    OriginalAmount   *intl.Money
    ConvertedAmount  *intl.Money
    Phone            *intl.LocalizedPhone
    ProcessedAt      *intl.LocalizedDateTime
    ExchangeRate     float64
}

// GetFormattedResult returns a formatted string representation
func (r *PaymentResult) GetFormattedResult() string {
    if r.OriginalAmount.Currency.Code == r.ConvertedAmount.Currency.Code {
        return fmt.Sprintf("Payment of %s processed at %s for %s",
            r.ConvertedAmount.Format(),
            r.ProcessedAt.Format("2006-01-02 15:04:05"),
            r.Phone.GetFullLocation())
    }
    
    return fmt.Sprintf("Payment of %s converted to %s (rate: %.4f) processed at %s for %s",
        r.OriginalAmount.Format(),
        r.ConvertedAmount.Format(),
        r.ExchangeRate,
        r.ProcessedAt.Format("2006-01-02 15:04:05"),
        r.Phone.GetFullLocation())
}
```

### Timezone-Aware Scheduling

```go
package main

import (
    "fmt"
    "time"
    intl "golang-arch/internal/shared/domain/internationalization"
)

// TimezoneAwareScheduler schedules events with timezone awareness
type TimezoneAwareScheduler struct{}

// ScheduleMeeting schedules a meeting with timezone considerations
func (s *TimezoneAwareScheduler) ScheduleMeeting(
    title string,
    duration time.Duration,
    participants []*intl.LocalizedPhone,
    startTime *intl.LocalizedDateTime,
) (*MeetingSchedule, error) {
    // Validate all participants can attend at the proposed time
    for _, participant := range participants {
        if !s.isTimeSuitableForParticipant(startTime, participant) {
            return nil, fmt.Errorf("time not suitable for participant %s", participant.Phone.Format())
        }
    }
    
    // Calculate end time
    endTime := startTime.Add(duration)
    
    // Create meeting schedule
    schedule := &MeetingSchedule{
        Title:        title,
        StartTime:    startTime,
        EndTime:      endTime,
        Duration:     duration,
        Participants: participants,
    }
    
    return schedule, nil
}

// isTimeSuitableForParticipant checks if the time is suitable for a participant
func (s *TimezoneAwareScheduler) isTimeSuitableForParticipant(time *intl.LocalizedDateTime, participant *intl.LocalizedPhone) bool {
    // Convert meeting time to participant's timezone
    participantTime := time.ToTime().In(participant.Timezone.ToLocation())
    hour := participantTime.Hour()
    
    // Suitable hours: 9 AM to 6 PM
    return hour >= 9 && hour < 18
}

// MeetingSchedule represents a scheduled meeting
type MeetingSchedule struct {
    Title        string
    StartTime    *intl.LocalizedDateTime
    EndTime      *intl.LocalizedDateTime
    Duration     time.Duration
    Participants []*intl.LocalizedPhone
}

// GetFormattedSchedule returns a formatted schedule
func (m *MeetingSchedule) GetFormattedSchedule() string {
    result := fmt.Sprintf("Meeting: %s\n", m.Title)
    result += fmt.Sprintf("Start: %s\n", m.StartTime.Format("2006-01-02 15:04:05"))
    result += fmt.Sprintf("End: %s\n", m.EndTime.Format("2006-01-02 15:04:05"))
    result += fmt.Sprintf("Duration: %s\n", m.Duration)
    result += "Participants:\n"
    
    for _, participant := range m.Participants {
        result += fmt.Sprintf("  - %s (%s)\n", participant.Phone.Format(), participant.GetFullLocation())
    }
    
    return result
}
```

## Integration Examples

### REST API Integration

```go
package main

import (
    "encoding/json"
    "net/http"
    "time"
    intl "golang-arch/internal/shared/domain/internationalization"
)

// InternationalizedAPIHandler handles API requests with internationalized data
type InternationalizedAPIHandler struct {
    paymentProcessor *MultiCurrencyPaymentProcessor
    scheduler        *TimezoneAwareScheduler
}

// PaymentRequest represents a payment request from API
type PaymentRequest struct {
    Amount          float64 `json:"amount"`
    Currency        string  `json:"currency"`
    PhoneNumber     string  `json:"phone_number"`
    Country         string  `json:"country"`
    Region          string  `json:"region"`
    TargetCurrency  string  `json:"target_currency"`
}

// PaymentResponse represents a payment response
type PaymentResponse struct {
    Success         bool    `json:"success"`
    OriginalAmount  string  `json:"original_amount"`
    ConvertedAmount string  `json:"converted_amount"`
    ProcessedAt     string  `json:"processed_at"`
    Message         string  `json:"message"`
}

// HandlePayment handles payment API requests
func (h *InternationalizedAPIHandler) HandlePayment(w http.ResponseWriter, r *http.Request) {
    var req PaymentRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request", http.StatusBadRequest)
        return
    }
    
    // Create domain types
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
    
    phone, err := intl.NewPhoneFromString(req.PhoneNumber)
    if err != nil {
        http.Error(w, "Invalid phone number", http.StatusBadRequest)
        return
    }
    
    timezone, err := intl.NewTimezoneFromID("America/New_York") // Default
    if err != nil {
        http.Error(w, "Invalid timezone", http.StatusBadRequest)
        return
    }
    
    localizedPhone, err := intl.NewLocalizedPhone(*phone, req.Country, req.Region, *timezone)
    if err != nil {
        http.Error(w, "Invalid phone data", http.StatusBadRequest)
        return
    }
    
    // Process payment
    result, err := h.paymentProcessor.ProcessInternationalPayment(
        r.Context(),
        money,
        localizedPhone,
        req.TargetCurrency,
    )
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Create response
    response := PaymentResponse{
        Success:         true,
        OriginalAmount:  result.OriginalAmount.Format(),
        ConvertedAmount: result.ConvertedAmount.Format(),
        ProcessedAt:     result.ProcessedAt.Format("2006-01-02 15:04:05"),
        Message:         "Payment processed successfully",
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}
```

### Database Integration with Multiple Types

```go
package main

import (
    "context"
    "database/sql"
    "fmt"
    intl "golang-arch/internal/shared/domain/internationalization"
)

// InternationalizedOrderRepository handles orders with internationalized data
type InternationalizedOrderRepository struct {
    db *sql.DB
}

// Order represents an order with internationalized data
type Order struct {
    ID          int
    CustomerID  string
    Amount      *intl.Money
    Phone       *intl.LocalizedPhone
    OrderTime   *intl.LocalizedDateTime
    Status      string
}

// SaveOrder saves an order with internationalized data
func (r *InternationalizedOrderRepository) SaveOrder(ctx context.Context, order *Order) error {
    // Extract primitive values
    amount, currencyCode := order.Amount.ToPrimitive()
    phoneStr, country, region, timezoneID := order.Phone.ToPrimitive()
    epoch, orderTimezoneID := order.OrderTime.ToPrimitive()
    
    query := `
        INSERT INTO orders (
            customer_id, amount, currency_code, 
            phone_number, country, region, timezone_id,
            order_epoch, order_timezone_id, status, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW())
        RETURNING id
    `
    
    var id int
    err := r.db.QueryRowContext(ctx, query,
        order.CustomerID, amount, currencyCode,
        phoneStr, country, region, timezoneID,
        epoch, orderTimezoneID, order.Status,
    ).Scan(&id)
    if err != nil {
        return fmt.Errorf("failed to save order: %w", err)
    }
    
    order.ID = id
    return nil
}

// GetOrderByID retrieves an order by ID
func (r *InternationalizedOrderRepository) GetOrderByID(ctx context.Context, id int) (*Order, error) {
    query := `
        SELECT customer_id, amount, currency_code,
               phone_number, country, region, timezone_id,
               order_epoch, order_timezone_id, status
        FROM orders
        WHERE id = $1
    `
    
    var (
        customerID, currencyCode, phoneStr, country, region, timezoneID string
        amount                                                                 float64
        orderEpoch                                                           int64
        orderTimezoneID                                                      string
        status                                                               string
    )
    
    err := r.db.QueryRowContext(ctx, query, id).Scan(
        &customerID, &amount, &currencyCode,
        &phoneStr, &country, &region, &timezoneID,
        &orderEpoch, &orderTimezoneID, &status,
    )
    if err != nil {
        return nil, fmt.Errorf("failed to get order: %w", err)
    }
    
    // Reconstruct domain types
    money, err := intl.NewMoneyFromPrimitive(amount, currencyCode)
    if err != nil {
        return nil, fmt.Errorf("failed to create money: %w", err)
    }
    
    localizedPhone, err := intl.NewLocalizedPhoneFromPrimitive(phoneStr, country, region, timezoneID)
    if err != nil {
        return nil, fmt.Errorf("failed to create localized phone: %w", err)
    }
    
    localizedDateTime, err := intl.NewLocalizedDateTimeFromPrimitive(orderEpoch, orderTimezoneID)
    if err != nil {
        return nil, fmt.Errorf("failed to create localized datetime: %w", err)
    }
    
    return &Order{
        ID:         id,
        CustomerID: customerID,
        Amount:     money,
        Phone:      localizedPhone,
        OrderTime:  localizedDateTime,
        Status:     status,
    }, nil
}
```

This guide demonstrates comprehensive interoperability patterns for the internationalization domain types, showing how they work together and integrate with external systems effectively.
