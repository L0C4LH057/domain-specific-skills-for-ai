---
name: saas-multitenant-db
description: >
  Expert SaaS multi-tenant database architect. Use for: multi-tenant schema design; tenancy
  isolation models (shared/hybrid/silo); rate limiting and throttling to prevent server overload;
  connection pooling; query optimization; healthcare SaaS (HMS, EMR, lab management, pharmacy,
  bed management, finance, HR, accounting); education, legal, logistics, manufacturing, real
  estate, e-commerce, and construction SaaS platforms. Also triggers for: handle thousands of
  tenants, prevent DB overload, tenant data isolation, row-level security, connection pool
  exhaustion, query throttling, sharding strategy, HIPAA/GDPR compliance, SaaS database best
  practices. Always use for any multi-tenant architecture, SaaS backend design, enterprise
  database planning, or domain schema question.
---

# SaaS Multi-Tenant Database Designer

Senior-level expertise in multi-tenant SaaS database architecture, request management,
domain modeling, and production-grade database engineering across all major verticals.

---

## STEP 1 — CLASSIFY THE REQUEST

Identify the task type before proceeding:

| Task | Action |
|------|--------|
| **Schema design** (new system) | → Phase 2: Tenancy Model + Phase 5 (domain) |
| **Request / throttling / rate limiting** | → Phase 3: Request Management |
| **Performance / slow queries / overload** | → Phase 4: Performance |
| **Domain-specific design** (healthcare, etc.) | → Phase 5: Domain Knowledge |
| **DB configuration / tuning** | → Phase 6: DB Best Practices |
| **Migration / tenant onboarding** | → Phase 7: Operations |
| **Security / isolation** | → Phase 2 isolation section + references/security.md |

For complex requests spanning multiple areas, work through each phase in sequence.

---

## PHASE 2 — MULTI-TENANCY MODELS

### 2.1 — The Three Isolation Models

**MODEL A: SHARED DATABASE, SHARED SCHEMA (Pool Model)**
- All tenants in one DB, separated by `tenant_id` column
- Row-Level Security (RLS) enforced at DB layer
- Pros: Lowest cost, easiest ops, instant provisioning
- Cons: Noisy neighbor risk, complex queries, RLS bugs = data leak
- **Use when:** >1,000 tenants, cost-sensitive, similar data shapes

**MODEL B: SHARED DATABASE, SEPARATE SCHEMA (Bridge Model)**
- One DB, one schema per tenant (`tenant_abc.patients`, `tenant_xyz.patients`)
- Pros: Strong logical isolation, easier per-tenant migrations, no RLS complexity
- Cons: Schema explosion at scale (>500 schemas gets painful), connection routing
- **Use when:** 50–500 tenants, regulated industries, per-tenant customization needed

**MODEL C: SEPARATE DATABASE PER TENANT (Silo Model)**
- Each tenant gets their own DB instance or cluster
- Pros: Maximum isolation, independent scaling, compliance-friendly
- Cons: Very high cost, operational complexity, hard to query cross-tenant
- **Use when:** Enterprise/VIP tenants, HIPAA/SOC2/banking compliance, <100 tenants

### 2.2 — Hybrid Strategy (Recommended for most SaaS)

```
Tier 1 (Free/Starter): Shared DB + Shared Schema → Pool
Tier 2 (Professional): Shared DB + Separate Schema → Bridge  
Tier 3 (Enterprise): Dedicated DB → Silo
```

Tenants are promoted to higher tiers as they grow or pay for isolation.

### 2.3 — Universal Tenant Registry (Always Required)

Every multi-tenant system MUST have a central control plane DB:

```sql
-- CONTROL PLANE DATABASE (separate from tenant data)

CREATE TABLE tenants (
    tenant_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_slug      VARCHAR(63) UNIQUE NOT NULL,  -- used in URLs/subdomains
    tenant_name      VARCHAR(255) NOT NULL,
    plan_tier        VARCHAR(20) NOT NULL DEFAULT 'starter',
    isolation_model  VARCHAR(20) NOT NULL DEFAULT 'shared',
    db_host          VARCHAR(255),        -- null = shared pool
    db_name          VARCHAR(255),        -- null = shared pool
    schema_name      VARCHAR(63),         -- for bridge model
    region           VARCHAR(30) NOT NULL DEFAULT 'us-east-1',
    status           VARCHAR(20) NOT NULL DEFAULT 'active',
    -- Limits
    max_users        INTEGER NOT NULL DEFAULT 10,
    max_storage_gb   NUMERIC(10,2) NOT NULL DEFAULT 5,
    max_api_rpm      INTEGER NOT NULL DEFAULT 100,
    max_db_connections INTEGER NOT NULL DEFAULT 5,
    -- Metadata
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    activated_at     TIMESTAMPTZ,
    suspended_at     TIMESTAMPTZ,
    settings         JSONB NOT NULL DEFAULT '{}',
    feature_flags    JSONB NOT NULL DEFAULT '{}',
    CONSTRAINT valid_plan CHECK (plan_tier IN ('starter','professional','enterprise','custom'))
);

CREATE TABLE tenant_audit_log (
    id           BIGSERIAL PRIMARY KEY,
    tenant_id    UUID NOT NULL REFERENCES tenants(tenant_id),
    event_type   VARCHAR(50) NOT NULL,
    actor_id     UUID,
    actor_type   VARCHAR(20),  -- 'user', 'system', 'admin'
    payload      JSONB,
    ip_address   INET,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_tenant_time ON tenant_audit_log(tenant_id, created_at DESC);
```

