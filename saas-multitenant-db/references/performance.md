# Performance Optimization — Query Patterns, Caching & Scaling

## TOC
1. EXPLAIN ANALYZE guide
2. Common slow query patterns & fixes
3. Multi-tenant query optimization
4. Pagination best practices
5. Full-text search
6. Caching patterns (Redis)
7. Read replica routing
8. Materialized views for dashboards
9. Bulk operations optimization
10. Database sharding strategies

---

## 1. EXPLAIN ANALYZE GUIDE

Always analyze slow queries before guessing:

```sql
-- Full analysis with buffers and timing
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT * FROM patients WHERE tenant_id = $1 AND last_name ILIKE $2;

-- Key things to look for:
-- Seq Scan → needs an index
-- Hash Join → often good; Nested Loop on large tables → may need index
-- rows=X (estimated) vs actual rows=Y → large gap = stale statistics (run ANALYZE)
-- Buffers: hit=X read=Y → read >> hit means poor cache utilization
-- "Filter: ..." after a scan → rows fetched then filtered (index should filter earlier)
```

### Red Flags in Query Plans
```
❌ Seq Scan on large table (> 10k rows)
❌ "rows removed by filter" >> rows returned
❌ Nested Loop with large outer table
❌ Sort using disk (spilling to temp file)
❌ Hash Join batches > 1 (memory exceeded)
❌ estimated rows wildly off actual rows
```

---

## 2. COMMON SLOW QUERY PATTERNS & FIXES

### Pattern 1: Missing tenant_id in index
```sql
-- SLOW: missing tenant_id
SELECT * FROM orders WHERE status = 'pending' AND created_at > NOW() - INTERVAL '7 days';
-- Plan: Seq Scan (scans ALL tenants' rows)

-- FIX: Add tenant_id to query and ensure composite index
SELECT * FROM orders 
WHERE tenant_id = $1 AND status = 'pending' AND created_at > NOW() - INTERVAL '7 days';
CREATE INDEX idx_orders_tenant_status_time 
    ON orders(tenant_id, status, created_at DESC);
```

### Pattern 2: LIKE with leading wildcard
```sql
-- SLOW: can't use B-Tree index
WHERE name LIKE '%smith%';

-- FIX option 1: trigram index (pg_trgm extension)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_name_trgm ON patients USING gin(last_name gin_trgm_ops);
-- Now: WHERE last_name ILIKE '%smith%' uses this index

-- FIX option 2: Full-text search (for longer text)
-- See section 5
```

### Pattern 3: Functions on indexed columns
```sql
-- SLOW: function prevents index use
WHERE DATE(created_at) = '2024-01-15';
WHERE LOWER(email) = 'user@example.com';

-- FIX: avoid function on column side
WHERE created_at >= '2024-01-15' AND created_at < '2024-01-16';

-- Or: functional index
CREATE INDEX idx_email_lower ON users(tenant_id, LOWER(email));
WHERE LOWER(email) = LOWER($1);  -- now uses index
```

### Pattern 4: N+1 query problem
```sql
-- SLOW: N+1 (1 query per patient to get latest vitals)
-- Application code: for each patient: SELECT * FROM vital_signs WHERE patient_id = ?

-- FIX: lateral join or window function
SELECT p.id, p.first_name, v.*
FROM patients p
LEFT JOIN LATERAL (
    SELECT * FROM vital_signs vs
    WHERE vs.patient_id = p.id AND vs.tenant_id = p.tenant_id
    ORDER BY vs.recorded_at DESC
    LIMIT 1
) v ON TRUE
WHERE p.tenant_id = $1;
```

### Pattern 5: Counting rows inefficiently
```sql
-- SLOW: COUNT(*) on large table
SELECT COUNT(*) FROM orders WHERE tenant_id = $1;

-- BETTER: Use pg_stat_user_tables for estimates (not exact, but fast)
SELECT n_live_tup FROM pg_stat_user_tables WHERE relname = 'orders';

-- BEST for exact count: maintain counter in Redis or separate counter table
-- Increment on INSERT, decrement on DELETE using triggers or application logic

-- Counter table pattern
CREATE TABLE tenant_stats (
    tenant_id   UUID PRIMARY KEY,
    order_count BIGINT DEFAULT 0,
    ...
);
-- Update via trigger or application after INSERT/DELETE
```

### Pattern 6: Expensive ORDER BY + LIMIT
```sql
-- SLOW: sorts millions of rows to return 20
SELECT * FROM events WHERE tenant_id = $1 ORDER BY created_at DESC LIMIT 20;

-- FIX: ensure index matches sort direction
CREATE INDEX idx_events_tenant_time ON events(tenant_id, created_at DESC);
-- Now: Index Scan Backward → very fast
```

### Pattern 7: JSONB queries without index
```sql
-- SLOW: full scan through JSONB
WHERE settings->>'theme' = 'dark';

-- FIX: GIN index on full JSONB column
CREATE INDEX idx_settings_gin ON tenants USING gin(settings);
-- Supports: ?, ?|, ?&, @>, <@ operators

-- OR: generated column + B-tree index (for frequently queried key)
ALTER TABLE tenants ADD COLUMN theme VARCHAR(20) 
    GENERATED ALWAYS AS (settings->>'theme') STORED;
CREATE INDEX idx_tenants_theme ON tenants(tenant_id, theme);
```

