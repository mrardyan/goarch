# User Service API

## Overview

The User Service manages user profiles, preferences, and user-related data. It provides comprehensive user management capabilities including profile management, user preferences, and user search functionality.

## Base URL

```
https://api.example.com/v1/users
```

## Authentication

All endpoints require authentication using JWT tokens:

```
Authorization: Bearer <jwt_token>
```

## Endpoints

### User Management Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users` | List all users (admin only) |
| GET | `/users/{id}` | Get user by ID |
| POST | `/users` | Create new user |
| PUT | `/users/{id}` | Update user |
| DELETE | `/users/{id}` | Delete user |
| GET | `/users/search` | Search users |

### Profile Management Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users/{id}/profile` | Get user profile |
| PUT | `/users/{id}/profile` | Update user profile |
| GET | `/users/{id}/preferences` | Get user preferences |
| PUT | `/users/{id}/preferences` | Update user preferences |

### User Status Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/users/{id}/activate` | Activate user account |
| PUT | `/users/{id}/deactivate` | Deactivate user account |
| PUT | `/users/{id}/suspend` | Suspend user account |

## Request/Response Examples

### Get User by ID

**Request:**
```bash
GET /v1/users/550e8400-e29b-41d4-a716-446655440000
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
    "email_verified": true,
    "phone_verified": false,
    "profile": {
      "avatar": "https://example.com/avatar.jpg",
      "bio": "Software developer",
      "location": "New York, NY",
      "website": "https://example.com",
      "social_links": {
        "twitter": "https://twitter.com/johndoe",
        "linkedin": "https://linkedin.com/in/johndoe"
      }
    },
    "preferences": {
      "language": "en",
      "timezone": "America/New_York",
      "currency": "USD",
      "notifications": {
        "email": true,
        "sms": false,
        "push": true
      }
    },
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "User retrieved successfully",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### Create User

**Request:**
```bash
POST /v1/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "email": "newuser@example.com",
  "first_name": "Jane",
  "last_name": "Smith",
  "phone": "+1234567891",
  "profile": {
    "bio": "Product manager",
    "location": "San Francisco, CA"
  },
  "preferences": {
    "language": "en",
    "timezone": "America/Los_Angeles",
    "currency": "USD"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "email": "newuser@example.com",
    "first_name": "Jane",
    "last_name": "Smith",
    "phone": "+1234567891",
    "status": "active",
    "email_verified": false,
    "phone_verified": false,
    "profile": {
      "avatar": null,
      "bio": "Product manager",
      "location": "San Francisco, CA",
      "website": null,
      "social_links": {}
    },
    "preferences": {
      "language": "en",
      "timezone": "America/Los_Angeles",
      "currency": "USD",
      "notifications": {
        "email": true,
        "sms": false,
        "push": true
      }
    },
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "User created successfully",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### Update User Profile

**Request:**
```bash
PUT /v1/users/550e8400-e29b-41d4-a716-446655440000/profile
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "bio": "Senior software developer with 5+ years experience",
  "location": "Austin, TX",
  "website": "https://johndoe.dev",
  "social_links": {
    "twitter": "https://twitter.com/johndoe",
    "linkedin": "https://linkedin.com/in/johndoe",
    "github": "https://github.com/johndoe"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "avatar": "https://example.com/avatar.jpg",
    "bio": "Senior software developer with 5+ years experience",
    "location": "Austin, TX",
    "website": "https://johndoe.dev",
    "social_links": {
      "twitter": "https://twitter.com/johndoe",
      "linkedin": "https://linkedin.com/in/johndoe",
      "github": "https://github.com/johndoe"
    }
  },
  "message": "Profile updated successfully",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### Search Users

**Request:**
```bash
GET /v1/users/search?q=john&status=active&page=1&limit=10
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "john.doe@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "status": "active",
      "profile": {
        "avatar": "https://example.com/avatar.jpg",
        "bio": "Software developer",
        "location": "New York, NY"
      }
    }
  ],
  "message": "Users found",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0",
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 1,
      "total_pages": 1
    }
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
  "profile": "UserProfile",
  "preferences": "UserPreferences",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### User Profile Model

```json
{
  "avatar": "string|null",
  "bio": "string|null",
  "location": "string|null",
  "website": "string|null",
  "social_links": {
    "twitter": "string|null",
    "linkedin": "string|null",
    "github": "string|null",
    "facebook": "string|null"
  }
}
```

### User Preferences Model

```json
{
  "language": "en|es|fr|de",
  "timezone": "string",
  "currency": "USD|EUR|GBP",
  "notifications": {
    "email": "boolean",
    "sms": "boolean",
    "push": "boolean"
  }
}
```

## Query Parameters

### List Users
- `page` (integer): Page number (default: 1)
- `limit` (integer): Items per page (default: 20, max: 100)
- `status` (string): Filter by status (active, inactive, suspended)
- `sort` (string): Sort field (created_at, updated_at, first_name, last_name)
- `order` (string): Sort order (asc, desc)

### Search Users
- `q` (string): Search query
- `status` (string): Filter by status
- `location` (string): Filter by location
- `page` (integer): Page number
- `limit` (integer): Items per page

## Error Responses

### Not Found Error

```json
{
  "success": false,
  "data": null,
  "message": "User not found",
  "errors": [
    {
      "field": "id",
      "message": "User with ID 550e8400-e29b-41d4-a716-446655440000 not found",
      "code": "NOT_FOUND_ERROR"
    }
  ],
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### Validation Error

```json
{
  "success": false,
  "data": null,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Email is already registered",
      "code": "VALIDATION_ERROR"
    },
    {
      "field": "phone",
      "message": "Invalid phone number format",
      "code": "VALIDATION_ERROR"
    }
  ],
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

## Security and Permissions

### Access Control

- **Public endpoints**: None
- **User endpoints**: Users can only access their own data
- **Admin endpoints**: Admin users can access all user data
- **Search endpoints**: Limited to admin users or with proper permissions

### Data Privacy

- Sensitive data (passwords, tokens) are never returned
- Personal information is masked for non-owner requests
- Audit logs track all data access

## Integration Examples

### JavaScript/Node.js

```javascript
const axios = require('axios');

// Get user by ID
const getUser = async (userId, token) => {
  const response = await axios.get(`/v1/users/${userId}`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  return response.data;
};

// Update user profile
const updateProfile = async (userId, profileData, token) => {
  const response = await axios.put(`/v1/users/${userId}/profile`, profileData, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  return response.data;
};

// Search users
const searchUsers = async (query, token) => {
  const response = await axios.get('/v1/users/search', {
    params: { q: query },
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

def get_user(user_id, token):
    headers = {'Authorization': f'Bearer {token}'}
    response = requests.get(f'/v1/users/{user_id}', headers=headers)
    return response.json()

def update_profile(user_id, profile_data, token):
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    response = requests.put(f'/v1/users/{user_id}/profile', 
                          json=profile_data, headers=headers)
    return response.json()

def search_users(query, token):
    headers = {'Authorization': f'Bearer {token}'}
    params = {'q': query}
    response = requests.get('/v1/users/search', 
                          params=params, headers=headers)
    return response.json()
```

## Monitoring

Key metrics to monitor:

- User creation rates
- Profile update frequency
- Search query patterns
- User status changes
- API response times
- Error rates by endpoint
- Data access patterns