### 2.4 — Row-Level Security (Shared Schema)

```sql
-- Enable RLS on every tenant-scoped table
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- Policy: tenant can only see own rows
CREATE POLICY tenant_isolation ON patients
    USING (tenant_id = current_setting('app.current_tenant_id')::UUID);

-- Set context at connection/transaction start (application layer)
-- In PostgreSQL:
SET LOCAL app.current_tenant_id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

-- In application code (Node.js example):
await pool.query(`SET LOCAL app.current_tenant_id = $1`, [tenantId]);
```

**CRITICAL:** Always test RLS with `SET ROLE tenant_user;` — superuser bypasses RLS silently.

### 2.5 — Schema Migration Strategy per Model

```sql
-- SHARED SCHEMA: Standard migrations run once, affect all tenants
-- Use: Flyway, Liquibase, or Prisma migrate

-- BRIDGE MODEL: Run migration per tenant schema
-- Pseudocode for migration runner:
-- FOR EACH schema IN get_tenant_schemas():
--   SET search_path = schema;
--   RUN migration;
--   LOG result;

-- SILO MODEL: Migrations per tenant DB
-- Use: parallel migration runner with rollback capability
-- Always: backup before migrate, canary tenant first
```

---

## PHASE 3 — REQUEST MANAGEMENT & THROTTLING

> **Read `references/request-management.md` for full implementation code.**

### 3.1 — The Problem: Server Overload in Multi-Tenant SaaS

Failure modes:
- **Noisy neighbor**: One heavy tenant starves all others
- **Connection pool exhaustion**: 1000 tenants × 5 connections = 5000 connections (PostgreSQL max ~300–500)
- **Thundering herd**: All tenants retry simultaneously after outage
- **Query storms**: Cron jobs, bulk imports, report generation spike load

### 3.2 — Defense Architecture (Layers)

```
Client Request
     │
     ▼
[1] API Gateway Rate Limiter      ← Global IP + tenant-level limits
     │
     ▼
[2] Application Rate Limiter      ← Per-tenant RPM/RPS sliding window
     │
     ▼
[3] Request Queue                 ← Priority queue by tenant tier
     │
     ▼
[4] Connection Pool               ← PgBouncer / connection broker
     │
     ▼
[5] Query Timeout Guard           ← statement_timeout per query class
     │
     ▼
[6] Database                      ← RLS + query isolation
```

### 3.3 — Tenant Rate Limit Tiers

```
Starter:      100 RPM,  5 concurrent DB connections,  30s query timeout
Professional: 500 RPM, 20 concurrent DB connections,  60s query timeout  
Enterprise:  2000 RPM, 50 concurrent DB connections, 120s query timeout
Custom:      Negotiated SLA
```

### 3.4 — Token Bucket Rate Limiter (Redis)

```python
# Redis Lua script — atomic token bucket
RATE_LIMIT_SCRIPT = """
local key = KEYS[1]
local capacity = tonumber(ARGV[1])   -- max tokens (burst)
local refill_rate = tonumber(ARGV[2]) -- tokens per second
local now = tonumber(ARGV[3])         -- unix timestamp ms
local requested = tonumber(ARGV[4])   -- tokens needed (usually 1)

local bucket = redis.call('HMGET', key, 'tokens', 'last_refill')
local tokens = tonumber(bucket[1]) or capacity
local last_refill = tonumber(bucket[2]) or now

-- Refill tokens based on elapsed time
local elapsed = math.max(0, (now - last_refill) / 1000)
tokens = math.min(capacity, tokens + elapsed * refill_rate)

if tokens >= requested then
    tokens = tokens - requested
    redis.call('HMSET', key, 'tokens', tokens, 'last_refill', now)
    redis.call('EXPIRE', key, 86400)
    return {1, math.floor(tokens)}  -- allowed, remaining
else
    redis.call('HMSET', key, 'tokens', tokens, 'last_refill', now)
    return {0, 0}  -- denied
end
"""

async def check_rate_limit(tenant_id: str, tier: str) -> tuple[bool, int]:
    limits = TIER_LIMITS[tier]  # {'capacity': 100, 'refill_rate': 1.67}
    key = f"ratelimit:{tenant_id}"
    result = await redis.eval(
        RATE_LIMIT_SCRIPT, 1, key,
        limits['capacity'], limits['refill_rate'],
        int(time.time() * 1000), 1
    )
    return bool(result[0]), result[1]  # (allowed, remaining_tokens)
```