---

## 3. MULTI-TENANT QUERY OPTIMIZATION

### Always pass tenant_id — never query without it

```python
# WRONG: Will scan all tenants
patients = await db.fetch("SELECT * FROM patients WHERE last_name = $1", name)

# CORRECT: Always filter by tenant first  
patients = await db.fetch(
    "SELECT * FROM patients WHERE tenant_id = $1 AND last_name = $2",
    tenant_id, name
)
```

### Tenant-Aware Query Builder Pattern
```python
class TenantQuery:
    """All queries go through this to ensure tenant isolation."""
    
    def __init__(self, pool, tenant_id: str):
        self.pool = pool
        self.tenant_id = tenant_id
    
    async def fetch(self, sql: str, *args) -> list:
        """Enforce tenant_id is the first parameter."""
        async with self.pool.acquire() as conn:
            return await conn.fetch(sql, self.tenant_id, *args)
    
    async def fetchrow(self, sql: str, *args):
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(sql, self.tenant_id, *args)
    
    # Automatic tenant_id injection: validate SQL contains $1 = tenant_id
    def validate_query(self, sql: str):
        if "tenant_id = $1" not in sql.lower() and "tenant_id=$1" not in sql.lower():
            raise QuerySecurityError("Query missing tenant_id filter")
```

---

## 4. PAGINATION BEST PRACTICES

### Cursor-Based Pagination (Recommended)

Better than OFFSET — no skip of N rows, stable across inserts/deletes.

```sql
-- First page
SELECT id, created_at, first_name, last_name
FROM patients
WHERE tenant_id = $1
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- Next page: use last row's (created_at, id) as cursor
SELECT id, created_at, first_name, last_name
FROM patients
WHERE tenant_id = $1
  AND (created_at, id) < ($2, $3)   -- cursor: (last_created_at, last_id)
ORDER BY created_at DESC, id DESC
LIMIT 20;
```

```python
def encode_cursor(row: dict) -> str:
    return base64.b64encode(
        json.dumps({"ts": row["created_at"].isoformat(), "id": str(row["id"])}).encode()
    ).decode()

def decode_cursor(cursor: str) -> tuple:
    data = json.loads(base64.b64decode(cursor))
    return data["ts"], data["id"]
```

### OFFSET Pagination (Use only for small datasets)
```sql
-- Works but degrades at high OFFSET values
SELECT * FROM patients 
WHERE tenant_id = $1
ORDER BY created_at DESC
LIMIT 20 OFFSET 10000;  -- PostgreSQL must read 10,020 rows, discard 10,000
```

---

## 5. FULL-TEXT SEARCH

```sql
-- Add search vector column (maintained by trigger)
ALTER TABLE patients ADD COLUMN search_vector TSVECTOR;

CREATE OR REPLACE FUNCTION patients_search_update() RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector = 
        setweight(to_tsvector('english', COALESCE(NEW.first_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.last_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.mrn, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.phone_primary, '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER patients_search_trigger
    BEFORE INSERT OR UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION patients_search_update();

-- GIN index for fast full-text search
CREATE INDEX idx_patients_search ON patients USING gin(search_vector);
CREATE INDEX idx_patients_search_tenant ON patients(tenant_id) 
    INCLUDE (search_vector);  -- tenant + search

-- Query
SELECT id, first_name, last_name, mrn,
       ts_rank(search_vector, query) AS rank
FROM patients, to_tsquery('english', $2) AS query
WHERE tenant_id = $1
  AND search_vector @@ query
ORDER BY rank DESC
LIMIT 20;
```

---

## 6. CACHING PATTERNS (REDIS)

```python
import json
from typing import Optional

class TenantCache:
    """All cache keys are tenant-scoped. Never store without tenant prefix."""
    
    PREFIX_TTL = {
        "config":      3600,   # tenant config — 1 hour
        "user":        900,    # user sessions — 15 min
        "lookup":      1800,   # reference data — 30 min
        "report":      300,    # report results — 5 min
        "realtime":    30,     # real-time KPIs — 30 sec
    }
    
    def cache_key(self, tenant_id: str, prefix: str, *parts) -> str:
        parts_str = ":".join(str(p) for p in parts)
        return f"{tenant_id}:{prefix}:{parts_str}"
    
    async def get(self, key: str) -> Optional[dict]:
        value = await redis.get(key)
        return json.loads(value) if value else None
    
    async def set(self, key: str, data: dict, prefix: str):
        ttl = self.PREFIX_TTL.get(prefix, 300)
        await redis.setex(key, ttl, json.dumps(data, default=str))
    
    async def invalidate_tenant(self, tenant_id: str, prefix: str):
        """Invalidate all cache entries for a tenant's prefix."""
        pattern = f"{tenant_id}:{prefix}:*"
        keys = await redis.keys(pattern)
        if keys:
            await redis.delete(*keys)

# Cache-aside pattern
async def get_patient(tenant_id: str, patient_id: str) -> dict:
    key = cache.cache_key(tenant_id, "patient", patient_id)
    
    # Try cache first
    if cached := await cache.get(key):
        return cached
    
    # Cache miss — query DB
    row = await db.fetchrow(
        "SELECT * FROM patients WHERE tenant_id = $1 AND id = $2",
        tenant_id, patient_id
    )
    if row:
        data = dict(row)
        await cache.set(key, data, "lookup")
        return data
    return None

# Write-through: update cache on every write
async def update_patient(tenant_id: str, patient_id: str, updates: dict) -> dict:
    result = await db.fetchrow(
        "UPDATE patients SET ... WHERE tenant_id = $1 AND id = $2 RETURNING *",
        tenant_id, patient_id
    )
    data = dict(result)
    key = cache.cache_key(tenant_id, "patient", patient_id)
    await cache.set(key, data, "lookup")  # update cache immediately
    return data
```

