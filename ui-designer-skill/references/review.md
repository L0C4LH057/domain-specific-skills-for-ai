# REVIEW Mode — Audit Framework & Scoring Rubric

## Table of Contents
1. [Audit Process](#audit-process)
2. [Scoring Rubric (10 Dimensions)](#scoring-rubric)
3. [Issue Classification](#issue-classification)
4. [Critique Template](#critique-template)
5. [Common Anti-Patterns](#common-anti-patterns)

---

## Audit Process

When reviewing a UI, follow this exact sequence:

### Step 1: First Impression (5-second test)
Answer these before analyzing details:
- What is this screen trying to communicate?
- What is the most prominent visual element? Is it the right one?
- Does this feel trustworthy? Professional? Finished?
- What emotion does it create?

### Step 2: Score All 10 Dimensions
Use the rubric below. Be honest — most amateur UIs score 3–5.

### Step 3: Identify Critical Issues
Any dimension scoring ≤ 3 is a critical issue. These MUST be fixed before any polish.

### Step 4: Produce the Upgrade
Don't just list problems. Deliver the fixed version with before/after code.

---

## Scoring Rubric

Score each dimension 1–10. Total max = 100.

### 1. Visual Hierarchy (0–10)
```
10 — Perfect hierarchy; eye moves exactly where intended; one dominant element per section
7  — Good hierarchy with minor inconsistencies in weight or sizing
5  — Multiple competing elements; unclear where to look first
3  — Flat, everything feels equal weight; no clear focal point
1  — Chaotic; multiple elements fighting for attention
```

### 2. Typography (0–10)
```
10 — Purposeful scale; max 3 levels per section; weights and tracking calibrated
7  — Good scale, minor size/weight inconsistencies
5  — Too many font sizes; inconsistent weights; poor line-height
3  — Mixed fonts without system; random sizing; poor readability
1  — Multiple font families fighting; unreadable sizes; no scale
```
Key checks:
- Body text ≥ 14px?
- Line height 1.4–1.6 for body?
- Heading hierarchy clear (H1 > H2 > H3)?
- No all-caps body text?
- Letter spacing appropriate (tight for headings, normal for body)?

### 3. Color & Contrast (0–10)
```
10 — Intentional palette; clear color roles; all contrast passes WCAG AA
7  — Good palette with 1–2 contrast issues
5  — Inconsistent use of color; some contrast failures; colors feel accidental
3  — Too many colors; no roles assigned; multiple contrast failures
1  — Random colors; unreadable text; no accessible contrast anywhere
```
Must check:
- Body text contrast ≥ 4.5:1
- Large text ≥ 3:1
- Interactive states visually distinct (not color-only)
- ≤ 5 colors in the core palette

### 4. Spacing & Layout (0–10)
```
10 — Perfect 8pt grid; generous breathing room; sections clearly delineated
7  — Mostly consistent; 1–2 spacing values off-grid
5  — Inconsistent margins/padding; some cramped sections; no clear rhythm
3  — Arbitrary spacing; elements crowd each other or float randomly
1  — No spacing system; elements overlapping or misaligned
```

### 5. Component Consistency (0–10)
```
10 — All buttons, inputs, cards identical in style; design system evident
7  — Mostly consistent; 1–2 component variants unexplained
5  — Multiple button styles without clear hierarchy; inconsistent card styles
3  — Major inconsistencies; same element looks different in different sections
1  — No component consistency; every element designed ad-hoc
```

### 6. Interaction & States (0–10)
```
10 — All interactive elements have hover, focus, active, disabled states; transitions smooth
7  — Most states present; missing some focus styles or loading states
5  — Only default state; hover sometimes missing; no focus styles
3  — Minimal states; no feedback to user interactions
1  — No interactive states; static only
```

### 7. Information Architecture (0–10)
```
10 — Perfect grouping; related items together; navigation obvious; zero confusion
7  — Good structure with minor grouping issues
5  — Some confusing groupings; navigation requires thought
3  — Poor information hierarchy; related items separated; confusing
1  — No logical structure; information dumped without organization
```

### 8. Data Presentation (0–10) — score N/A if no data
```
10 — Right chart for the data; proper axis labels; meaningful comparisons possible
7  — Good charts; minor label or scale issues
5  — Charts present but poorly labeled; hard to extract insight
3  — Wrong chart type; missing labels; chart doesn't answer a question
1  — Charts are decorative; convey no information
```

### 9. Responsiveness (0–10)
```
10 — Perfect at 375px, 768px, 1280px, 1440px; nothing breaks or overflows
7  — Works at most sizes; 1–2 breakpoint issues
5  — Works on desktop; mobile has problems
3  — Major layout breaks on tablet/mobile
1  — Desktop only; completely broken on mobile
```

### 10. Professional Finish (0–10)
```
10 — Feels like Stripe/Linear/Vercel quality; investor-ready
7  — Professional; would pass a design review
5  — Functional but clearly unpolished; lacks attention to detail
3  — Clearly in progress; multiple rough edges visible
1  — Prototype quality; not ready for users
```

---

## Issue Classification

### 🔴 Critical (fix first — blocks professional status)
- Contrast failures on body text
- No focus states on interactive elements
- Broken layouts at common screen sizes
- Mixed font families with no system
- Primary actions indistinguishable from secondary

### 🟡 Important (fix for professional grade)
- Inconsistent spacing (off the 8pt grid)
- Missing hover states
- No empty states for data tables/lists
- KPI numbers without context (no comparison, no trend)
- Charts without proper axis labels or titles

### 🟢 Polish (elevate to premium grade)
- Micro-transitions missing (< 150ms ease on hover)
- Skeleton loading not implemented
- Icon style inconsistency (mixed filled/outline)
- Shadow hierarchy undefined
- Missing tooltips on abbreviated/truncated content

---

## Critique Template

```markdown
## UI Review: [Screen Name]

### First Impression
[3 sentences: what this looks like, what emotion it creates, verdict on professionalism]

### Scores
| Dimension              | Score | Note |
|------------------------|-------|------|
| Visual Hierarchy       | X/10  | ... |
| Typography             | X/10  | ... |
| Color & Contrast       | X/10  | ... |
| Spacing & Layout       | X/10  | ... |
| Component Consistency  | X/10  | ... |
| Interaction & States   | X/10  | ... |
| Information Architecture | X/10 | ... |
| Data Presentation      | X/10  | ... |
| Responsiveness         | X/10  | ... |
| Professional Finish    | X/10  | ... |
| **TOTAL**              | **X/100** | |

### Critical Issues (must fix)
1. [Issue] → [Specific fix]
2. [Issue] → [Specific fix]

### Important Improvements
1. [Issue] → [Specific fix with code snippet]

### Upgraded Version
[Full working code of the redesigned screen]
```

---

## Common Anti-Patterns

### Typography Anti-Patterns
```css
/* ❌ Too many sizes */
font-size: 11px; /* also 12, 13, 14, 15, 16, 18, 20, 22, 24, 28... */

/* ✅ Fixed scale */
--text-xs: 12px;
--text-sm: 13px;
--text-base: 14px;
--text-md: 16px;
--text-lg: 18px;
--text-xl: 20px;
--text-2xl: 24px;
--text-3xl: 30px;
```

### Spacing Anti-Patterns
```css
/* ❌ Arbitrary spacing */
margin: 7px 11px 13px 9px;
padding: 15px;
gap: 17px;

/* ✅ 8pt grid */
margin: var(--space-2) var(--space-3);
padding: var(--space-4);
gap: var(--space-4);
```

### Color Anti-Patterns
```css
/* ❌ Same color, different shades scattered everywhere */
background: #f1f5f9;
background: #f8fafc;
background: #f3f4f6;
background: #fafafa;

/* ✅ Named surface tokens */
--color-surface:        #ffffff;
--color-surface-subtle: #f8fafc;
--color-surface-raised: #ffffff;
```

### KPI Anti-Patterns
```
❌ Big number, no context ("Revenue: $124,500")
✅ Number + trend + period ("$124,500  ↑ 12.3%  vs last month")

❌ All numbers same visual weight
✅ Primary metric large (32px bold), supporting data small (12px muted)

❌ 8+ KPIs on one row
✅ Max 4 primary KPIs; secondary metrics below or in detail panel
```
