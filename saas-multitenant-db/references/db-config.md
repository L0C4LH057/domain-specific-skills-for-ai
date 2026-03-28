# Database Configuration & Best Practices

## TOC
1. PostgreSQL production tuning
2. Connection management
3. Replication & high availability
4. Backup & disaster recovery
5. Monitoring & alerting
6. Index management
7. Vacuum & maintenance
8. MySQL/MariaDB tuning (comparison)
9. MongoDB for multi-tenant (when to use)
10. Database security hardening

---

## 1. POSTGRESQL PRODUCTION TUNING

### postgresql.conf — Base Settings for SaaS

```ini
# Memory (for 16GB RAM server — adjust proportionally)
shared_buffers = 4GB                    # 25% of RAM
effective_cache_size = 12GB             # 75% of RAM (hint to planner)
work_mem = 64MB                         # per sort/hash operation
maintenance_work_mem = 1GB              # for VACUUM, CREATE INDEX
wal_buffers = 64MB                      # 3% of shared_buffers, min 64MB

# Parallel query
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
max_parallel_maintenance_workers = 4

# WAL & Checkpoints
wal_level = replica                     # needed for replication
max_wal_size = 4GB
min_wal_size = 1GB
checkpoint_completion_target = 0.9     # spread checkpoint I/O
wal_compression = on                   # reduce WAL size

# Connection settings
max_connections = 300                   # use PgBouncer, keep this low
superuser_reserved_connections = 5

# Query planner
random_page_cost = 1.1                  # for SSD (default 4 is for HDD)
effective_io_concurrency = 200          # for SSD
seq_page_cost = 1.0

# Logging (production-grade)
log_destination = 'csvlog'
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 1GB
log_min_duration_statement = 1000       # log queries > 1 second
log_checkpoints = on
log_connections = off                   # too noisy with PgBouncer
log_disconnections = off
log_lock_waits = on
log_temp_files = 0                      # log all temp files
log_autovacuum_min_duration = 250ms

# Autovacuum (tuned for write-heavy SaaS)
autovacuum_max_workers = 5
autovacuum_naptime = 30s
autovacuum_vacuum_cost_limit = 800      # default 200, increase for SSD
autovacuum_vacuum_scale_factor = 0.05  # vacuum when 5% of rows dead
autovacuum_analyze_scale_factor = 0.02

# Timeouts (critical for multi-tenant)
lock_timeout = 5000                     # 5 seconds max wait for lock
statement_timeout = 60000               # 60 second default (override per query)
idle_in_transaction_session_timeout = 30000  # kill abandoned transactions
deadlock_detection = 1000               # detect deadlocks faster
```

### Per-Role Overrides
```sql
-- Application user (most API traffic)
ALTER ROLE app_user SET statement_timeout = '30s';
ALTER ROLE app_user SET lock_timeout = '5s';
ALTER ROLE app_user SET idle_in_transaction_session_timeout = '15s';

-- Report worker (long analytical queries)
ALTER ROLE report_worker SET statement_timeout = '300s';
ALTER ROLE report_worker SET work_mem = '256MB';  -- more memory for reports

-- Background jobs
ALTER ROLE bg_worker SET statement_timeout = '600s';

-- Analytics / BI read replica user
ALTER ROLE analytics_user SET default_transaction_read_only = on;
ALTER ROLE analytics_user SET statement_timeout = '120s';
```

---

## 2. CONNECTION MANAGEMENT

### PgBouncer Config (Transaction Pooling)

```ini
# /etc/pgbouncer/pgbouncer.ini

[databases]
; Application databases
saas_main = host=db-primary port=5432 dbname=saas_prod
saas_main_replica = host=db-replica-1 port=5432 dbname=saas_prod

; Per-tenant silo DBs (add as they're provisioned)
tenant_enterprise_abc = host=db-shard-1 port=5432 dbname=tenant_abc

[pgbouncer]
logfile = /var/log/pgbouncer/pgbouncer.log
pidfile = /var/run/pgbouncer/pgbouncer.pid
listen_addr = 0.0.0.0
listen_port = 5432
auth_type = hba
auth_file = /etc/pgbouncer/userlist.txt

pool_mode = transaction          ; BEST for SaaS — share connections between requests
max_client_conn = 50000          ; clients (app server threads/processes)
default_pool_size = 25           ; server connections per (db, user) pair
min_pool_size = 5
reserve_pool_size = 10
reserve_pool_timeout = 5

server_idle_timeout = 600
client_idle_timeout = 0
server_lifetime = 3600           ; recycle connections hourly

; Transaction pooling limitations (must handle in app):
; - No SET that persists across transactions (use app-level context)
; - No LISTEN/NOTIFY (use separate non-pooled connection)
; - No prepared statements (use name-based prepared statements workaround)

max_db_connections = 500         ; hard cap total server connections
query_timeout = 0                ; 0 = use PostgreSQL statement_timeout
client_login_timeout = 60

; Logging
log_connections = 0
log_disconnections = 0
log_pooler_errors = 1
stats_period = 60
```

