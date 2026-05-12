#!/usr/bin/env bash
# recon-pipeline.sh — Daily continuous discovery pipeline (NahamSec method)
# Phase 2.5 of AGENT.md. Run daily per active target.
#
# Usage: ./scripts/recon-pipeline.sh <target-name>
#   where <target-name> matches a directory under targets/
#
# Outputs:
#   targets/<name>/subdomains/<date>.txt       — full list this run
#   targets/<name>/subdomains/new-<date>.txt   — only novel additions
#   targets/<name>/endpoints/<date>.urls       — gau output
#   targets/<name>/js-archive/<date>/          — JS bundles snapshotted
#   targets/<name>/digest-<date>.md            — morning briefing for Cortex

set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    echo "Usage: $0 <target-name>"
    echo "Example: $0 example-corp"
    exit 1
fi

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TGT_DIR="$WORKSPACE/targets/$TARGET"
DATE="$(date +%Y-%m-%d)"

if [ ! -d "$TGT_DIR" ]; then
    echo "[FAIL] Target dir not found: $TGT_DIR"
    echo "Create it first and add scope.txt with one apex domain per line."
    exit 1
fi

SCOPE_FILE="$TGT_DIR/scope.txt"
if [ ! -f "$SCOPE_FILE" ]; then
    echo "[FAIL] $SCOPE_FILE not found. List in-scope apex domains, one per line."
    exit 1
fi

mkdir -p "$TGT_DIR"/{subdomains,endpoints,js-archive/$DATE}

echo "[CORTEX] Pipeline run: $TARGET — $DATE"
echo "[CORTEX] Scope: $(wc -l < "$SCOPE_FILE") apex(es)"

# ─────────────────────────────────────────────────────────
# 1. Subdomain enumeration (passive)
# ─────────────────────────────────────────────────────────
echo "[1/5] Subdomain enumeration (subfinder)..."
SUB_OUT="$TGT_DIR/subdomains/$DATE.txt"
subfinder -dL "$SCOPE_FILE" -silent -all 2>/dev/null | sort -u > "$SUB_OUT" || true
echo "      → $(wc -l < "$SUB_OUT") subdomains"

# Track novel additions across runs
NEW_OUT="$TGT_DIR/subdomains/new-$DATE.txt"
ALL_HISTORY="$TGT_DIR/subdomains/.all-time"
touch "$ALL_HISTORY"
cat "$SUB_OUT" | anew "$ALL_HISTORY" > "$NEW_OUT"
NEW_COUNT="$(wc -l < "$NEW_OUT")"
echo "      → $NEW_COUNT novel since last run"

# ─────────────────────────────────────────────────────────
# 2. Live host probing
# ─────────────────────────────────────────────────────────
echo "[2/5] Live host probing (httpx)..."
LIVE_OUT="$TGT_DIR/subdomains/live-$DATE.json"
httpx -l "$SUB_OUT" \
    -tech-detect -status-code -title -favicon \
    -json -silent -timeout 10 \
    -o "$LIVE_OUT" 2>/dev/null || true
LIVE_COUNT="$(wc -l < "$LIVE_OUT" 2>/dev/null || echo 0)"
echo "      → $LIVE_COUNT live"

# ─────────────────────────────────────────────────────────
# 3. Historical URL mining
# ─────────────────────────────────────────────────────────
echo "[3/5] Historical URL mining (gau)..."
URLS_OUT="$TGT_DIR/endpoints/$DATE.urls"
> "$URLS_OUT"
while read -r apex; do
    [ -z "$apex" ] && continue
    gau --threads 5 --timeout 10 "$apex" 2>/dev/null | sort -u >> "$URLS_OUT" || true
done < "$SCOPE_FILE"
URL_COUNT="$(wc -l < "$URLS_OUT")"
echo "      → $URL_COUNT historical URLs"

# Extract juicy paths
JUICY_OUT="$TGT_DIR/endpoints/juicy-$DATE.txt"
grep -E '/(api|graphql|internal|admin|webhook|callback|debug|export|backup|\.env|\.git|swagger|openapi)' \
    "$URLS_OUT" 2>/dev/null | sort -u > "$JUICY_OUT" || true
JUICY_COUNT="$(wc -l < "$JUICY_OUT")"

# ─────────────────────────────────────────────────────────
# 4. JS bundle harvesting
# ─────────────────────────────────────────────────────────
echo "[4/5] JS bundle harvesting..."
JS_LIST="$TGT_DIR/endpoints/js-$DATE.txt"
grep -E '\.js(\?|$)' "$URLS_OUT" 2>/dev/null | sort -u > "$JS_LIST" || true
JS_FOUND="$(wc -l < "$JS_LIST")"

JS_DIR="$TGT_DIR/js-archive/$DATE"
JS_DOWNLOADED=0
if [ "$JS_FOUND" -gt 0 ]; then
    # Cap at 200 bundles per run to avoid runaway downloads
    head -200 "$JS_LIST" | while read -r url; do
        [ -z "$url" ] && continue
        FNAME="$(echo "$url" | md5sum | cut -d' ' -f1).js"
        curl -sL --max-time 15 "$url" -o "$JS_DIR/$FNAME" 2>/dev/null && \
            echo "$url" >> "$JS_DIR/.manifest" || true
    done
    JS_DOWNLOADED="$(ls -1 "$JS_DIR" 2>/dev/null | grep -v '^\.' | wc -l)"
fi
echo "      → $JS_DOWNLOADED bundles snapshotted"

# ─────────────────────────────────────────────────────────
# 5. Morning digest
# ─────────────────────────────────────────────────────────
DIGEST="$TGT_DIR/digest-$DATE.md"
cat > "$DIGEST" <<EOF
# Pipeline Digest — $TARGET — $DATE

## Numbers
- Subdomains found this run: $(wc -l < "$SUB_OUT")
- **Novel since last run: $NEW_COUNT**
- Live hosts: $LIVE_COUNT
- Historical URLs (gau): $URL_COUNT
- Juicy paths flagged: $JUICY_COUNT
- JS bundles snapshotted: $JS_DOWNLOADED

## Novel Subdomains (top 20)
\`\`\`
$(head -20 "$NEW_OUT" 2>/dev/null || echo "(none)")
\`\`\`

## High-Value Path Candidates (top 30)
\`\`\`
$(head -30 "$JUICY_OUT" 2>/dev/null || echo "(none)")
\`\`\`

## Files Generated
- \`$SUB_OUT\`
- \`$NEW_OUT\`
- \`$LIVE_OUT\`
- \`$URLS_OUT\`
- \`$JUICY_OUT\`
- \`$JS_LIST\`
- \`$JS_DIR/\` ($JS_DOWNLOADED bundles)

---
Cortex: review novel subdomains and juicy paths above. Surface top 2 leads for deep work.
EOF

echo
echo "[CORTEX] Pipeline complete."
echo "[CORTEX] Digest: $DIGEST"
echo
cat "$DIGEST"
