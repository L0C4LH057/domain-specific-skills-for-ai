# Cortex Hunter Workspace

> Bug bounty hunting workspace for Claude Code on Kali Linux.
> Implements the **Cortex Recon Co-Pilot — Elite Hunter Edition**.

---

## What This Is

A complete, drop-in workspace that turns Claude Code into Cortex — a precision offensive-security co-pilot built around NahamSec's continuous recon philosophy, deep JavaScript AST intelligence mining, and Z-Wink's manual Broken Access Control mastery. Cortex amplifies a human bug bounty hunter; it does not replace one.

Two modes, hard-gated:

- **Analyst** (default, read-only) — surface mapping, JS mining, hypothesis generation
- **Operator** (per-test, human-confirmed) — surgical attack execution via `EXECUTE` + `CONFIRM`

Every finding gets run through the Impact Escalation Engine before it's presented. Reputation-economic filtering is on by default.

---

## Quick Start

```bash
# 1. Drop this folder somewhere stable
cp -r cortex-hunter ~/hunting/

# 2. Make scripts executable (first run only)
cd ~/hunting/cortex-hunter
chmod +x scripts/*.sh scripts/*.py

# 3. Install the toolkit
./scripts/setup-kali.sh

# 4. Reload shell so Go binaries are on PATH
source ~/.zshrc   # or ~/.bashrc

# 5. Per-engagement: fill TARGET_CONTEXT.md
nano TARGET_CONTEXT.md

# 6. Create target directory
mkdir -p targets/example-corp
echo "example.com" > targets/example-corp/scope.txt

# 7. Daily recon
./scripts/recon-pipeline.sh example-corp

# 8. Start hunting
claude
```

Full operating guide: **`USAGE.md`**.

---

## File Map

| File | Purpose |
|---|---|
| `AGENT.md` | The operating contract. Cortex's identity, modes, methodology. |
| `CLAUDE.md` | Project memory file. Claude Code reads this automatically. |
| `TARGET_CONTEXT.md` | Per-engagement scope/program briefing. Fill before work. |
| `USAGE.md` | Hunter's operating guide. Read this first. |
| `scripts/setup-kali.sh` | Idempotent toolkit installer. |
| `scripts/recon-pipeline.sh` | Daily continuous discovery (NahamSec method). |
| `scripts/js-mine.sh` | JS bundle static pattern extraction. |
| `scripts/param-diff.py` | Phase 5 — 3-request parameter differential analyzer. |
| `targets/<name>/` | Per-target working directories. |
| `wordlists/` | Custom contextual wordlists. |

---

## The Mantra

> *Recon is everything, but exploitation needs a human spark.*
> *Impact is everything, or you're not getting paid.*

---

## License & Use

For authorized bug bounty research only. Only operate against targets where you have explicit written authorization — bug bounty program scope, private engagement contract, or your own infrastructure. The hard boundaries in `AGENT.md` exist for a reason. Respect them.
