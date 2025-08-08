# Authentication Service API

## Overview

The Authentication Service provides user authentication, authorization, and session management capabilities. It handles user registration, login, password management, and JWT token generation.

## Base URL

```
https://api.example.com/v1/auth
```

## Authentication

This service uses JWT (JSON Web Tokens) for authentication. Include the JWT token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

## Endpoints

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/register` | Register a new user |
| POST | `/login` | Authenticate user and get token |
| POST | `/logout` | Logout user (invalidate token) |
| POST | `/refresh` | Refresh access token |
| POST | `/forgot-password` | Request password reset |
| POST | `/reset-password` | Reset password with token |

### User Management Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/profile` | Get current user profile |
| PUT | `/profile` | Update user profile |
| PUT | `/change-password` | Change user password |
| DELETE | `/account` | Delete user account |

## Request/Response Examples

### Register User

**Request:**
```bash
POST /v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+1234567890",
      "status": "active",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    },
    "token": {
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expires_in": 3600,
      "token_type": "Bearer"
    }
  },
  "message": "User registered successfully",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### Login User

**Request:**
```bash
POST /v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "status": "active"
    },
    "token": {
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expires_in": 3600,
      "token_type": "Bearer"
    }
  },
  "message": "Login successful",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### Get User Profile

**Request:**
```bash
GET /v1/auth/profile
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone": "+1234567890",
    "status": "active",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "Profile retrieved successfully",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

## Error Responses

### Validation Error

```json
{
  "success": false,
  "data": null,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format",
      "code": "VALIDATION_ERROR"
    },
    {
      "field": "password",
      "message": "Password must be at least 8 characters",
      "code": "VALIDATION_ERROR"
    }
  ],
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### Authentication Error

```json
{
  "success": false,
  "data": null,
  "message": "Invalid credentials",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email or password",
      "code": "AUTHENTICATION_ERROR"
    }
  ],
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

## Data Models

### User Model

```json
{
  "id": "uuid",
  "email": "string",
  "first_name": "string",
  "last_name": "string",
  "phone": "string",
  "status": "active|inactive|suspended",
  "email_verified": "boolean",
  "phone_verified": "boolean",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Token Model

```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": "integer",
  "token_type": "Bearer"
}
```

## Security Considerations

1. **Password Requirements:**
   - Minimum 8 characters
   - At least one uppercase letter
   - At least one lowercase letter
   - At least one number
   - At least one special character

2. **Token Security:**
   - Access tokens expire in 1 hour
   - Refresh tokens expire in 7 days
   - Tokens are invalidated on logout
   - Rate limiting on authentication endpoints

3. **Rate Limiting:**
   - Login: 5 attempts per 15 minutes
   - Registration: 3 attempts per hour
   - Password reset: 3 attempts per hour

## Testing

Use the provided Postman collection (`postman-collection.json`) to test all endpoints. The collection includes:

- Pre-request scripts for token management
- Test scripts for response validation
- Environment variables for different environments
- Example requests for all endpoints

## Integration Examples

### JavaScript/Node.js

```javascript
const axios = require('axios');

// Login
const login = async (email, password) => {
  const response = await axios.post('/v1/auth/login', {
    email,
    password
  });
  return response.data;
};

// Get profile with token
const getProfile = async (token) => {
  const response = await axios.get('/v1/auth/profile', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  return response.data;
};
```

### Python

```python
import requests

# Login
def login(email, password):
    response = requests.post('/v1/auth/login', json={
        'email': email,
        'password': password
    })
    return response.json()

# Get profile with token
def get_profile(token):
    headers = {'Authorization': f'Bearer {token}'}
    response = requests.get('/v1/auth/profile', headers=headers)
    return response.json()
```

## Monitoring

Key metrics to monitor:

- Authentication success/failure rates
- Token refresh patterns
- Password reset requests
- Account creation rates
- Session duration statistics
- Failed login attempts by IP
