# API & SDK Documentation Reference

## Table of Contents
1. [REST API Documentation Standard](#rest-api)
2. [GraphQL API Documentation](#graphql)
3. [SDK Documentation](#sdk)
4. [Authentication Documentation](#auth)
5. [Error Reference Documentation](#errors)
6. [Webhooks Documentation](#webhooks)
7. [OpenAPI / Swagger Integration](#openapi)
8. [Developer Quickstart Template](#quickstart)

---

## 1. REST API Documentation Standard {#rest-api}

### Endpoint Documentation Structure

Every API endpoint page follows this exact structure:

```markdown
# [Resource Name] API

Brief description of what this resource represents and what the API allows you to do with it.

## Base URL
```
https://api.example.com/v1
```

## Authentication
All requests require a Bearer token in the Authorization header.
See [Authentication](#) for how to obtain a token.

---

## List [Resources]
`GET /resources`

Returns a paginated list of [resources] for the authenticated account.

### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `limit` | integer | No | `20` | Number of results per page. Max: `100` |
| `offset` | integer | No | `0` | Number of results to skip for pagination |
| `status` | string | No | — | Filter by status. One of: `active`, `inactive`, `pending` |
| `created_after` | string | No | — | ISO 8601 date. Returns records created after this date |

### Request Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | `Bearer <token>` |
| `Content-Type` | No | `application/json` (recommended) |

### Response

**200 OK**

```json
{
  "data": [
    {
      "id": "res_01H9X4K8W2M3N7P",
      "name": "Production Server",
      "status": "active",
      "created_at": "2024-01-15T09:30:00Z",
      "updated_at": "2024-03-20T14:22:11Z"
    }
  ],
  "pagination": {
    "total": 142,
    "limit": 20,
    "offset": 0,
    "has_more": true
  }
}
```

**Response Fields**

| Field | Type | Description |
|-------|------|-------------|
| `data` | array | Array of resource objects |
| `data[].id` | string | Unique resource identifier. Format: `res_[alphanumeric]` |
| `data[].name` | string | Human-readable display name |
| `data[].status` | string | Current resource status |
| `data[].created_at` | string | ISO 8601 creation timestamp (UTC) |
| `pagination.total` | integer | Total number of matching records |
| `pagination.has_more` | boolean | Whether additional pages exist |

### Code Examples

```bash
# cURL
curl -X GET "https://api.example.com/v1/resources?limit=10&status=active" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json"
```

```python
# Python
import requests

response = requests.get(
    "https://api.example.com/v1/resources",
    headers={"Authorization": "Bearer YOUR_API_KEY"},
    params={"limit": 10, "status": "active"}
)

data = response.json()
resources = data["data"]
```

```javascript
// Node.js
const response = await fetch('https://api.example.com/v1/resources?limit=10&status=active', {
  headers: {
    'Authorization': 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json'
  }
});

const { data } = await response.json();
```

### Error Responses

| Status | Error Code | Description |
|--------|-----------|-------------|
| `400` | `invalid_parameter` | A query parameter is invalid. Check the `error.param` field |
| `401` | `unauthorized` | Missing or invalid API key |
| `429` | `rate_limit_exceeded` | Too many requests. Retry after the `Retry-After` header value |

---

## Create [Resource]
`POST /resources`

Creates a new [resource].

### Request Body

```json
{
  "name": "Production Server",
  "type": "primary",
  "region": "us-east-1",
  "config": {
    "timeout": 30,
    "retry_count": 3
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **Yes** | Display name. 1–128 characters |
| `type` | string | **Yes** | Resource type. One of: `primary`, `secondary`, `backup` |
| `region` | string | **Yes** | AWS region identifier (e.g., `us-east-1`) |
| `config.timeout` | integer | No | Request timeout in seconds. Default: `30`. Range: `1–300` |
| `config.retry_count` | integer | No | Number of retry attempts. Default: `3`. Range: `0–10` |

### Response

**201 Created** — Returns the created resource object.

> ⚠️ **WARNING**: Resource creation is not immediately reversible. Deleting a resource permanently removes all associated data.

```

### API Documentation Writing Rules

1. **Every parameter must have**: name, type, required/optional, description, valid values if enumerated
2. **Every response field must be documented** — no undocumented fields
3. **Show real examples** — never use `string`, `value`, `test` as example values
4. **Document all error codes** the endpoint can return
5. **Note rate limits** on every endpoint or in a prominent shared section
6. **Version the docs** — always show which API version the endpoint belongs to
7. **Link between related endpoints** — PUT links to GET, DELETE links to GET

---

## 2. GraphQL API Documentation {#graphql}

```markdown
# [Query/Mutation Name]

**Type**: Query | Mutation | Subscription

Brief description.

## Signature

```graphql
query GetUser($id: ID!, $includeProfile: Boolean = false) {
  user(id: $id) {
    id
    name
    email
    profile @include(if: $includeProfile) {
      bio
      avatarUrl
    }
  }
}
```

## Arguments

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | `ID!` | Yes | The user's unique identifier |
| `includeProfile` | `Boolean` | No | Include profile data. Default: `false` |

## Return Type: `User`

| Field | Type | Description |
|-------|------|-------------|
| `id` | `ID!` | Unique identifier |
| `name` | `String!` | Full display name |
| `email` | `String!` | Email address |
| `profile` | `UserProfile` | Profile details (null if not requested) |

## Example

```graphql
# Request
query {
  user(id: "usr_01H9X4") {
    id
    name
    email
  }
}

# Response
{
  "data": {
    "user": {
      "id": "usr_01H9X4",
      "name": "Amara Okonkwo",
      "email": "amara@example.com"
    }
  }
}
```
```

---

## 3. SDK Documentation {#sdk}

### SDK README Structure

```markdown
# [Product] SDK for [Language]

> One-sentence description of what this SDK does.

[![npm version](https://badge.fury.io/js/%40example%2Fsdk.svg)](https://badge.fury.io/js/%40example%2Fsdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Requirements

- Node.js 18+ (or Python 3.9+, etc.)
- [Product] account with API access
- API key from the [dashboard](https://dashboard.example.com/api-keys)

## Installation

```bash
npm install @example/sdk
# or
yarn add @example/sdk
```

## Quick Start

```javascript
import { ExampleClient } from '@example/sdk';

const client = new ExampleClient({
  apiKey: process.env.EXAMPLE_API_KEY,
});

// Create a resource
const resource = await client.resources.create({
  name: 'My First Resource',
  type: 'primary',
});

console.log(resource.id); // res_01H9X4K8W2M3N7P
```

## Configuration

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `apiKey` | string | Yes | — | Your API key |
| `baseUrl` | string | No | `https://api.example.com/v1` | Override the API base URL |
| `timeout` | number | No | `30000` | Request timeout in milliseconds |
| `retries` | number | No | `3` | Number of automatic retry attempts |
| `logger` | Logger | No | — | Custom logger instance |

## Handling Errors

The SDK throws typed errors for all failure cases:

```javascript
import { ExampleClient, NotFoundError, RateLimitError } from '@example/sdk';

try {
  const resource = await client.resources.get('nonexistent_id');
} catch (error) {
  if (error instanceof NotFoundError) {
    console.log('Resource not found:', error.resourceId);
  } else if (error instanceof RateLimitError) {
    console.log('Rate limited. Retry after:', error.retryAfter);
  } else {
    throw error; // Re-throw unexpected errors
  }
}
```

## Pagination

```javascript
// Manual pagination
const page1 = await client.resources.list({ limit: 20 });
if (page1.hasMore) {
  const page2 = await client.resources.list({ limit: 20, offset: 20 });
}

// Auto-pagination (iterates all results)
for await (const resource of client.resources.listAll()) {
  console.log(resource.id);
}
```
```

### SDK Method Documentation Pattern

```markdown
### `client.resources.create(params)`

Creates a new resource.

**Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `params.name` | `string` | Yes | Display name (1–128 characters) |
| `params.type` | `'primary' \| 'secondary'` | Yes | Resource type |
| `params.config` | `ResourceConfig` | No | Optional configuration object |

**Returns**: `Promise<Resource>`

**Throws**:
- `ValidationError` — If required parameters are missing or invalid
- `AuthenticationError` — If the API key is invalid
- `RateLimitError` — If the rate limit is exceeded

**Example**

```javascript
const resource = await client.resources.create({
  name: 'Staging Server',
  type: 'secondary',
  config: { timeout: 60 }
});
```
```

---

## 4. Authentication Documentation {#auth}

```markdown
# Authentication

[Product] uses API keys to authenticate requests. All API requests must include your API key.

## Getting Your API Key

1. Log in to the [Dashboard](https://dashboard.example.com)
2. Navigate to **Settings → API Keys**
3. Click **Create New Key**
4. Copy the key — it will only be shown once

> ⚠️ **WARNING**: API keys grant full access to your account. Never commit them to source control, share them publicly, or include them in client-side code.

## Using Your API Key

Include your API key as a Bearer token in the `Authorization` header of every request:

```bash
Authorization: Bearer YOUR_API_KEY
```

## Environment Variables (Recommended)

Store API keys in environment variables, not hardcoded in source files:

```bash
# .env (add to .gitignore)
EXAMPLE_API_KEY=key_live_abc123...
```

```python
import os
import example_sdk

client = example_sdk.Client(api_key=os.environ["EXAMPLE_API_KEY"])
```

## Key Types

| Type | Prefix | Scope | Use For |
|------|--------|-------|---------|
| Live key | `key_live_` | Full access | Production |
| Test key | `key_test_` | Test data only | Development, CI/CD |
| Restricted key | `key_rk_` | Configurable | Least-privilege access |

## Rate Limits

| Plan | Requests/minute | Requests/day |
|------|----------------|-------------|
| Free | 60 | 1,000 |
| Pro | 600 | 100,000 |
| Enterprise | 6,000 | Unlimited |

When rate limited, the API returns `429 Too Many Requests` with a `Retry-After` header indicating when to retry.
```

---

## 5. Error Reference Documentation {#errors}

```markdown
# API Error Reference

## Error Response Format

All errors return a consistent JSON structure:

```json
{
  "error": {
    "code": "invalid_parameter",
    "message": "The 'email' field must be a valid email address.",
    "param": "email",
    "doc_url": "https://docs.example.com/errors#invalid_parameter"
  }
}
```

| Field | Description |
|-------|-------------|
| `error.code` | Machine-readable error code (stable across API versions) |
| `error.message` | Human-readable description of the error |
| `error.param` | The specific parameter that caused the error (if applicable) |
| `error.doc_url` | Link to this error in the documentation |

## Error Code Reference

### 4xx Client Errors

| Status | Code | Description | How to Fix |
|--------|------|-------------|-----------|
| `400` | `invalid_parameter` | Request parameter is missing or malformed | Check the `param` field and correct the value |
| `400` | `invalid_json` | Request body is not valid JSON | Validate JSON syntax before sending |
| `401` | `unauthorized` | API key is missing | Include `Authorization: Bearer <key>` header |
| `401` | `invalid_api_key` | API key is invalid or revoked | Generate a new key from the dashboard |
| `403` | `forbidden` | Key lacks permission for this action | Use a key with appropriate scope |
| `404` | `not_found` | Requested resource does not exist | Verify the resource ID is correct |
| `409` | `conflict` | Resource already exists | Check if a resource with this identifier already exists |
| `422` | `validation_error` | Semantic validation failed | Review field constraints in the request body docs |
| `429` | `rate_limit_exceeded` | Too many requests | Wait for `Retry-After` seconds and retry |

### 5xx Server Errors

| Status | Code | Description | How to Fix |
|--------|------|-------------|-----------|
| `500` | `internal_error` | Unexpected server error | Retry with exponential backoff; contact support if persists |
| `503` | `service_unavailable` | Temporary maintenance | Check [status.example.com](https://status.example.com) and retry |

## Handling Errors in Code

```python
import time
import example_sdk
from example_sdk.errors import RateLimitError, InternalError

def create_resource_with_retry(client, params, max_retries=3):
    for attempt in range(max_retries):
        try:
            return client.resources.create(params)
        except RateLimitError as e:
            if attempt == max_retries - 1:
                raise
            time.sleep(e.retry_after)
        except InternalError:
            if attempt == max_retries - 1:
                raise
            time.sleep(2 ** attempt)  # Exponential backoff: 1s, 2s, 4s
```
```

---

## 6. Webhooks Documentation {#webhooks}

```markdown
# Webhooks

Webhooks allow [Product] to notify your application when events occur, without requiring
your app to poll the API.

## How Webhooks Work

1. You register an endpoint URL in the [Dashboard](https://dashboard.example.com/webhooks)
2. When an event occurs, [Product] sends an HTTP POST to your endpoint
3. Your endpoint returns `200 OK` within 30 seconds to acknowledge receipt
4. If no acknowledgment is received, [Product] retries up to 5 times with exponential backoff

## Event Payload Format

```json
{
  "id": "evt_01H9X4K8W2M3N7P",
  "type": "resource.created",
  "created_at": "2024-03-20T14:22:11Z",
  "data": {
    "object": {
      "id": "res_01H9X4",
      "name": "Production Server",
      "status": "active"
    }
  }
}
```

## Verifying Webhook Signatures

Always verify webhook signatures to confirm requests come from [Product]:

```python
import hmac
import hashlib

def verify_webhook(payload_body: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(
        secret.encode('utf-8'),
        payload_body,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(f"sha256={expected}", signature)

# In your webhook handler:
signature = request.headers.get("X-Webhook-Signature")
if not verify_webhook(request.body, signature, WEBHOOK_SECRET):
    return Response(status=401)
```

## Event Types Reference

| Event | Description |
|-------|-------------|
| `resource.created` | A new resource was created |
| `resource.updated` | A resource's properties changed |
| `resource.deleted` | A resource was permanently deleted |
| `payment.succeeded` | A payment was successfully processed |
| `payment.failed` | A payment attempt failed |
```

---

## 7. Developer Quickstart Template {#quickstart}

```markdown
# Quickstart: [Goal in 5 Minutes]

In this guide you will [specific outcome]. This takes approximately **5 minutes**.

## Before You Begin

- A [Product] account — [Sign up free](https://example.com/signup)
- [Tool] version X.X or higher installed
- Basic familiarity with [language/concept]

## Step 1: Install the SDK

```bash
npm install @example/sdk
```

## Step 2: Get Your API Key

1. Open the [Dashboard](https://dashboard.example.com)
2. Go to **Settings → API Keys**
3. Click **Create Key** and copy the value

Set it as an environment variable:

```bash
export EXAMPLE_API_KEY="key_test_..."
```

## Step 3: Make Your First Request

Create a file called `quickstart.js`:

```javascript
import { ExampleClient } from '@example/sdk';

const client = new ExampleClient({
  apiKey: process.env.EXAMPLE_API_KEY,
});

async function main() {
  // Create your first resource
  const resource = await client.resources.create({
    name: 'My First Resource',
    type: 'primary',
  });

  console.log('Created resource:', resource.id);

  // Retrieve it
  const retrieved = await client.resources.get(resource.id);
  console.log('Status:', retrieved.status);
}

main().catch(console.error);
```

Run it:

```bash
node quickstart.js
```

**Expected output:**
```
Created resource: res_01H9X4K8W2M3N7P
Status: active
```

🎉 **You're up and running!** Your first API call succeeded.

## Next Steps

- [Core Concepts](./concepts) — Understand the data model
- [Full API Reference](./api) — All endpoints and parameters
- [Example Projects](./examples) — Real-world implementation examples
- [Webhooks Guide](./webhooks) — React to events in real time
```

---

## References & Standards

- **OpenAPI Specification 3.1** — https://spec.openapis.org/oas/v3.1.0
- **Google Developer Documentation Style Guide** — https://developers.google.com/style
- **Microsoft Writing Style Guide** — https://docs.microsoft.com/en-us/style-guide/
- **Stripe API Docs** — Industry gold standard for API documentation
- **Twilio Docs** — Best-in-class developer quickstart experience
- **Write the Docs Community** — https://www.writethedocs.org/
- **"Docs for Developers"** — Bhatti et al., Apress 2021
