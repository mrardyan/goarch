# API Standards and Guidelines

## Overview

This document defines the standards and guidelines for API design and documentation across all services in the golang-arch project.

## API Design Principles

### 1. RESTful Design
- Use HTTP methods appropriately (GET, POST, PUT, DELETE, PATCH)
- Use nouns for resources, not verbs
- Use plural nouns for resource collections
- Use hierarchical URLs for nested resources

### 2. URL Structure
```
https://api.example.com/v1/{service}/{resource}/{id}
```

Examples:
- `GET /v1/users` - List users
- `GET /v1/users/{id}` - Get specific user
- `POST /v1/users` - Create user
- `PUT /v1/users/{id}` - Update user
- `DELETE /v1/users/{id}` - Delete user

### 3. HTTP Status Codes

| Code | Description | Usage |
|------|-------------|-------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid request data |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Valid authentication but insufficient permissions |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource conflict |
| 422 | Unprocessable Entity | Validation errors |
| 500 | Internal Server Error | Server error |

### 4. Request/Response Headers

#### Required Headers
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

#### Optional Headers
```
X-Request-ID: {uuid}
X-Client-Version: {version}
Accept-Language: {language}
```

## Data Formats

### Request Body
```json
{
  "field1": "value1",
  "field2": "value2"
}
```

### Response Body
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "field1": "value1",
    "field2": "value2",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "Operation successful",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0",
    "request_id": "uuid"
  }
}
```

### Error Response
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
    }
  ],
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0",
    "request_id": "uuid"
  }
}
```

## Authentication

### JWT Token Authentication
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### API Key Authentication
```
X-API-Key: {api_key}
```

## Pagination

### Query Parameters
```
?page=1&limit=20&sort=created_at&order=desc
```

### Response Format
```json
{
  "success": true,
  "data": [...],
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "total_pages": 5
    }
  }
}
```

## Filtering and Sorting

### Filtering
```
?filter[status]=active&filter[created_at][gte]=2024-01-01
```

### Sorting
```
?sort=created_at&order=desc
?sort=name,created_at&order=asc,desc
```

## Rate Limiting

### Headers
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Versioning

### URL Versioning
```
https://api.example.com/v1/users
https://api.example.com/v2/users
```

### Header Versioning
```
Accept: application/vnd.api+json;version=1.0
```

## Error Codes

| Code | Description |
|------|-------------|
| VALIDATION_ERROR | Input validation failed |
| AUTHENTICATION_ERROR | Authentication failed |
| AUTHORIZATION_ERROR | Insufficient permissions |
| NOT_FOUND_ERROR | Resource not found |
| CONFLICT_ERROR | Resource conflict |
| INTERNAL_ERROR | Internal server error |

## Best Practices

### 1. Consistent Naming
- Use snake_case for field names
- Use kebab-case for URLs
- Use PascalCase for enum values

### 2. Documentation
- Document all endpoints with OpenAPI 3.0
- Include request/response examples
- Document error scenarios
- Provide Postman collections

### 3. Testing
- Include unit tests for all endpoints
- Provide integration test examples
- Document test scenarios

### 4. Security
- Validate all inputs
- Sanitize data
- Use HTTPS only
- Implement proper authentication
- Log security events

### 5. Performance
- Implement caching where appropriate
- Use pagination for large datasets
- Optimize database queries
- Monitor response times

## OpenAPI 3.0 Template

```yaml
openapi: 3.0.0
info:
  title: Service API
  version: 1.0.0
  description: API documentation for service

servers:
  - url: https://api.example.com/v1
    description: Production server

security:
  - bearerAuth: []

paths:
  /resource:
    get:
      summary: List resources
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ResourceList'

components:
  schemas:
    Resource:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        created_at:
          type: string
          format: date-time

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

## Validation Rules

### Common Validation Patterns

| Field Type | Validation Rules |
|------------|------------------|
| Email | RFC 5322 format |
| Phone | E.164 format |
| UUID | RFC 4122 format |
| Date | ISO 8601 format |
| URL | Valid URL format |
| Password | Minimum 8 characters, mixed case, numbers |

### Custom Validation

```go
type ValidationRule struct {
    Field   string `json:"field"`
    Rule    string `json:"rule"`
    Message string `json:"message"`
}
```

## Monitoring and Logging

### Metrics to Track
- Request/response times
- Error rates
- Rate limit usage
- Authentication failures
- Database query performance

### Logging Standards
```json
{
  "level": "info",
  "timestamp": "2024-01-01T00:00:00Z",
  "request_id": "uuid",
  "method": "GET",
  "path": "/v1/users",
  "status_code": 200,
  "response_time": 150,
  "user_id": "uuid",
  "ip_address": "192.168.1.1"
}
```
