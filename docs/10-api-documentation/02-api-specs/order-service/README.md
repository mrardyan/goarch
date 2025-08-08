# Order Service API

## Overview

The Order Service manages order processing, order lifecycle, and order-related data. It provides comprehensive order management capabilities including order creation, status tracking, payment processing, and order history.

## Base URL

```
https://api.example.com/v1/orders
```

## Authentication

All endpoints require authentication using JWT tokens:

```
Authorization: Bearer <jwt_token>
```

## Endpoints

### Order Management Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/orders` | List user orders |
| GET | `/orders/{id}` | Get order by ID |
| POST | `/orders` | Create new order |
| PUT | `/orders/{id}` | Update order |
| DELETE | `/orders/{id}` | Cancel order |
| GET | `/orders/{id}/status` | Get order status |

### Order Items Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/orders/{id}/items` | Get order items |
| POST | `/orders/{id}/items` | Add item to order |
| PUT | `/orders/{id}/items/{item_id}` | Update order item |
| DELETE | `/orders/{id}/items/{item_id}` | Remove item from order |

### Payment Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/orders/{id}/payments` | Process payment |
| GET | `/orders/{id}/payments` | Get payment history |
| POST | `/orders/{id}/payments/refund` | Process refund |

### Admin Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/orders` | List all orders (admin) |
| PUT | `/admin/orders/{id}/status` | Update order status (admin) |
| GET | `/admin/orders/analytics` | Get order analytics (admin) |

## Request/Response Examples

### Create Order

**Request:**
```bash
POST /v1/orders
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "items": [
    {
      "product_id": "550e8400-e29b-41d4-a716-446655440000",
      "quantity": 2,
      "unit_price": 999.99
    },
    {
      "product_id": "550e8400-e29b-41d4-a716-446655440001",
      "quantity": 1,
      "unit_price": 199.99
    }
  ],
  "shipping_address": {
    "first_name": "John",
    "last_name": "Doe",
    "address_line_1": "123 Main St",
    "address_line_2": "Apt 4B",
    "city": "New York",
    "state": "NY",
    "postal_code": "10001",
    "country": "US",
    "phone": "+1234567890"
  },
  "billing_address": {
    "first_name": "John",
    "last_name": "Doe",
    "address_line_1": "123 Main St",
    "address_line_2": "Apt 4B",
    "city": "New York",
    "state": "NY",
    "postal_code": "10001",
    "country": "US"
  },
  "payment_method": {
    "type": "credit_card",
    "token": "tok_visa"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "user_id": "550e8400-e29b-41d4-a716-446655440003",
    "order_number": "ORD-2024-001",
    "status": "pending",
    "items": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440004",
        "product_id": "550e8400-e29b-41d4-a716-446655440000",
        "product_name": "iPhone 15 Pro",
        "quantity": 2,
        "unit_price": 999.99,
        "total_price": 1999.98
      },
      {
        "id": "550e8400-e29b-41d4-a716-446655440005",
        "product_id": "550e8400-e29b-41d4-a716-446655440001",
        "product_name": "AirPods Pro",
        "quantity": 1,
        "unit_price": 199.99,
        "total_price": 199.99
      }
    ],
    "subtotal": 2199.97,
    "tax": 219.99,
    "shipping": 29.99,
    "total": 2449.95,
    "currency": "USD",
    "shipping_address": {
      "first_name": "John",
      "last_name": "Doe",
      "address_line_1": "123 Main St",
      "address_line_2": "Apt 4B",
      "city": "New York",
      "state": "NY",
      "postal_code": "10001",
      "country": "US",
      "phone": "+1234567890"
    },
    "billing_address": {
      "first_name": "John",
      "last_name": "Doe",
      "address_line_1": "123 Main St",
      "address_line_2": "Apt 4B",
      "city": "New York",
      "state": "NY",
      "postal_code": "10001",
      "country": "US"
    },
    "payment_status": "pending",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "Order created successfully",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### Get Order by ID

**Request:**
```bash
GET /v1/orders/550e8400-e29b-41d4-a716-446655440002
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "user_id": "550e8400-e29b-41d4-a716-446655440003",
    "order_number": "ORD-2024-001",
    "status": "processing",
    "items": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440004",
        "product_id": "550e8400-e29b-41d4-a716-446655440000",
        "product_name": "iPhone 15 Pro",
        "product_image": "https://example.com/images/iphone15pro.jpg",
        "quantity": 2,
        "unit_price": 999.99,
        "total_price": 1999.98
      }
    ],
    "subtotal": 2199.97,
    "tax": 219.99,
    "shipping": 29.99,
    "total": 2449.95,
    "currency": "USD",
    "shipping_address": {
      "first_name": "John",
      "last_name": "Doe",
      "address_line_1": "123 Main St",
      "address_line_2": "Apt 4B",
      "city": "New York",
      "state": "NY",
      "postal_code": "10001",
      "country": "US",
      "phone": "+1234567890"
    },
    "billing_address": {
      "first_name": "John",
      "last_name": "Doe",
      "address_line_1": "123 Main St",
      "address_line_2": "Apt 4B",
      "city": "New York",
      "state": "NY",
      "postal_code": "10001",
      "country": "US"
    },
    "payment_status": "paid",
    "payment_method": {
      "type": "credit_card",
      "last4": "4242",
      "brand": "visa"
    },
    "tracking": {
      "carrier": "FedEx",
      "tracking_number": "123456789012",
      "status": "in_transit",
      "estimated_delivery": "2024-01-05T00:00:00Z"
    },
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "Order retrieved successfully",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### Process Payment

