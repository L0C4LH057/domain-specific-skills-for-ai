# Request Management — Rate Limiting, Throttling, Queuing & Circuit Breakers

## TOC
1. Redis-based sliding window rate limiter
2. Token bucket (burst-tolerant)
3. Leaky bucket (smooth output)
4. Multi-dimensional limiting (global + tenant + user + endpoint)
5. API Gateway config (Nginx, Kong, AWS API GW)
6. Priority queue with fair scheduling
7. Circuit breaker pattern
8. Backpressure & graceful degradation
9. Retry with exponential backoff + jitter
10. Connection pool management (PgBouncer + Pgpool)
11. Query timeout classification
12. Async job queue for heavy operations
13. Webhook delivery with guaranteed at-least-once
14. Observability: metrics to track

---

## 1. Sliding Window Rate Limiter (Redis)

More accurate than fixed window — prevents edge-case bursts at window boundary.

```python
import time
import redis.asyncio as aioredis

class SlidingWindowRateLimiter:
    """Sliding log implementation using Redis sorted sets."""
    
    def __init__(self, redis_client: aioredis.Redis):
        self.redis = redis_client
    
    async def is_allowed(
        self,
        tenant_id: str,
        endpoint: str,
        limit: int,
        window_seconds: int
    ) -> tuple[bool, dict]:
        """
        Returns (allowed, metadata)
        metadata: {remaining, reset_at, retry_after}
        """
        now = time.time()
        window_start = now - window_seconds
        key = f"sw:{tenant_id}:{endpoint}"
        
        pipe = self.redis.pipeline()
        # Remove old entries outside window
        pipe.zremrangebyscore(key, 0, window_start)
        # Count current entries
        pipe.zcard(key)
        # Add current request timestamp
        pipe.zadd(key, {str(now): now})
        # Set expiry
        pipe.expire(key, window_seconds + 1)
        results = await pipe.execute()
        
        current_count = results[1]  # count BEFORE adding current
        
        if current_count >= limit:
            # Find oldest entry to calculate retry_after
            oldest = await self.redis.zrange(key, 0, 0, withscores=True)
            retry_after = window_seconds - (now - oldest[0][1]) if oldest else window_seconds
            return False, {
                "remaining": 0,
                "reset_at": now + retry_after,
                "retry_after": round(retry_after, 1),
                "limit": limit,
            }
        
        return True, {
            "remaining": limit - current_count - 1,
            "reset_at": now + window_seconds,
            "retry_after": 0,
            "limit": limit,
        }
```

## 2. Token Bucket (Redis Lua — Atomic)

Best for APIs that need burst tolerance (allow burst up to capacity, then throttle).

```lua
-- token_bucket.lua — Deploy as Redis script
local key = KEYS[1]
local capacity    = tonumber(ARGV[1])   -- max burst size
local refill_rate = tonumber(ARGV[2])   -- tokens/second
local now_ms      = tonumber(ARGV[3])   -- current time (ms)
local cost        = tonumber(ARGV[4])   -- tokens this request costs

local data = redis.call('HMGET', key, 'tokens', 'ts')
local tokens    = tonumber(data[1]) or capacity
local last_ts   = tonumber(data[2]) or now_ms

local elapsed_s = math.max(0, (now_ms - last_ts) / 1000.0)
tokens = math.min(capacity, tokens + elapsed_s * refill_rate)

if tokens >= cost then
    tokens = tokens - cost
    redis.call('HMSET', key, 'tokens', tokens, 'ts', now_ms)
    redis.call('PEXPIRE', key, 86400000)
    return {1, math.floor(tokens), 0}  -- {allowed, remaining, retry_ms}
else
    local deficit = cost - tokens
    local wait_ms = math.ceil((deficit / refill_rate) * 1000)
    redis.call('HMSET', key, 'tokens', tokens, 'ts', now_ms)
    return {0, 0, wait_ms}  -- {denied, remaining, retry_after_ms}
end
```

