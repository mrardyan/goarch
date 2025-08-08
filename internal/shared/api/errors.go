package api

import (
	"errors"
	"fmt"
)

// Common API errors
var (
	ErrInvalidInput     = errors.New("invalid input")
	ErrNotFound         = errors.New("resource not found")
	ErrUnauthorized     = errors.New("unauthorized")
	ErrForbidden        = errors.New("forbidden")
	ErrInternalServer   = errors.New("internal server error")
	ErrDatabaseError    = errors.New("database error")
	ErrValidationFailed = errors.New("validation failed")
)

// APIError represents a structured API error
type APIError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

// Error implements the error interface
func (e APIError) Error() string {
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

// NewAPIError creates a new API error
func NewAPIError(code, message string) *APIError {
	return &APIError{
		Code:    code,
		Message: message,
	}
}

// WithDetails adds details to the error
func (e *APIError) WithDetails(details string) *APIError {
	e.Details = details
	return e
}

// Common error codes
const (
	ErrCodeInvalidInput     = "INVALID_INPUT"
	ErrCodeNotFound         = "NOT_FOUND"
	ErrCodeUnauthorized     = "UNAUTHORIZED"
	ErrCodeForbidden        = "FORBIDDEN"
	ErrCodeInternalServer   = "INTERNAL_SERVER_ERROR"
	ErrCodeDatabaseError    = "DATABASE_ERROR"
	ErrCodeValidationFailed = "VALIDATION_FAILED"
)

// Common error constructors
func NewInvalidInputError(message string) *APIError {
	return NewAPIError(ErrCodeInvalidInput, message)
}

func NewNotFoundError(message string) *APIError {
	return NewAPIError(ErrCodeNotFound, message)
}

func NewUnauthorizedError(message string) *APIError {
	return NewAPIError(ErrCodeUnauthorized, message)
}

func NewForbiddenError(message string) *APIError {
	return NewAPIError(ErrCodeForbidden, message)
}

func NewInternalServerError(message string) *APIError {
	return NewAPIError(ErrCodeInternalServer, message)
}

func NewDatabaseError(message string) *APIError {
	return NewAPIError(ErrCodeDatabaseError, message)
}

func NewValidationError(message string) *APIError {
	return NewAPIError(ErrCodeValidationFailed, message)
}
