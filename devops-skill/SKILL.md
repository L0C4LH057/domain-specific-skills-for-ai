---
name: devops
description: >
  Execute DevOps engineering tasks end-to-end: writing CI/CD pipelines, Dockerfiles, Kubernetes
  manifests, Terraform/Ansible IaC, shell scripts, monitoring configs, and cloud infrastructure.
  Use this skill whenever the user mentions pipelines, deployments, containers, Kubernetes, Helm,
  Terraform, Ansible, Docker, GitHub Actions, GitLab CI, Jenkins, cloud infra (AWS/GCP/Azure),
  monitoring (Prometheus/Grafana/ELK), secrets management, or anything involving infrastructure
  automation, DevSecOps, SRE practices, or platform engineering. Trigger even for partial requests
  like "set up CI", "write a Dockerfile", "deploy to K8s", or "automate my infrastructure".
---

# DevOps Skill

Produces production-grade DevOps artifacts: pipelines, container configs, IaC, shell scripts,
monitoring stacks, and cloud infrastructure. All output is idiomatic, secure, and immediately usable.

## How to Use This Skill

1. **Identify the task type** from the table below → load the relevant reference file
2. **Gather context** (language, cloud provider, existing stack, environment targets)
3. **Produce the artifact** following conventions in the reference file
4. **Validate** using the checklist at the bottom of this file

---

## Task → Reference File Map

| User wants to... | Load reference |
|---|---|
| Write a CI/CD pipeline (GitHub Actions, GitLab, Jenkins, etc.) | `references/cicd.md` |
| Write a Dockerfile, Docker Compose, or container config | `references/containers.md` |
| Write Kubernetes manifests, Helm charts, or Kustomize | `references/kubernetes.md` |
| Write Terraform, Pulumi, or CloudFormation | `references/iac-terraform.md` |
| Write Ansible playbooks or config management | `references/iac-ansible.md` |
| Set up monitoring, alerting, dashboards (Prometheus, Grafana, ELK) | `references/observability.md` |
| Write shell/bash scripts for automation | `references/shell-scripting.md` |
| Set up security scanning, secrets, DevSecOps practices | `references/devsecops.md` |
| Anything AWS-specific (EC2, EKS, S3, Lambda, VPC, IAM) | `references/cloud-aws.md` |
| Anything Azure or GCP | `references/cloud-aws.md` (see multi-cloud section) |
| Troubleshoot infra, diagnose failures, write runbooks | `references/troubleshooting.md` |

> **Multiple references**: Load all relevant files. A "deploy a containerized app to Kubernetes with
> CI/CD" task needs `cicd.md` + `containers.md` + `kubernetes.md`.

---

## Universal Conventions (Apply to All Tasks)

### Security-First Defaults
- **Never** hardcode secrets, tokens, passwords, or API keys in any file
- Use environment variables, vault references, or secret manager paths instead
- Default to least-privilege IAM/RBAC — no wildcard permissions unless explicitly requested
- Add `.gitignore` entries for sensitive files whenever creating new repos/projects

### Idiomatic & Production-Ready
- Pin dependency/image versions — never use `:latest` in production configs
- Add health checks, readiness/liveness probes, resource limits wherever applicable
- Include comments explaining *why*, not just *what*, for non-obvious decisions
- Follow the principle of immutable infrastructure — replace, don't patch in place

### File Output Format
- Always specify the target filename as a comment or header above code blocks
- Group related files together in a single response with clear separators
- If multiple files are needed, offer a directory tree first

### Asking vs. Assuming
If critical context is missing, ask ONE focused question, then proceed:
- Missing: cloud provider → ask once, then default to AWS
- Missing: environment count → default to `dev` + `prod`
- Missing: language/runtime → infer from any visible code or filenames

---

## Output Quality Checklist

Before finalizing any artifact, verify:

- [ ] No hardcoded secrets or credentials
- [ ] Image/package versions are pinned (not `latest`)
- [ ] Resource limits defined (CPU/memory for containers)
- [ ] Health checks / liveness probes included (K8s, Docker)
- [ ] Error handling present in shell scripts (`set -euo pipefail`)
- [ ] IAM/RBAC follows least privilege
- [ ] Pipeline has a test stage before deploy
- [ ] Sensitive files listed in `.gitignore` or equivalent
- [ ] README or inline comments explain usage where non-obvious

---

## Reference Files Index

```
devops-skill/
├── SKILL.md                     ← You are here
└── references/
    ├── cicd.md                  ← CI/CD pipelines (GitHub Actions, GitLab, Jenkins, Tekton)
    ├── containers.md            ← Docker, Docker Compose, multi-stage builds, registries
    ├── kubernetes.md            ← K8s manifests, Helm, Kustomize, RBAC, Ingress, HPA
    ├── iac-terraform.md         ← Terraform modules, state, workspaces, best practices
    ├── iac-ansible.md           ← Ansible playbooks, roles, inventory, Vault integration
    ├── observability.md         ← Prometheus, Grafana, ELK, Loki, alerting, SLOs
    ├── shell-scripting.md       ← Bash patterns, error handling, automation scripts
    ├── devsecops.md             ← Secrets mgmt, SAST/DAST, container scanning, OPA
    ├── cloud-aws.md             ← AWS services, IAM patterns, networking, EKS, Lambda
    └── troubleshooting.md       ← Debug patterns, runbooks, incident response templates
```
