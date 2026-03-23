# Documentation Site Structure, Style Guide & Templates

## Table of Contents
1. [Documentation Information Architecture](#ia)
2. [Writing Style Guide](#style)
3. [Docs Site Platform Comparison](#platforms)
4. [Full Page Templates Library](#templates)

---

## 1. Documentation Information Architecture {#ia}

### The Standard Docs Site Structure

```
docs.example.com/
├── /                     → Home: search + card navigation
│
├── /getting-started/     → NEW USER JOURNEY
│   ├── overview          → What is this product?
│   ├── quickstart        → Up and running in 5 min
│   ├── key-concepts      → Mental model / glossary
│   └── first-[action]    → First meaningful task
│
├── /guides/              → HOW-TO GUIDES (task-oriented)
│   ├── [use-case-1]
│   ├── [use-case-2]
│   └── [use-case-3]
│
├── /tutorials/           → LEARNING-ORIENTED (narrative)
│   ├── build-[project-1]
│   └── build-[project-2]
│
├── /api-reference/       → REFERENCE (complete, exhaustive)
│   ├── authentication
│   ├── resources/
│   │   ├── overview
│   │   ├── create
│   │   ├── list
│   │   ├── get
│   │   ├── update
│   │   └── delete
│   └── errors
│
├── /sdks/                → SDK DOCUMENTATION
│   ├── javascript
│   ├── python
│   ├── go
│   └── ruby
│
├── /integrations/        → INTEGRATION GUIDES
│   ├── slack
│   ├── github
│   └── zapier
│
├── /changelog/           → RELEASE NOTES
│
└── /support/             → HELP
    ├── troubleshooting
    ├── faq
    └── contact
```

### Navigation Principles

1. **Top navigation**: Maximum 5 items. Never use generic labels like "Docs" or "Resources"
2. **Left sidebar**: No more than 3 levels deep. If you need 4 levels, restructure
3. **Breadcrumbs**: Always show on all pages except the homepage
4. **Search**: Must be present and prominent — 70% of users navigate by search
5. **Next/Previous links**: Every page should link to what comes before and after

### Documentation Homepage Requirements

```markdown
# [Product] Documentation

[One-sentence description of what users can learn here]

## [Search bar — prominently placed]

## Where would you like to start?

🚀 **New to [Product]?**       → [Quickstart guide] — up and running in 5 minutes
🔧 **Building an integration?** → [API Reference] — complete endpoint documentation
📖 **Looking for examples?**    → [Tutorials] — step-by-step project guides
🆘 **Need help?**               → [Troubleshooting] or [Contact Support]

## Recently Updated

- [Page title] — [Date]
- [Page title] — [Date]
```

---

## 2. Writing Style Guide {#style}

### Terminology Management

Pick one term per concept and use it everywhere. Document your terminology:

```markdown
## Approved Terminology

| Use This | Not These | Notes |
|----------|-----------|-------|
| workspace | project, org, organization, team | Our term for the top-level container |
| resource | item, object, entity | Generic term for things in the system |
| API key | token, secret, credential, API token | We use "key" not "token" |
| dashboard | admin panel, console, portal, control panel | The web UI at dashboard.example.com |
| sign in | log in, login | Verb form |
| sign up | register, create account | Verb form |
| email address | email, e-mail | Never hyphenated |
```

### Number and Date Formatting

| Type | Format | Example |
|------|--------|---------|
| Dates | ISO 8601 in code | `2025-03-20T14:30:00Z` |
| Dates | Month DD, YYYY in prose | March 20, 2025 |
| Numbers | Spell out 0–9 in prose | "three requests" not "3 requests" |
| Numbers | Use digits for 10+ | "15 requests" not "fifteen requests" |
| Numbers | Use digits with units | "5 seconds", "30 MB", "2 hours" |
| Percentages | Use % symbol | "99.9% uptime" |
| Ranges | En dash, no spaces | "10–20 requests" |

### UI Element Formatting

| Element | Format | Example |
|---------|--------|---------|
| Button names | **Bold** | Click **Save** |
| Menu items | **Bold** with → | Go to **Settings → API Keys** |
| Field names | **Bold** | Enter your **Email address** |
| Code, values | `inline code` | Set to `true` |
| File names | `inline code` | Edit `config.json` |
| URLs in prose | [linked text](#) | Visit the [dashboard](#) |
| Keyboard shortcuts | `Key` + `Key` | Press `Ctrl` + `S` |
| Error messages | `inline code` | If you see `Error: unauthorized` |

### Inclusive Language

| Avoid | Use Instead |
|-------|------------|
| whitelist / blacklist | allowlist / blocklist |
| master / slave | primary / replica (or main / secondary) |
| kill | stop, terminate, end |
| he/she (for user) | they / the user |
| sanity check | validation check, smoke test |
| dummy value | placeholder value, example value |
| native (as in "native support") | built-in, first-class |

### Heading Hierarchy Rules

```
H1 → Page title only. One per page.
H2 → Major sections of the page (visible in sidebar/TOC)
H3 → Subsections within H2
H4 → Rarely needed. If using H4 regularly, restructure the page.
Never → Skip levels (H1 → H3 without H2)
```

### Sentence Length and Readability

- **Target reading level**: Grade 8–10 (Flesch-Kincaid)
- **Maximum sentence length**: 25 words (warning), 35 words (hard limit)
- **Paragraph length**: 3–5 sentences. Never one giant paragraph
- **Passive voice**: < 10% of sentences

---

## 3. Docs Site Platform Comparison {#platforms}

| Platform | Best For | Strengths | Weaknesses | Cost |
|----------|----------|-----------|------------|------|
| **Docusaurus** | Developer docs, open source | React-based, versioning, search, free, GitHub pages | Requires Node.js knowledge to customize | Free (self-host) |
| **Mintlify** | API docs, developer portals | Beautiful defaults, OpenAPI integration, MDX support | Paid for teams | $150/mo+ |
| **GitBook** | Team wikis, product docs | Easiest setup, non-technical contributors | Less developer-focused | $8/user/mo |
| **ReadMe** | API reference docs | API explorer, versioning, developer hub | Expensive at scale | $99/mo+ |
| **Notion** | Internal docs, wikis | Familiar, fast to start | Poor search, not for public | $10/user/mo |
| **Confluence** | Enterprise internal docs | Jira integration, permissions | Cluttered, search is poor | $5.75/user/mo |
| **MkDocs Material** | Developer docs | Python-based, beautiful, free, fast | Less flexible than Docusaurus | Free |
| **Starlight (Astro)** | Modern developer docs | Fast, Astro-based, beautiful defaults | Newer, smaller ecosystem | Free |

### Recommended Stack by Company Stage

| Stage | Recommendation | Reasoning |
|-------|---------------|-----------|
| Pre-launch / startup | Mintlify or Docusaurus | Ship fast, great defaults |
| Growing developer platform | Docusaurus or ReadMe | Versioning, API explorer |
| Enterprise internal | Confluence + Notion | Team familiarity |
| Open source project | Docusaurus | Free, GitHub integration, versioning |

---

## 4. Full Page Templates Library {#templates}

### Concept / Overview Page

```markdown
# What is [Concept]?

[One-sentence answer to the title question.]

---

## Overview

[2–4 sentences explaining the concept in plain language. Assume the reader is
smart but unfamiliar with this specific thing.]

[Optional diagram illustrating the concept]

---

## Why [Concept] Matters

[Explain the value and purpose. Connect it to something the reader already
understands or cares about.]

---

## How [Concept] Works

[Mechanism explanation. Keep it focused on what the reader needs to know to
use the product effectively — not a PhD-level deep dive.]

---

## [Concept] in [Product]

[How specifically this product implements or relates to the concept.
What the reader can do with it.]

---

## Related Concepts

- [Related concept 1](#) — [How it relates]
- [Related concept 2](#) — [How it relates]

---

## Next Steps

- [How to use this feature/concept in practice](#)
- [Tutorial: Build something using this concept](#)
```

### Troubleshooting Page

```markdown
# Troubleshooting [Product / Feature]

If you're experiencing an issue not covered here, [contact support](#) or
[search the community forum](#).

---

## Common Issues

### `Error: API key is invalid`

**Cause**: The API key in your request is missing, malformed, or has been revoked.

**Solution**:
1. Verify your API key is correctly set in your environment:
   ```bash
   echo $EXAMPLE_API_KEY  # Should print your key, not empty
   ```
2. Log in to the [Dashboard](#) and check that the key is active under **Settings → API Keys**
3. If the key was recently created, wait 30 seconds for propagation

**If this doesn't work**: Generate a new API key and update your configuration.

---

### `Error: Rate limit exceeded`

**Cause**: Your application has exceeded [N] requests per minute on your current plan.

**Solution**:
1. Add exponential backoff to your retry logic:
   ```python
   import time
   for attempt in range(3):
       try:
           result = client.do_thing()
           break
       except RateLimitError as e:
           time.sleep(2 ** attempt)
   ```
2. Check your current usage in the [Dashboard → Usage](#)
3. Consider [upgrading your plan](#) if you regularly hit limits

---

### [Feature] not appearing in the interface

**Cause**: This feature may not be enabled for your account or plan.

**Solution**:
1. Confirm your plan includes this feature: [Plans comparison](#)
2. Check that the feature flag is enabled in **Settings → Features**
3. Clear your browser cache: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)

**If this doesn't work**: [Contact support](#) with your account ID and a screenshot.
```

---

## References

- **Google Developer Documentation Style Guide** — https://developers.google.com/style
- **Microsoft Writing Style Guide** — https://docs.microsoft.com/en-us/style-guide/
- **"Docs for Developers"** — Bhatti, Corleissen, Lambourne, Nunez, Waterhouse — Apress 2021
- **Write the Docs** — https://www.writethedocs.org/
- **Divio Documentation System** — https://documentation.divio.com/
- **Hemingway App** — https://hemingwayapp.com/ (readability checker)
- **Vale** — https://vale.sh/ (prose linting for documentation CI)
- **Docusaurus** — https://docusaurus.io/
- **Mintlify** — https://mintlify.com/
