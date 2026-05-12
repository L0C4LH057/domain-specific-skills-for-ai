# USAGE — Operating Cortex with Claude Code on Kali

This guide walks you from zero to first hunt with Cortex running in Claude Code on a Kali Linux box.

---

## Part 1 — One-Time Setup

### 1.1 Install Claude Code

If you haven't already:

```bash
# Node 18+ is required
curl -fsSL https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.xz | sudo tar -xJf - -C /opt
sudo ln -sf /opt/node-v20.11.0-linux-x64/bin/{node,npm,npx} /usr/local/bin/

# Install Claude Code globally
npm install -g @anthropic-ai/claude-code

# Verify
claude --version
```

Authenticate on first run:
```bash
claude
# Follow the OAuth prompt — opens a browser to log into your Anthropic account
```

### 1.2 Drop the Cortex Workspace Into Place

Copy the entire `cortex-hunter/` folder somewhere stable on your Kali box. A common layout:

```bash
mkdir -p ~/hunting
cp -r /path/to/cortex-hunter ~/hunting/
cd ~/hunting/cortex-hunter
```

### 1.3 Run the Toolkit Installer

```bash
chmod +x scripts/*.sh
./scripts/setup-kali.sh
```

The script is idempotent — re-running is safe. It installs:

- ProjectDiscovery suite (`subfinder`, `dnsx`, `httpx`, `nuclei`, `katana`)
- Tomnomnom toolkit (`anew`, `unfurl`, `gf`, `qsreplace`, `waybackurls`)
- `ffuf`, `gau`
- Python venv with `requests`, `jsbeautifier` for the diff script
- Node packages for AST mining (`acorn`, `acorn-walk`, `@babel/parser`)
- Nuclei templates

After it finishes, reload your shell so Go binaries are on `$PATH`:
```bash
source ~/.zshrc   # or ~/.bashrc
```

Verify:
```bash
which subfinder httpx nuclei ffuf gau anew
```

All six should resolve. If any don't, check `~/.go/bin` is in your `$PATH`.

### 1.4 Verify Cortex Wakes Up

From the workspace directory:
```bash
cd ~/hunting/cortex-hunter
claude
```

You should land in an interactive Claude Code session. Cortex reads `CLAUDE.md` automatically, which points it at `AGENT.md`. Confirm by typing:

```
Are you operating as Cortex?
```

You should get a response confirming Analyst mode and asking you to fill `TARGET_CONTEXT.md` if it isn't filled.

---

## Part 2 — Per-Engagement Setup

Every new bug bounty target follows this rhythm.

### 2.1 Fill the Target Context

```bash
# In a separate terminal or editor
nano TARGET_CONTEXT.md
```

Fill **every** field. Cortex refuses to run active tests if the context is empty or stale. The fields aren't optional:

- **Out-of-Scope** — the most important field. If you skip it, you risk testing something that gets you banned from the program.
- **Test Accounts** — Cortex needs to know which sessions are yours. It will not test against accounts not listed here.
- **Special Rules** — programs vary. Some forbid automated scanning, some forbid certain test classes. Tell Cortex.

### 2.2 Create the Target Directory

```bash
TARGET=example-corp
mkdir -p targets/$TARGET
echo "example.com" > targets/$TARGET/scope.txt
echo "api.example.com" >> targets/$TARGET/scope.txt
# One apex domain per line — these are what subfinder enumerates from
```

### 2.3 First Pipeline Run

```bash
./scripts/recon-pipeline.sh $TARGET
```

This generates:
- `targets/$TARGET/subdomains/<date>.txt` — all subdomains
- `targets/$TARGET/subdomains/new-<date>.txt` — novel since last run (empty on first run, populated thereafter)
- `targets/$TARGET/endpoints/<date>.urls` — gau historical URLs
- `targets/$TARGET/endpoints/juicy-<date>.txt` — high-value path candidates
- `targets/$TARGET/js-archive/<date>/` — snapshotted JS bundles
- `targets/$TARGET/digest-<date>.md` — the morning digest

The digest is the artifact Cortex reads when you ask for direction.

---

## Part 3 — Daily Working Rhythm

### Morning (10–15 min)

```bash
cd ~/hunting/cortex-hunter
./scripts/recon-pipeline.sh <target>
```

Read the digest. Then:

```bash
claude
```

Inside Claude Code:
> *Read the latest digest for `<target>`. What are the top 2 leads?*

Cortex will analyze `targets/<target>/digest-<date>.md` and return ranked leads with reasoning.

### Deep Work (where the bounties get found)

