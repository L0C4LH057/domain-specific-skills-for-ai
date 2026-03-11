# DevSecOps Reference — Security in the Pipeline

## Table of Contents
1. [Secrets Management](#secrets-management)
2. [Container Security](#container-security)
3. [Pipeline Security Scanning](#pipeline-security-scanning)
4. [Policy as Code](#policy-as-code)
5. [SAST / Dependency Scanning](#sast--dependency-scanning)

---

## Secrets Management

### HashiCorp Vault (Kubernetes Integration)
```yaml
# Vault Agent sidecar injection (annotation-based)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "myapp"
        vault.hashicorp.com/agent-inject-secret-db: "secret/data/myapp/db"
        vault.hashicorp.com/agent-inject-template-db: |
          {{- with secret "secret/data/myapp/db" -}}
          export DB_PASSWORD="{{ .Data.data.password }}"
          {{- end }}
```

### External Secrets Operator (K8s native)
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: myapp-secrets
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: myapp-secrets
    creationPolicy: Owner
  data:
    - secretKey: db_password
      remoteRef:
        key: myapp/production
        property: db_password
```

### SealedSecrets (GitOps-safe)
```bash
# Install kubeseal
kubeseal --fetch-cert --controller-name=sealed-secrets > pub-cert.pem

# Seal a secret
kubectl create secret generic myapp-secrets \
  --from-literal=db_password=supersecret \
  --dry-run=client -o yaml | \
  kubeseal --cert pub-cert.pem --format yaml > sealed-secret.yaml

# SealedSecret is safe to commit to git; the controller decrypts it in-cluster
```

---

## Container Security

### Image Scanning (Trivy in CI)
```yaml
# GitHub Actions step
- name: Scan image for vulnerabilities
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.IMAGE }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'HIGH,CRITICAL'
    exit-code: '1'
    ignore-unfixed: true

- name: Upload Trivy SARIF to GitHub Security
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: 'trivy-results.sarif'
```

### .trivyignore (suppress known false positives)
```
# CVE-YYYY-XXXXX: Reason for suppression + ticket reference
CVE-2023-12345
```

---

## Pipeline Security Scanning

### SAST — Semgrep
```yaml
# GitHub Actions
- name: Run Semgrep
  uses: semgrep/semgrep-action@v1
  with:
    config: >-
      p/security-audit
      p/secrets
      p/owasp-top-ten
```

### Secret Detection — Gitleaks
```bash
# Pre-commit hook
gitleaks protect --staged

# In CI
gitleaks detect --source . --exit-code 1
```

### IaC Scanning — Checkov / tfsec
```bash
# Checkov (Terraform, K8s, Dockerfile)
checkov -d . --framework terraform --soft-fail-on MEDIUM

# tfsec
tfsec . --minimum-severity HIGH
```

---

## Policy as Code

### OPA / Conftest (K8s manifest validation)
```rego
# policy/deny-latest-tag.rego
package main

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  endswith(container.image, ":latest")
  msg := sprintf("Container '%v' uses :latest tag — pin to a specific version", [container.name])
}

deny[msg] {
  input.kind == "Deployment"
  not input.spec.template.spec.securityContext.runAsNonRoot
  msg := "Deployment must set securityContext.runAsNonRoot: true"
}
```

```bash
# Run in CI
conftest test k8s/ --policy policy/
```

---

## SAST / Dependency Scanning

### npm / Node.js
```bash
npm audit --audit-level=high
npx snyk test --severity-threshold=high
```

### Python
```bash
pip-audit --requirement requirements.txt
safety check -r requirements.txt
bandit -r src/ -ll   # code analysis
```

### GitHub Dependabot Config
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: npm
    directory: "/"
    schedule:
      interval: weekly
    assignees: ["security-team"]
    labels: ["dependencies", "security"]

  - package-ecosystem: docker
    directory: "/"
    schedule:
      interval: weekly
```
