#!/usr/bin/env bash
# js-mine.sh — Phase 4 kickoff. Static pattern extraction across collected JS.
# AST deep parse (Pass 2) is invoked separately by Cortex on demand.
#
# Usage: ./scripts/js-mine.sh <target-name> [<date>]
#   <date> defaults to today

set -euo pipefail

TARGET="${1:-}"
DATE="${2:-$(date +%Y-%m-%d)}"

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <target-name> [<date>]"
    exit 1
fi

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JS_DIR="$WORKSPACE/targets/$TARGET/js-archive/$DATE"
OUT_DIR="$WORKSPACE/targets/$TARGET/findings/js-mining-$DATE"

if [ ! -d "$JS_DIR" ]; then
    echo "[FAIL] No JS archive at $JS_DIR"
    echo "Run recon-pipeline.sh first."
    exit 1
fi

mkdir -p "$OUT_DIR"

echo "[CORTEX] JS mining: $TARGET — $DATE"
echo "[CORTEX] Source: $JS_DIR"
echo "[CORTEX] Output: $OUT_DIR"

# ─────────────────────────────────────────────────────────
# Pass 1 — Static pattern extraction
# ─────────────────────────────────────────────────────────
echo "[1/3] Static pattern extraction..."

PATHS_OUT="$OUT_DIR/paths.txt"
SECRETS_OUT="$OUT_DIR/secrets.txt"
FLAGS_OUT="$OUT_DIR/feature-flags.txt"
DEBUG_OUT="$OUT_DIR/debug-backdoors.txt"

> "$PATHS_OUT"; > "$SECRETS_OUT"; > "$FLAGS_OUT"; > "$DEBUG_OUT"

# API path patterns
grep -hroE '"/(api|graphql|v[0-9]+|internal|admin|webhook|callback)/[a-zA-Z0-9_/-]*"' "$JS_DIR" 2>/dev/null | \
    sort -u > "$PATHS_OUT" || true
echo "      → $(wc -l < "$PATHS_OUT") path patterns"