### Application-Side Pool Config

```python
# asyncpg (Python) — recommended for async SaaS backends
import asyncpg

async def create_pool():
    return await asyncpg.create_pool(
        dsn="postgresql://app_user:password@pgbouncer:5432/saas_main",
        min_size=5,
        max_size=20,          # per app server instance
        command_timeout=30,   # query timeout
        max_inactive_connection_lifetime=300,  # recycle idle connections
        max_queries=50000,    # recycle connection after N queries
    )

# Always: acquire → use → release (async context manager)
async def get_patient(tenant_id: str, patient_id: str):
    async with pool.acquire() as conn:
        # Set tenant context (transaction-scoped)
        await conn.execute("SET LOCAL app.current_tenant_id = $1", tenant_id)
        return await conn.fetchrow(
            "SELECT * FROM patients WHERE id = $1 AND tenant_id = $2",
            patient_id, tenant_id
        )
```

---

## 3. REPLICATION & HIGH AVAILABILITY

### Streaming Replication Setup

```ini
# Primary: postgresql.conf additions
wal_level = replica
max_wal_senders = 10
wal_keep_size = 1GB
synchronous_standby_names = 'FIRST 1 (replica1, replica2)'
# 'FIRST 1' = synchronous commit to at least 1 replica before confirming

# Primary: pg_hba.conf addition
host    replication     replicator      10.0.0.0/8      md5
```

```sql
-- Create replication user
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'strong_password';
```

```bash
# Replica setup (bash)
pg_basebackup -h primary-db -D /var/lib/postgresql/14/replica \
  -U replicator -W -v -P --wal-method=stream

# replica: postgresql.conf
hot_standby = on
hot_standby_feedback = on   # prevent query conflicts on replica
max_standby_streaming_delay = 30s
```

### HA Topology for Production SaaS

```
                   ┌─────────────────┐
Application ──────▶│  Load Balancer  │
                   └────────┬────────┘
                            │
               ┌────────────┼────────────┐
               ▼            ▼            ▼
          ┌─────────┐  ┌─────────┐  ┌─────────┐
          │PgBouncer│  │PgBouncer│  │PgBouncer│  
          └────┬────┘  └────┬────┘  └────┬────┘
               │            │            │
          ┌────▼────┐  ┌────▼────┐  ┌────▼────┐
          │ Primary │──▶│Replica1 │  │Replica2 │
          │  (R/W)  │  │ (R/O)   │  │ (R/O)   │
          └─────────┘  └─────────┘  └─────────┘
                                          │
                                    Analytics/
                                    Reports
```

**Route reads to replicas:**
```python
# Separate pools for primary (writes) and replicas (reads)
write_pool = await asyncpg.create_pool(dsn=PRIMARY_DSN)
read_pool  = await asyncpg.create_pool(dsn=REPLICA_DSN)

async def execute_query(sql: str, params, read_only: bool = False):
    pool = read_pool if read_only else write_pool
    async with pool.acquire() as conn:
        return await conn.fetch(sql, *params)
```

---

## 4. BACKUP & DISASTER RECOVERY

### Continuous Archiving (WAL-G)
```bash
# postgresql.conf — enable WAL archiving
archive_mode = on
archive_command = 'wal-g wal-push %p'
archive_timeout = 60s  # archive WAL segment at least every 60s

# Restore command (for PITR)
restore_command = 'wal-g wal-fetch %f %p'
recovery_target_time = '2024-03-15 14:30:00 UTC'  # PITR target
```

```bash
# Take base backup (daily)
wal-g backup-push $PGDATA

# List available backups
wal-g backup-list

# Restore to specific point in time
wal-g backup-fetch $PGDATA LATEST
```

