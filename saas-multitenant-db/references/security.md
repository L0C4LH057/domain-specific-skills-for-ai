# Security, Compliance & Audit — Multi-Tenant SaaS

## TOC
1. Tenant isolation security model
2. Encryption at rest & in transit
3. Audit logging architecture
4. HIPAA compliance (Healthcare)
5. GDPR compliance (EU data)
6. SOC 2 Type II controls
7. PCI DSS (Payment data)
8. Data masking & anonymization
9. Access control & RBAC
10. Security checklist

---

## 1. TENANT ISOLATION SECURITY MODEL

### Defense in Depth

```
Layer 1: Network   — VPC isolation, private subnets, security groups
Layer 2: Auth      — JWT with tenant_id claim, verified every request
Layer 3: App       — Tenant context set and validated in middleware
Layer 4: Database  — Row-Level Security policies, RLS bypass requires superuser
Layer 5: Column    — PII columns encrypted with tenant-specific keys
Layer 6: Audit     — Every data access logged with actor and tenant
```

### Tenant Context Injection (Application Layer)

```python
# FastAPI middleware — sets tenant context for every request
from fastapi import Request, HTTPException
import jwt

class TenantMiddleware:
    async def __call__(self, request: Request, call_next):
        token = request.headers.get("Authorization", "").replace("Bearer ", "")
        if not token:
            raise HTTPException(401, "Missing auth token")
        
        try:
            payload = jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])
            tenant_id = payload["tenant_id"]
            user_id = payload["sub"]
            
            # Verify tenant is active (cached)
            tenant = await tenant_registry.get(tenant_id)
            if not tenant or tenant.status != "active":
                raise HTTPException(403, "Tenant suspended or not found")
            
            # Attach to request state
            request.state.tenant_id = tenant_id
            request.state.user_id = user_id
            request.state.tenant = tenant
        except jwt.ExpiredSignatureError:
            raise HTTPException(401, "Token expired")
        except jwt.InvalidTokenError:
            raise HTTPException(401, "Invalid token")
        
        response = await call_next(request)
        return response
```

### PostgreSQL RLS — Critical Security Notes

```sql
-- RLS is bypassed by superuser and table owners — NEVER use these for app connections
-- Use a non-superuser role with FORCE ROW SECURITY

ALTER TABLE patients FORCE ROW LEVEL SECURITY;  -- applies even to table owner
-- This ensures even if app_user is table owner, RLS still applies

-- Test isolation (always test this in staging before production):
SET ROLE app_user;
SET app.current_tenant_id = 'tenant-a-uuid';
SELECT COUNT(*) FROM patients;  -- should return only tenant-a patients

SET app.current_tenant_id = 'tenant-b-uuid';  
SELECT COUNT(*) FROM patients;  -- should return only tenant-b patients
-- Any crossover = critical security bug
```

---

## 2. ENCRYPTION AT REST & IN TRANSIT

### Column-Level Encryption (PostgreSQL + pgcrypto)

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Encrypt sensitive columns
-- Store national_id, SSN, financial data encrypted
INSERT INTO patients (tenant_id, mrn, national_id_encrypted, ...)
VALUES ($1, $2, pgp_sym_encrypt($3, $4), ...)
-- $3 = plaintext national ID
-- $4 = symmetric key (per-tenant key from KMS, never hardcode)

-- Decrypt for authorized access
SELECT 
    id, first_name, last_name,
    pgp_sym_decrypt(national_id_encrypted, $2) AS national_id
FROM patients
WHERE tenant_id = $1 AND id = $3;

-- Key rotation (re-encrypt with new key)
UPDATE patients
SET national_id_encrypted = pgp_sym_encrypt(
    pgp_sym_decrypt(national_id_encrypted, $old_key),
    $new_key
)
WHERE tenant_id = $1;
```

### KMS Integration Pattern
```python
# Never store encryption keys in code or DB
# Use AWS KMS, GCP KMS, or HashiCorp Vault

