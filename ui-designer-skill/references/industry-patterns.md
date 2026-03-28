# Industry-Specific UI Patterns

## SaaS / B2B Application

### Design Characteristics
- Clean, professional, neutral palette (not playful)
- Information-dense but organized
- Feature-rich with discoverability (tooltips, progressive disclosure)
- Sidebar navigation (not top-nav, which wastes vertical space)
- Consistent with design system throughout

### Must-Have Patterns
- **Command palette** (Cmd+K) — for power users; Linear, Vercel, GitHub all have this
- **Keyboard shortcuts** — document them; show in tooltips
- **Bulk actions** — when table rows are selected
- **Inline editing** — click a value to edit without navigating away
- **Optimistic UI** — update instantly, sync in background
- **Collaborative indicators** — if real-time: show who else is viewing
- **Activity / audit log** — enterprise requirement
- **Role-based UI** — hide/disable features based on permissions (don't just show errors)

### SaaS Pricing Page Pattern
```
Pricing card hierarchy:
- Most popular: border highlight, badge, slightly taller
- CTA: primary for popular, secondary for others
- Feature list: checkmarks for included, muted dash for excluded
- Annual vs monthly toggle at top
```

### Onboarding Patterns
- Progress steps (not a wall of form fields)
- Empty states with calls-to-action (not just blank screens)
- Contextual tooltips on first visit
- Sample data / demo mode for new users

---

## Analytics & Data Platforms

### Design Characteristics
- Dense, information-rich layouts
- Sidebar filters + main canvas
- Multiple chart types in one view
- Table-heavy with sorting/filtering
- Dark mode common (reduces eye strain for long sessions)

### Key Patterns
```
Filter sidebar:     Left, 240–280px wide, collapsible
Chart grid:         2–3 columns, variable row heights
Time range picker:  Top right, presets + custom range
Data freshness:     "Updated 2 minutes ago" — always visible
Comparison mode:    vs previous period, vs target, vs cohort
Drill-down:         Click any chart → see underlying data
Export:             CSV, PNG, share link — always available
```

### Color Encoding for Analytics
```
Performance indicators:
  Well above target:  #059669 (green)
  On track:           #10B981 (lighter green)
  At risk:            #D97706 (amber)
  Critical:           #DC2626 (red)
  No data:            #9CA3AF (gray)
```

---

## Fintech / Financial Software

### Design Characteristics
- Trust signals everywhere (security badges, certifications)
- Conservative color palette (navy, dark blue, gray — not bright colors)
- Precision typography (tabular numbers throughout)
- Clear disclosure language
- Audit trails and confirmations for all actions

### Critical Fintech Patterns
```
Money display:
  Always show currency symbol: $1,234.56 (not 1234.56)
  Negative values: red AND parentheses: ($234.56)
  Large values: $1.2M, $45.8B (abbreviated with full on hover)
  Never truncate: show all decimals for transactions

Transaction states:
  Pending   → amber badge
  Completed → green badge
  Failed    → red badge
  Cancelled → gray badge (strikethrough row)

Confirmation dialogs:
  ALL destructive financial actions need:
  1. Clear summary of what will happen
  2. Amount/account confirmation
  3. "This cannot be undone" warning
  4. Two-step: review → confirm
```

### Security Indicators
```html
<!-- Always visible in fintech UI -->
<div class="security-bar">
  <svg aria-hidden="true"><!-- lock icon --></svg>
  <span>256-bit SSL encrypted</span>
  <span class="separator">·</span>
  <span>Bank-level security</span>
</div>
```

---

## Healthcare / HealthTech

### Design Characteristics
- Calm, trustworthy palette (blues, greens — avoid alarming reds except for critical alerts)
- Very high accessibility compliance (patient users may have disabilities)
- Large touch targets (users may be wearing gloves)
- Clear visual hierarchy — critical information first
- Avoid medical jargon where possible

### Critical Health UI Rules
```
Status severity system:
  CRITICAL/Emergency: Red background (#FEE2E2), loud alert
  WARNING/Urgent:     Amber (#FEF3C7), visible badge
  NORMAL:             Green indicator, minimal visual weight
  INFO:               Blue (#EFF6FF), informational

Alert fatigue rule:
  Only 3 alert severity levels — Critical, Warning, Info
  Too many alerts = all ignored (worse than no alerts)

Time-sensitive data:
  Always show timestamp with every data point
  Time zone MUST be explicit (not just "9:00 AM")
  "Last updated" always visible for vital signs / lab results

Patient safety rule:
  Destructive actions (delete, archive patient record) require typed confirmation
  Patient name confirmation: type "JOHN SMITH" to proceed
```

---

## Developer Tools & Admin Panels

### Design Characteristics
- Monospace fonts for code, technical values
- Dark mode as default (or equal first-class treatment)
- High information density accepted
- Terminal/console aesthetic for logs
- Copy-to-clipboard on all code/ID/key values

### Key Patterns
```
API key display:
  Partially masked: sk-***...***abc4
  "Copy" button inline — copy on click, shows "Copied!" for 2s

Log viewer:
  Monospace font, dark background
  Timestamp left-aligned: [2025-01-15 14:23:07]
  Level badges: ERROR (red), WARN (amber), INFO (blue), DEBUG (gray)
  Highlight on hover (full row)
  Expandable JSON payloads
  Filter by level, search by text, time range picker

Status page:
  Uptime %: large, prominent
  Incident history: chronological, most recent first
  Affected components: clearly labeled
  Each incident: title, status (investigating/monitoring/resolved), updates
```

### Admin Panel Navigation
```
Hierarchy:
  Overview / Dashboard
  Users & Permissions
  ├── Users
  ├── Roles
  └── Audit Log
  Configuration
  ├── Settings
  ├── Integrations
  └── API Keys
  Billing
  ├── Subscription
  ├── Invoices
  └── Usage
```

---

## E-Commerce Platforms

### Design Characteristics
- Visual-heavy (product images are the UI)
- Clear purchase flow
- Trust signals (reviews, security badges)
- Persistent cart indicator
- Mobile-first

### Conversion-Critical Patterns
```
Product listing:
  Image ratio: consistent (1:1 or 4:3, never mixed)
  Price: large, bold, front-and-center
  Sale price: original struck through, sale in red
  CTA button: fixed position, visible without scroll on mobile
  Stock indicator: "Only 3 left" creates urgency

Checkout flow:
  Progress indicator (Step 1 of 3)
  Never require account creation before checkout
  Guest checkout always available
  Payment options visible early (Apple Pay, PayPal icons)
  Order summary always visible (sticky sidebar on desktop)
  Clear error messages inline (not page-level)
```