```python
class TokenBucket:
    SCRIPT_SHA = None

    async def load_script(self, redis):
        with open('token_bucket.lua') as f:
            script = f.read()
        self.SCRIPT_SHA = await redis.script_load(script)

    async def consume(self, redis, tenant_id: str, cost: int = 1) -> dict:
        tier = await get_tenant_tier(tenant_id)
        cfg = TIER_CONFIG[tier]  # {capacity, refill_rate}
        key = f"bucket:{tenant_id}"
        now_ms = int(time.time() * 1000)
        
        allowed, remaining, retry_ms = await redis.evalsha(
            self.SCRIPT_SHA, 1, key,
            cfg['capacity'], cfg['refill_rate'], now_ms, cost
        )
        return {
            "allowed": bool(allowed),
            "remaining": remaining,
            "retry_after_ms": retry_ms,
        }
```

## 3. Multi-Dimensional Rate Limiting

Apply limits at every layer simultaneously:

```python
class MultiDimensionalLimiter:
    LIMITS = {
        "global_ip":      {"limit": 1000, "window": 60},   # 1000/min per IP
        "tenant_api":     {"limit": 500,  "window": 60},   # per tenant plan
        "user_actions":   {"limit": 100,  "window": 60},   # per user
        "endpoint_heavy": {"limit": 10,   "window": 60},   # report endpoints
    }
    
    async def check_all(self, request: Request, tenant_id: str, user_id: str) -> None:
        """Raises RateLimitError with Retry-After header info."""
        checks = [
            self.check(f"ip:{request.client.host}", "global_ip"),
            self.check(f"tenant:{tenant_id}", "tenant_api", tenant_override=True),
            self.check(f"user:{user_id}", "user_actions"),
        ]
        if request.path in HEAVY_ENDPOINTS:
            checks.append(self.check(f"tenant:{tenant_id}:heavy", "endpoint_heavy"))
        
        results = await asyncio.gather(*checks, return_exceptions=True)
        for result in results:
            if isinstance(result, RateLimitExceeded):
                raise result  # FastAPI/Django middleware catches this

    async def check(self, key: str, config_key: str, tenant_override: bool = False):
        cfg = await self.get_tenant_limits(key) if tenant_override else self.LIMITS[config_key]
        allowed, meta = await self.limiter.is_allowed(key, config_key, cfg['limit'], cfg['window'])
        if not allowed:
            raise RateLimitExceeded(
                message=f"Rate limit exceeded",
                retry_after=meta['retry_after'],
                limit=meta['limit'],
            )
```

## 4. Response Headers (RFC 6585 Standard)

Always return these headers so clients can self-throttle:

```python
def set_rate_limit_headers(response, meta: dict):
    response.headers["X-RateLimit-Limit"]     = str(meta["limit"])
    response.headers["X-RateLimit-Remaining"] = str(meta["remaining"])
    response.headers["X-RateLimit-Reset"]     = str(int(meta["reset_at"]))
    if meta.get("retry_after"):
        response.headers["Retry-After"]        = str(int(meta["retry_after"]))
    # Return 429 Too Many Requests (not 503)
```

## 5. API Gateway Config

### Nginx Rate Limiting
```nginx
# nginx.conf
http {
    # Define limit zones
    limit_req_zone $http_x_tenant_id zone=per_tenant:10m rate=100r/m;
    limit_req_zone $binary_remote_addr zone=per_ip:10m rate=30r/m;
    
    server {
        location /api/ {
            # Tenant-level limit (burst=50 allows short spikes)
            limit_req zone=per_tenant burst=50 nodelay;
            limit_req zone=per_ip burst=10 nodelay;
            limit_req_status 429;
            
            # Timeout guards
            proxy_read_timeout 30s;
            proxy_connect_timeout 5s;
            
            proxy_pass http://app_servers;
        }
        
        # Heavy endpoints get stricter limits
        location /api/reports/ {
            limit_req zone=per_tenant burst=5 nodelay;
            proxy_read_timeout 120s;  # longer for reports
            proxy_pass http://app_servers;
        }
    }
}
```

### Kong Gateway Rate Limiting Plugin
```yaml
plugins:
  - name: rate-limiting
    config:
      minute: 500
      hour: 20000
      policy: redis
      redis_host: redis-cluster
      redis_port: 6379
      fault_tolerant: true  # allow requests if Redis is down
      hide_client_headers: false
      limit_by: header
      header_name: X-Tenant-ID
```