### 3.5 — Connection Pooling with PgBouncer

```ini
# pgbouncer.ini — Transaction pooling (best for SaaS)
[databases]
saas_pool = host=db-primary port=5432 dbname=saas_db pool_size=100

[pgbouncer]
pool_mode = transaction          ; transaction-level pooling
max_client_conn = 10000          ; total client connections
default_pool_size = 20           ; server connections per db/user pair
min_pool_size = 5
reserve_pool_size = 5
reserve_pool_timeout = 3

server_idle_timeout = 600
client_idle_timeout = 0
max_db_connections = 200         ; hard cap on actual DB connections
query_timeout = 30               ; kill queries > 30s
```

**Rule:** With transaction pooling, never use `SET LOCAL`, advisory locks, or prepared statements — they break. Use `SET` alternatives at the application layer.

### 3.6 — Priority Queue for DB Requests

```python
import asyncio
from enum import IntEnum

class Priority(IntEnum):
    CRITICAL = 0    # Patient vitals, emergency workflows
    HIGH = 1        # Real-time user-facing reads
    NORMAL = 2      # Standard CRUD operations
    LOW = 3         # Reports, analytics, exports
    BACKGROUND = 4  # Batch jobs, data sync

class TenantAwareQueue:
    def __init__(self):
        self.queues = [asyncio.PriorityQueue() for _ in range(5)]
        self.tenant_counts: dict[str, int] = {}
        self.max_per_tenant = 50  # max concurrent requests per tenant

    async def enqueue(self, tenant_id: str, priority: Priority, task):
        if self.tenant_counts.get(tenant_id, 0) >= self.max_per_tenant:
            raise TenantOverloadError(f"Tenant {tenant_id} exceeded concurrent limit")
        self.tenant_counts[tenant_id] = self.tenant_counts.get(tenant_id, 0) + 1
        await self.queues[priority].put((priority, tenant_id, task))

    async def worker(self):
        while True:
            for q in self.queues:   # drain higher priority first
                if not q.empty():
                    _, tenant_id, task = await q.get()
                    try:
                        await task()
                    finally:
                        self.tenant_counts[tenant_id] -= 1
                    break
            else:
                await asyncio.sleep(0.01)
```

---

## PHASE 4 — PERFORMANCE & OPTIMIZATION

> **Read `references/performance.md` for indexing strategies, query patterns, and caching.**

### 4.1 — Index Strategy for Multi-Tenant Tables

**Rule: EVERY query must include `tenant_id` as the FIRST column in composite indexes.**

```sql
-- WRONG: misses tenant filter → full table scan across all tenants
CREATE INDEX idx_patients_name ON patients(last_name, first_name);

-- CORRECT: tenant_id first → index-scanned for that tenant only
CREATE INDEX idx_patients_name ON patients(tenant_id, last_name, first_name);

-- For time-series/audit data: tenant + time range
CREATE INDEX idx_orders_tenant_time 
    ON orders(tenant_id, created_at DESC)
    WHERE status != 'archived';

-- Partial indexes to exclude soft-deleted rows
CREATE INDEX idx_patients_active 
    ON patients(tenant_id, last_name) 
    WHERE deleted_at IS NULL;
```

### 4.2 — Caching Strategy

```
L1: Application memory cache (tenant config, feature flags) — TTL 60s
L2: Redis per-tenant cache (lookup data, user sessions)    — TTL 5–30m
L3: CDN/edge cache (static tenant assets, public data)     — TTL 1h+
L4: DB materialized views (reports, dashboards)            — refresh schedule
```

Cache key pattern: `{tenant_id}:{resource_type}:{resource_id}`
Never cache without tenant prefix — cross-tenant data leak risk.

### 4.3 — Query Timeout Enforcement

```sql
-- Per session (set by application layer)
SET statement_timeout = '30000';  -- 30 seconds

-- Per role (for background workers)
ALTER ROLE report_worker SET statement_timeout = '300000'; -- 5 min

-- Per transaction class (lock timeout)
SET lock_timeout = '5000';   -- fail fast rather than wait on locks
SET idle_in_transaction_session_timeout = '30000';  -- kill abandoned txns
```

---

## PHASE 5 — DOMAIN KNOWLEDGE

> **For healthcare: read `references/healthcare-domain.md`**
> **For other verticals: read `references/enterprise-domains.md`**