import boto3

kms = boto3.client('kms', region_name='us-east-1')

async def get_tenant_key(tenant_id: str) -> bytes:
    """Get data encryption key for tenant (cached in memory, short TTL)."""
    cache_key = f"dek:{tenant_id}"
    if cached := key_cache.get(cache_key):
        return cached
    
    # KMS: Generate data key encrypted under tenant's CMK
    response = kms.generate_data_key(
        KeyId=f"alias/tenant-{tenant_id}",
        KeySpec='AES_256'
    )
    plaintext_key = response['Plaintext']  # Use for encryption, then discard
    # Store encrypted_key in tenant settings (can't be used without KMS)
    
    key_cache.set(cache_key, plaintext_key, ttl=300)  # 5-minute memory cache
    return plaintext_key

# Envelope encryption: each tenant has their own CMK
# Data encrypted with DEK; DEK encrypted with CMK
# To decrypt: call KMS to decrypt DEK, use DEK to decrypt data
```

### TLS Configuration
```nginx
# Nginx — enforce TLS 1.2+ for all tenant API connections
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384';
ssl_prefer_server_ciphers on;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_stapling on;
ssl_stapling_verify on;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

---

## 3. AUDIT LOGGING ARCHITECTURE

```sql
-- Comprehensive audit log (separate high-write table, partitioned)
CREATE TABLE audit_log (
    id              BIGSERIAL,
    tenant_id       UUID NOT NULL,
    event_time      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    event_type      VARCHAR(50) NOT NULL,
    -- 'DATA_ACCESS','DATA_WRITE','DATA_DELETE','LOGIN','LOGOUT',
    -- 'PERMISSION_CHANGE','EXPORT','CRITICAL_VALUE_ACCESS'
    actor_id        UUID,
    actor_type      VARCHAR(20),   -- 'user','system','api_key','admin'
    actor_ip        INET,
    actor_user_agent TEXT,
    resource_type   VARCHAR(50),   -- 'patient','prescription','lab_result'
    resource_id     UUID,
    action          VARCHAR(30),   -- 'SELECT','INSERT','UPDATE','DELETE'
    changed_fields  TEXT[],        -- which fields were modified
    old_values      JSONB,         -- previous values (for UPDATE/DELETE)
    new_values      JSONB,         -- new values (for INSERT/UPDATE)
    outcome         VARCHAR(20) DEFAULT 'success',  -- 'success','denied','error'
    session_id      VARCHAR(100),
    request_id      VARCHAR(100),
    notes           TEXT
) PARTITION BY RANGE (event_time);

-- Monthly partitions (audit logs grow fast)
CREATE TABLE audit_log_2024_01 PARTITION OF audit_log
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- Index for compliance queries
CREATE INDEX idx_audit_tenant_time ON audit_log(tenant_id, event_time DESC);
CREATE INDEX idx_audit_resource ON audit_log(tenant_id, resource_type, resource_id);
CREATE INDEX idx_audit_actor ON audit_log(tenant_id, actor_id, event_time DESC);
```

### Application-Level Audit Decorator
```python
def audit_log(event_type: str, resource_type: str = None):
    """Decorator to automatically log data access and mutations."""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            request = get_current_request()  # from context var
            start = time.time()
            outcome = "success"
            result = None
            try:
                result = await func(*args, **kwargs)
                return result
            except PermissionError:
                outcome = "denied"
                raise
            except Exception:
                outcome = "error"
                raise
            finally:
                await audit_writer.log({
                    "tenant_id": request.state.tenant_id,
                    "event_type": event_type,
                    "actor_id": request.state.user_id,
                    "actor_ip": request.client.host,
                    "resource_type": resource_type,
                    "action": func.__name__,
                    "outcome": outcome,
                    "request_id": request.state.request_id,
                    "duration_ms": int((time.time() - start) * 1000),
                })
        return wrapper
    return decorator

@audit_log("DATA_ACCESS", "patient")
async def get_patient(tenant_id: str, patient_id: str): ...

@audit_log("DATA_WRITE", "prescription")
async def create_prescription(tenant_id: str, data: dict): ...
```