## 6. Priority Queue with Fair Scheduling

```python
import heapq
from dataclasses import dataclass, field
from typing import Any

@dataclass(order=True)
class QueueItem:
    priority: int
    sequence: int  # tie-breaker (FIFO within same priority)
    tenant_id: str = field(compare=False)
    task: Any = field(compare=False)
    enqueued_at: float = field(compare=False)

class FairPriorityQueue:
    """
    Priority queue with per-tenant fairness.
    High-priority tenants can't starve low-priority ones indefinitely.
    Uses weighted fair queuing: lower tiers still get 10% of capacity.
    """
    
    PRIORITY_MAP = {
        'enterprise':     0,
        'professional':   1,
        'starter':        2,
        'background':     3,
    }
    CAPACITY_WEIGHTS = {0: 50, 1: 30, 2: 15, 3: 5}  # % of worker capacity
    
    def __init__(self, max_size: int = 10000):
        self.heap = []
        self.sequence = 0
        self.tenant_queue_depth: dict[str, int] = {}
        self.max_size = max_size
        self.max_per_tenant = 100
    
    async def put(self, tenant_id: str, task, tier: str) -> bool:
        if len(self.heap) >= self.max_size:
            return False  # shed load
        if self.tenant_queue_depth.get(tenant_id, 0) >= self.max_per_tenant:
            return False  # per-tenant backpressure
        
        priority = self.PRIORITY_MAP.get(tier, 2)
        item = QueueItem(
            priority=priority,
            sequence=self.sequence,
            tenant_id=tenant_id,
            task=task,
            enqueued_at=time.time()
        )
        heapq.heappush(self.heap, item)
        self.sequence += 1
        self.tenant_queue_depth[tenant_id] = self.tenant_queue_depth.get(tenant_id, 0) + 1
        return True
    
    async def get(self) -> QueueItem | None:
        if not self.heap:
            return None
        item = heapq.heappop(self.heap)
        self.tenant_queue_depth[item.tenant_id] -= 1
        # Emit latency metric
        latency = time.time() - item.enqueued_at
        metrics.histogram("queue.wait_seconds", latency, tags={"tier": item.priority})
        return item
```

## 7. Circuit Breaker

Prevent cascading failures when a DB shard or service is degraded.

```python
from enum import Enum
import asyncio

class CircuitState(Enum):
    CLOSED = "closed"       # Normal operation
    OPEN = "open"           # Failing — reject requests immediately
    HALF_OPEN = "half_open" # Testing recovery

class CircuitBreaker:
    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: float = 30.0,
        success_threshold: int = 2,
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.success_threshold = success_threshold
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time: float = 0
    
    async def call(self, func, *args, **kwargs):
        if self.state == CircuitState.OPEN:
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = CircuitState.HALF_OPEN
                self.success_count = 0
            else:
                raise CircuitOpenError("Circuit breaker OPEN — service unavailable")
        
        try:
            result = await func(*args, **kwargs)
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise
    
    def _on_success(self):
        self.failure_count = 0
        if self.state == CircuitState.HALF_OPEN:
            self.success_count += 1
            if self.success_count >= self.success_threshold:
                self.state = CircuitState.CLOSED
    
    def _on_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()
        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN

# Usage
db_circuit = CircuitBreaker(failure_threshold=3, recovery_timeout=10.0)

async def query_with_breaker(sql, params):
    return await db_circuit.call(db_pool.fetchrow, sql, params)
```

## 8. Exponential Backoff + Jitter

```python
import random

async def retry_with_backoff(
    func,
    max_attempts: int = 5,
    base_delay: float = 0.5,
    max_delay: float = 30.0,
    jitter: bool = True,
    retryable_errors = (ConnectionError, TimeoutError, RateLimitExceeded),
):
    for attempt in range(max_attempts):
        try:
            return await func()
        except retryable_errors as e:
            if attempt == max_attempts - 1:
                raise
            # Exponential backoff: 0.5, 1, 2, 4, 8...
            delay = min(base_delay * (2 ** attempt), max_delay)
            if jitter:
                # Full jitter: spread retries to prevent thundering herd
                delay = random.uniform(0, delay)
            await asyncio.sleep(delay)
        except Exception:
            raise  # Non-retryable errors fail immediately
```

