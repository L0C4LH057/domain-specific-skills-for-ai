# README & Open Source Documentation Reference

## Table of Contents
1. [The Perfect README](#readme)
2. [CONTRIBUTING Guide](#contributing)
3. [CHANGELOG Format](#changelog)
4. [Code of Conduct](#coc)
5. [GitHub-Specific Documentation Files](#github-files)
6. [Documentation Site Setup](#docs-site)

---

## 1. The Perfect README {#readme}

### README Structure (Copy-Paste Template)

```markdown
<div align="center">

# [Project Name]

[One compelling sentence that explains exactly what this project does and who it's for.]

[![npm version](https://badge.fury.io/js/project.svg)](https://badge.fury.io/js/project)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Tests](https://github.com/org/repo/workflows/tests/badge.svg)](https://github.com/org/repo/actions)
[![Discord](https://img.shields.io/discord/...)](https://discord.gg/...)

[**Documentation**](https://docs.example.com) · [**Examples**](./examples) · [**Report Bug**](https://github.com/org/repo/issues) · [**Request Feature**](https://github.com/org/repo/issues)

</div>

---

## What is [Project Name]?

[2–3 sentences. What problem does it solve? Who is it for? What makes it different?]

```python
# Show the most compelling use case in as few lines as possible
from project import Client

result = Client("api_key").do_awesome_thing("input")
print(result)  # "The awesome output"
```

---

## Features

- ✅ **[Feature 1]** — [One-line description of value]
- ✅ **[Feature 2]** — [One-line description of value]
- ✅ **[Feature 3]** — [One-line description of value]
- 🚧 **[Planned Feature]** — Coming in v2.0 ([Roadmap](#))

---

## Installation

```bash
# npm
npm install project-name

# yarn  
yarn add project-name

# pip
pip install project-name

# cargo
cargo add project-name
```

**Requirements**: Node.js 18+ · Python 3.9+ · [Other requirements]

---

## Quick Start

```python
from project import Client

# Initialize
client = Client(api_key="your_key_here")

# Do the core thing
result = client.process(
    input="Hello, world!",
    options={"format": "json"}
)

print(result.output)
# {"message": "Hello, world!", "processed": true}
```

For more examples, see the [examples directory](./examples) or the [full documentation](https://docs.example.com).

---

## Usage

### [Common Task 1]
[Brief code example]

### [Common Task 2]
[Brief code example]

### Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_key` | string | Required | Your API key from [dashboard](#) |
| `timeout` | int | `30` | Request timeout in seconds |
| `retries` | int | `3` | Number of retry attempts |

---

## Documentation

- [Full Documentation](https://docs.example.com)
- [API Reference](https://docs.example.com/api)
- [Changelog](CHANGELOG.md)
- [Migration Guide v1 → v2](https://docs.example.com/migration)

---

## Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) before submitting a PR.

**Development setup:**
```bash
git clone https://github.com/org/project.git
cd project
npm install
npm test
```

---

## Support

| Channel | Purpose |
|---------|---------|
| [GitHub Issues](https://github.com/org/project/issues) | Bug reports, feature requests |
| [GitHub Discussions](https://github.com/org/project/discussions) | Questions, ideas |
| [Discord](https://discord.gg/...) | Community chat |
| [docs@example.com](mailto:docs@example.com) | Documentation feedback |

---

## License

[MIT](LICENSE) © 2025 [Your Name / Organization]

---

<div align="center">
  <sub>Built with ❤️ by [Name/Org] and [N] contributors</sub>
</div>
```

### README Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad | Fix |
|-------------|-------------|-----|
| "A powerful tool for..." | Vague, self-congratulatory | State what it actually does |
| Installation before context | Users don't know if they want it yet | Show the value first |
| Outdated code examples | Builds distrust, wastes time | Test examples in CI |
| 500-line README | Nobody reads it all | Move depth to docs site |
| No license badge/info | Enterprises can't adopt it | Always include license |
| Missing requirements | "Works on my machine" | State OS, language version, deps |

---

## 2. CONTRIBUTING Guide {#contributing}

```markdown
# Contributing to [Project Name]

Thank you for your interest in contributing! This guide explains how to get started.

## Ways to Contribute

- **Report bugs** — [Open an issue](https://github.com/org/project/issues/new?template=bug_report.md)
- **Request features** — [Open a discussion](https://github.com/org/project/discussions/new)
- **Fix a bug** — Pick an issue labeled [`good first issue`](https://github.com/org/project/labels/good%20first%20issue) or [`help wanted`](https://github.com/org/project/labels/help%20wanted)
- **Improve documentation** — Edit any `.md` file or the `/docs` directory

## Development Setup

### Prerequisites
- Node.js 18+
- Git

### Setup
```bash
# Fork the repo, then:
git clone https://github.com/YOUR_USERNAME/project.git
cd project
npm install

# Create a branch
git checkout -b feat/your-feature-name
# or
git checkout -b fix/issue-123-description
```

## Development Workflow

### Running Tests
```bash
npm test              # Run all tests
npm run test:unit     # Unit tests only
npm run test:watch    # Watch mode
```

### Code Style
We use ESLint and Prettier. Run before committing:
```bash
npm run lint          # Check
npm run lint:fix      # Auto-fix
```

The CI pipeline will reject PRs that fail linting.

## Submitting a Pull Request

1. Ensure tests pass: `npm test`
2. Update documentation if you changed public APIs
3. Add an entry to `CHANGELOG.md` under `[Unreleased]`
4. Open a PR against the `main` branch

### PR Title Format
We use [Conventional Commits](https://www.conventionalcommits.org/):
```
feat: add support for webhook retry configuration
fix: handle null response from /users endpoint
docs: update authentication guide
chore: upgrade dependencies
```

### PR Review Process
- A maintainer will review within 3 business days
- Address review comments in new commits (don't force-push during review)
- PRs require 1 approval from a maintainer to merge

## Reporting Security Vulnerabilities

**Do not open a public GitHub issue.** Email security@example.com with:
- Description of the vulnerability
- Steps to reproduce
- Potential impact

We'll respond within 48 hours and credit you in the security advisory.

## Community

Be excellent to each other. See our [Code of Conduct](CODE_OF_CONDUCT.md).
```

---

## 3. CHANGELOG Format {#changelog}

Keep a Changelog standard (keepachangelog.com):

```markdown
# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Support for webhook retry configuration via `retryPolicy` option (#342)

### Fixed
- Null pointer exception when response body is empty (#389)

---

## [2.4.1] — 2025-03-15

### Fixed
- Connection pool exhaustion under high load — increased default pool size to 20 (#401)
- Incorrect timestamp formatting for timezones east of UTC (#398)

### Security
- Upgraded `jsonwebtoken` from 8.5.1 to 9.0.0 (resolves CVE-2022-23529)

---

## [2.4.0] — 2025-02-28

### Added
- **Streaming responses**: All list endpoints now support `stream: true` option for real-time data (#356)
- **Batch operations**: New `client.resources.batchCreate()` method accepts up to 100 resources per call (#344)
- TypeScript: Added generic type parameters to `Client` class (#371)

### Changed
- **BREAKING**: `client.resources.list()` now returns an object `{data, pagination}` instead of a plain array. See the [migration guide](docs/migration-v2.3-to-v2.4.md) (#333)
- Default timeout increased from 10s to 30s (#368)

### Deprecated
- `client.getResource()` is deprecated. Use `client.resources.get()` instead. Will be removed in v3.0. (#355)

### Removed
- Removed `legacyMode` option introduced in v1.x. Use the standard configuration. (#340)

---

## [2.3.0] — 2025-01-10
...
```

### Changelog Writing Rules

| Rule | Example |
|------|---------|
| Link every change to its issue/PR | `(#342)` |
| Note breaking changes prominently | `**BREAKING**:` prefix |
| Use past tense | "Added", "Fixed", "Changed" |
| User-facing language | "Fixed crash when..." not "Resolved NPE in ResourceManager.java" |
| Date every release | `[2.4.0] — 2025-02-28` |
| Keep Unreleased section at top | Accumulate changes until release |

---

## References

- **Keep a Changelog** — https://keepachangelog.com/
- **Semantic Versioning** — https://semver.org/
- **Conventional Commits** — https://www.conventionalcommits.org/
- **Make a README** — https://www.makeareadme.com/
- **Contributor Covenant** (Code of Conduct) — https://www.contributor-covenant.org/
- **GitHub Community Standards** — https://docs.github.com/en/communities
- **"Working in Public"** — Nadia Eghbal (open source sustainability)