---

## 8. MATERIALIZED VIEWS FOR DASHBOARDS

```sql
-- Dashboard KPI materialized view — refresh on schedule
CREATE MATERIALIZED VIEW tenant_dashboard_kpis AS
SELECT
    tenant_id,
    DATE_TRUNC('day', created_at) AS day,
    COUNT(*) FILTER (WHERE encounter_type = 'inpatient') AS inpatient_count,
    COUNT(*) FILTER (WHERE encounter_type = 'outpatient') AS outpatient_count,
    COUNT(*) FILTER (WHERE encounter_type = 'emergency') AS emergency_count,
    AVG(EXTRACT(EPOCH FROM (discharge_date - admission_date))/86400) 
        FILTER (WHERE discharge_date IS NOT NULL) AS avg_los_days,
    COUNT(*) FILTER (WHERE status = 'open') AS open_encounters
FROM encounters
WHERE created_at > NOW() - INTERVAL '90 days'
GROUP BY tenant_id, DATE_TRUNC('day', created_at)
WITH DATA;

-- Unique index for concurrent refresh
CREATE UNIQUE INDEX idx_mv_kpis ON tenant_dashboard_kpis(tenant_id, day);

-- Refresh without locking (concurrent refresh requires unique index)
REFRESH MATERIALIZED VIEW CONCURRENTLY tenant_dashboard_kpis;

-- Schedule refresh (using pg_cron extension)
SELECT cron.schedule('*/15 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY tenant_dashboard_kpis');
```

---

## 9. BULK OPERATIONS

```sql
-- COPY for bulk insert (orders of magnitude faster than individual INSERTs)
COPY patients(tenant_id, mrn, first_name, last_name, date_of_birth)
FROM '/tmp/patients.csv' 
WITH (FORMAT csv, HEADER true);

-- Bulk upsert with ON CONFLICT
INSERT INTO patients (id, tenant_id, mrn, first_name, last_name, updated_at)
VALUES 
    ($1, $2, $3, $4, $5, NOW()),
    ($6, $7, $8, $9, $10, NOW())
ON CONFLICT (tenant_id, mrn) 
DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    updated_at = NOW();

-- Batch updates (avoid row-by-row updates)
UPDATE patients AS p
SET first_name = u.first_name, last_name = u.last_name
FROM (VALUES
    ('uuid1'::uuid, 'John', 'Doe'),
    ('uuid2'::uuid, 'Jane', 'Smith')
) AS u(id, first_name, last_name)
WHERE p.id = u.id AND p.tenant_id = $1;
```

---

## 10. DATABASE SHARDING STRATEGIES

### Horizontal Sharding by Tenant

```python
# Tenant-to-shard routing
SHARD_CONFIG = {
    "shard_1": "postgresql://db-shard-1:5432/saas",
    "shard_2": "postgresql://db-shard-2:5432/saas",
    "shard_3": "postgresql://db-shard-3:5432/saas",
    "shard_4": "postgresql://db-shard-4:5432/saas",
}

def get_shard_key(tenant_id: str, num_shards: int = 4) -> str:
    """Consistent hash — tenant always routes to same shard."""
    import hashlib
    hash_val = int(hashlib.md5(tenant_id.encode()).hexdigest(), 16)
    shard_num = (hash_val % num_shards) + 1
    return f"shard_{shard_num}"

async def get_pool_for_tenant(tenant_id: str) -> asyncpg.Pool:
    # Check if tenant has dedicated silo DB first
    tenant = await control_plane.get_tenant(tenant_id)
    if tenant.db_host:  # silo tenant
        return await get_or_create_pool(tenant.db_host, tenant.db_name)
    
    # Shared tenant — route to shard via consistent hash
    shard_key = get_shard_key(tenant_id)
    return shard_pools[shard_key]
```

### Re-sharding Tenant (Moving to new shard)
```
1. Create target shard entry in control plane (status = 'migrating')
2. Take logical dump of tenant data: pg_dump --schema=tenant_slug
3. Restore to target shard
4. Enable dual-write: write to both source and target
5. Verify data consistency (hash comparison)
6. Switch reads to target
7. Stop dual-write, cleanup source
8. Update tenant routing in control plane
```
