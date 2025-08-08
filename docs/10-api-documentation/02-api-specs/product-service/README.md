# Product Service API

## Overview

The Product Service manages product catalog, inventory, and product-related data. It provides comprehensive product management capabilities including product creation, categorization, inventory tracking, and product search functionality.

## Base URL

```
https://api.example.com/v1/products
```

## Authentication

Most endpoints require authentication using JWT tokens:

```
Authorization: Bearer <jwt_token>
```

Public endpoints (product browsing) do not require authentication.

## Endpoints

### Product Management Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/products` | List all products | No |
| GET | `/products/{id}` | Get product by ID | No |
| POST | `/products` | Create new product | Yes |
| PUT | `/products/{id}` | Update product | Yes |
| DELETE | `/products/{id}` | Delete product | Yes |
| GET | `/products/search` | Search products | No |

### Category Management Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/categories` | List all categories | No |
| GET | `/categories/{id}` | Get category by ID | No |
| POST | `/categories` | Create new category | Yes |
| PUT | `/categories/{id}` | Update category | Yes |
| DELETE | `/categories/{id}` | Delete category | Yes |

### Inventory Management Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/products/{id}/inventory` | Get product inventory | No |
| PUT | `/products/{id}/inventory` | Update product inventory | Yes |
| POST | `/products/{id}/inventory/adjust` | Adjust inventory | Yes |

## Request/Response Examples

### Get Product by ID

