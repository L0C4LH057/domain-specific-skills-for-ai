# Release Notes, Changelogs & Migration Guides Reference

## Table of Contents
1. [Release Notes vs Changelog — The Difference](#difference)
2. [Release Notes Templates](#release-notes)
3. [Version Numbering Guide](#versioning)
4. [Migration Guide Template](#migration)
5. [Deprecation Notice Template](#deprecation)

---

## 1. Release Notes vs Changelog {#difference}

| | Release Notes | Changelog |
|-|---------------|-----------|
| **Audience** | End users, customers, stakeholders | Developers, contributors |
| **Language** | Plain English, benefit-focused | Technical, change-focused |
| **Format** | Narrative + highlights | Structured list by category |
| **Tone** | Marketing-friendly | Engineering-precise |
| **Example** | "You can now export reports as PDF" | "Added `Export.toPDF()` method to `ReportService`" |
| **Lives in** | Product blog, in-app, email | CHANGELOG.md, GitHub releases |

Both are necessary. Neither replaces the other.

---

## 2. Release Notes Templates {#release-notes}

### Major Release (x.0.0)

```markdown
# [Product] 3.0 — [Release Theme / Tagline]

*Released March 20, 2025*

We've completely rebuilt [core component] from the ground up. [Product] 3.0 is
faster, more reliable, and introduces [headline capability] that [benefit statement].

---

## What's New

### 🚀 [Headline Feature]

[2–3 sentences describing the feature and its value. Write for someone who doesn't
know technical details — explain what they can do now that they couldn't before.]

[Screenshot or short demo GIF]

**How to get started**: [Link to guide or tutorial]

### ⚡ [Second Major Feature]

[Same structure]

### 🔒 [Reliability / Performance Improvement]

[Product] 3.0 is [X]% faster at [specific operation]. We rewrote the [component]
to [technical change], reducing [specific metric] from [before] to [after].

---

## Breaking Changes

> ⚠️ **This release contains breaking changes.** See the [Migration Guide](#)
> for step-by-step instructions to upgrade from 2.x.

| What Changed | Old Behavior | New Behavior |
|-------------|-------------|-------------|
| [Change 1] | [What it was] | [What it is now] |
| [Change 2] | [What it was] | [What it is now] |

---

## All Changes

For a complete list of every change in this release, see the [full changelog](CHANGELOG.md#300).

---

## How to Upgrade

```bash
npm update @example/product@3
```

See the [Upgrade Guide](https://docs.example.com/upgrade/3.0) for detailed instructions.

---

## Thank You

This release includes contributions from 47 community members.
[View all contributors](https://github.com/org/product/graphs/contributors).
```

### Minor Release (x.y.0)

```markdown
# [Product] 2.4 — [Month Year]

*Released February 28, 2025*

This release adds [headline capability], improves [X], and fixes [N] bugs reported
by the community.

---

## Highlights

**[Feature Name]** — [One sentence of value]. [Link to guide]

**[Improvement]** — [One sentence of value]. [Link to docs]

---

## New Features

- **[Feature 1]**: [Description + link to docs]
- **[Feature 2]**: [Description + link to docs]

## Improvements

- [Improvement 1]
- [Improvement 2]

## Bug Fixes

- Fixed [issue] that caused [symptom] (#issue-number)
- Fixed [issue] when [condition] (#issue-number)

## Upgrade

```bash
npm update @example/product@2.4
```

No breaking changes. Drop-in upgrade from 2.3.x.
```

### Patch Release (x.y.z)

```markdown
# [Product] 2.4.1

*Released March 15, 2025*

**This is a bug fix release.** No new features or breaking changes.

## Fixed

- Fixed connection pool exhaustion under high load (#401)
- Fixed incorrect timestamp formatting for UTC+ timezones (#398)

## Security

- Upgraded `jsonwebtoken` dependency to address CVE-2022-23529

## Upgrade

```bash
npm update @example/product@2.4.1
```
```

---

## 3. Version Numbering Guide {#versioning}

### Semantic Versioning (SemVer) Reference

**Format**: `MAJOR.MINOR.PATCH` (e.g., `3.2.1`)

| Increment | When | Example Change |
|-----------|------|----------------|
| **MAJOR** | Breaking change — existing code must change to upgrade | Removed `legacyAuth()` method; renamed API endpoint |
| **MINOR** | New backward-compatible feature | Added new `export()` method; new optional config parameter |
| **PATCH** | Backward-compatible bug fix or security patch | Fixed null pointer exception; updated vulnerable dependency |

### Pre-release Labels
```
3.0.0-alpha.1   → Early development, unstable API
3.0.0-beta.1    → Feature complete, may have bugs
3.0.0-rc.1      → Release candidate, production-ready for testing
3.0.0            → Stable release
```

### Calendar Versioning (CalVer) — for date-based products
```
2025.03.1       → Year.Month.Patch
2025.03         → Year.Month (no patch)
```
Used by: Ubuntu (25.04), pip, Twisted

---

## 4. Migration Guide Template {#migration}

Migration guides help users upgrade between breaking versions. Be brutally specific.

```markdown
# Migrating from [Product] v2.x to v3.0

**Estimated time**: 30–60 minutes for a typical project
**Difficulty**: Medium — [N] breaking changes to address
**Support**: [migration@example.com](mailto:migration@example.com) · [Migration Discord channel](#)

---

## Before You Begin

1. Read the [v3.0 Release Notes](#) to understand what changed
2. Back up your project: `git commit -am "pre-v3-migration backup"`
3. Check your current version: `example --version`

---

## Step-by-Step Migration

### Step 1: Update the Dependency

```bash
npm install @example/product@3
# or
pip install --upgrade example-sdk==3.0.0
```

### Step 2: [First Breaking Change]

**What changed**: [Precise description of the change]

**Old code** (v2.x):
```javascript
// This no longer works in v3
const client = new Client({
  apiKey: 'key',
  legacyMode: true,  // ❌ Option removed in v3
});
```

**New code** (v3.0):
```javascript
// Use the new configuration format
const client = new Client({
  apiKey: 'key',
  // legacyMode is no longer needed — the new default behavior handles this
});
```

**Why this changed**: [Brief explanation — helps users understand and trust the change]

### Step 3: [Second Breaking Change]

**What changed**: `client.getResource()` renamed to `client.resources.get()`

**Find and replace**:
```bash
# Run this in your project root to find all usages:
grep -rn "client.getResource(" src/

# Manual replacement needed — automated codemod available:
npx @example/codemod v2-to-v3 src/
```

**Old code**:
```javascript
const resource = await client.getResource(id);
```

**New code**:
```javascript
const resource = await client.resources.get(id);
```

---

## Automated Codemod

For large codebases, use our codemod to automate the mechanical changes:

```bash
npx @example/codemod v2-to-v3 ./src
```

This handles:
- ✅ `getResource()` → `resources.get()`
- ✅ `listResources()` → `resources.list()`
- ✅ Configuration option renames

This does NOT handle:
- ❌ Logic changes in `list()` return format (manual change required — see Step 4)
- ❌ Custom subclasses of `Client`

---

## Breaking Changes Checklist

Use this checklist to confirm you've addressed all breaking changes:

- [ ] Removed `legacyMode` option from Client configuration (Step 2)
- [ ] Updated all `getResource()` calls to `resources.get()` (Step 3)
- [ ] Updated `list()` return value handling — now returns `{data, pagination}` (Step 4)
- [ ] Updated TypeScript types if using `ClientOptions` interface (Step 5)

---

## Rollback Plan

If you encounter issues after upgrading:

```bash
npm install @example/product@2.4
```

v2.4 is the last v2 release and will receive security patches through December 2025.

---

## Getting Help

- [Open a migration issue](https://github.com/org/product/issues/new?template=migration.md)
- [Migration Discord channel](#)
- [Migration office hours: every Tuesday 2pm UTC](#)
```

---

## 5. Deprecation Notice Template {#deprecation}

```markdown
> ⚠️ **DEPRECATED in v2.4**: `client.getResource()` is deprecated and will be
> removed in **v3.0** (planned for Q2 2025).
>
> **Replace with**: `client.resources.get(id)`
>
> ```javascript
> // Old (deprecated)
> const resource = await client.getResource(id);
>
> // New
> const resource = await client.resources.get(id);
> ```
>
> See the [migration guide](#) for full details.
```

**Deprecation timeline documentation**:

| Version | Action |
|---------|--------|
| v2.4 | Feature deprecated. Warning added in runtime logs. |
| v2.x (6 months) | Deprecated feature continues to work |
| v3.0 | Feature removed. Throws `DeprecatedMethodError` |

---

## References

- **Semantic Versioning** — https://semver.org/
- **Calendar Versioning** — https://calver.org/
- **Keep a Changelog** — https://keepachangelog.com/
- **"How to Write a Migration Guide"** — Stripe Engineering Blog
- **Stripe Changelog** — Industry benchmark for release communication
- **GitHub Releases** — https://docs.github.com/en/repositories/releasing-projects-on-github
