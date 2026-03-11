# Troubleshooting Reference — Debug Patterns & Runbooks

## Table of Contents
1. [Kubernetes Debugging](#kubernetes-debugging)
2. [Container Debugging](#container-debugging)
3. [Pipeline Failures](#pipeline-failures)
4. [Network Debugging](#network-debugging)
5. [Runbook Template](#runbook-template)
6. [Post-Mortem Template](#post-mortem-template)

---

## Kubernetes Debugging

### Decision Tree for Pod Issues
```
Pod not running?
├── Pending
│   ├── kubectl describe pod → check Events section
│   ├── Insufficient resources? → kubectl top nodes
│   ├── Unschedulable? → check taints/tolerations, node selectors
│   └── PVC not bound? → kubectl get pvc
├── CrashLoopBackOff
│   ├── kubectl logs <pod> --previous
│   ├── Check liveness probe path/port
│   ├── Check env vars / secrets exist
│   └── kubectl exec -it <pod> -- sh (if it starts briefly)
├── OOMKilled
│   ├── Increase memory limit in resources.limits.memory
│   └── Add JVM heap flags (-XX:MaxRAMPercentage=75)
└── ImagePullBackOff
    ├── Check image name/tag spelling
    ├── Check imagePullSecrets
    └── kubectl describe pod → check registry auth error
```

### Essential Debug Commands
```bash
# Full pod info
kubectl describe pod <pod> -n <ns>

# Previous container logs (after crash)
kubectl logs <pod> -n <ns> --previous

# Live logs with timestamps
kubectl logs <pod> -n <ns> --follow --timestamps

# Run debug container alongside failing pod
kubectl debug -it <pod> --image=busybox --share-processes --copy-to=debug-pod

# Check events across namespace
kubectl get events -n <ns> --sort-by='.lastTimestamp'

# Resource usage
kubectl top pods -n <ns> --sort-by=memory

# Check why HPA isn't scaling
kubectl describe hpa <hpa-name> -n <ns>

# Drain a node safely
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data

# Force delete stuck terminating pod
kubectl delete pod <pod> -n <ns> --force --grace-period=0
```

---

## Container Debugging

```bash
# Exec into running container
docker exec -it <container_id> /bin/sh

# Run one-off debug container with same network
docker run --rm -it --network container:<container_id> nicolaka/netshoot

# Inspect container config
docker inspect <container_id> | jq '.[0].Config'

# Check container logs with timestamps
docker logs <container_id> --timestamps --tail=100

# Check resource usage
docker stats --no-stream

# Build without cache (when debugging layer issues)
docker build --no-cache -t myapp:debug .
```

---

## Pipeline Failures

### GitHub Actions
```bash
# Enable debug logging
# Set repository secret: ACTIONS_STEP_DEBUG = true

# Re-run failed jobs only (UI or CLI)
gh run rerun <run-id> --failed
gh run view <run-id> --log-failed
```

### Common CI Failures & Fixes
| Symptom | Likely Cause | Fix |
|---|---|---|
| `ENOSPC: no space left` | Runner disk full | Add cache cleanup step |
| `permission denied` | Wrong file ownership | Check `chown` in Dockerfile |
| `connection refused` | Service not ready | Add wait/health check step |
| `npm ci` fails | `package-lock.json` out of sync | Run `npm install` and commit |
| Docker push `unauthorized` | Expired token | Re-run login step |
| Kubectl `Unauthorized` | Expired kubeconfig | Refresh `aws eks update-kubeconfig` |

---

## Network Debugging

```bash
# From inside a pod (using netshoot)
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- /bin/bash

# DNS resolution
nslookup myapp.production.svc.cluster.local
dig myapp.production.svc.cluster.local

# TCP connectivity
curl -v http://myapp.production.svc.cluster.local/health
nc -zv myapp 3000

# Trace route
traceroute myapp.production.svc.cluster.local

# Check service endpoints
kubectl get endpoints myapp -n production

# Port-forward for local testing
kubectl port-forward svc/myapp 8080:80 -n production
curl localhost:8080/health
```

---

## Runbook Template

```markdown
# Runbook: <Alert Name>

## Alert Details
- **Alert**: `HighErrorRate` / `PodCrashLooping` / etc.
- **Severity**: Critical / Warning
- **Team**: @platform-team
- **SLO Impact**: Yes/No — [link to SLO dashboard]

## Symptoms
- What the user/customer experiences
- What metrics/logs indicate the problem

## Immediate Actions (first 5 minutes)
1. Check dashboard: [link]
2. Check recent deployments: `kubectl rollout history deployment/myapp -n production`
3. Check pod status: `kubectl get pods -n production -l app=myapp`

## Diagnosis Steps
1. Step one with exact command
2. Step two
3. Decision point: if X → go to section A; if Y → go to section B

## Resolution
### Option A: Rollback deployment
```bash
kubectl rollout undo deployment/myapp -n production
kubectl rollout status deployment/myapp -n production
```

### Option B: Scale up replicas
```bash
kubectl scale deployment myapp --replicas=6 -n production
```

## Escalation
- If unresolved after 30 min → page @oncall-lead
- If data loss suspected → engage @data-team immediately

## Prevention / Follow-up
- Open ticket for root cause analysis
- Link to post-mortem after resolution
```

---

## Post-Mortem Template

```markdown
# Post-Mortem: <Incident Title>

**Date**: YYYY-MM-DD
**Duration**: X hours Y minutes
**Severity**: P1 / P2 / P3
**Author(s)**: 

## Summary
One paragraph: what happened, impact, how it was resolved.

## Timeline (UTC)
| Time | Event |
|---|---|
| 14:02 | Alert fired: HighErrorRate > 5% |
| 14:07 | On-call acknowledged |
| 14:23 | Root cause identified |
| 14:45 | Fix deployed; error rate returning to baseline |
| 15:00 | Incident resolved |

## Root Cause
Detailed technical explanation of why this happened.

## Contributing Factors
- Factor 1
- Factor 2

## Impact
- X% of requests failed for Y minutes
- Z customers affected (if known)

## What Went Well
- Monitoring alerted within 2 minutes
- Rollback completed in under 5 minutes

## What Went Poorly
- Alert runbook was out of date
- No staging environment caught this regression

## Action Items
| Action | Owner | Due Date |
|---|---|---|
| Update runbook | @alice | 2025-02-01 |
| Add integration test for X | @bob | 2025-02-07 |
| Review deployment checklist | @team | 2025-02-14 |

## Lessons Learned
Key takeaways to share with the broader team.
```
