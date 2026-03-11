# Shell Scripting Reference — Bash Automation

## Script Template (always start here)
```bash
#!/usr/bin/env bash
set -euo pipefail   # -e exit on error, -u no unset vars, -o pipefail pipe errors
IFS=$'\n\t'         # safer word splitting
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Usage
usage() {
  cat <<-EOF
    Usage: $(basename "$0") [OPTIONS] <arg>
    Options:
      -e, --env      Environment (dev|staging|prod)
      -h, --help     Show this help
  EOF
  exit 1
}

# Logging
log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]  $*" >&2; }
err()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2; exit 1; }

# Arg parsing
ENV=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -e|--env) ENV="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) err "Unknown argument: $1" ;;
  esac
done

[[ -z "$ENV" ]] && err "--env is required"

main() {
  log "Starting deployment to $ENV"
  # ... logic here
  log "Done"
}

main "$@"
```

## Common Patterns

### Check Prerequisites
```bash
check_deps() {
  local deps=("kubectl" "helm" "aws" "jq")
  for dep in "${deps[@]}"; do
    command -v "$dep" &>/dev/null || err "Required tool not found: $dep"
  done
}
```

### Retry with Backoff
```bash
retry() {
  local retries=5 delay=2 cmd="$@"
  for ((i=1; i<=retries; i++)); do
    "$@" && return 0
    warn "Attempt $i/$retries failed. Retrying in ${delay}s..."
    sleep "$delay"
    delay=$((delay * 2))
  done
  err "All $retries attempts failed: $cmd"
}

retry kubectl rollout status deployment/myapp -n production
```

### Cleanup on Exit
```bash
TMPDIR=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR"; log "Cleaned up $TMPDIR"; }
trap cleanup EXIT INT TERM
```

### Confirm Before Destructive Action
```bash
confirm() {
  local prompt="${1:-Are you sure?}"
  read -r -p "$prompt [y/N] " response
  [[ "$response" =~ ^[Yy]$ ]] || { log "Aborted"; exit 0; }
}

confirm "This will delete the $ENV database. Continue?"
```

### Parse JSON (jq)
```bash
# Extract value
IMAGE_TAG=$(aws ecr describe-images \
  --repository-name myapp \
  --query 'sort_by(imageDetails, &imagePushedAt)[-1].imageTags[0]' \
  --output text)

# Iterate over JSON array
aws ec2 describe-instances --query 'Reservations[].Instances[]' | \
  jq -r '.[] | "\(.InstanceId) \(.State.Name) \(.Tags[]? | select(.Key=="Name") | .Value)"'
```

## Deployment Script Pattern
```bash
#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="production"
APP="myapp"
IMAGE_TAG="${1:?Usage: $0 <image-tag>}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "Deploying $APP:$IMAGE_TAG to $NAMESPACE"

# Update image
kubectl set image deployment/"$APP" \
  app="registry.example.com/$APP:$IMAGE_TAG" \
  --namespace="$NAMESPACE"

# Wait for rollout
if ! kubectl rollout status deployment/"$APP" \
    --namespace="$NAMESPACE" \
    --timeout=5m; then
  log "Rollout failed — rolling back"
  kubectl rollout undo deployment/"$APP" --namespace="$NAMESPACE"
  exit 1
fi

log "Deployment successful: $APP:$IMAGE_TAG"
```

## Useful One-Liners
```bash
# Find files modified in last 24h
find /var/log -mtime -1 -name "*.log"

# Watch pod logs across multiple pods
kubectl logs -l app=myapp -n production --follow --max-log-requests=10

# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=myapp -n production --timeout=120s

# Decode a K8s secret
kubectl get secret myapp-secrets -n production -o jsonpath='{.data.db_password}' | base64 -d

# Tail logs from all nodes
for node in $(kubectl get nodes -o name); do echo "=== $node ==="; kubectl describe "$node" | grep -A5 "Conditions:"; done
```