### 5.1 — Domain Selection Guide

| Domain Mentioned | Reference File | Key Modules |
|-----------------|---------------|-------------|
| Hospital, clinic, EMR, patient | `healthcare-domain.md` | Patient, Clinical, Lab, Pharmacy, Bed, Finance, HR |
| School, university, LMS | `enterprise-domains.md#education` | Enrollment, Courses, Grades, Billing |
| Logistics, warehouse, supply chain | `enterprise-domains.md#logistics` | Orders, Inventory, Fleet, WMS |
| Legal, law firm, case management | `enterprise-domains.md#legal` | Cases, Billing, Documents, Courts |
| Manufacturing, ERP | `enterprise-domains.md#manufacturing` | BOM, Production, Quality, MRP |
| Real estate, property mgmt | `enterprise-domains.md#realestate` | Properties, Tenants, Leases, Maintenance |
| E-commerce, retail | `enterprise-domains.md#ecommerce` | Products, Orders, Inventory, Fulfillment |
| Finance, accounting, ERP | `enterprise-domains.md#finance` | GL, AP/AR, Payroll, Assets, Tax |

---

## PHASE 6 — DATABASE CONFIGURATION & BEST PRACTICES

> **Read `references/db-config.md` for PostgreSQL, MySQL, and MongoDB tuning.**

### 6.1 — Non-Negotiable Best Practices

**Schema conventions:**
- All tables have: `id UUID PK`, `tenant_id UUID NOT NULL`, `created_at TIMESTAMPTZ`, `updated_at TIMESTAMPTZ`, `deleted_at TIMESTAMPTZ` (soft delete)
- Surrogate UUIDs (not serial integers) — prevents tenant enumeration attacks
- All foreign keys indexed
- No `NULL` in columns that business logic treats as mandatory
- JSONB for flexible metadata, typed columns for queryable fields
- Enum types as CHECK constraints or DB enums — never raw strings

**Transaction discipline:**
- Short transactions — hold locks for <100ms when possible
- Optimistic locking for concurrent edits (`version` column, CAS pattern)
- Saga pattern for multi-table business transactions
- Idempotency keys for mutations (prevent duplicate processing)

**Data integrity:**
- Enforce business rules at DB level (CHECK constraints, triggers for critical paths)
- Application-level validation is secondary defense, not primary
- Use DB-level `GENERATED ALWAYS` for computed columns where possible

### 6.2 — Partitioning for Scale

```sql
-- Range partition by tenant_id hash (for very large shared tables)
CREATE TABLE events (
    tenant_id    UUID NOT NULL,
    event_id     UUID NOT NULL DEFAULT gen_random_uuid(),
    event_type   VARCHAR(50) NOT NULL,
    payload      JSONB,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY HASH (tenant_id);

-- Create N partitions (start with 8, double as needed)
CREATE TABLE events_p0 PARTITION OF events FOR VALUES WITH (MODULUS 8, REMAINDER 0);
-- ... repeat for 1-7

-- Time-based partition for audit/time-series data
CREATE TABLE audit_log_2024_q1 PARTITION OF audit_log
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
```

---

## PHASE 7 — OPERATIONS

### 7.1 — Tenant Onboarding Flow

```
1. Register tenant in control plane (tenants table)
2. Provision resources based on tier:
   - Shared: assign schema or just register tenant_id
   - Bridge: CREATE SCHEMA tenant_{slug}; run baseline migrations
   - Silo:   provision DB instance, run full migrations
3. Seed reference/config data
4. Configure rate limits in Redis
5. Send activation webhook
6. Log TENANT_PROVISIONED event
```

### 7.2 — Tenant Offboarding / Data Deletion

```
1. Mark status = 'suspended' (keeps data, blocks access)
2. After retention period: export data (GDPR right to portability)
3. Anonymize or delete PII per data retention policy
4. Drop schema (bridge) or decommission DB (silo)
5. Remove from connection pools and caches
6. Archive tenant record (never hard-delete audit trail)
```

---

## REFERENCE FILES

Load the relevant file(s) based on the task:

| File | When to load |
|------|-------------|
| `references/request-management.md` | Full rate limiting, queuing, circuit breaker code |
| `references/healthcare-domain.md` | Healthcare SaaS: all modules (HMS, Lab, Pharmacy, etc.) |
| `references/enterprise-domains.md` | Non-healthcare verticals: education, legal, logistics, etc. |
| `references/db-config.md` | PostgreSQL/MySQL tuning, replication, backup, monitoring |
| `references/performance.md` | Query optimization, indexing patterns, caching strategies |
| `references/security.md` | Encryption, audit, compliance (HIPAA, SOC2, GDPR) |

**Always load the domain reference BEFORE designing any schema for that domain.**