### Backup Schedule
```
Every 1 minute  : WAL segments → S3 (continuous archiving)
Daily at 02:00  : Full base backup → S3 + offsite copy
Weekly          : Verify backup integrity (restore test in staging)
Monthly         : Full DR drill — restore to new server and verify data
```

### RTO/RPO Targets
```
Tier             | RPO (data loss) | RTO (downtime)
Free/Starter     | 1 hour          | 4 hours
Professional     | 15 minutes      | 1 hour
Enterprise       | 1 minute        | 15 minutes
Healthcare/PCI   | 0 (synchronous) | < 5 minutes (auto-failover)
```

---

## 5. MONITORING & ALERTING

### Key Queries

```sql
-- Active connections by state
SELECT state, count(*), max(now() - state_change) as max_duration
FROM pg_stat_activity 
WHERE datname = current_database()
GROUP BY state;

-- Long-running queries (check every minute)
SELECT pid, now() - query_start AS duration, state, query
FROM pg_stat_activity
WHERE query_start < now() - interval '30 seconds'
  AND state NOT IN ('idle', 'idle in transaction (aborted)')
ORDER BY duration DESC;

-- Lock waits
SELECT blocked.pid AS blocked_pid,
       blocked.query AS blocked_query,
       blocking.pid AS blocking_pid,
       blocking.query AS blocking_query,
       blocked.wait_event
FROM pg_stat_activity AS blocked
JOIN pg_stat_activity AS blocking 
    ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
WHERE cardinality(pg_blocking_pids(blocked.pid)) > 0;

-- Table bloat (dead tuples)
SELECT relname, n_live_tup, n_dead_tup,
       round(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct,
       last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 10000
ORDER BY n_dead_tup DESC;

-- Cache hit ratio (should be > 95%)
SELECT sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) * 100 AS cache_hit_ratio
FROM pg_statio_user_tables;

-- Index usage (find unused indexes)
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexname NOT LIKE '%_pkey'
ORDER BY schemaname, tablename;

-- Replication lag
SELECT client_addr, state, 
       pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag_bytes
FROM pg_stat_replication;
```

### Alert Thresholds
```
CRITICAL:
  - Replication lag > 10MB
  - Dead tuple pct > 30% on any table
  - Active connections > 90% of max_connections
  - Cache hit ratio < 90%
  - Checkpoint frequency > 1/min (signals too much write activity)

WARNING:
  - Queries > 5 seconds running count > 10
  - Lock waits > 20 concurrent
  - Disk usage > 80%
  - Long-running autovacuum > 30 minutes
```

---

## 6. INDEX MANAGEMENT

### Index Types Reference

```sql
-- B-Tree (default): equality, range, ORDER BY
CREATE INDEX idx_name ON table(col);

-- Hash: equality only, slightly faster than B-Tree for =
CREATE INDEX idx_hash ON table USING hash(col);

-- GIN: JSONB, arrays, full-text search
CREATE INDEX idx_jsonb ON table USING gin(jsonb_column);
CREATE INDEX idx_array ON table USING gin(array_column);
CREATE INDEX idx_fts ON table USING gin(to_tsvector('english', text_column));

-- BRIN: Time-series, sequential insert data (tiny, very fast for ranges)
CREATE INDEX idx_created ON large_table USING brin(created_at);

-- Partial: index subset of rows
CREATE INDEX idx_active ON users(tenant_id, email) WHERE deleted_at IS NULL;

-- Covering: include extra columns to avoid table access
CREATE INDEX idx_covering ON orders(tenant_id, status) 
    INCLUDE (customer_id, total_amount, created_at);

-- Concurrent: build without locking (use for production)
CREATE INDEX CONCURRENTLY idx_name ON table(col);
```

### Multi-Tenant Index Pattern
```sql
-- ALWAYS: tenant_id FIRST in every composite index
-- Column order: tenant_id → selectivity (high to low) → sort columns

-- Good: tenant + high-selectivity filter + sort
CREATE INDEX idx_orders ON orders(tenant_id, status, created_at DESC);

-- Bad: leads to full partition scan
CREATE INDEX idx_orders_bad ON orders(status, created_at);
```

---

## 7. VACUUM & MAINTENANCE

