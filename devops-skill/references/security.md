# Security Reference (DevSecOps)

## Table of Contents
1. [Secret Management](#secret-management)
2. [Container Security](#container-security)
3. [Pipeline Security (SAST/DAST)](#pipeline-security)
4. [Kubernetes Security](#kubernetes-security)
5. [IAM Least Privilege](#iam-least-privilege)
6. [Policy as Code (OPA)](#policy-as-code)

---

## Secret Management

### HashiCorp Vault

#### Docker Compose (Dev)
```yaml
services:
  vault:
    image: hashicorp/vault:1.16
    cap_add: [IPC_LOCK]
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: dev-root-token
      VAULT_DEV_LISTEN_ADDRESS: "0.0.0.0:8200"
    ports: ["8200:8200"]
    command: server -dev
```

#### Kubernetes Agent Injector Pattern
```yaml
# Annotations on the Pod spec — Vault injects secrets as files
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "my-app"
  vault.hashicorp.com/agent-inject-secret-config: "secret/data/my-app/config"
  vault.hashicorp.com/agent-inject-template-config: |
    {{- with secret "secret/data/my-app/config" -}}
    export DB_PASSWORD="{{ .Data.data.db_password }}"
    export API_KEY="{{ .Data.data.api_key }}"
    {{- end }}
```

#### Vault Policy
```hcl
# my-app-policy.hcl
path "secret/data/my-app/*" {
  capabilities = ["read"]
}

path "secret/metadata/my-app/*" {
  capabilities = ["list"]
}
```
```bash
vault policy write my-app my-app-policy.hcl
vault write auth/kubernetes/role/my-app \
  bound_service_account_names=my-app-sa \
  bound_service_account_namespaces=production \
  policies=my-app \
  ttl=1h
```

### AWS Secrets Manager (via External Secrets Operator)
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-store
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
            namespace: external-secrets
```

### Sealed Secrets (GitOps-safe K8s secrets)
```bash
# Install kubeseal CLI
brew install kubeseal

# Seal a secret (only the cluster can decrypt)
kubectl create secret generic app-secrets \
  --from-literal=db-password=mysecret \
  --dry-run=client -o yaml \
  | kubeseal --controller-namespace kube-system \
  > sealed-app-secrets.yaml
# sealed-app-secrets.yaml is safe to commit to Git
```

---

## Container Security

### Trivy (Image Scanning)
```bash
# Scan image for vulnerabilities
trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:latest

# Scan filesystem (in CI before building image)
trivy fs --severity HIGH,CRITICAL --exit-code 1 .

# Scan IaC files
trivy config --severity HIGH,CRITICAL ./infra/

# Generate SBOM
trivy image --format cyclonedx --output sbom.json myapp:latest

# GitHub Actions step
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    format: sarif
    output: trivy-results.sarif
    severity: HIGH,CRITICAL
    exit-code: '1'
```

### Dockerfile Hardening Checklist
```dockerfile
# ✅ Use non-root user
RUN addgroup -g 1001 appgroup && adduser -u 1001 -G appgroup -D appuser
USER appuser

# ✅ Read-only root filesystem (set in K8s securityContext too)
# securityContext.readOnlyRootFilesystem: true

# ✅ No SUID/GUID bits
RUN find / -perm /6000 -type f -exec chmod a-s {} \; 2>/dev/null || true

# ✅ Minimal image
FROM gcr.io/distroless/static-debian12  # or alpine

# ✅ Drop capabilities in K8s (not Docker)
# securityContext.capabilities.drop: ["ALL"]

# ✅ Don't use shell form CMD (uses /bin/sh -c)
CMD ["./server"]         # ✅ exec form
CMD ./server             # ❌ shell form
```

---

## Pipeline Security

### GitHub Actions — Full Security Stage
```yaml
security-scan:
  runs-on: ubuntu-latest
  permissions:
    security-events: write  # For SARIF upload
  steps:
    - uses: actions/checkout@v4

    # SAST with Semgrep
    - name: Semgrep SAST
      uses: returntocorp/semgrep-action@v1
      with:
        config: auto

    # Dependency scanning
    - name: Run Snyk
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        args: --severity-threshold=high

    # Secret scanning (gitleaks)
    - name: Secret scan with Gitleaks
      uses: gitleaks/gitleaks-action@v2
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

    # IaC scanning
    - name: Checkov IaC scan
      uses: bridgecrewio/checkov-action@master
      with:
        directory: infra/
        framework: terraform
        soft_fail: false
```

### GitLab CI Security Stage
```yaml
sast:
  stage: scan
  image: returntocorp/semgrep:latest
  script:
    - semgrep --config=auto --json --output=gl-sast-report.json . || true
  artifacts:
    reports:
      sast: gl-sast-report.json

dependency-scanning:
  stage: scan
  image: aquasec/trivy:latest
  script:
    - trivy fs --format json --output gl-dependency-scanning-report.json .
  artifacts:
    reports:
      dependency_scanning: gl-dependency-scanning-report.json
```

---

## Kubernetes Security

### Pod Security Standards (Restricted)
```yaml
# Namespace-level enforcement
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### SecurityContext (Minimum for Restricted PSS)
```yaml
securityContext:           # Pod level
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001
  seccompProfile:
    type: RuntimeDefault

containers:
  - name: app
    securityContext:       # Container level
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
```

### Falco Runtime Security (DaemonSet)
```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set falco.json_output=true \
  --set falcosidekick.enabled=true \
  --set falcosidekick.config.slack.webhookurl=${SLACK_WEBHOOK}
```

---

## IAM Least Privilege

### AWS IAM — EKS IRSA (Service Account Role)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-app-bucket",
        "arn:aws:s3:::my-app-bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:123456789:secret:/production/my-app/*"
      ]
    }
  ]
}
```

### Trust Policy (for EKS IRSA)
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::123456789:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:sub":
          "system:serviceaccount:production:my-app-sa"
      }
    }
  }]
}
```

---

## Policy as Code

### OPA/Conftest — Require Non-Root in K8s
```rego
# policies/k8s/no-root.rego
package main

deny[msg] {
  input.kind == "Deployment"
  not input.spec.template.spec.securityContext.runAsNonRoot
  msg = sprintf("Deployment '%s' must set runAsNonRoot: true", [input.metadata.name])
}

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.securityContext.allowPrivilegeEscalation == false
  msg = sprintf("Container '%s' must set allowPrivilegeEscalation: false", [container.name])
}
```

```bash
# Test K8s manifests against policies in CI
conftest test k8s/ --policy policies/k8s/

# Test Terraform plan
terraform show -json tfplan | conftest test - --policy policies/terraform/
```

### Checkov (Terraform)
```bash
# Scan and fail on HIGH severity
checkov -d infra/ --framework terraform --check HIGH --compact
```
