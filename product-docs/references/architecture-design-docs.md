# Architecture & Design Documentation Reference

## Table of Contents
1. [Technical Design Document (TDD)](#tdd)
2. [Product Requirements Document (PRD)](#prd)
3. [Request for Comments (RFC)](#rfc)
4. [System Architecture Document](#architecture)
5. [Data Flow Diagrams in Docs](#diagrams)

---

## 1. Technical Design Document (TDD) {#tdd}

A TDD explains *how* an engineering solution will be built. Written before implementation to align the team and catch issues early.

```markdown
# Technical Design: [Feature / System Name]

**Author(s)**: Emeka Osei, Fatima Al-Hassan
**Date**: 2025-03-01
**Status**: Draft | In Review | Approved | Implemented
**Reviewers**: @tech-lead, @platform-team
**JIRA**: [ENG-1234](https://jira.example.com/ENG-1234)
**Related PRD**: [PRD: Payments V2](#)

---

## Problem Statement

[2–3 sentences. What problem are we solving? Why does it matter now?
What is the impact of NOT solving it?]

**Current behavior**: [What happens today]
**Desired behavior**: [What we want to happen]
**Success metrics**: [How we'll know it worked]

---

## Background & Context

[Any context needed to understand the design decisions. Links to relevant
ADRs, previous designs, or technical constraints.]

**Constraints**:
- [Technical constraint 1, e.g., "Must not require downtime"]
- [Business constraint, e.g., "Must be shippable within 6 weeks"]
- [External dependency, e.g., "Must integrate with existing auth service"]

---

## Proposed Solution

### High-Level Overview

[1–3 paragraphs + diagram describing the solution at a high level.
A reader should understand the approach without reading the details.]

```
[ASCII or Mermaid diagram of the system]

User → API Gateway → Payment Service → [Stripe API]
                           ↓
                     PostgreSQL DB
                           ↓
                    Audit Log Service
```

### Detailed Design

#### [Component 1: API Layer]

**Endpoints added / changed:**

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/v2/payments/initiate` | Initiates a payment intent |
| `GET` | `/v2/payments/{id}` | Gets payment status |

**Request/Response contracts:**
[Show full request and response schemas for new/changed endpoints]

#### [Component 2: Database Changes]

**Schema changes:**
```sql
-- New table
CREATE TABLE payment_intents (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amount      INTEGER NOT NULL,           -- in smallest currency unit
  currency    CHAR(3) NOT NULL,
  status      payment_status NOT NULL DEFAULT 'pending',
  user_id     UUID NOT NULL REFERENCES users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TYPE payment_status AS ENUM ('pending', 'processing', 'succeeded', 'failed', 'cancelled');
CREATE INDEX idx_payment_intents_user_id ON payment_intents(user_id);
CREATE INDEX idx_payment_intents_status ON payment_intents(status) WHERE status = 'pending';
```

**Migration strategy:** [Zero-downtime / maintenance window / phased rollout]

#### [Component 3: Service Logic]

[Pseudocode or description of core business logic, especially for complex flows]

```
function initiatePayment(userId, amount, currency):
  1. Validate amount > 0 and currency is supported
  2. Check user's payment method is on file
  3. Create payment_intent record (status: 'pending')
  4. Call Stripe PaymentIntent API
     - On success: update status to 'processing', store stripe_id
     - On failure: update status to 'failed', log error
  5. Return payment intent ID to caller
  6. (Async) Listen for Stripe webhook to update final status
```

---

## Alternatives Considered

### Alternative 1: [Name]
[Description]

**Pros**: [Why this was appealing]
**Cons / Why rejected**: [Why we didn't choose it]

### Alternative 2: [Name]
...

---

## Data Flow

[Describe or diagram how data flows through the system]

**Happy path:**
1. Client sends `POST /v2/payments/initiate`
2. API validates request, authenticates user
3. Payment Service creates DB record, calls Stripe
4. Stripe responds with `payment_intent.id`
5. Service updates DB, returns `{id, status: "processing"}`
6. Stripe webhook fires `payment_intent.succeeded`
7. Service updates DB status to `succeeded`
8. Client polls `GET /v2/payments/{id}` → sees `succeeded`

**Failure modes:**
| Failure | Detection | Recovery |
|---------|-----------|---------|
| Stripe API timeout | 30s timeout | Retry with exponential backoff (3x) |
| DB write failure | Exception caught | Return 500, no Stripe call made |
| Webhook delivery failure | Stripe retries 72h | Reconciliation job runs hourly |

---

## Security Considerations

- [ ] All payment data encrypted at rest (AES-256)
- [ ] PCI DSS: We are NOT storing raw card data (handled by Stripe)
- [ ] API key rotation procedure documented in [runbook](#)
- [ ] Audit log writes are append-only (no UPDATE or DELETE permissions)
- [ ] Rate limiting: 10 payment initiations per user per minute

---

## Observability

**Metrics to add:**
- `payments.initiated` (counter, by currency)
- `payments.succeeded` (counter, by currency)
- `payments.failed` (counter, by error_type)
- `payments.latency_ms` (histogram)

**Alerts to add:**
- Payment failure rate > 5% for 5 minutes → P1 alert
- Stripe API latency p99 > 5s → P2 alert

**Dashboards:** [Link to Grafana dashboard to create]

---

## Rollout Plan

| Phase | Scope | Duration | Rollback Plan |
|-------|-------|----------|--------------|
| 1. DB migration | Deploy schema changes (no code change) | 1 day | Backward-compatible; rollback is safe |
| 2. Feature flag: 5% | Enable for 5% of users | 3 days | Toggle flag to 0% |
| 3. Feature flag: 50% | If P0/P1 rate acceptable | 3 days | Toggle flag to 5% |
| 4. GA | All users | — | Revert deploy if > 1% error rate |

---

## Open Questions

| Question | Owner | Due |
|----------|-------|-----|
| Should we support partial refunds in v2? | PM | 2025-03-10 |
| What's the SLA for webhook delivery? | Infra | 2025-03-08 |

---

## References

- [Stripe PaymentIntents API](https://stripe.com/docs/api/payment_intents)
- [ADR-042: PostgreSQL as primary data store](#)
- [Security review: Payment flows (2024-12)](#)
```

---

## 2. Product Requirements Document (PRD) {#prd}

```markdown
# PRD: [Feature Name]

**Product Manager**: [Name]
**Engineering Lead**: [Name]
**Designer**: [Name]
**Date**: 2025-03-01
**Target Release**: Q2 2025 (v3.2)
**Status**: Draft | Review | Approved | In Development | Shipped

---

## Problem

### User Problem
[Who is experiencing this problem? What is the problem? How are they currently solving it (if at all)?
What is the cost of the problem to them?]

### Business Opportunity
[Why does solving this matter for the business? Revenue impact, retention, NPS, competitive parity?]

---

## Goals & Success Metrics

| Goal | Metric | Baseline | Target |
|------|--------|----------|--------|
| [Goal 1] | [Metric] | [Current value] | [Target value] |
| [Goal 2] | [Metric] | [Current value] | [Target value] |

**Non-goals** (explicitly out of scope for this release):
- [Non-goal 1]
- [Non-goal 2]

---

## User Stories

**Primary persona**: [Name] — [Brief description]

| As a... | I want to... | So that... | Priority |
|---------|-------------|------------|---------|
| [User type] | [Action] | [Outcome/value] | P0 |
| [User type] | [Action] | [Outcome/value] | P1 |
| [User type] | [Action] | [Outcome/value] | P2 |

---

## Requirements

### Functional Requirements

**P0 (Must have for launch):**
- [ ] [Requirement 1]
- [ ] [Requirement 2]

**P1 (Should have):**
- [ ] [Requirement 3]

**P2 (Nice to have / future):**
- [ ] [Requirement 4]

### Non-Functional Requirements

| Requirement | Specification |
|-------------|--------------|
| Performance | Page load < 2s at p95 |
| Availability | 99.9% uptime |
| Security | [Requirements] |
| Accessibility | WCAG 2.1 AA |

---

## Design & UX

[Link to Figma designs]

**Key UX decisions and rationale:**
1. [Decision]: [Rationale]

---

## Out of Scope

The following are explicitly NOT included in this release:
- [Exclusion 1] — Rationale: [Why]
- [Exclusion 2] — Rationale: [Why / deferred to when]

---

## Dependencies & Risks

| Dependency / Risk | Impact | Mitigation |
|-------------------|--------|-----------|
| [Dependency on X team] | [Impact if blocked] | [Mitigation] |
| [Technical risk] | [Probability / severity] | [Mitigation] |

---

## Launch Plan

- [ ] Documentation updated
- [ ] Support team trained
- [ ] Release notes written
- [ ] Feature flagged (rollout %)
- [ ] Monitoring / alerting in place
```

---

## References

- **"Shape Up"** — Basecamp/Ryan Singer — https://basecamp.com/shapeup (product design process)
- **Google Design Docs** — https://www.industrialempathy.com/posts/design-docs-at-google/
- **"Writing an Effective Design Doc"** — Gergely Orosz, The Pragmatic Engineer
- **Mermaid.js** — https://mermaid.js.org/ (diagrams-as-code for docs)
- **C4 Model** — https://c4model.com/ (architecture diagramming standard)
- **"An Elegant Puzzle"** — Will Larson (engineering management, design culture)
