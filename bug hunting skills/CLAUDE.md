	# CLAUDE.md — Bug Bounty Hunting Workspace

	## Initialization — Read This First

At the start of every session, before responding to anything else:

1. Read and fully internalize `agent.md` — this defines who you are, how you operate, your methodology, your workflow, and your report template. Every response must be consistent with it.
2. Check the `targets/` directory for any existing target folder that matches the current session.
3. Check `skills/` for any relevant skill file based on what the user mentions (XSS, SQLi, SSRF, etc.) and load it silently.
4. Run the Session Start Checklist from `agent.md` and surface it to the user if they haven't filled in the target context block yet.

Do not skip initialization. Do not wait to be asked.

---

## Workspace Structure

```
.
├── CLAUDE.md                          ← You are here. Claude Code reads this on startup.
├── agent.md                           ← Full identity, methodology, workflow, report template.
├── TARGET_CONTEXT.md                 # Per-engagement scope/program briefing (FILL BEFORE WORK)
│       
│   
├── targets/
│   └── [target-name]/
│       ├── scope.md                   ← In-scope and out-of-scope assets for this target.
│       ├── recon/
│       │   ├── subdomains.txt         ← Enumerated subdomains.
│       │   ├── urls.txt               ← Harvested URLs and parameters.
│       │   ├── js-endpoints.txt       ← Endpoints extracted from JS files.
│       │   ├── tech-stack.md          ← Identified technologies, frameworks, libraries, WAF.
│       │   └── notes.md               ← Free-form recon notes.
│       ├── findings/
│       │   └── [vuln-name]/
│       │       ├── request.txt        ← Raw HTTP request(s) for reproduction.
│       │       ├── response.txt       ← Relevant response(s).
│       │       ├── payload.txt        ← Exact payload(s) used.
│       │       ├── screenshots/       ← Evidence screenshots.
│       │       └── notes.md           ← Exploitation notes and chain ideas.
│       └── reports/
│           └── [vuln-name]-report.md  ← Final report draft ready for submission.
└── resources/
    ├── payloads/                       ← Custom payload lists organized by vuln class.
    ├── wordlists/                      ← Custom fuzzing wordlists.
    └── templates/                     ← Blank report templates, PoC HTML templates.
```

When I name a target, create its folder structure under `targets/` automatically if it doesn't exist.

---

## Skill Files — Load by Context

Load the relevant skill file silently when the context matches. Never announce that you are loading it — just apply it.

| Context Trigger | Skill File to Load |
|---|---|
| XSS, cross-site scripting, payload, DOM, reflected, stored, blind XSS | `skills/xss-bug-bounty-hunter.md` |
| SQL injection, SQLi, database, union, blind, time-based | Load SQL knowledge |
| SSRF, server-side request, internal metadata, cloud credentials | Load SSRF knowledge |
| IDOR, broken access control, unauthorized access, object reference | Load BAC knowledge |
| Authentication, JWT, OAuth, session, MFA bypass, password reset | Load auth knowledge |
| Business logic, race condition, price manipulation, workflow bypass | Load logic knowledge |
| File upload, MIME bypass, extension bypass, SVG upload | Load upload knowledge |
| Subdomain takeover, dangling CNAME, DNS | Load takeover knowledge |
| GraphQL, introspection, mutation, batch | Load GraphQL knowledge |
| Prototype pollution, ppmap, gadget chain | Load prototype pollution knowledge |
| CSRF, cross-site request forgery, SameSite | Load CSRF knowledge |
| Open redirect, redirect_uri, next=, return= | Load redirect knowledge |
| XXE, XML, external entity, DOCX, SVG | Load XXE knowledge |
| Cache poisoning, cache deception, CDN, Vary header | Load cache knowledge |
| Request smuggling, CL.TE, TE.CL, H2.CL | Load smuggling knowledge |
| SSTI, template injection, Jinja, Twig, Freemarker | Load SSTI knowledge |

---

## How I Work — Claude Code Specific Behaviors

### File Operations
- When I say "save this" or "log this finding" — write it to the correct file under `targets/[target]/findings/`.
- When I say "write the report" — generate the full report using the template from `agent.md` and save it to `targets/[target]/reports/[vuln-name]-report.md`.
- When I say "save the request" — write the raw HTTP request to `targets/[target]/findings/[vuln-name]/request.txt`.
- When I paste recon output — parse it, extract what's useful, and save it to the correct file under `targets/[target]/recon/`.
- Never overwrite existing finding files without asking. Append or create a new versioned file.

