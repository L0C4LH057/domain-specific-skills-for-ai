# User-Facing Product Documentation Reference

## Table of Contents
1. [User Manual Structure](#manual)
2. [Onboarding Documentation](#onboarding)
3. [Feature Documentation](#features)
4. [Help Center / Knowledge Base Articles](#help-center)
5. [FAQ Documentation](#faq)
6. [Tutorial Writing](#tutorials)
7. [Video Script Documentation](#video)

---

## 1. User Manual Structure {#manual}

### Complete User Manual Template

```markdown
# [Product Name] User Guide
**Version**: 3.2 | **Last Updated**: March 2025

---

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Account Setup](#account-setup)
4. [Core Features](#core-features)
   - [Feature A](#feature-a)
   - [Feature B](#feature-b)
5. [Settings & Configuration](#settings)
6. [Integrations](#integrations)
7. [Troubleshooting](#troubleshooting)
8. [Glossary](#glossary)
9. [Support](#support)

---

## Introduction

**What is [Product]?**
[Product] is a [one-sentence description] that helps [target audience] [achieve outcome].

**Who is this guide for?**
This guide is for [audience description]. If you are a [developer / admin / other role], see the [specific guide] instead.

**What you'll learn:**
- How to set up your account
- How to [core task 1]
- How to [core task 2]

---

## Getting Started

### System Requirements

**Desktop**
| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| Operating System | Windows 10, macOS 11, Ubuntu 20.04 | Latest stable version |
| RAM | 4 GB | 8 GB |
| Browser | Chrome 90+, Firefox 88+, Safari 14+ | Latest Chrome or Firefox |

**Mobile**
- iOS 14 or later
- Android 10 or later

### Creating Your Account

1. Go to [example.com/signup](https://example.com/signup)
2. Enter your email address and click **Continue**
3. Check your email for a verification link
4. Click the link and set your password
5. Complete your profile and click **Finish Setup**

> 💡 **TIP**: Use your work email address to make team collaboration easier later.
```

---

## 2. Onboarding Documentation {#onboarding}

### Onboarding Flow Documentation

Well-structured onboarding docs follow this exact pattern:

```markdown
# Welcome to [Product]

You're moments away from [core value promise]. This guide will walk you through
your first [timeframe], step by step.

---

## Your Onboarding Checklist

- [ ] Create your account
- [ ] Set up your workspace
- [ ] Invite your first team member
- [ ] Complete your first [core action]
- [ ] Connect your first integration

---

## Day 1: Your First [Core Action]

**Goal**: [Specific, measurable outcome you'll achieve]
**Time**: About 10 minutes

### What You'll Need
- [Prerequisite 1]
- [Prerequisite 2]

### Step 1: Create Your First [Object]

Click **+ New [Object]** in the top navigation.

[Screenshot: new-object-button.png]
*The "+ New Object" button in the top navigation bar*

Fill in the required fields:
- **Name**: A descriptive name for your [object]
- **Type**: Choose the type that matches your use case (see [Types guide](#) for details)
- **Description**: Optional. Helps teammates understand what this [object] is for

Click **Create** when you're done.

### Step 2: Configure Your Settings

...

### ✅ Checkpoint: What You've Accomplished

By now you should have:
- A [object] named "[example name]"
- Your workspace configured with [setting]
- [Expected visible result]

If something doesn't look right, see [Troubleshooting your first setup](#).

---

## Day 2–7: Building Your Workflow

[Continue with progressive complexity...]
```

### Onboarding Email Sequence Documentation

Document the customer email journey alongside the product:

```markdown
## Onboarding Email Sequence

### Email 1: Welcome (Sent immediately after signup)
**Subject**: Welcome to [Product] — here's where to start
**Goal**: Drive user to complete profile and first action
**Link**: [Getting Started guide]

### Email 2: Day 2 — First Milestone Prompt
**Subject**: Did you complete your first [action]?
**Trigger**: Sent if user has NOT completed first action after 24 hours
**Goal**: Re-engage with contextual help

### Email 3: Day 7 — Feature Discovery
**Subject**: You haven't tried [Feature X] yet
**Trigger**: 7 days after signup, user hasn't used Feature X
**Goal**: Drive feature adoption

[Continue sequence...]
```

---

## 3. Feature Documentation {#features}

### Feature Page Template

```markdown
# [Feature Name]

> One sentence: what this feature does and the problem it solves.

**Available on**: Free, Pro, Enterprise plans (or: Pro and Enterprise plans only)

---

## Overview

[2–3 sentences explaining the feature in plain language. What it does, when to use it,
and what value it provides.]

[Screenshot or diagram of the feature]

---

## How It Works

[Optional section explaining the underlying concept if non-obvious.
Skip for straightforward features.]

---

## Using [Feature Name]

### [Common Task 1]

1. Navigate to **[Menu] → [Sub-menu]**
2. Click **[Button Name]**
3. [Complete the action]
4. Click **Save**

**Result**: [What the user sees when done correctly]

### [Common Task 2]

...

---

## Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| [Option 1] | [What it does] | [Default value] |
| [Option 2] | [What it does] | [Default value] |

---

## Limitations

- Maximum [N] [objects] per [scope]
- [Feature] is not available in [specific context]
- Changes may take up to [timeframe] to take effect

---

## Related Features

- [Feature A] — [How it relates]
- [Feature B] — [How it relates]

---

## Frequently Asked Questions

**Q: [Common question about this feature]**
A: [Clear answer]

**Q: [Another common question]**
A: [Clear answer]
```

---

## 4. Help Center / Knowledge Base Articles {#help-center}

### Knowledge Base Article Structure

Every KB article maps to exactly one user intent:

```markdown
# How to [Specific Task]

[One sentence confirming what the user will be able to do after reading this]

**Applies to**: [Product version / plan / role]
**Last updated**: [Date]

---

## Before You Start

Make sure you have:
- [Permission level] access (see [Role permissions](#))
- [Prerequisite 2]

---

## Steps

1. **Open [location]**
   Go to **Settings → [Section]** from the main menu.

2. **Click [button/link]**
   [Screenshot showing exact button location]

3. **Enter your [field name]**
   - [What to enter / valid values]
   - [Any restrictions or format requirements]

4. **Confirm the action**
   A confirmation dialog will appear. Review the details and click **[Confirm button text]**.

> ⚠️ **WARNING**: [Any irreversible consequences the user should know about]

---

## What Happens Next

After completing these steps:
- [Expected result 1]
- [Expected result 2]
- You'll receive a confirmation [email / notification]

If you don't see the expected result within [timeframe], see [Troubleshooting](#).

---

## Related Articles

- [Related article 1](#)
- [Related article 2](#)

---

*Was this article helpful? [👍 Yes] [👎 No]*
*[Contact Support](#) if you still need help*
```

### KB Article Quality Criteria

| Criteria | Pass | Fail |
|----------|------|------|
| Title is a complete task statement | "How to reset your password" | "Passwords" |
| Steps are numbered, not bulleted | ✓ | — |
| Every step has exactly one action | "Click Save" | "Fill in the form and save" |
| Screenshots show the exact UI element | Annotated screenshot | Generic screenshot |
| Article has exactly one focus | ✓ | Multiple tasks in one article |
| Troubleshooting link at the bottom | ✓ | — |
| Last updated date is current | Within 6 months | Over 1 year old |

---

## 5. FAQ Documentation {#faq}

### FAQ Page Structure

FAQs are not a dumping ground — curate the top 8–12 questions only:

```markdown
# Frequently Asked Questions

**Can't find your answer?** [Contact our support team](#) or [search the knowledge base](#).

---

## Account & Billing

### How do I change my plan?
Go to **Settings → Billing → Change Plan**. Your new plan takes effect immediately.
You'll be charged or credited on a prorated basis for the remainder of your billing period.

### What payment methods do you accept?
We accept Visa, Mastercard, American Express, and PayPal. For Enterprise plans,
we also support invoiced annual payments. [Contact sales](#) for details.

---

## Getting Started

### How long does setup take?
Most users are up and running within 15 minutes. [See our quickstart guide](#)
for step-by-step instructions.

### Do I need technical knowledge to use [Product]?
No. [Product] is designed for [audience description]. No coding or technical background required.
If you are a developer looking to integrate via API, see our [API documentation](#).
```

### FAQ Writing Rules

1. **Write the question exactly as users ask it** — use informal, first-person language ("How do I..." not "How does one...")
2. **Answer in the first sentence** — don't make users read 3 sentences before getting to the answer
3. **Link to detailed docs** — FAQs should be concise; depth lives elsewhere
4. **Group by topic** — never have a single flat list of 50 questions
5. **Review quarterly** — FAQs go stale fast; outdated answers damage trust

---

## 6. Tutorial Writing {#tutorials}

### Tutorial vs How-to Guide (Critical Distinction)

| Tutorial | How-to Guide |
|----------|-------------|
| Learning-oriented | Problem-solving oriented |
| Guided, narrated experience | Steps to achieve a specific goal |
| May use simplified/toy examples | Uses real-world scenarios |
| Holds user's hand | Assumes baseline competency |
| "Build a to-do app to learn our API" | "How to bulk import users via CSV" |

### Tutorial Template

```markdown
# Build [Concrete Thing]: A [Product] Tutorial

**What you'll build**: [One sentence + screenshot of finished result]
**Skills you'll practice**: [List 2–4 skills]
**Time**: 20–30 minutes
**Difficulty**: Beginner | Intermediate | Advanced

---

## What We're Building

[1–2 paragraphs describing the finished project, why it's useful, and what
concepts it teaches. Include a screenshot or diagram of the end result.]

---

## Prerequisites

Before starting this tutorial, make sure you:
- Have a [Product] account ([create one free](#))
- Are familiar with [basic concept] (if new, see [intro guide](#))
- Have [tool] installed: `[tool] --version` should return `X.X` or higher

---

## Part 1: [Foundation Setup]

### What We're Doing in This Part
[Brief explanation of what this section accomplishes and why]

### 1.1 [First Sub-step]
[Explanation of what we're doing and why, then the action]

```[language]
[Complete, runnable code]
```

**What this does**: [Explain non-obvious parts of the code]

### 1.2 [Second Sub-step]
...

### ✅ Checkpoint
Your project should now [visible state]. Run:
```bash
[verification command]
```
Expected output:
```
[exact expected output]
```

---

## Part 2: [Adding Core Functionality]

[Continue building complexity progressively...]

---

## Summary

You've built [what they built]. Along the way you learned:
- [Concept 1] and how to [apply it]
- [Concept 2]

### What's Next
- **More complex version**: [Tutorial that builds on this one](#)
- **Production considerations**: [Guide for making this production-ready](#)
- **API reference**: [Full reference for the methods used](#)
```

---

## References

- **Divio Documentation System** — https://documentation.divio.com/
- **Google Developer Documentation Style Guide** — https://developers.google.com/style
- **"Every Page is Page One"** — Mark Baker, XML Press 2013
- **Nielsen Norman Group — Writing for the Web** — https://www.nngroup.com/articles/writing-for-lower-literacy-users/
- **Mailchimp Content Style Guide** — https://styleguide.mailchimp.com/ (excellent plain-language standard)
- **Intercom Product Documentation** — Industry benchmark for product docs
