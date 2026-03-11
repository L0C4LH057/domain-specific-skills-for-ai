# Git Reference

## Table of Contents
1. [Branch Strategies](#branch-strategies)
2. [Conventional Commits & Versioning](#conventional-commits--versioning)
3. [Git Hooks](#git-hooks)
4. [Common Workflows](#common-workflows)

---

## Branch Strategies

### Trunk-Based Development (Recommended for CI/CD)
```
main (always deployable)
  ├── feature/add-auth          (short-lived, < 2 days)
  ├── fix/payment-race-condition
  └── chore/update-deps

Merge via PR with required:
  - 1+ approvals
  - All CI checks passing
  - No merge conflicts
```

### Gitflow (for versioned releases)
```
main          ← production releases only (tagged v1.x.x)
develop       ← integration branch
  ├── feature/user-dashboard
  ├── feature/api-v2
  └── release/v1.5.0   ← release prep (→ main + develop)
      └── hotfix/v1.4.1 ← urgent production fix (→ main + develop)
```

### Environment Branches (simple teams)
```
main       → production deployment
staging    → staging deployment
develop    → development deployment
```

---

## Conventional Commits & Versioning

### Commit Format
```
<type>(<scope>): <short summary>

[optional body]

[optional footer: BREAKING CHANGE, Closes #123]
```

### Types
| Type       | Description                              | Version Bump |
|------------|------------------------------------------|--------------|
| `feat`     | New feature                              | MINOR        |
| `fix`      | Bug fix                                  | PATCH        |
| `BREAKING` | Breaking API change (`!` or footer)      | MAJOR        |
| `chore`    | Build/tooling/deps, no prod code change  | none         |
| `docs`     | Documentation only                       | none         |
| `refactor` | Code change, not feat/fix                | none         |
| `test`     | Adding/updating tests                    | none         |
| `perf`     | Performance improvement                  | PATCH        |
| `ci`       | CI/CD pipeline changes                   | none         |

### Examples
```
feat(auth): add OAuth2 login with Google
fix(api): handle null pointer in payment service
chore(deps): update node to 20.11.0
feat!: remove deprecated v1 API endpoints

BREAKING CHANGE: v1 API endpoints removed; migrate to v2
```

### Semantic Versioning (SemVer)
```
v<MAJOR>.<MINOR>.<PATCH>[-<pre-release>][+<build>]

v1.4.2
v2.0.0-beta.1
v1.5.0-rc.2+20240115
```

### Tagging Releases
```bash
# Create annotated tag (preferred for releases)
git tag -a v1.5.0 -m "Release v1.5.0: OAuth support"
git push origin v1.5.0

# Tag from CI after merge to main
git tag -a "v${VERSION}" -m "Release ${VERSION}"
git push origin "v${VERSION}"
```

---

## Git Hooks

### pre-commit Hook (`.git/hooks/pre-commit`)
```bash
#!/usr/bin/env bash
set -euo pipefail

# Run linter
npm run lint --silent || { echo "Lint failed. Fix errors before committing."; exit 1; }

# Run tests
npm test --silent || { echo "Tests failed. Fix before committing."; exit 1; }

# Scan for secrets (requires gitleaks)
if command -v gitleaks &>/dev/null; then
  gitleaks protect --staged || { echo "Secret detected in staged files!"; exit 1; }
fi
```

### commit-msg Hook (enforce conventional commits)
```bash
#!/usr/bin/env bash
commit_msg=$(cat "$1")
pattern="^(feat|fix|chore|docs|refactor|test|perf|ci|build|revert)(\(.+\))?(!)?: .{1,100}"

if ! echo "$commit_msg" | grep -qE "$pattern"; then
  echo "ERROR: Commit message doesn't follow Conventional Commits format."
  echo "Expected: feat(scope): description"
  echo "Got: $commit_msg"
  exit 1
fi
```

### pre-commit Framework (Recommended)
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-merge-conflict
      - id: detect-private-key

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.88.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: checkov
```

---

## Common Workflows

### Feature Branch Workflow
```bash
# Start feature
git checkout main && git pull
git checkout -b feature/my-feature

# Work, commit regularly
git add -p   # Stage hunks interactively
git commit -m "feat(scope): description"

# Keep up to date
git fetch origin
git rebase origin/main   # Prefer rebase over merge for cleaner history

# Push and open PR
git push -u origin feature/my-feature

# After PR merged, clean up
git checkout main && git pull
git branch -d feature/my-feature
```

### Hotfix Workflow
```bash
git checkout main
git checkout -b hotfix/payment-null-ptr
# Fix, test
git commit -m "fix(payment): handle null pointer on refund"
git push -u origin hotfix/payment-null-ptr
# PR → merge to main → deploy immediately
```

### Useful Git Commands
```bash
# Undo last commit (keep changes staged)
git reset --soft HEAD~1

# Discard all local changes
git checkout -- .

# Stash work in progress
git stash push -m "WIP: half-done auth feature"
git stash pop

# Interactive rebase (clean up commits before PR)
git rebase -i origin/main

# Find commit that introduced a bug
git bisect start
git bisect bad           # Current commit is bad
git bisect good v1.4.0   # This tag was good
# Git checks out commits — test each and run: git bisect good/bad

# View diff of staged changes
git diff --staged

# Blame with ignore whitespace
git blame -w -C -C <file>

# Log graph
git log --oneline --graph --decorate --all

# Grep through all commits
git log -S "function_name" --source --all
```
