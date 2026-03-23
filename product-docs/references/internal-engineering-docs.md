# Internal & Engineering Documentation Reference

## Table of Contents
1. [Runbook Template](#runbook)
2. [Architecture Decision Record (ADR)](#adr)
3. [Postmortem / Incident Report](#postmortem)
4. [Standard Operating Procedure (SOP)](#sop)
5. [Engineering Onboarding Guide](#onboarding)
6. [Technical Design Document](#design-doc)
7. [Playbook Templates](#playbook)

---

## 1. Runbook Template {#runbook}

A runbook is a set of step-by-step procedures an on-call engineer follows to respond to a specific operational scenario. It must be executable under pressure, at 2am, by someone who didn't write it.

### Runbook Writing Rules
1. **Assume nothing** — link to every tool, dashboard, and command reference
2. **Use exact commands** — never say "restart the service", say `sudo systemctl restart api-server`
3. **Include verification steps** — after every action, tell the engineer what "success" looks like
4. **Define escalation** — every runbook must say when and to whom to escalate
5. **Keep short** — if a runbook exceeds 15 steps, split it

```markdown
# Runbook: [Service/System] — [Scenario]

**Last Updated**: 2025-03-20
**Owner**: Platform Team
**Severity**: P1 | P2 | P3
**Estimated Resolution Time**: 15–30 minutes

---

## Purpose

This runbook covers [exact scenario, e.g., "high error rate on the payment API
exceeding 5% for more than 5 minutes"].

---

## Trigger Conditions

This runbook is triggered when:
- Alert: `[AlertName]` fires in [PagerDuty / OpsGenie]
- Threshold: [Error rate > 5%] for [5+ minutes]
- Symptoms: [What users/systems experience]

---

## Impact Assessment

| Component Affected | User Impact | Revenue Impact |
|-------------------|------------|----------------|
| [Service name] | [Description] | [High / Medium / Low] |

---

## Immediate Actions (First 5 Minutes)

1. **Acknowledge the alert** in PagerDuty
2. **Open the dashboard**: [Dashboard URL]
3. **Check current error rate**:
   ```bash
   kubectl logs -n production -l app=api-server --tail=100 | grep ERROR | wc -l
   ```
4. **Notify the team** in #incidents Slack channel:
   ```
   🚨 Investigating payment API errors. Dashboard: [URL]. Updates every 10 min.
   ```

---

## Diagnosis

### Check 1: Application Logs
```bash
kubectl logs -n production -l app=api-server --since=15m | grep -E "ERROR|FATAL"
```
**If you see** `Connection refused`:  → Go to [Check 3: Database Connectivity](#check-3)
**If you see** `Timeout waiting for`:  → Go to [Check 4: Downstream Services](#check-4)
**If you see** `OOMKilled`:  → Go to [Check 2: Memory](#check-2)

### Check 2: Memory & Resources {#check-2}
```bash
kubectl top pods -n production -l app=api-server
```
If memory > 90% of limit, proceed to [Mitigation: Scale Up](#scale-up).

### Check 3: Database Connectivity {#check-3}
```bash
kubectl run -it --rm debug --image=postgres:14 --restart=Never -- \
  psql -h $DB_HOST -U $DB_USER -c "SELECT 1;"
```
If connection fails → [Escalate to Database On-Call](#escalation)

### Check 4: Downstream Services {#check-4}
Check service status pages:
- Payment processor: [status.stripe.com](https://status.stripe.com)
- Auth service: [internal status page URL]

---

## Mitigation

### Option A: Restart Pods (Safe, try first)
```bash
kubectl rollout restart deployment/api-server -n production
```
Wait 2 minutes, then verify:
```bash
kubectl rollout status deployment/api-server -n production
```
**Expected**: `deployment "api-server" successfully rolled out`

### Option B: Scale Up {#scale-up}
```bash
kubectl scale deployment/api-server -n production --replicas=10
```
Monitor for 5 minutes. If error rate drops below 1%, this is sufficient.

### Option C: Rollback to Previous Version
```bash
kubectl rollout undo deployment/api-server -n production
```

> ⚠️ **CAUTION**: Rollback may cause brief additional downtime (30–60 seconds).

---

## Verification

Confirm resolution by checking all of these:
- [ ] Error rate < 1% for 5 consecutive minutes: [Dashboard link]
- [ ] No new ERROR logs: `kubectl logs -n production -l app=api-server --since=5m | grep ERROR`
- [ ] Synthetic monitoring passing: [Monitoring URL]

---

## Resolution

1. Update the incident channel with resolution message
2. Set PagerDuty incident to **Resolved**
3. File a follow-up ticket for root cause analysis if incident was P1 or P2:
   [JIRA project link]

---

## Escalation {#escalation}

If unable to resolve within 30 minutes, or if issue requires database/infrastructure access:

| Who | Contact | When to Escalate |
|-----|---------|-----------------|
| Database On-Call | PagerDuty: DB rotation | DB connectivity issues |
| Engineering Manager | Slack: @mgr-name | P1 with no resolution path |
| VP Engineering | Phone: [number] | Revenue impact > $10K |

---

## Related Resources

- [Architecture Overview](#)
- [Service Dependencies Diagram](#)
- [Previous incidents with this service](https://jira.example.com/issues/?filter=12345)
```

---

## 2. Architecture Decision Record (ADR) {#adr}

ADRs document significant architectural decisions. The goal is to record the context, options considered, and reasoning — so future engineers understand *why*, not just *what*.

```markdown
# ADR-042: Use PostgreSQL for Primary Data Store

**Status**: Accepted
**Date**: 2025-02-14
**Deciders**: Emeka Osei (Tech Lead), Platform Team
**Tags**: database, infrastructure, storage

---

## Context and Problem Statement

We need a primary data store for the new payments service. The service will handle
~50,000 transactions per day at launch, with potential growth to 500,000/day within 18 months.
Requirements include:
- ACID transactions (essential for financial data)
- Complex queries with joins across multiple entity types
- Point-in-time recovery capability
- Team familiarity and operational experience

---

## Decision Drivers

- Financial data integrity is non-negotiable (ACID required)
- Team has 5 years of operational experience with PostgreSQL
- Query complexity: we need multi-table joins with complex aggregations
- Compliance requirements: audit logs must be immutable and queryable

---

## Options Considered

### Option 1: PostgreSQL (Chosen)
**Pros**:
- Full ACID compliance
- Mature tooling (backups, replication, monitoring)
- Team expertise
- Handles our expected load (with read replicas)
- Rich ecosystem (Prisma, pgvector, PostGIS if needed)

**Cons**:
- Vertical scaling is expensive at 10M+ transactions/day
- Schema migrations require careful planning

### Option 2: MongoDB
**Pros**: Flexible schema, horizontal sharding

**Cons**:
- No native multi-document ACID until v4 (and still complex)
- Team would need training
- Overkill: our data is highly relational

### Option 3: CockroachDB
**Pros**: Distributed ACID, automatic sharding

**Cons**:
- 3x cost of PostgreSQL
- Team has no operational experience
- Complexity not justified at current scale

---

## Decision Outcome

**Chosen option**: PostgreSQL, running on AWS RDS with Multi-AZ deployment.

**Rationale**: ACID compliance is non-negotiable for payment data. PostgreSQL comfortably
handles our projected load with read replicas added at ~200K transactions/day. Team
expertise reduces operational risk significantly.

---

## Consequences

**Positive**:
- Proven reliability for financial systems
- Fast initial development (team familiarity)
- Lower operational overhead

**Negative / Risks**:
- Will need to plan for horizontal sharding if we exceed 5M transactions/day
- Schema migrations must be backward-compatible (blue/green deployments required)

**Mitigation**:
- Set a review trigger: revisit if write throughput exceeds 5,000 TPS sustained
- All migrations must pass through PR review by a senior engineer

---

## Links

- [PostgreSQL RDS Pricing](https://aws.amazon.com/rds/postgresql/pricing/)
- [ADR-031: Database Migration Strategy](#)
- [Spike: Load Testing Results (Confluence)](#)
```

---

## 3. Postmortem / Incident Report {#postmortem}

Postmortems are blameless documents that capture what happened, why, and how to prevent recurrence.

```markdown
# Postmortem: Payment Service Outage — 2025-03-15

**Incident ID**: INC-2025-0315-001
**Severity**: P1
**Duration**: 47 minutes (14:32–15:19 UTC)
**Author**: On-call SRE: Fatima Al-Hassan
**Status**: Complete
**Review Date**: 2025-03-18

---

## Executive Summary

The payment service experienced a complete outage for 47 minutes due to a database
connection pool exhaustion triggered by an inefficient query introduced in deploy v2.4.1.
Approximately 1,240 payment attempts failed. Mitigation was a configuration change to
the connection pool limit. Root cause fix is scheduled for v2.4.2.

---

## Impact

| Metric | Value |
|--------|-------|
| Duration | 47 minutes |
| Failed transactions | ~1,240 |
| Estimated revenue impact | $18,600 |
| Users affected | ~890 |
| SLA breach | Yes (99.9% monthly SLA at risk) |

---

## Timeline

All times UTC.

| Time | Event |
|------|-------|
| 14:30 | Deploy v2.4.1 completed to production |
| 14:32 | Error rate alert fires (> 5%) |
| 14:33 | PagerDuty pages on-call engineer (Fatima) |
| 14:38 | Fatima acknowledges, opens logs, sees DB timeouts |
| 14:45 | Fatima identifies connection pool exhaustion |
| 14:52 | Attempt to increase pool size — requires config restart |
| 15:10 | Config change applied, pods restarting |
| 15:19 | Error rate returns to < 0.1%, incident resolved |
| 15:25 | All-clear posted in #incidents |

---

## Root Cause Analysis

### What Happened
Deploy v2.4.1 introduced a new endpoint (`GET /payments/summary`) containing
an N+1 query: for each payment record, a separate database query fetched
the associated user details. Under light load in staging, this was unnoticeable.
Under production load (~200 req/min), this generated ~40,000 database queries/minute,
exhausting the connection pool (max: 100 connections).

### Why It Happened (5 Whys)

1. **Why did the outage occur?** — Connection pool was exhausted
2. **Why was the pool exhausted?** — Excessive DB queries from the new endpoint
3. **Why were there excessive queries?** — N+1 query pattern not caught in code review
4. **Why wasn't it caught?** — No query count limit or slow-query detection in staging
5. **Why is there no detection?** — We lack automated query analysis in our CI pipeline

---

## What Went Well

- Alert fired within 2 minutes of the issue starting (good monitoring)
- On-call engineer acknowledged quickly and followed runbook
- Communication to stakeholders was clear and timely
- Mitigation (config change) was available and worked

---

## What Went Poorly

- No automated detection of N+1 queries before production
- Staging environment did not replicate production query load
- Runbook for connection pool exhaustion didn't exist (created post-incident)
- Time to mitigation was 38 minutes (target: < 15 minutes for P1)

---

## Action Items

| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| Fix N+1 query in v2.4.2 | Backend Team | 2025-03-22 | In Progress |
| Add query analyzer to CI pipeline (reject N+1 patterns) | Platform Team | 2025-04-05 | Planned |
| Create runbook: connection pool exhaustion | Fatima | 2025-03-21 | Complete |
| Load test staging with production-level traffic | QA Team | 2025-04-12 | Planned |
| Add connection pool utilization alert (> 80%) | Platform Team | 2025-03-25 | In Progress |

---

## Lessons Learned

> This section is for reflection, not blame. Focus on systemic factors.

- Our staging environment is insufficiently representative of production load.
  We need either load testing in CI or a properly sized staging environment.
- N+1 queries are a class of bug that code review often misses.
  Automated detection is the right systemic fix.

---

## References

- [Incident timeline (PagerDuty)](#)
- [Deploy v2.4.1 PR](#)
- [Connection pool exhaustion runbook (newly created)](#)
```

---

## 4. Standard Operating Procedure (SOP) {#sop}

```markdown
# SOP: [Process Name]

**Document ID**: SOP-ENG-042
**Version**: 1.2
**Effective Date**: 2025-01-15
**Owner**: Platform Engineering
**Review Cycle**: Quarterly
**Next Review**: 2025-04-15

---

## Purpose

This SOP defines the standard procedure for [process name] to ensure
[consistency / compliance / safety / quality outcome].

---

## Scope

Applies to: [Who must follow this procedure]
Does not apply to: [Exceptions]

---

## Prerequisites

Before performing this procedure:
- [ ] You have [permission / role]
- [ ] You have access to [system / tool]
- [ ] [Prerequisite condition is met]

---

## Procedure

### Step 1: [Step Name]
**Who**: [Role responsible]
**When**: [When this step occurs in the process]

1. [Specific action]
2. [Specific action]
3. **Verify**: [How to confirm this step completed successfully]

### Step 2: [Step Name]
...

---

## Quality Checks

Before marking this procedure complete, verify:
- [ ] [Check 1]
- [ ] [Check 2]
- [ ] Documentation updated in [system]

---

## Exceptions and Escalations

| Situation | Action | Who to Contact |
|-----------|--------|----------------|
| [Exception scenario] | [What to do] | [Contact] |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.2 | 2025-01-15 | J. Smith | Updated Step 3 for new tooling |
| 1.1 | 2024-10-01 | A. Osei | Added exception handling section |
| 1.0 | 2024-07-01 | J. Smith | Initial version |
```

---

## References

- **Google SRE Book** — https://sre.google/sre-book/table-of-contents/ (runbooks, postmortems)
- **"Accelerate"** — Forsgren et al. (documentation's role in DevOps performance)
- **Michael Nygard: "Release It!"** — Circuit breakers, operational readiness
- **PagerDuty Incident Response Docs** — https://response.pagerduty.com/
- **Atlassian Incident Management** — https://www.atlassian.com/incident-management
- **"Architecture Decision Records"** — Michael Nygard, 2011 — https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