---

## 4. HIPAA COMPLIANCE (HEALTHCARE)

### PHI (Protected Health Information) Columns
All PHI must be identified, encrypted, and access-logged:

```sql
-- HIPAA PHI identifiers that require protection:
-- Names, Dates (except year), Phone numbers, Addresses, SSN/NIN
-- Medical record numbers, Account numbers, Biometric identifiers
-- Full-face photos, Email addresses, IP addresses, URLs

-- Encrypt PHI columns
ALTER TABLE patients ADD COLUMN ssn_encrypted BYTEA;
ALTER TABLE patients ADD COLUMN dob_encrypted BYTEA;

-- Access to PHI requires audit log entry (automated via decorator)
-- Minimum necessary access: query only columns needed, not SELECT *
-- De-identification for research/analytics: see section 8
```

### HIPAA Technical Safeguards
```python
HIPAA_CONTROLS = {
    "access_control": [
        "Unique user IDs for all staff",
        "Automatic logoff after 15 minutes inactivity",
        "Emergency access procedure documented",
        "Encryption/decryption of PHI",
    ],
    "audit_controls": [
        "Log all PHI access (reads AND writes)",
        "Log authentication events",
        "Regular log review process",
        "Tamper-evident audit trail",
    ],
    "integrity_controls": [
        "Data in transit: TLS 1.2+",
        "Data at rest: AES-256",
        "Checksums for data integrity verification",
    ],
    "transmission_security": [
        "No PHI in URL parameters",
        "No PHI in logs (mask before writing)",
        "No PHI in error messages sent to clients",
    ],
}
```

### PHI in Logs — Never Log Raw PHI
```python
import re

def mask_phi(text: str) -> str:
    """Remove PHI patterns before writing to logs."""
    # Mask emails
    text = re.sub(r'\b[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}\b', '[EMAIL]', text)
    # Mask phone numbers  
    text = re.sub(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b', '[PHONE]', text)
    # Mask SSN
    text = re.sub(r'\b\d{3}-\d{2}-\d{4}\b', '[SSN]', text)
    # Mask MRN pattern (customize per tenant format)
    text = re.sub(r'\bMRN[-:]?\s*\d+\b', 'MRN:[MASKED]', text, flags=re.IGNORECASE)
    return text
```

---

## 5. GDPR COMPLIANCE

```python
# Right to erasure (Right to be Forgotten)
async def delete_user_data(tenant_id: str, user_id: str, reason: str):
    """
    GDPR Article 17 — anonymize PII while preserving business data integrity.
    Don't DELETE records (breaks referential integrity and audit trails).
    ANONYMIZE instead.
    """
    async with db.transaction() as tx:
        # Anonymize personal data
        await tx.execute("""
            UPDATE users SET
                email = gen_random_uuid() || '@deleted.invalid',
                first_name = 'DELETED',
                last_name = 'USER',
                phone = NULL,
                date_of_birth = NULL,
                national_id_encrypted = NULL,
                deleted_at = NOW(),
                deletion_reason = $3
            WHERE tenant_id = $1 AND id = $2
        """, tenant_id, user_id, reason)
        
        # Log the deletion event (required by GDPR Art. 30)
        await tx.execute("""
            INSERT INTO gdpr_deletion_log(tenant_id, user_id, deleted_at, reason, requested_by)
            VALUES ($1, $2, NOW(), $3, $4)
        """, tenant_id, user_id, reason, current_user_id())

# Data portability (Article 20) — export all user data
async def export_user_data(tenant_id: str, user_id: str) -> dict:
    """Export all personal data for a user in machine-readable format."""
    # Collect from all tables that store user data
    data = {
        "export_date": datetime.utcnow().isoformat(),
        "user": await get_user_profile(tenant_id, user_id),
        "activity": await get_user_activity(tenant_id, user_id),
        "communications": await get_user_communications(tenant_id, user_id),
    }
    return data

# Data retention policies
DATA_RETENTION_DAYS = {
    "user_sessions":   90,
    "audit_logs":      2555,    # 7 years (financial requirement)
    "health_records":  2555,    # 7 years (HIPAA)
    "marketing_data":  365,
    "inactive_users":  1095,    # 3 years
}
```