# Hardcoded secrets/tokens (high-value patterns)
grep -hrEo '(Bearer [a-zA-Z0-9_\-\.]{20,}|sk-[a-zA-Z0-9]{20,}|sk_live_[a-zA-Z0-9]{20,}|api[_-]?key["'\'']?\s*[:=]\s*["'\''][a-zA-Z0-9_\-]{16,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_\-]{35}|xox[bp]-[0-9a-zA-Z\-]+|ghp_[a-zA-Z0-9]{36})' \
    "$JS_DIR" 2>/dev/null | sort -u > "$SECRETS_OUT" || true
echo "      → $(wc -l < "$SECRETS_OUT") potential secrets"

# Feature flags
grep -hrEo '(featureFlags|enabledFeatures|FEATURES|isEnabled\([^)]*\)|LD\.[a-zA-Z]+\([^)]*\))' \
    "$JS_DIR" 2>/dev/null | sort -u > "$FLAGS_OUT" || true
echo "      → $(wc -l < "$FLAGS_OUT") feature flag refs"

# Debug/test backdoors
grep -hrEo '(debug\s*[:=]\s*true|bypassAuth|testMode|__DEV__|adminMode|X-Debug|_debug=)' \
    "$JS_DIR" 2>/dev/null | sort -u > "$DEBUG_OUT" || true
echo "      → $(wc -l < "$DEBUG_OUT") debug/backdoor refs"

# ─────────────────────────────────────────────────────────
# Pass 1.5 — Cross-file correlation (admin vs user bundles)
# ─────────────────────────────────────────────────────────
echo "[2/3] Cross-file correlation..."

ADMIN_BUNDLES="$OUT_DIR/admin-bundles.txt"
USER_BUNDLES="$OUT_DIR/user-bundles.txt"

# Bundles whose content references "admin" routes heavily
> "$ADMIN_BUNDLES"
for f in "$JS_DIR"/*.js; do
    [ -f "$f" ] || continue
    if [ "$(grep -cE '/admin/|isAdmin|adminOnly|requiresAdmin' "$f" 2>/dev/null || echo 0)" -gt 3 ]; then
        echo "$(basename "$f")" >> "$ADMIN_BUNDLES"
    fi
done
echo "      → $(wc -l < "$ADMIN_BUNDLES") bundles flagged as admin-flavored"

# Endpoints unique to admin bundles
ADMIN_ENDPOINTS="$OUT_DIR/admin-only-endpoints.txt"
> "$ADMIN_ENDPOINTS"
if [ -s "$ADMIN_BUNDLES" ]; then
    while read -r bundle; do
        grep -hoE '"/(api|v[0-9]+)/[a-zA-Z0-9_/-]*"' "$JS_DIR/$bundle" 2>/dev/null
    done < "$ADMIN_BUNDLES" | sort -u > "$ADMIN_ENDPOINTS"
    echo "      → $(wc -l < "$ADMIN_ENDPOINTS") admin-bundle endpoints"
fi

# ─────────────────────────────────────────────────────────
# Pass 1.9 — Summary digest
# ─────────────────────────────────────────────────────────
echo "[3/3] Generating digest..."

DIGEST="$OUT_DIR/SUMMARY.md"
cat > "$DIGEST" <<EOF
# JS Mining Summary — $TARGET — $DATE

## Sources
- Bundles analyzed: $(ls -1 "$JS_DIR"/*.js 2>/dev/null | wc -l)
- Total size: $(du -sh "$JS_DIR" 2>/dev/null | cut -f1)

## Pass 1 — Static Pattern Extraction
| Category | Count | File |
|---|---|---|
| API/route paths | $(wc -l < "$PATHS_OUT") | \`paths.txt\` |
| Potential secrets | $(wc -l < "$SECRETS_OUT") | \`secrets.txt\` |
| Feature flag references | $(wc -l < "$FLAGS_OUT") | \`feature-flags.txt\` |
| Debug/backdoor strings | $(wc -l < "$DEBUG_OUT") | \`debug-backdoors.txt\` |

## Pass 1.5 — Cross-File Correlation
- Admin-flavored bundles: $(wc -l < "$ADMIN_BUNDLES")
- Admin-only endpoint candidates: $(wc -l < "$ADMIN_ENDPOINTS")

## High-Priority Items for Cortex Pass 3
EOF

if [ -s "$SECRETS_OUT" ]; then
    cat >> "$DIGEST" <<EOF

### ⚠️ Secrets/Tokens Found
\`\`\`
$(head -20 "$SECRETS_OUT")
\`\`\`
*Cortex: validate each — many are public test keys; some are live.*
EOF
fi

if [ -s "$DEBUG_OUT" ]; then
    cat >> "$DIGEST" <<EOF

### 🚪 Debug/Backdoor References
\`\`\`
$(head -10 "$DEBUG_OUT")
\`\`\`
*Cortex: test each as a header/cookie/parameter against discovered endpoints.*
EOF
fi

if [ -s "$ADMIN_ENDPOINTS" ]; then
    cat >> "$DIGEST" <<EOF

### 🔐 Admin-Only Endpoint Candidates
\`\`\`
$(head -15 "$ADMIN_ENDPOINTS")
\`\`\`
*Cortex: prime BAC targets — test from a non-admin session.*
EOF
fi

cat >> "$DIGEST" <<EOF

---

## Next Steps for Cortex (Pass 2 — AST Deep Parse)

To run AST deep parse on a specific bundle, use:
\`\`\`bash
node -e "
const fs = require('fs');
const acorn = require('acorn');
const walk = require('acorn-walk');
const code = fs.readFileSync('PATH_TO_BUNDLE', 'utf8');
const ast = acorn.parse(code, {ecmaVersion: 'latest', sourceType: 'module'});
// Walk for fetch/axios/route definitions...
"
\`\`\`

Or ask Cortex directly: *"Run AST deep parse on the top 3 admin-flavored bundles."*
EOF

echo
echo "[CORTEX] JS mining complete."
echo "[CORTEX] Summary: $DIGEST"
echo
cat "$DIGEST"
