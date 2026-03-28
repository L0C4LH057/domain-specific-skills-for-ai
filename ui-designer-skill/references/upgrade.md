# UPGRADE Mode — Amateur → Professional Transformations

## Table of Contents
1. [Upgrade Philosophy](#upgrade-philosophy)
2. [Tier Classification](#tier-classification)
3. [Transformation Patterns](#transformation-patterns)
4. [Enterprise Standards Checklist](#enterprise-standards-checklist)
5. [SaaS Product Standards](#saas-product-standards)
6. [Reference Products by Category](#reference-products-by-category)

---

## Upgrade Philosophy

Upgrading a UI is not about decoration — it's about **communication clarity and user trust**.

The upgrade ladder:
```
Tier 1 (Amateur)    → Fix fundamentals: spacing, type, contrast
Tier 2 (Functional) → Add consistency: tokens, system, states
Tier 3 (Professional) → Refine density, hierarchy, polish
Tier 4 (Enterprise) → Accessibility, performance, governance
Tier 5 (Premium)    → Micro-interactions, delight, brand cohesion
```

When upgrading, always move through tiers in order. Polishing a UI with bad fundamentals is lipstick on a pig.

---

## Tier Classification

### How to identify which tier a UI is at:

**Tier 1 (Amateur) — signs:**
- Hardcoded colors, fonts, sizes throughout
- No spacing rhythm (arbitrary px values)
- Missing interactive states (hover, focus)
- Mixed font families without intentional pairing
- Text too small (< 13px body) or too large (32px body)
- Borders/shadows used decoratively without meaning

**Tier 2 (Functional) — signs:**
- Consistent spacing but not systematic
- One font family but inconsistent weights
- Hover states on buttons only, not other interactive elements
- Forms work but feel generic
- Color used but not as a system

**Tier 3 (Professional) — signs:**
- Clear spacing system (may not be strict 8pt)
- Type hierarchy clear but may have too many levels
- Most states covered
- Loading states present
- Mobile works but may have rough edges

**Tier 4 (Enterprise) — signs:**
- Strict design token usage
- Full state coverage including skeleton loading
- Accessibility score ≥ 85
- Consistent empty states
- Data tables sortable, filterable, paginated properly

**Tier 5 (Premium) — signs:**
- Motion design adds delight without distraction
- Brand feels alive
- Zero rough edges at any viewport
- Accessibility score 95+
- Performance ≤ 100ms interaction response

---

## Transformation Patterns

### Transform 1: Color System Upgrade
```css
/* BEFORE (Tier 1): scattered hex values */
.header  { background: #1a1a2e; }
.sidebar { background: #16213e; }
.btn     { background: #0f3460; }
.accent  { color: #e94560; }

/* AFTER (Tier 3+): token system */
:root {
  /* Brand */
  --color-brand-50:  #eff6ff;
  --color-brand-100: #dbeafe;
  --color-brand-500: #3b82f6;
  --color-brand-600: #2563eb;
  --color-brand-700: #1d4ed8;
  --color-brand-ring: rgba(59,130,246,0.3);

  /* Neutral (semantic) */
  --color-bg:             #ffffff;
  --color-bg-subtle:      #f8fafc;
  --color-surface:        #ffffff;
  --color-surface-raised: #ffffff;
  --color-border:         #e2e8f0;
  --color-border-strong:  #cbd5e1;

  /* Text */
  --color-text:           #0f172a;
  --color-text-secondary: #475569;
  --color-text-muted:     #94a3b8;
  --color-text-placeholder: #cbd5e1;

  /* Semantic */
  --color-success:        #22c55e;
  --color-success-subtle: #f0fdf4;
  --color-success-text:   #166534;
  --color-warning:        #f59e0b;
  --color-warning-subtle: #fffbeb;
  --color-warning-text:   #92400e;
  --color-danger:         #ef4444;
  --color-danger-subtle:  #fef2f2;
  --color-danger-text:    #991b1b;
  --color-danger-ring:    rgba(239,68,68,0.3);
  --color-info:           #3b82f6;
  --color-info-subtle:    #eff6ff;
  --color-info-text:      #1e40af;
}
```

### Transform 2: Typography Upgrade
```css
/* BEFORE (Tier 1) */
h1 { font-size: 24px; }
h2 { font-size: 20px; }
p  { font-size: 14px; }
small { font-size: 11px; }
/* mixing: font-size: 15px, 17px, 19px scattered inline */

/* AFTER (Tier 3+) */
:root {
  --font-sans: 'Geist', 'Inter', system-ui, sans-serif;
  --font-mono: 'Geist Mono', 'Fira Code', monospace;

  --text-xs:   12px;
  --text-sm:   13px;
  --text-base: 14px;
  --text-md:   16px;
  --text-lg:   18px;
  --text-xl:   20px;
  --text-2xl:  24px;
  --text-3xl:  30px;
  --text-4xl:  36px;
  --text-5xl:  48px;

  --leading-tight:  1.25;
  --leading-snug:   1.375;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;

  --tracking-tight:  -0.02em;
  --tracking-snug:   -0.01em;
  --tracking-normal:  0;
  --tracking-wide:    0.025em;
  --tracking-wider:   0.05em;
  --tracking-widest:  0.1em;
}
```

### Transform 3: Shadow & Depth Upgrade
```css
/* BEFORE (Tier 1): arbitrary or no shadows */
box-shadow: 0 2px 10px rgba(0,0,0,0.1);  /* same shadow everywhere */

/* AFTER (Tier 3+): elevation system */
:root {
  --shadow-xs:  0 1px 2px 0 rgba(0,0,0,.05);
  --shadow-sm:  0 1px 3px 0 rgba(0,0,0,.1), 0 1px 2px -1px rgba(0,0,0,.1);
  --shadow-md:  0 4px 6px -1px rgba(0,0,0,.1), 0 2px 4px -2px rgba(0,0,0,.1);
  --shadow-lg:  0 10px 15px -3px rgba(0,0,0,.1), 0 4px 6px -4px rgba(0,0,0,.1);
  --shadow-xl:  0 20px 25px -5px rgba(0,0,0,.1), 0 8px 10px -6px rgba(0,0,0,.1);
  --shadow-2xl: 0 25px 50px -12px rgba(0,0,0,.25);
  --shadow-inner: inset 0 2px 4px 0 rgba(0,0,0,.05);
}
/* Usage: cards get --shadow-sm, modals get --shadow-xl, tooltips get --shadow-md */
```

### Transform 4: Border Radius Upgrade
```css
/* BEFORE: inconsistent */
border-radius: 4px;  /* on some buttons */
border-radius: 8px;  /* on some cards */
border-radius: 3px;  /* on badges */

/* AFTER: scale */
:root {
  --radius-none: 0;
  --radius-sm:   4px;   /* inputs, small elements */
  --radius-md:   6px;   /* buttons, badges, tags */
  --radius-lg:   8px;   /* cards, panels */
  --radius-xl:   12px;  /* modals, large cards */
  --radius-2xl:  16px;  /* marketing cards, feature blocks */
  --radius-full: 9999px; /* pills, avatars */
}
```

### Transform 5: Sidebar Navigation Upgrade
```css
/* BEFORE (Tier 1): basic list */
.nav-item { padding: 8px 16px; color: #333; display: block; }
.nav-item:hover { background: #eee; }
.nav-item.active { color: blue; font-weight: bold; }

/* AFTER (Tier 4): professional nav item */
.nav-item {
  display: flex;
  align-items: center;
  gap: var(--space-2-5);
  padding: 6px var(--space-3);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--color-text-secondary);
  transition: background 120ms, color 120ms;
  cursor: pointer;
  user-select: none;
  margin: 1px 0;
}
.nav-item:hover {
  background: var(--color-surface-hover);
  color: var(--color-text);
}
.nav-item.active {
  background: var(--color-brand-subtle);
  color: var(--color-brand-700);
  font-weight: 600;
}
.nav-item .nav-icon {
  width: 16px; height: 16px;
  opacity: 0.7;
  flex-shrink: 0;
}
.nav-item.active .nav-icon { opacity: 1; }
.nav-item .nav-badge {
  margin-left: auto;
  background: var(--color-neutral-100);
  color: var(--color-text-muted);
  font-size: 11px;
  padding: 1px 6px;
  border-radius: var(--radius-full);
}
```

---

## Enterprise Standards Checklist

### Security & Trust Signals
- [ ] Role-based access states visible (locked features shown, not hidden)
- [ ] Audit log access visible in navigation
- [ ] Session timeout warnings implemented
- [ ] Sensitive data masked by default (show/hide toggle)
- [ ] Confirmation dialogs for destructive actions

### Data & Performance
- [ ] Tables paginated (max 50 rows visible; 25 preferred)
- [ ] All data columns sortable
- [ ] Bulk actions available on table selection
- [ ] Export functionality present (CSV, PDF)
- [ ] Search and filter on all major lists
- [ ] Real-time indicators clearly marked (live vs cached data)

### Scalability
- [ ] Long strings truncated with ellipsis + tooltip
- [ ] Empty states for every list/table
- [ ] Error states for every data source
- [ ] Works with 0 items, 1 item, 100 items, 10,000 items

### Administration
- [ ] Settings clearly separated from operational UI
- [ ] User management section follows standard pattern
- [ ] Notification preferences accessible
- [ ] API key / integration management present

---

## SaaS Product Standards

### Onboarding / First-Run Experience
```
1. Welcome state — personalized, shows what to do first
2. Progress indicator — how complete is setup? (e.g., "3/5 steps done")
3. Sample/demo data — never show empty state to new users without a way forward
4. Contextual help — tooltips, walkthroughs, not just a help docs link
```

### Navigation Patterns (follow these conventions)
```
Top-level:    Sidebar items (max 7)
Second-level: Sub-navigation (tabs or nested sidebar items)
Third-level:  Never in nav — use page structure instead
Settings:     Always last item in sidebar with gear icon
Profile/Account: Always bottom-left of sidebar
Notifications: Bell icon top-right of topbar
Search:       Cmd+K global shortcut + topbar input
```

### Pricing / Upgrade Prompts
```css
/* Feature gate — professional pattern */
.feature-locked {
  position: relative;
  pointer-events: none;
  filter: blur(4px);
}
.feature-locked-overlay {
  position: absolute; inset: 0;
  display: flex; align-items: center; justify-content: center;
  background: rgba(255,255,255,0.8);
  backdrop-filter: blur(2px);
  border-radius: var(--radius-lg);
}
```

---

## Reference Products by Category

| Category | Reference Products | Key Design Traits |
|---|---|---|
| **SaaS Dashboard** | Linear, Vercel, Planetscale | Clean sidebar, data-dense but airy, strong typography |
| **Analytics** | Mixpanel, Amplitude, Posthog | Chart-first, comparison-focused, drill-down patterns |
| **Admin Panel** | Retool, Appsmith, Forest Admin | Dense tables, bulk actions, filter-first |
| **Dev Tools** | GitHub, GitLab, Supabase | Code-first, dark-mode native, technical density |
| **CRM / Sales** | Salesforce Lightning, HubSpot, Attio | Pipeline views, activity feeds, relationship graphs |
| **Finance** | Stripe, Brex, Mercury | Trust-first, precision typography, calm palette |
| **Marketing** | Webflow, Framer, Mailchimp | Creative, expressive, visual-first |
| **Data Warehouse** | Snowflake, dbt Cloud, Databricks | Query-centric, schema trees, dark-mode preferred |
