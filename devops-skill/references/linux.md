# Linux & Shell Scripting Reference

## Table of Contents
1. [Bash Scripting Patterns](#bash-scripting-patterns)
2. [Systemd Services](#systemd-services)
3. [Cron Jobs](#cron-jobs)
4. [Log Management](#log-management)
5. [Performance Debugging](#performance-debugging)
6. [User & Permission Management](#user--permission-management)

---

## Bash Scripting Patterns

### Script Header (Always Include)
```bash
#!/usr/bin/env bash
set -euo pipefail   # e=exit on error, u=error on unset var, o pipefail=pipe errors propagate
IFS=$'\n\t'         # Safer word splitting

# Script metadata
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/var/log/${SCRIPT_NAME%.sh}.log"

# Logging
log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO  $*" | tee -a "$LOG_FILE"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN  $*" | tee -a "$LOG_FILE" >&2; }
err()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR $*" | tee -a "$LOG_FILE" >&2; }

# Cleanup on exit
cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    err "Script failed with exit code $exit_code"
  fi
  # Remove temp files, release locks, etc.
  rm -f /tmp/my-script.lock
}
trap cleanup EXIT
```

### Argument Parsing
```bash
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
  -e, --env       Environment (dev|staging|production)
  -v, --version   App version to deploy
  -d, --dry-run   Dry run — show what would be done
  -h, --help      Show this help

Example:
  $SCRIPT_NAME --env production --version 1.2.3
EOF
}

DRY_RUN=false
ENV=""
VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--env)     ENV="$2"; shift 2 ;;
    -v|--version) VERSION="$2"; shift 2 ;;
    -d|--dry-run) DRY_RUN=true; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# Validate required args
[[ -z "$ENV" ]]     && { err "--env is required"; usage; exit 1; }
[[ -z "$VERSION" ]] && { err "--version is required"; usage; exit 1; }
```

### Functions & Error Handling
```bash
# Retry function — useful for flaky network operations
retry() {
  local n=1
  local max=3
  local delay=5
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        warn "Command failed. Attempt $n/$max. Retrying in ${delay}s..."
        sleep $delay
        ((n++))
      else
        err "Command failed after $max attempts."
        return 1
      fi
    }
  done
}

# Check required commands
require_command() {
  command -v "$1" &>/dev/null || { err "Required command not found: $1"; exit 1; }
}

require_command docker
require_command kubectl
require_command aws

# Usage
retry aws s3 cp ./artifact.tar.gz s3://my-bucket/artifacts/
```

### Deployment Script Pattern
```bash
#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${1:?Usage: $0 <image-tag>}"
NAMESPACE="production"
DEPLOYMENT="my-app"
TIMEOUT="5m"

log "Deploying $IMAGE_TAG to $NAMESPACE..."

# Pre-flight checks
kubectl get ns "$NAMESPACE" &>/dev/null || { err "Namespace $NAMESPACE not found"; exit 1; }

# Scale down if needed, or rolling update
kubectl set image deployment/"$DEPLOYMENT" \
  app="registry.example.com/my-app:${IMAGE_TAG}" \
  -n "$NAMESPACE"

# Wait for rollout
log "Waiting for rollout to complete..."
if ! kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE" --timeout="$TIMEOUT"; then
  err "Rollout failed! Rolling back..."
  kubectl rollout undo deployment/"$DEPLOYMENT" -n "$NAMESPACE"
  exit 1
fi

log "Deployment complete: $IMAGE_TAG"
```

### Common One-Liners
```bash
# Find files modified in last 24h
find /var/log -name "*.log" -mtime -1

# Disk usage sorted
du -sh /var/* | sort -rh | head -20

# Port in use
ss -tlnp | grep :8080
lsof -i :8080

# Process by memory
ps aux --sort=-%mem | head -20

# Watch a directory for changes
inotifywait -m -r /var/www -e modify,create,delete

# Tail multiple logs
tail -f /var/log/nginx/access.log /var/log/app/*.log

# Find largest files
find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null | sort -k5 -rh

# Extract field from log
grep "ERROR" /var/log/app.log | awk '{print $4}' | sort | uniq -c | sort -rn

# Check cert expiry
echo | openssl s_client -connect example.com:443 2>/dev/null \
  | openssl x509 -noout -dates
```

---

## Systemd Services

### Service Unit File
```ini
# /etc/systemd/system/my-app.service
[Unit]
Description=My Application Service
Documentation=https://docs.example.com
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=appuser
Group=appgroup
WorkingDirectory=/opt/my-app
EnvironmentFile=/etc/my-app/env
ExecStart=/opt/my-app/bin/server --config /etc/my-app/config.yaml
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=my-app

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/my-app /var/log/my-app
PrivateTmp=true
PrivateDevices=true

# Resource limits
LimitNOFILE=65535
MemoryMax=512M
CPUQuota=200%

[Install]
WantedBy=multi-user.target
```

```bash
# Deploy new service
sudo cp my-app.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable my-app
sudo systemctl start my-app
sudo systemctl status my-app
journalctl -u my-app -f
```

---

## Cron Jobs

### crontab Syntax
```
# ┌─────────── minute (0-59)
# │ ┌───────── hour (0-23)
# │ │ ┌─────── day of month (1-31)
# │ │ │ ┌───── month (1-12)
# │ │ │ │ ┌─── day of week (0-7, 0/7=Sunday)
# │ │ │ │ │
# * * * * * command

0 2 * * *    /opt/scripts/backup.sh          # Daily at 2am
0 */6 * * *  /opt/scripts/sync.sh            # Every 6 hours
*/15 * * * * /opt/scripts/healthcheck.sh     # Every 15 minutes
0 0 1 * *    /opt/scripts/monthly-report.sh  # First of month
```

### Cron Best Practices
```bash
# Always use full paths in cron
# Always redirect output to log
# Use flock to prevent overlapping runs

0 * * * * /usr/bin/flock -n /tmp/my-job.lock \
  /opt/scripts/my-job.sh >> /var/log/my-job.log 2>&1
```

---

## Log Management

### Logrotate Config
```
# /etc/logrotate.d/my-app
/var/log/my-app/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0644 appuser appgroup
    postrotate
        systemctl reload my-app 2>/dev/null || true
    endscript
}
```

### Log Analysis
```bash
# Count HTTP status codes from nginx
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Top 10 IPs by request count
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head 10

# Error rate last hour
grep "$(date -d '1 hour ago' '+%d/%b/%Y:%H')" /var/log/nginx/access.log \
  | awk '$9 ~ /^5/' | wc -l

# Parse structured JSON logs
cat /var/log/app.json | jq 'select(.level=="error") | .message'
```

---

## Performance Debugging

```bash
# CPU
top -bn1 | grep "Cpu(s)"
mpstat -P ALL 1 5          # Per-CPU stats
perf top                   # Real-time profiling

# Memory
free -h
vmstat -s
cat /proc/meminfo

# Disk I/O
iostat -x 1 5
iotop -ao                  # Interactive I/O top
dstat -cdngy 1             # All stats together

# Network
sar -n DEV 1 5             # Network interface stats
netstat -s                 # Protocol stats
ss -s                      # Socket summary
tcpdump -i eth0 port 8080 -w /tmp/capture.pcap  # Packet capture

# System-wide
dmesg | tail -50           # Kernel messages
journalctl -p err -n 50    # System errors
uptime                     # Load average
vmstat 1 10                # VM stats

# Find zombie processes
ps aux | awk '$8 == "Z" {print $2, $11}'

# Check file descriptor limits
cat /proc/sys/fs/file-max        # System max
ulimit -n                        # Current process limit
ls /proc/<pid>/fd | wc -l       # FDs used by process
```

---

## User & Permission Management

```bash
# Create system user for service
useradd --system --no-create-home --shell /bin/false --comment "App User" appuser

# Add to group
usermod -aG docker appuser

# SSH key setup
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Sudoers (least privilege)
# /etc/sudoers.d/appuser
appuser ALL=(root) NOPASSWD: /usr/bin/systemctl restart my-app

# File permissions
chmod 640 /etc/my-app/secrets.env   # Owner r/w, group r, others none
chown appuser:appgroup /var/lib/my-app
chmod -R 755 /opt/my-app/bin        # Executable scripts
```
