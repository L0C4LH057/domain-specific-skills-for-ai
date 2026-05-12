# TARGET CONTEXT — Pre-Flight Briefing

> **You will refuse to suggest active tests until this file is filled.**
> Update it at the start of every engagement. Stale context = wrong recommendations.

---

## Active Target

| Field | Value |
|-------|-------|
| **Program Type** | <!-- BBP / VDP --> |
| **Platform** | <!-- HackerOne / Bugcrowd / Intigriti / YesWeHack / Immunefi / Self-hosted --> |
| **Program URL** | <!-- e.g. https://hackerone.com/example --> |
| **Target Name** | <!-- e.g. Example Corp --> |
| **In-Scope Assets** | <!-- explicit list — wildcards only if program permits --> |
| **Out-of-Scope** | <!-- explicit list — never test these --> |
| **Known Tech Stack** | <!-- e.g. React frontend, Rails backend, Postgres, AWS --> |
| **WAF / CDN** | <!-- e.g. Cloudflare, AWS WAF, Akamai, none observed --> |
| **Auth Required** | <!-- Yes / No / Both --> |
| **Test Accounts** | <!-- e.g. user-a@test.example, user-b@test.example, admin-c@test.example --> |
| **Max Payout** | <!-- e.g. $5000 Critical, $2000 High --> |
| **Special Rules** | <!-- e.g. no automated scanners, no DoS, no social engineering --> |
| **Reporting Format** | <!-- platform default / custom template required --> |
| **Engagement Started** | <!-- date --> |

## Program Notes

<!--
Free-form. Capture anything that matters for this specific program:
- Known duplicate-heavy classes
- Specific bonus categories
- Subdomains the program treats specially
- Any prior reports filed and their status
-->

## Session State

| Field | Value |
|-------|-------|
| **Active Phase** | <!-- ASG / Horizontal Recon / Vertical Recon / JS Mining / Param Archaeology / BAC Hunt / Reporting --> |
| **Current Focus** | <!-- e.g. /api/v2/ endpoints under app.example.com --> |
| **Next Scheduled Action** | <!-- e.g. run daily pipeline tomorrow 09:00 --> |
| **Open Hypotheses** | <!-- list of untested leads carried forward --> |
| **Confirmed Findings** | <!-- count and severity tier --> |

---

*Update this file when scope changes, accounts rotate, or you switch focus to a new target. Cortex reads it on every session start.*