**Request:**
```bash
GET /v1/products/550e8400-e29b-41d4-a716-446655440000
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "iPhone 15 Pro",
    "description": "Latest iPhone with advanced features",
    "sku": "IPHONE-15-PRO-128",
    "price": {
      "amount": 999.99,
      "currency": "USD"
    },
    "category": {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Smartphones",
      "slug": "smartphones"
    },
    "images": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "url": "https://example.com/images/iphone15pro.jpg",
        "alt": "iPhone 15 Pro",
        "is_primary": true
      }
    ],
    "attributes": {
      "color": "Space Black",
      "storage": "128GB",
      "screen_size": "6.1 inches"
    },
    "inventory": {
      "quantity": 50,
      "reserved": 5,
      "available": 45,
      "low_stock_threshold": 10
    },
    "status": "active",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "Product retrieved successfully",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### Create Product

**Request:**
```bash
POST /v1/products
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "name": "MacBook Air M2",
  "description": "Lightweight laptop with M2 chip",
  "sku": "MACBOOK-AIR-M2-256",
  "price": {
    "amount": 1199.99,
    "currency": "USD"
  },
  "category_id": "550e8400-e29b-41d4-a716-446655440003",
  "attributes": {
    "color": "Silver",
    "storage": "256GB",
    "memory": "8GB"
  },
  "inventory": {
    "quantity": 25,
    "low_stock_threshold": 5
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440004",
    "name": "MacBook Air M2",
    "description": "Lightweight laptop with M2 chip",
    "sku": "MACBOOK-AIR-M2-256",
    "price": {
      "amount": 1199.99,
      "currency": "USD"
    },
    "category": {
      "id": "550e8400-e29b-41d4-a716-446655440003",
      "name": "Laptops",
      "slug": "laptops"
    },
    "images": [],
    "attributes": {
      "color": "Silver",
      "storage": "256GB",
      "memory": "8GB"
    },
    "inventory": {
      "quantity": 25,
      "reserved": 0,
      "available": 25,
      "low_stock_threshold": 5
    },
    "status": "active",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "Product created successfully",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### Search Products

**Request:**
```bash
GET /v1/products/search?q=iphone&category=smartphones&min_price=500&max_price=1000&page=1&limit=10
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "iPhone 15 Pro",
      "description": "Latest iPhone with advanced features",
      "sku": "IPHONE-15-PRO-128",
      "price": {
        "amount": 999.99,
        "currency": "USD"
      },
      "category": {
        "id": "550e8400-e29b-41d4-a716-446655440001",
        "name": "Smartphones",
        "slug": "smartphones"
      },
      "images": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440002",
          "url": "https://example.com/images/iphone15pro.jpg",
          "alt": "iPhone 15 Pro",
          "is_primary": true
        }
      ],
      "inventory": {
        "quantity": 50,
        "available": 45
      },
      "status": "active"
    }
  ],
  "message": "Products found",
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

### Update Product Inventory

**Request:**
```bash
PUT /v1/products/550e8400-e29b-41d4-a716-446655440000/inventory
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "quantity": 75,
  "reserved": 10,
  "low_stock_threshold": 15
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "quantity": 75,
    "reserved": 10,
    "available": 65,
    "low_stock_threshold": 15,
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "Inventory updated successfully",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

## Data Models

### Product Model

```json
{
  "id": "uuid",
  "name": "string",
  "description": "string",
  "sku": "string",
  "price": "Price",
  "category": "Category",
  "images": "ProductImage[]",
  "attributes": "object",
  "inventory": "Inventory",
  "status": "active|inactive|discontinued",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Price Model

```json
{
  "amount": "decimal",
  "currency": "USD|EUR|GBP|JPY"
}
```

### Category Model

```json
{
  "id": "uuid",
  "name": "string",
  "slug": "string",
  "description": "string|null",
  "parent_id": "uuid|null",
  "image_url": "string|null",
  "status": "active|inactive"
}
```

### Inventory Model

```json
{
  "quantity": "integer",
  "reserved": "integer",
  "available": "integer",
  "low_stock_threshold": "integer"
}
```

### Product Image Model

```json
{
  "id": "uuid",
  "url": "string",
  "alt": "string",
  "is_primary": "boolean",
  "order": "integer"
}
```

## Query Parameters

### List Products
- `page` (integer): Page number (default: 1)
- `limit` (integer): Items per page (default: 20, max: 100)
- `category` (string): Filter by category slug
- `status` (string): Filter by status (active, inactive, discontinued)
- `min_price` (decimal): Minimum price filter
- `max_price` (decimal): Maximum price filter
- `sort` (string): Sort field (name, price, created_at, updated_at)
- `order` (string): Sort order (asc, desc)

### Search Products
- `q` (string): Search query
- `category` (string): Filter by category
- `min_price` (decimal): Minimum price
- `max_price` (decimal): Maximum price
- `in_stock` (boolean): Filter by stock availability
- `page` (integer): Page number
- `limit` (integer): Items per page

## Error Responses

### Not Found Error

```json
{
  "success": false,
  "data": null,
  "message": "Product not found",
  "errors": [
    {
      "field": "id",
      "message": "Product with ID 550e8400-e29b-41d4-a716-446655440000 not found",
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
      "field": "sku",
      "message": "SKU is already in use",
      "code": "VALIDATION_ERROR"
    },
    {
      "field": "price.amount",
      "message": "Price must be greater than 0",
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

- **Public endpoints**: Product browsing, search, and viewing
- **Admin endpoints**: Product creation, updates, deletion
- **Inventory management**: Requires admin or inventory manager role

### Data Privacy

- Product data is publicly accessible for browsing
- Inventory details may be limited for non-admin users
- Audit logs track all product modifications

## Integration Examples

### JavaScript/Node.js

```javascript
const axios = require('axios');

// Get product by ID
const getProduct = async (productId) => {
  const response = await axios.get(`/v1/products/${productId}`);
  return response.data;
};

// Create product
const createProduct = async (productData, token) => {
  const response = await axios.post('/v1/products', productData, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  return response.data;
};

// Search products
const searchProducts = async (query) => {
  const response = await axios.get('/v1/products/search', {
    params: { q: query }
  });
  return response.data;
};

// Update inventory
const updateInventory = async (productId, inventoryData, token) => {
  const response = await axios.put(`/v1/products/${productId}/inventory`, inventoryData, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  return response.data;
};
```

### Python

```python
import requests

def get_product(product_id):
    response = requests.get(f'/v1/products/{product_id}')
    return response.json()

def create_product(product_data, token):
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    response = requests.post('/v1/products', 
                          json=product_data, headers=headers)
    return response.json()

def search_products(query):
    params = {'q': query}
    response = requests.get('/v1/products/search', params=params)
    return response.json()

def update_inventory(product_id, inventory_data, token):
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    response = requests.put(f'/v1/products/{product_id}/inventory', 
                          json=inventory_data, headers=headers)
    return response.json()
```

## Monitoring

Key metrics to monitor:

- Product creation rates
- Inventory updates frequency
- Search query patterns
- Product view counts
- Stock level alerts
- API response times
- Error rates by endpoint
- Category popularity
