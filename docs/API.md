# PSM Enterprise API Documentation

## Overview

The PSM Enterprise API provides access to the multi-cloud serverless mesh powering Purple Squirrel Media.

**Base URLs:**
- Vercel: `https://vercel-dusky-pi.vercel.app`
- Unified Gateway: `http://localhost:3002`
- Netlify: `https://psm-enterprise.netlify.app` (pending)
- Deno: `https://psm-api.deno.dev` (pending)

## Authentication

Most endpoints are public. Protected endpoints require an API key:

```
Authorization: Bearer <api_key>
```

Or via query parameter:
```
?api_key=<api_key>
```

## Endpoints

### Status

Check service status.

```http
GET /api/status
```

**Response:**
```json
{
  "service": "PSM Edge Functions",
  "provider": "Vercel",
  "region": "iad1",
  "version": "1.0.0",
  "timestamp": "2025-12-30T16:00:00.000Z",
  "status": "operational"
}
```

---

### Health Check

Get service health information.

```http
GET /api/health
```

**Response:**
```json
{
  "status": "healthy",
  "checks": {
    "vercel": true,
    "memory": "edge",
    "region": "iad1"
  },
  "timestamp": "2025-12-30T16:00:00.000Z"
}
```

---

### Cloud Mesh Status

Get all cloud providers and their status.

```http
GET /api/clouds
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `provider` | string | Filter by specific provider |

**Response:**
```json
{
  "totalProviders": 12,
  "activeProviders": 4,
  "clouds": {
    "azure": { "status": "active", "services": 9 },
    "oracle": { "status": "active", "services": 4 },
    "vercel": { "status": "active", "services": 7 },
    "cloudflare": { "status": "pending", "services": 7 }
  },
  "timestamp": "2025-12-30T16:00:00.000Z"
}
```

---

### Unified Gateway Health

Check all cloud endpoints at once (Gateway only).

```http
GET /api/health
```

**Response:**
```json
{
  "status": "degraded",
  "uptime": "92%",
  "online": 11,
  "total": 12,
  "clouds": {
    "azure": {
      "website": { "status": "online", "latency": 380 },
      "vision": { "status": "online", "latency": 120 }
    },
    "oracle": {
      "jellyfin": { "status": "online", "latency": 122 }
    },
    "vercel": {
      "status": { "status": "online", "latency": 201 }
    }
  },
  "timestamp": "2025-12-30T16:00:00.000Z"
}
```

---

### AI Vision Analysis

Analyze images using Azure Computer Vision (Processor only).

```http
POST /api/process
Content-Type: application/json
```

**Request Body:**
```json
{
  "image_url": "https://example.com/image.jpg",
  "operations": ["tags", "description", "objects", "faces"]
}
```

**Response:**
```json
{
  "success": true,
  "results": {
    "tags": ["outdoor", "sky", "building"],
    "description": "A modern building against blue sky",
    "objects": [
      { "name": "building", "confidence": 0.95 }
    ]
  },
  "processingTime": 1250
}
```

---

## Rate Limits

| Tier | Requests/min | Requests/day |
|------|--------------|--------------|
| Free | 60 | 1,000 |
| Pro | 300 | 10,000 |
| Enterprise | Unlimited | Unlimited |

Rate limit headers:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 55
X-RateLimit-Reset: 1704067200
```

---

## Error Responses

```json
{
  "error": "Error Type",
  "message": "Human readable message",
  "code": "ERROR_CODE",
  "timestamp": "2025-12-30T16:00:00.000Z"
}
```

**Error Codes:**
| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Invalid or missing API key |
| `RATE_LIMITED` | 429 | Too many requests |
| `NOT_FOUND` | 404 | Endpoint not found |
| `INTERNAL_ERROR` | 500 | Server error |
| `SERVICE_UNAVAILABLE` | 503 | Cloud service offline |

---

## SDKs

### JavaScript/TypeScript

```javascript
const PSM = {
  baseUrl: 'https://vercel-dusky-pi.vercel.app',

  async status() {
    const res = await fetch(`${this.baseUrl}/api/status`);
    return res.json();
  },

  async health() {
    const res = await fetch(`${this.baseUrl}/api/health`);
    return res.json();
  },

  async clouds(provider) {
    const url = provider
      ? `${this.baseUrl}/api/clouds?provider=${provider}`
      : `${this.baseUrl}/api/clouds`;
    const res = await fetch(url);
    return res.json();
  }
};

// Usage
const status = await PSM.status();
console.log(status);
```

### Python

```python
import requests

class PSM:
    BASE_URL = "https://vercel-dusky-pi.vercel.app"

    @classmethod
    def status(cls):
        return requests.get(f"{cls.BASE_URL}/api/status").json()

    @classmethod
    def health(cls):
        return requests.get(f"{cls.BASE_URL}/api/health").json()

    @classmethod
    def clouds(cls, provider=None):
        url = f"{cls.BASE_URL}/api/clouds"
        if provider:
            url += f"?provider={provider}"
        return requests.get(url).json()

# Usage
status = PSM.status()
print(status)
```

### cURL

```bash
# Status
curl https://vercel-dusky-pi.vercel.app/api/status

# Health
curl https://vercel-dusky-pi.vercel.app/api/health

# Clouds
curl https://vercel-dusky-pi.vercel.app/api/clouds

# Specific provider
curl "https://vercel-dusky-pi.vercel.app/api/clouds?provider=azure"
```

---

## Webhooks

Configure webhooks to receive notifications:

```json
POST /api/webhooks/register
{
  "url": "https://your-server.com/webhook",
  "events": ["service.down", "service.up", "quota.warning"],
  "secret": "your-webhook-secret"
}
```

---

## Live Endpoints

| Provider | URL | Status |
|----------|-----|--------|
| Vercel | https://vercel-dusky-pi.vercel.app/api/status | ✅ Live |
| Azure | https://purplesquirrel.media | ✅ Live |
| Oracle | http://163.192.105.31:8096 | ✅ Live |
| Gateway | http://localhost:3002/api/status | ✅ Local |
| Cloudflare | Pending subdomain registration | 🟡 Pending |
| Netlify | Pending deployment | 🟡 Pending |
| Deno | Pending deployment | 🟡 Pending |
