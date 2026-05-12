#!/usr/bin/env bash
# setup-kali.sh — Cortex Hunter toolkit installer for Kali Linux
# Idempotent: safe to re-run. Installs everything Cortex expects.
# Tested on Kali 2024.x rolling.

set -euo pipefail

CORTEX_VERSION="5.1-final"
WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ─────────────────────────────────────────────────────────
# Color output
# ─────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${BLUE}[CORTEX]${NC} $*"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[FAIL]${NC} $*" >&2; }

# ─────────────────────────────────────────────────────────
# Pre-flight
# ─────────────────────────────────────────────────────────
log "Cortex Hunter toolkit setup — version ${CORTEX_VERSION}"
log "Workspace: ${WORKSPACE}"

if ! grep -qi kali /etc/os-release 2>/dev/null; then
    warn "Not detected as Kali. Continuing anyway — most steps are distro-agnostic."
fi

# ─────────────────────────────────────────────────────────
# 1. APT packages (Kali repos cover most of these)
# ─────────────────────────────────────────────────────────
log "Step 1/6 — APT packages"

APT_PKGS=(
    curl wget jq git
    python3 python3-pip python3-venv
    nodejs npm
    golang-go
    chromium                # for headless DOM inspection
    sqlmap
    seclists                # /usr/share/seclists/
)

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq
    for pkg in "${APT_PKGS[@]}"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            ok "$pkg already installed"
        else
            log "Installing $pkg..."
            sudo apt-get install -y -qq "$pkg" || warn "$pkg failed — non-fatal, continuing"
        fi
    done
else
    warn "apt-get not found — skipping system packages. Install manually: ${APT_PKGS[*]}"
fi

# ─────────────────────────────────────────────────────────
# 2. Go-based recon tools (ProjectDiscovery + community)
# ─────────────────────────────────────────────────────────
log "Step 2/6 — Go-based recon tools"

if ! command -v go >/dev/null 2>&1; then
    err "go not available — cannot install Go-based tools. Aborting."
    exit 1
fi

# Ensure GOPATH/bin is in PATH for this shell and persistently
GOBIN="$(go env GOPATH)/bin"
mkdir -p "$GOBIN"

if ! grep -q "$GOBIN" <<<"$PATH"; then
    export PATH="$PATH:$GOBIN"
fi

PROFILE_FILE="$HOME/.zshrc"
[ -f "$PROFILE_FILE" ] || PROFILE_FILE="$HOME/.bashrc"

if ! grep -q 'go env GOPATH' "$PROFILE_FILE" 2>/dev/null; then
    echo '' >> "$PROFILE_FILE"
    echo '# Cortex toolkit — Go binaries' >> "$PROFILE_FILE"
    echo 'export PATH="$PATH:$(go env GOPATH)/bin"' >> "$PROFILE_FILE"
    ok "Added GOPATH/bin to $PROFILE_FILE"
fi

declare -A GO_TOOLS=(
    [subfinder]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    [dnsx]="github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    [httpx]="github.com/projectdiscovery/httpx/cmd/httpx@latest"
    [nuclei]="github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    [katana]="github.com/projectdiscovery/katana/cmd/katana@latest"
    [ffuf]="github.com/ffuf/ffuf/v2@latest"
    [gau]="github.com/lc/gau/v2/cmd/gau@latest"
    [waybackurls]="github.com/tomnomnom/waybackurls@latest"
    [anew]="github.com/tomnomnom/anew@latest"
    [unfurl]="github.com/tomnomnom/unfurl@latest"
    [gf]="github.com/tomnomnom/gf@latest"
    [qsreplace]="github.com/tomnomnom/qsreplace@latest"
)

for tool in "${!GO_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        ok "$tool already installed ($(command -v "$tool"))"
    else
        log "Installing $tool..."
        if go install "${GO_TOOLS[$tool]}" 2>&1 | tail -3; then
            ok "$tool installed"
        else
            warn "$tool install failed — check go env"
        fi
    fi
done

# ─────────────────────────────────────────────────────────
# 3. Nuclei templates
# ─────────────────────────────────────────────────────────
log "Step 3/6 — Nuclei templates"
if command -v nuclei >/dev/null 2>&1; then
    nuclei -update-templates -silent 2>/dev/null || warn "Template update failed (offline?)"
    ok "Nuclei templates current"
fi

# ─────────────────────────────────────────────────────────
# 4. Python tooling
# ─────────────────────────────────────────────────────────
log "Step 4/6 — Python tooling"

PYTHON_PKGS=(requests beautifulsoup4 lxml jsbeautifier)

# Use venv to avoid clobbering Kali's system python
VENV_DIR="$WORKSPACE/.venv"
if [ ! -d "$VENV_DIR" ]; then
    log "Creating Python venv at $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
pip install -q --upgrade pip
for pkg in "${PYTHON_PKGS[@]}"; do
    pip install -q "$pkg" && ok "$pkg installed in venv"
done
deactivate

# ─────────────────────────────────────────────────────────
# 5. Node tooling for AST mining
# ─────────────────────────────────────────────────────────
log "Step 5/6 — Node tooling for JS AST mining"

cd "$WORKSPACE"
if [ ! -f package.json ]; then
    log "Initializing Node package.json..."
    npm init -y >/dev/null 2>&1
fi

NODE_PKGS=(acorn acorn-walk @babel/parser @babel/traverse)
for pkg in "${NODE_PKGS[@]}"; do
    if [ -d "node_modules/$pkg" ] || [ -d "node_modules/${pkg/@*\//}" ]; then
        ok "$pkg already installed"
    else
        log "Installing $pkg..."
        npm install --silent "$pkg" >/dev/null 2>&1 && ok "$pkg installed"
    fi
done

# ─────────────────────────────────────────────────────────
# 6. Workspace directories
# ─────────────────────────────────────────────────────────
log "Step 6/6 — Workspace structure"

mkdir -p "$WORKSPACE"/{targets,wordlists,scripts}
ok "Directory structure created under $WORKSPACE"

# Generate baseline custom wordlist seed for ffuf (Cortex caps these at ~100)
WORDLIST="$WORKSPACE/wordlists/cortex-baseline.txt"
if [ ! -f "$WORDLIST" ]; then
    cat > "$WORDLIST" <<'EOF'
admin
admin-api
internal
internal-api
debug
test
testing
staging
dev
beta
v0
v2
v3
old
legacy
backup
config
.env
.git
swagger
openapi
graphql
internal/admin
admin/users
admin/export
admin/dump
export
dump
bulk
all
search
audit
history
stats
internal_user
service_account
__debug__
.well-known
EOF
    ok "Baseline wordlist created at $WORDLIST"
fi

# ─────────────────────────────────────────────────────────
# Final report
# ─────────────────────────────────────────────────────────
echo
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "Setup complete. Verifying installation:"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

VERIFY_TOOLS=(subfinder dnsx httpx nuclei katana ffuf gau waybackurls anew unfurl gf qsreplace curl jq python3 node)
for tool in "${VERIFY_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        ok "$tool: $(command -v "$tool")"
    else
        err "$tool: NOT FOUND"
    fi
done

echo
log "Reload your shell or run:  source $PROFILE_FILE"
log "Then: claude  (in this directory) to start Cortex"
log "Read USAGE.md for the operating guide."
echo