**Request:**
```bash
POST /v1/orders/550e8400-e29b-41d4-a716-446655440002/payments
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "payment_method": {
    "type": "credit_card",
    "token": "tok_visa"
  },
  "amount": 2449.95
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440006",
    "order_id": "550e8400-e29b-41d4-a716-446655440002",
    "amount": 2449.95,
    "currency": "USD",
    "status": "succeeded",
    "payment_method": {
      "type": "credit_card",
      "last4": "4242",
      "brand": "visa"
    },
    "transaction_id": "txn_123456789",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "message": "Payment processed successfully",
  "errors": null,
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### List User Orders

**Request:**
```bash
GET /v1/orders?page=1&limit=10&status=completed
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "order_number": "ORD-2024-001",
      "status": "completed",
      "total": 2449.95,
      "currency": "USD",
      "items_count": 2,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ],
  "message": "Orders retrieved successfully",
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

### Order Model

```json
{
  "id": "uuid",
  "user_id": "uuid",
  "order_number": "string",
  "status": "pending|processing|shipped|delivered|cancelled|refunded",
  "items": "OrderItem[]",
  "subtotal": "decimal",
  "tax": "decimal",
  "shipping": "decimal",
  "total": "decimal",
  "currency": "string",
  "shipping_address": "Address",
  "billing_address": "Address",
  "payment_status": "pending|paid|failed|refunded",
  "payment_method": "PaymentMethod",
  "tracking": "Tracking|null",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Order Item Model

```json
{
  "id": "uuid",
  "product_id": "uuid",
  "product_name": "string",
  "product_image": "string|null",
  "quantity": "integer",
  "unit_price": "decimal",
  "total_price": "decimal"
}
```

### Address Model

```json
{
  "first_name": "string",
  "last_name": "string",
  "address_line_1": "string",
  "address_line_2": "string|null",
  "city": "string",
  "state": "string",
  "postal_code": "string",
  "country": "string",
  "phone": "string|null"
}
```

### Payment Method Model

```json
{
  "type": "credit_card|paypal|apple_pay|google_pay",
  "last4": "string|null",
  "brand": "visa|mastercard|amex|discover|null"
}
```

### Tracking Model

```json
{
  "carrier": "string",
  "tracking_number": "string",
  "status": "pending|in_transit|delivered|failed",
  "estimated_delivery": "datetime|null"
}
```

## Query Parameters

### List Orders
- `page` (integer): Page number (default: 1)
- `limit` (integer): Items per page (default: 20, max: 100)
- `status` (string): Filter by status
- `payment_status` (string): Filter by payment status
- `date_from` (date): Filter by start date
- `date_to` (date): Filter by end date
- `sort` (string): Sort field (created_at, updated_at, total)
- `order` (string): Sort order (asc, desc)

## Error Responses

### Not Found Error

```json
{
  "success": false,
  "data": null,
  "message": "Order not found",
  "errors": [
    {
      "field": "id",
      "message": "Order with ID 550e8400-e29b-41d4-a716-446655440000 not found",
      "code": "NOT_FOUND_ERROR"
    }
  ],
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

### Payment Error

```json
{
  "success": false,
  "data": null,
  "message": "Payment failed",
  "errors": [
    {
      "field": "payment_method",
      "message": "Card declined",
      "code": "PAYMENT_ERROR"
    }
  ],
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

## Order Status Flow

1. **pending**: Order created, awaiting payment
2. **processing**: Payment received, order being processed
3. **shipped**: Order shipped with tracking
4. **delivered**: Order delivered to customer
5. **cancelled**: Order cancelled (before shipping)
6. **refunded**: Order refunded

## Security and Permissions

### Access Control

- **User endpoints**: Users can only access their own orders
- **Admin endpoints**: Admin users can access all orders
- **Payment processing**: Requires valid payment method

### Data Privacy

- Order details are only accessible to the order owner
- Payment information is masked for security
- Audit logs track all order modifications

## Integration Examples

### JavaScript/Node.js

```javascript
const axios = require('axios');

// Create order
const createOrder = async (orderData, token) => {
  const response = await axios.post('/v1/orders', orderData, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  return response.data;
};

// Get order by ID
const getOrder = async (orderId, token) => {
  const response = await axios.get(`/v1/orders/${orderId}`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  return response.data;
};

// Process payment
const processPayment = async (orderId, paymentData, token) => {
  const response = await axios.post(`/v1/orders/${orderId}/payments`, paymentData, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  return response.data;
};

// List user orders
const listOrders = async (params, token) => {
  const response = await axios.get('/v1/orders', {
    params,
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

def create_order(order_data, token):
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    response = requests.post('/v1/orders', 
                          json=order_data, headers=headers)
    return response.json()

def get_order(order_id, token):
    headers = {'Authorization': f'Bearer {token}'}
    response = requests.get(f'/v1/orders/{order_id}', headers=headers)
    return response.json()

def process_payment(order_id, payment_data, token):
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    response = requests.post(f'/v1/orders/{order_id}/payments', 
                          json=payment_data, headers=headers)
    return response.json()

def list_orders(params, token):
    headers = {'Authorization': f'Bearer {token}'}
    response = requests.get('/v1/orders', 
                          params=params, headers=headers)
    return response.json()
```

## Monitoring

Key metrics to monitor:

- Order creation rates
- Payment success/failure rates
- Order status transitions
- Average order value
- Cart abandonment rates
- Shipping and delivery times
- Refund rates
- API response times
- Error rates by endpoint
