---
name: ui-designer
description: >
  Full-stack UI/UX design skill for creating, reviewing, auditing, and upgrading interfaces to
  enterprise, SaaS, and professional product standards. Use this skill for ANY of the following:
  designing dashboards, KPI views, analytics screens, admin panels, SaaS product UIs, design systems,
  component libraries, landing pages, onboarding flows, data tables, charts, and forms. Also trigger
  for REVIEW and AUDIT tasks — "review my dashboard", "is this design professional?", "make this
  look enterprise", "upgrade my UI", "fix the KPIs", "critique my layout", "improve this screen",
  "make it look like Linear/Notion/Stripe/Figma". Trigger even for partial requests like "clean up
  my dashboard", "what's wrong with my design", or "make this more polished".
---

# UI Designer Skill

Designs, reviews, audits, and upgrades user interfaces to professional, enterprise, and SaaS
product standards. Produces working code (HTML/CSS/JS, React/JSX, Tailwind) and structured
design critiques with actionable fixes.

---

## Mode Selection

Identify which mode applies, then load the corresponding reference file:

| User intent | Mode | Load reference |
|---|---|---|
| Build a new UI from scratch | **CREATE** | `references/create.md` |
| Review / audit an existing design | **REVIEW** | `references/review.md` |
| Upgrade UI to enterprise/SaaS standards | **UPGRADE** | `references/upgrade.md` |
| Design or fix a dashboard with KPIs | **DASHBOARD** | `references/dashboard.md` |
| Build or extend a design system / tokens | **SYSTEM** | `references/design-system.md` |
| Design data tables, charts, analytics | **DATA-VIZ** | `references/data-viz.md` |
| Accessibility audit or remediation | **A11Y** | `references/accessibility.md` |

> **Compound tasks**: Load all relevant files. "Review my SaaS dashboard and upgrade it" → load
> `review.md` + `dashboard.md` + `upgrade.md`.

---

## Universal Design Principles (Apply to All Modes)

### The 5 Laws of Professional UI
1. **Hierarchy is king** — Visual weight must match information importance. One dominant element per screen.
2. **Consistency is trust** — Spacing, color, type, and interaction patterns must be identical across the product.
3. **Density is intentional** — Enterprise tools can be dense; consumer tools should breathe. Never accidentally dense.
4. **Every pixel earns its place** — Remove decoration that doesn't communicate. Simplify until removing one more thing would break clarity.
5. **States tell the story** — Every interactive element needs: default, hover, active, focus, disabled, loading, error, empty.

### Token-First Thinking
All values must reference tokens, never hardcode:
```css
/* WRONG */
color: #2563eb;
padding: 12px 16px;
border-radius: 6px;

/* RIGHT */
color: var(--color-primary-600);
padding: var(--space-3) var(--space-4);
border-radius: var(--radius-md);
```

### Spacing System (8pt grid — non-negotiable)
```
4px   = --space-1   (tight: icon gaps, badge padding)
8px   = --space-2   (small: inline spacing)
12px  = --space-3   (medium: form field padding)
16px  = --space-4   (base: component padding)
24px  = --space-6   (section gaps)
32px  = --space-8   (card padding, major spacing)
48px  = --space-12  (section breaks)
64px  = --space-16  (page-level spacing)
```

### Typography Scale (Professional)
```
Display  48–72px  weight 700–800  tracking -0.02em  (hero headlines only)
H1       32–40px  weight 700      tracking -0.02em
H2       24–28px  weight 600      tracking -0.01em
H3       18–20px  weight 600      tracking -0.005em
Body     14–16px  weight 400      tracking  0
Small    12–13px  weight 400–500  tracking +0.01em
Label    11–12px  weight 500–600  tracking +0.06em  uppercase
Code     13–14px  monospace
```

### Color Roles (always assign, never guess)
```
--color-brand          Primary actions, selected states, links
--color-brand-subtle   Hover backgrounds for brand elements
--color-neutral-*      Text (900→600), borders (300), backgrounds (100→50)
--color-success-*      Positive KPIs, confirmations, online status
--color-warning-*      Caution states, degraded performance
--color-danger-*       Errors, destructive actions, critical alerts
--color-info-*         Informational, help text, secondary actions
```

---

## Output Standards

### Code Output Rules
- Always output **complete, runnable** code — no placeholders like `// your content here`
- Include all states: hover, focus, active, disabled, loading, empty, error
- CSS: use custom properties (variables), never hardcoded values
- React: use Tailwind utility classes; shadcn/ui components where applicable
- Always include responsive breakpoints (mobile-first)
- Dark mode support via `prefers-color-scheme` or `.dark` class

### Review Output Rules
When in REVIEW mode, always produce:
1. **Score** — numeric rating per dimension (see `references/review.md`)
2. **Critical issues** — must-fix items that block professional status
3. **Improvements** — ranked list with before/after code snippets
4. **Upgraded version** — full reworked implementation, not just notes

### Quality Gate (before any output)
- [ ] 8pt grid compliance — all spacing is multiples of 4px
- [ ] Typography hierarchy clear — 3 or fewer visual levels per section
- [ ] Color contrast ≥ 4.5:1 for body text, ≥ 3:1 for large text (WCAG AA)
- [ ] Interactive elements ≥ 44×44px touch target
- [ ] All states defined (default, hover, active, focus, disabled)
- [ ] No orphaned styles — all values from token system
- [ ] Responsive — tested at 375px, 768px, 1280px, 1440px

---

## Reference Files Index

```
ui-designer-skill/
├── SKILL.md                      ← You are here
└── references/
    ├── create.md                 ← Creating UIs from scratch: process, patterns, components
    ├── review.md                 ← Audit framework, scoring rubric, critique templates
    ├── upgrade.md                ← Upgrade patterns: amateur→professional transformations
    ├── dashboard.md              ← Dashboard & KPI design: layout, metrics, chart selection
    ├── design-system.md          ← Tokens, component APIs, Storybook, documentation
    ├── data-viz.md               ← Charts, tables, analytics screens, data density
    └── accessibility.md          ← WCAG 2.2, keyboard nav, screen readers, color contrast
```