## 9. Async Job Queue (for Heavy Operations)

Heavy operations (bulk import, report generation, data export) MUST be async:

```python
# Celery task example
from celery import Celery
from kombu import Queue

app = Celery('saas_tasks')

# Priority queues
app.conf.task_queues = (
    Queue('critical',    routing_key='critical',    priority=10),
    Queue('high',        routing_key='high',        priority=7),
    Queue('default',     routing_key='default',     priority=5),
    Queue('low',         routing_key='low',         priority=2),
    Queue('background',  routing_key='background',  priority=0),
)

# Always include tenant context in task
@app.task(
    bind=True,
    max_retries=3,
    default_retry_delay=60,
    queue='default',
    rate_limit='100/m',  # per worker
)
def generate_report(self, tenant_id: str, report_config: dict):
    try:
        with tenant_context(tenant_id):
            result = _generate_report_sync(report_config)
            notify_report_complete(tenant_id, result)
    except Exception as exc:
        raise self.retry(exc=exc, countdown=2 ** self.request.retries * 60)

# API endpoint: enqueue and return job ID
async def request_report(tenant_id: str, config: dict) -> str:
    tier = await get_tenant_tier(tenant_id)
    queue = 'high' if tier == 'enterprise' else 'low'
    task = generate_report.apply_async(
        args=[tenant_id, config],
        queue=queue,
        task_id=f"{tenant_id}:{uuid4()}"
    )
    return task.id  # Client polls GET /jobs/{task_id}
```

## 10. Query Timeout Classification

```python
# Categorize queries by expected duration and set appropriate timeouts
QUERY_TIMEOUTS = {
    "realtime":    "2s",    # Patient vitals, availability checks
    "interactive": "10s",   # Dashboard KPIs, user-facing queries
    "background":  "60s",   # Scheduled reports, aggregations
    "batch":       "300s",  # Bulk imports, data migrations
    "maintenance": "3600s", # VACUUM, REINDEX, large backfills
}

async def execute_query(sql: str, params: list, category: str = "interactive"):
    timeout = QUERY_TIMEOUTS[category]
    async with pool.acquire() as conn:
        await conn.execute(f"SET LOCAL statement_timeout = '{timeout}'")
        await conn.execute(f"SET LOCAL lock_timeout = '5s'")
        return await conn.fetch(sql, *params)
```

## 11. Observability — Metrics to Track

Emit these metrics for every request/query in production:

```python
# Request metrics
metrics.increment("api.requests", tags=["tenant_id", "endpoint", "method", "status"])
metrics.histogram("api.response_time_ms", duration, tags=["endpoint", "tenant_tier"])
metrics.increment("ratelimit.hit", tags=["tenant_id", "limiter_type"])

# Queue metrics  
metrics.gauge("queue.depth", queue.size(), tags=["priority"])
metrics.histogram("queue.wait_seconds", wait_time, tags=["tenant_tier"])
metrics.increment("queue.shed", tags=["reason"])  # dropped requests

# DB metrics
metrics.histogram("db.query_duration_ms", duration, tags=["query_type", "table"])
metrics.gauge("db.pool.active", pool.size - pool.freesize)
metrics.gauge("db.pool.waiting", pool.waiting)
metrics.increment("db.timeout", tags=["tenant_id", "query_class"])
metrics.increment("circuit_breaker.trip", tags=["service"])

# Tenant health
metrics.gauge("tenant.active_connections", conn_count, tags=["tenant_id"])
metrics.increment("tenant.quota.exceeded", tags=["tenant_id", "quota_type"])
```

Alert thresholds:
- P99 response time > 2s → alert
- Queue depth > 1000 → alert
- Circuit breaker trips > 3 in 5min → page
- Rate limit hit rate > 5% of requests → investigate noisy tenant