Pick one lead. Tell Cortex:
> *Let's go deep on `admin-api.example.com`. Run Phase 1 ASG, then plan vertical recon.*

Cortex executes Phase 1 (read-only — `httpx` probing, header analysis, tech detection) and outputs the node table. It then proposes the next move with a ready-to-issue `EXECUTE` command.

### When You Find Something Worth Testing

Cortex never modifies state without authorization. When it suggests an active test, it ends with something like:

> *Would you like me to attempt this test? If so, issue:*
> *`EXECUTE: GET /api/v2/admin/users using user-A session`*

Issue the EXECUTE verbatim. Cortex returns a Plan Summary:

```
PLAN SUMMARY — Admin endpoint access from user session
REQUEST
  Method:  GET
  URL:     https://api.example.com/api/v2/admin/users
  Headers: Cookie: session=•••••• (user-A)
  Body:    N/A
NORMAL BEHAVIOR
  403 Forbidden — admin endpoint, user-A is not admin
ATTACKER'S GOAL
  200 with full user list — proves vertical privilege escalation
RISK LEVEL
  Critical — full user enumeration
TRIAGE PREDICTION
  High to Critical depending on data sensitivity
SCOPE CONFIRMATION
  api.example.com is in scope per TARGET_CONTEXT.md
SIDE EFFECTS
  None (read-only GET)
Waiting for CONFIRM to proceed.
```

Reply `CONFIRM`. Cortex executes the request, returns the raw response, runs it through the Impact Escalation Engine, and reverts to Analyst mode.

### Writing Up Findings

When a finding is confirmed:

> *Write up the IDOR finding using the §17 template.*

Cortex generates the report draft. **Read it. Edit it. Don't submit AI-written reports verbatim** — triagers read hundreds a week and pattern-match LLM artifacts instantly. Cortex's draft is your starting point, not your final submission.

The Forbidden list in `AGENT.md` §17 captures what to strip:
- "This issue poses a significant risk..."
- "Implement proper authorization."
- CVSS guesses without a vector
- Multi-paragraph narratives without concrete data

---

## Part 4 — Common Workflows

### Workflow A — Cold Start on a New Target

```
1. Fill TARGET_CONTEXT.md
2. mkdir targets/<name> && echo "<apex>" > targets/<name>/scope.txt
3. ./scripts/recon-pipeline.sh <name>
4. claude
   > Review the digest. Top 2 leads?
5. Pick a lead → Cortex runs Phase 1 ASG
6. Iterate: Phase 2 (horizontal) → Phase 3 (vertical) → Phase 4 (JS mining)
7. EXECUTE specific tests → CONFIRM → analyze → write up
```

### Workflow B — Deep JS Mining on a Target You've Mapped

```
1. ./scripts/js-mine.sh <name>            # static pattern extraction
2. claude
   > Run AST deep parse on the top 3 admin-flavored bundles
3. Cortex extracts endpoints, auth gates, feature flags
4. Cortex proposes the highest-value untested endpoint as an EXECUTE
5. Confirm → execute → analyze
```

### Workflow C — Parameter Hunting on a Specific Endpoint

```
1. claude
   > I want to find hidden parameters on /api/v1/user/profile.
   > Build me a contextual wordlist from what we've mined.
2. Cortex outputs ~50 candidate parameters with reasoning
3. Run param-diff.py manually for each high-value candidate:
   ./scripts/param-diff.py \
     --url "https://api.example.com/api/v1/user/profile" \
     --param debug \
     --value true \
     --header "Cookie: session=$SESSION"
4. Feed the diff results back to Cortex for analysis
```

### Workflow D — BAC Hunt (The Z-Wink Cadence)

```
1. claude
   > Pick one endpoint and walk me through the full Z-Wink BAC battery.
2. Cortex builds the permission matrix for the chosen endpoint
3. For each technique (object-type swap, nested ownership, array
   bombing, UUID prediction, parameter injection, cross-tenant), Cortex
   proposes the test as a ready-to-issue EXECUTE
4. You confirm each one individually
5. Cortex documents every response variation — even failures, which
   reveal validation logic
6. Move to the next endpoint only when this one is exhausted
```

### Workflow E — Daily Continuous Recon

Drop this in cron for your active targets:

```bash
crontab -e
```

```cron
# Cortex daily pipeline — 7 AM local time
0 7 * * * cd ~/hunting/cortex-hunter && ./scripts/recon-pipeline.sh example-corp >> targets/example-corp/cron.log 2>&1
0 7 * * * cd ~/hunting/cortex-hunter && ./scripts/recon-pipeline.sh other-target >> targets/other-target/cron.log 2>&1
```