```sql
-- Manual vacuum when autovacuum can't keep up (e.g., after bulk delete)
VACUUM (VERBOSE, ANALYZE) tablename;

-- Aggressive vacuum to reclaim space (locks table briefly)
VACUUM FULL tablename;  -- use during maintenance window only

-- Reindex concurrently (no downtime)
REINDEX INDEX CONCURRENTLY idx_name;
REINDEX TABLE CONCURRENTLY tablename;

-- Update statistics (when planner makes bad choices)
ANALYZE tablename;
ANALYZE tablename (column1, column2);

-- Reset sequence if auto-incremented IDs drift
SELECT setval('tablename_id_seq', (SELECT MAX(id) FROM tablename));
```

---

## 8. MYSQL/MARIADB TUNING (Comparison)

```ini
# my.cnf for SaaS (8GB RAM example)
[mysqld]
innodb_buffer_pool_size = 5G          # 60-70% of RAM
innodb_buffer_pool_instances = 8      # 1 per 1GB of buffer pool
innodb_log_file_size = 1G             # larger = better write performance
innodb_log_buffer_size = 256M
innodb_flush_log_at_trx_commit = 1    # 1 = ACID (use 2 for performance, risk of 1s loss)
innodb_flush_method = O_DIRECT

max_connections = 500
thread_cache_size = 64
table_open_cache = 4000
table_definition_cache = 2000

# Replication
server_id = 1
log_bin = mysql-bin
binlog_format = ROW                   # ROW for multi-tenant (safer than STATEMENT)
sync_binlog = 1                       # flush binlog per transaction
gtid_mode = ON                        # for easy replica promotion

# Query cache (DISABLE in MySQL 8 — removed)
# query_cache_size = 0   # deprecated

# Timeouts
wait_timeout = 28800
interactive_timeout = 28800
lock_wait_timeout = 10                # 10 seconds
innodb_lock_wait_timeout = 10
```

### MySQL Multi-Tenant: Schema per Tenant
```sql
-- MySQL supports schema per tenant well
-- Create schema for each tenant during onboarding
CREATE DATABASE tenant_abc CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON tenant_abc.* TO 'app_user'@'%';

-- Route queries:
USE tenant_abc;
SELECT * FROM patients WHERE id = ?;
```

---

## 9. MONGODB FOR MULTI-TENANT

Use MongoDB when: schema varies significantly between tenants, document-centric data, rapid prototyping.

```javascript
// Collection-per-tenant (Bridge model)
// Each tenant gets prefixed collections
db['tenant_abc_patients'].insertOne({...})

// Shared collection with tenant filter (Pool model)
db.patients.createIndex({ tenant_id: 1, _id: 1 })
db.patients.createIndex({ tenant_id: 1, last_name: 1 })

// MongoDB multi-tenancy with connection per tenant (Silo)
const getDb = (tenantId) => {
  const dbName = `tenant_${tenantId}`;
  return mongoClient.db(dbName);
};
```

**When NOT to use MongoDB for SaaS:**
- Financial data (need ACID transactions)
- Complex joins (e.g., HMS with many related entities)
- Reporting/analytics (aggregation pipeline gets unwieldy)

---

## 10. DATABASE SECURITY HARDENING

```sql
-- Create application user with minimal privileges
CREATE ROLE app_user WITH LOGIN PASSWORD 'use_strong_password_from_vault';
GRANT CONNECT ON DATABASE saas_prod TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_user;
-- app_user cannot DROP, TRUNCATE, or ALTER tables

-- Read-only user for analytics
CREATE ROLE analytics_user WITH LOGIN;
GRANT CONNECT ON DATABASE saas_prod TO analytics_user;
GRANT USAGE ON SCHEMA public TO analytics_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_user;
ALTER ROLE analytics_user SET default_transaction_read_only = on;

-- Audit user actions
CREATE EXTENSION IF NOT EXISTS pgaudit;
-- pgaudit.log = 'write' in postgresql.conf  -- log INSERT/UPDATE/DELETE
-- pgaudit.log = 'read' on sensitive tables (patients, financial data)

-- Row-Level Security for tenant isolation (see SKILL.md Phase 2.4)
-- Column-level encryption for PII
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Encrypt SSN/NIN at column level
-- Store as: pgp_sym_encrypt(value, symmetric_key)
-- Read as:  pgp_sym_decrypt(column, symmetric_key)

-- Revoke public schema creation
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- SSL enforcement
-- postgresql.conf:
-- ssl = on
-- ssl_cert_file = 'server.crt'
-- ssl_key_file = 'server.key'
-- pg_hba.conf: require ssl for all connections
-- hostssl all all 0.0.0.0/0 scram-sha-256
```