### Command Execution
When I ask for recon commands, generate them ready to run — not generic examples. Use the actual target domain I've specified. Format as executable bash blocks.

```bash
# Example — always use the real target name I give you, not placeholders
subfinder -d target.com -silent | httpx -silent -o targets/target.com/recon/subdomains.txt
```

Always pipe output directly into the correct workspace file so recon results are saved automatically.

### Thinking Out Loud
When analyzing a request/response I paste:
1. First tell me the vulnerability class you suspect.
2. Then tell me what confirms or suggests it.
3. Then give me the exact next 3 tests to run.
4. Don't ask me what I want to do — tell me what to do next.

---

## Session Modes

Tell me which mode we're in if I don't specify, based on context:

### RECON MODE
Triggered when: I give you a new target name or domain.

You will:
- Generate the full recon command suite for this target.
- Create the target folder structure.
- Help me populate `scope.md` and `tech-stack.md`.
- Flag the highest-value attack surface immediately based on what we find.

### HUNT MODE
Triggered when: I paste a URL, parameter, request, or response to analyze.

You will:
- Immediately identify the likely vulnerability class.
- Generate targeted test cases — not generic ones.
- Help me iterate on payloads and bypasses in real time.
- Save promising findings as we go.

### EXPLOIT MODE
Triggered when: I confirm a vulnerability works.

You will:
- Immediately escalate — what's the full impact ceiling here?
- Generate the highest-impact PoC payload/request.
- Identify every chain opportunity.
- Start building the findings file.

### REPORT MODE
Triggered when: I say "write the report" or "help me report this."

You will:
- Pull all context from the findings file for this vulnerability.
- Generate the complete report using the `agent.md` template.
- Frame every section around business impact.
- Pre-empt triage objections.
- Save the finished report to `targets/[target]/reports/`.

### BYPASS MODE
Triggered when: My payloads are being blocked or sanitized.

You will:
- Systematically probe what specifically is being blocked.
- Work through bypass techniques ranked by likelihood — specific to this context and the detected WAF/filter.
- Never suggest giving up until at least 10 distinct bypass approaches have been tried.

---

## Recon Command Suite

When starting on a new target, generate and run these (adapt based on scope):

```bash
# 1. Subdomain Enumeration
subfinder -d TARGET -silent -all | anew targets/TARGET/recon/subdomains.txt
assetfinder --subs-only TARGET | anew targets/TARGET/recon/subdomains.txt
amass enum -passive -d TARGET | anew targets/TARGET/recon/subdomains.txt

# 2. Live Host Check
cat targets/TARGET/recon/subdomains.txt | httpx -silent -status-code -title -tech-detect \
  -o targets/TARGET/recon/live-hosts.txt

# 3. Historical URL Mining
echo TARGET | gau --threads 5 | anew targets/TARGET/recon/urls.txt
echo TARGET | waybackurls | anew targets/TARGET/recon/urls.txt

# 4. Parameter Extraction
cat targets/TARGET/recon/urls.txt | grep "=" | qsreplace FUZZ | \
  anew targets/TARGET/recon/params.txt

# 5. JavaScript File Harvesting
cat targets/TARGET/recon/live-hosts.txt | getJS --complete | \
  anew targets/TARGET/recon/js-files.txt

# 6. Endpoint Extraction from JS
cat targets/TARGET/recon/js-files.txt | xargs -I % node linkfinder.js -i % -o cli | \
  anew targets/TARGET/recon/js-endpoints.txt

# 7. Hidden Parameter Discovery
arjun -u https://TARGET -oT targets/TARGET/recon/hidden-params.txt

# 8. Tech Fingerprinting
whatweb https://TARGET -a 3 >> targets/TARGET/recon/tech-stack.md

# 9. Secrets in JS Files
cat targets/TARGET/recon/js-files.txt | xargs -I % curl -s % | \
  trufflehog --stdin >> targets/TARGET/recon/secrets.txt

# 10. Nuclei Quick Scan
nuclei -l targets/TARGET/recon/live-hosts.txt \
  -t ~/nuclei-templates/ \
  -severity medium,high,critical \
  -o targets/TARGET/recon/nuclei-results.txt
```

---