Each morning, the digests are ready. You just open Claude Code and ask Cortex which leads matter.

---

## Part 5 — Operational Rules

### Things That Happen Without Asking

- All `httpx` probing, JS bundle download, `gau` URL mining, `subfinder` enumeration. These are passive/read-only.
- Parsing your collected JS, generating reports, building wordlists.
- Suggesting next moves and ranked leads.

### Things That Require `EXECUTE: ... CONFIRM`

- Any HTTP request that isn't passive observation.
- Anything that touches an endpoint with parameters you're testing.
- Anything that uses your authenticated session.
- Anything Cortex labels `⚠️ DANGEROUS`.

### Things Cortex Will Refuse Even With EXECUTE

- Targets not listed as in-scope in `TARGET_CONTEXT.md`.
- Brute-force or credential stuffing.
- Interaction with real user accounts (anything not on your Test Accounts list).
- Mass data exfiltration even from in-scope endpoints.
- Chained autonomous exploitation.

### How To Override (When You Genuinely Need To)

If Cortex refuses something you have legitimate authority for — say a private engagement with broader rules:

1. Update `TARGET_CONTEXT.md` to reflect the actual permitted scope and rules.
2. Tell Cortex: *"`TARGET_CONTEXT.md` has been updated. Re-read it."*
3. Re-issue the `EXECUTE`.

This forces the override to be documented, not hand-waved.

---

## Part 6 — Reading Cortex's Output

Cortex separates **Observations** (verifiable facts) from **Hypotheses** (interpretations requiring tests). Pay attention to which is which:

> **Observation:** `/api/v1/user/124` returned 200 OK with `{"email":"victim@example.com","role":"admin"}` while authenticated as user 123.
>
> **Hypothesis:** Backend does not verify ownership of the requested user_id — likely IDOR.
>
> **Recommended next step:** `EXECUTE: GET /api/v1/user/125 using user-123 session — confirm consistent unauthorized access across IDs.`

You can trust Observations. You should test Hypotheses. The "Recommended next step" is always a ready-to-issue EXECUTE.

---

## Part 7 — Troubleshooting

| Symptom | Fix |
|---|---|
| Cortex won't suggest tests | `TARGET_CONTEXT.md` is empty or stale. Fill it. |
| Tools not found after setup | `source ~/.zshrc` or `source ~/.bashrc` to reload `$PATH` |
| Pipeline returns 0 subdomains | Check `targets/<name>/scope.txt` exists and contains apex domains, one per line |
| `nuclei` permission errors | First run downloads templates: `nuclei -update-templates` |
| Cortex sounds generic / not in character | Ensure you launched `claude` from inside `cortex-hunter/` so `CLAUDE.md` is picked up |
| Findings sound AI-generated | Edit them manually before submitting. Cortex drafts; you ship. |
| `param-diff.py` ImportError | Activate the venv: `source .venv/bin/activate` |

---

## Part 8 — The Reputation Reality Check

Before submitting any finding, run through this mentally:

1. **Is the impact demonstrated, not hypothetical?** If you wrote "could potentially," you haven't proven it yet.
2. **Is this likely a duplicate?** Open redirects on `next=` parameters get reported daily. So do missing security headers. So do `clickjacking on /admin` reports. If your finding looks like one of these, find the differentiating angle (chain to OAuth token theft, etc.) before submitting.
3. **Is the severity defensible in one sentence using only demonstrated evidence?** If you can't write that sentence, the severity is wrong.
4. **Would a triager close this in under three minutes as Valid?** If the report is bloated, theoretical, or vague — tighten it.

Cortex helps you answer these. It will tell you when something isn't worth submitting. **Listen to it** — a rejected report damages your reputation more than the inconvenience of not filing.

---

## Part 9 — Quick Command Reference

```bash
# Daily pipeline
./scripts/recon-pipeline.sh <target>

# JS static mining (after pipeline)
./scripts/js-mine.sh <target>

# Parameter diff test
./scripts/param-diff.py --url <url> --param <name> --value <val> --header "Cookie: ..."

# Start Cortex
cd ~/hunting/cortex-hunter && claude

# Verify toolkit
which subfinder httpx nuclei ffuf gau anew katana

# Update nuclei templates
nuclei -update-templates
```

---

## Part 10 — The Mantra

From `AGENT.md`:

> *"Recon is everything, but exploitation needs a human spark.*
> *Impact is everything, or you're not getting paid."*

Cortex compresses weeks of recon into hours. It makes the next move obvious. It catches what you'd miss. But the human spark — the intuition, the chain insight, the decision to push or fold — that's still you.

Hunt well.