---

## 9. ROLE-BASED ACCESS CONTROL (RBAC)

```sql
-- Roles
CREATE TABLE roles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    name            VARCHAR(50) NOT NULL,
    description     TEXT,
    is_system       BOOLEAN DEFAULT FALSE,   -- system roles can't be deleted
    UNIQUE (tenant_id, name)
);

-- Permissions (resource:action format)
CREATE TABLE permissions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource        VARCHAR(50) NOT NULL,  -- 'patient','prescription','lab_result'
    action          VARCHAR(20) NOT NULL,  -- 'read','create','update','delete','approve'
    scope           VARCHAR(20) DEFAULT 'own',  -- 'own','department','all'
    description     TEXT,
    UNIQUE (resource, action, scope)
);

CREATE TABLE role_permissions (
    role_id         UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id   UUID NOT NULL REFERENCES permissions(id),
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
    user_id         UUID NOT NULL,
    role_id         UUID NOT NULL REFERENCES roles(id),
    tenant_id       UUID NOT NULL,
    granted_by      UUID,
    granted_at      TIMESTAMPTZ DEFAULT NOW(),
    expires_at      TIMESTAMPTZ,   -- temporary role grants
    PRIMARY KEY (user_id, role_id, tenant_id)
);

-- Permission check function
CREATE OR REPLACE FUNCTION has_permission(
    p_user_id UUID,
    p_tenant_id UUID,
    p_resource VARCHAR,
    p_action VARCHAR
) RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1
        FROM user_roles ur
        JOIN role_permissions rp ON rp.role_id = ur.role_id
        JOIN permissions p ON p.id = rp.permission_id
        WHERE ur.user_id = p_user_id
          AND ur.tenant_id = p_tenant_id
          AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
          AND p.resource = p_resource
          AND p.action = p_action
    );
$$ LANGUAGE sql STABLE;
```

---

## 10. SECURITY CHECKLIST

```
AUTHENTICATION
□ JWT tokens signed with RS256 (asymmetric, rotate keys)
□ Token expiry: access=15min, refresh=7days
□ Tenant_id in JWT claims, verified every request
□ Rate limit authentication endpoints (5 attempts/min)
□ Account lockout after 10 failed attempts

AUTHORIZATION  
□ RBAC with least-privilege principles
□ All endpoints require explicit permission check
□ Admin operations require separate elevated session
□ Audit log every permission grant/revoke

DATA ISOLATION
□ RLS enabled and FORCE on all tenant-scoped tables
□ Integration tests: cross-tenant data access returns empty
□ Tenant context set before EVERY DB query
□ No raw SQL that constructs tenant_id from user input

ENCRYPTION
□ All PHI/PII columns encrypted at column level
□ AES-256 for data at rest (disk encryption)
□ TLS 1.2+ for all connections (DB, API, internal services)
□ Per-tenant encryption keys managed by KMS
□ Key rotation procedure documented and tested

AUDIT
□ All PHI access logged (read AND write)
□ Authentication events logged
□ Admin actions logged
□ Logs tamper-evident (append-only, hashed chains)
□ Log retention: 7 years (healthcare), 1 year minimum

VULNERABILITIES
□ SQL injection: parameterized queries everywhere
□ No raw string concatenation in SQL
□ Dependency scanning in CI/CD
□ Penetration test annually
□ Secrets in Vault/KMS, never in code or environment files (use .env only for dev)
```