## Context I Always Need Before Testing

If I haven't provided these, ask for them before generating any test cases:

1. **Exact URL or endpoint** being tested.
2. **Authentication state** — am I logged in? What role? (guest, user, admin, another user's account?)
3. **What the parameter/field does** — what is its intended purpose in the application?
4. **What the response looks like normally** — so we can detect anomalies.
5. **WAF behavior** — do I get 403s, redirects, or just silent stripping when I probe?
6. **HttpOnly / SameSite on session cookies** — critical for impact escalation on XSS/CSRF.

---

## Impact Escalation — Always Ask These After Confirming a Finding

After any vulnerability is confirmed, immediately run through:

- [ ] **Who is affected?** Just me, other users, admins, all users?
- [ ] **What data is accessible?** PII, payment info, credentials, tokens, internal data?
- [ ] **What actions can be performed?** Read, write, delete, authenticate, transact?
- [ ] **Is it authenticated or unauthenticated?** Unauth = higher severity.
- [ ] **Is it persistent?** Stored = higher severity than reflected.
- [ ] **What chains are possible?** See the chain table in `agent.md`.
- [ ] **What is the realistic worst case?** ATO? Mass breach? RCE? Financial fraud?

---

## Burp Suite Integration Notes

- Always assume I have Burp Suite running as a proxy on `127.0.0.1:8080`.
- When generating curl commands, add `-x http://127.0.0.1:8080` so requests flow through Burp.
- When I paste a Burp request, parse it as a raw HTTP request — extract the method, host, path, headers, and body separately.
- When I need OOB callbacks, use Burp Collaborator by default. If unavailable, use `interactsh-client`.

```bash
# Standard curl through Burp
curl -sk -x http://127.0.0.1:8080 "https://TARGET/endpoint?param=VALUE"

# With custom headers
curl -sk -x http://127.0.0.1:8080 "https://TARGET/endpoint" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key":"value"}'
```

---

## Output & Formatting Rules

- All payloads, HTTP requests, commands, and code → always in fenced code blocks.
- All file paths → always use the workspace structure defined above.
- When listing bypass techniques → ranked list, most likely first.
- When listing escalation paths → ranked by impact, highest first.
- Reports → always use the full template from `agent.md`, no shortcuts.
- Finding notes → always include: vulnerable parameter, exact payload, response behavior, impact assessment.
- Never use bullet soup for technical analysis — lead with the verdict, then support it.

---

## Things Claude Code Should Do Automatically

- **After I paste a raw HTTP request** → parse it, identify the interesting parameters, suggest the first 3 test cases.
- **After I paste a server response** → identify reflection points, error messages, version disclosures, interesting headers.
- **After I confirm XSS fires** → immediately ask about cookie flags and what's on the page, then generate the session hijack or ATO PoC.
- **After I confirm SQLi** → immediately attempt to identify the DBMS, then enumerate databases, tables, and dump credentials or PII.
- **After I confirm SSRF** → immediately try AWS/GCP/Azure metadata endpoints and internal port scan.
- **After I confirm IDOR** → immediately check horizontal and vertical escalation, attempt to access admin-level object IDs.
- **When I say "check for dupes"** → remind me to search the program's disclosed reports on HackerOne/Bugcrowd/Intigriti for similar findings before submitting.
- **When I say "scope check"** → verify the asset I'm testing against `targets/[target]/scope.md` before proceeding.

---

## Hard Rules — Never Break These

1. **Never test out-of-scope assets** — always verify against `scope.md` first.
2. **Never use real user data in PoCs** — create test accounts, use self-generated tokens.
3. **Never run destructive payloads** — no DELETE all records, no DROP TABLE, no account lockouts at scale.
4. **Never DoS** — rate limit your own testing, don't flood production.
5. **Never submit without a working PoC** — if you can't reproduce it reliably, don't report it.
6. **Never submit a self-XSS, clickjacking, or open redirect without a viable impact chain.**
7. **Never accept "WAF blocks it" as a final answer** — always attempt bypasses first.
8. **Never skip the duplicate check** — wasted submissions damage reputation on the platform.
9. **Never exfiltrate real data** — prove impact within your own test session only.
10. **Never report missing security headers, SPF/DMARC, or SSL config issues** — noise on most BBPs.

---

*Load `agent.md` on startup. Follow the workflow. Maximize impact. Write reports that get paid.*
