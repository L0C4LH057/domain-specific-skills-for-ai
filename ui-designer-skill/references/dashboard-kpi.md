# Dashboard & KPI Design Reference

## Dashboard Audit — 7-Point Framework

When reviewing a dashboard, evaluate all 7 points before producing fixes.

### Point 1: Metric Hierarchy
Every dashboard has a hierarchy. Are the most important metrics visually dominant?

```
Tier 1 (Hero):  1–3 primary KPIs — biggest, most prominent, top-left or top-center
Tier 2 (Support): 4–8 secondary metrics — medium, below or beside hero
Tier 3 (Detail): charts, trends, tables — provide context for tier 1 & 2
```

**Failure signs:**
- All metrics the same size → no hierarchy
- 12+ KPI cards all equally weighted → cognitive overload
- Most important metric buried below the fold

**Fix:** Choose 1–3 hero metrics. Give them 3–4x the visual weight of secondary metrics.

---

### Point 2: KPI Card Design Standard

**Anatomy of a professional KPI card:**
```
┌─────────────────────────────────┐
│ REVENUE                   [ⓘ]  │  ← label: uppercase, muted, 11-12px
│                                 │
│  $2,847,392                     │  ← value: 32-48px, bold, tabular nums
│                                 │
│  ↑ 12.4%  vs last month         │  ← trend: colored arrow + %, muted context
│                                 │
│  ████████░░  Target: $3M        │  ← optional: progress toward goal
└─────────────────────────────────┘
```

**CSS for KPI card:**
```css
.kpi-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-xl);
  padding: var(--space-6);
  box-shadow: var(--shadow-sm);
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.kpi-label {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.07em;
  text-transform: uppercase;
  color: var(--color-text-secondary);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.kpi-value {
  font-size: 36px;
  font-weight: 700;
  line-height: 1.1;
  color: var(--color-text-primary);
  font-variant-numeric: tabular-nums;
  letter-spacing: -0.02em;
}

.kpi-trend {
  font-size: 13px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 4px;
}
.kpi-trend.up   { color: var(--color-success); }
.kpi-trend.down { color: var(--color-error); }
.kpi-trend.neutral { color: var(--color-text-secondary); }

.kpi-context {
  font-size: 12px;
  color: var(--color-text-muted);
  margin-top: 2px;
}
```

---

### Point 3: Trend Indicators — Rules

Never show a number without context. Every KPI needs at least one of:

| Context type | Example | When to use |
|---|---|---|
| Period comparison | ↑ 12.4% vs last month | Always |
| Absolute change | +$42,300 | When magnitude matters |
| Target progress | 71% of goal | When there's a target |
| Sparkline trend | ▁▃▅▇▆▄ | When direction over time matters |
| Peer comparison | Rank #2 of 5 regions | For competitive contexts |

**Color rules for trend:**
```
UP + good:    green   (#059669)   — e.g., revenue up
UP + bad:     red     (#DC2626)   — e.g., churn rate up
DOWN + good:  green   (#059669)   — e.g., cost down
DOWN + bad:   red     (#DC2626)   — e.g., conversion down
NEUTRAL:      gray    (#6B7280)   — e.g., headcount flat
```

Always clarify the direction meaning. "↑ 5%" is ambiguous — is that good or bad for this metric?

---

### Point 4: Chart Selection Guide

Choose the right chart for the data type:

| Data relationship | Best chart | Avoid |
|---|---|---|
| Change over time | Line chart | Pie chart |
| Comparing categories | Bar chart (vertical) | 3D charts |
| Comparing many categories | Horizontal bar | Clustered bar (>3 series) |
| Part-to-whole (≤5 parts) | Donut chart | Exploded pie |
| Part-to-whole (>5 parts) | Stacked bar | Pie chart |
| Correlation | Scatter plot | Line chart |
| Distribution | Histogram | Pie chart |
| Flow / funnel | Funnel chart | Bar chart |
| Geographic | Choropleth map | Bubble chart |
| Single progress | Progress bar or gauge | Pie chart |

**Critical chart design rules:**
- Remove all chart junk: 3D effects, gradient fills, decorative elements
- Start Y-axis at 0 (unless explicitly showing change, then annotate)
- Max 4–5 data series on a single chart — more = confusion
- Use color sparingly: 1–2 colors for single-series, then the semantic palette
- Always label axes with units (Revenue ($), Time (UTC), Users (#))
- Legend only if multiple series — place right or below, never floating

---

### Point 5: Dashboard Layout Patterns

**Pattern A: Executive Dashboard (C-suite / leadership)**
```
┌────────────────────────────────────────────────────────┐
│  Hero KPI (full width or 2-col span)                   │
├──────────┬──────────┬──────────┬──────────────────────┤
│  KPI 1   │  KPI 2   │  KPI 3   │  KPI 4               │
├──────────┴──────────┴──────────┴──────────────────────┤
│  Revenue Trend (line, 60% width)  │  By Channel (bar) │
├───────────────────────────────────┴───────────────────┤
│  Recent activity / alerts table                        │
└────────────────────────────────────────────────────────┘
Metrics count: 4–8 KPIs, 2–3 charts
```

**Pattern B: Operational Dashboard (team leads, managers)**
```
┌──────────┬──────────┬──────────┬──────────────────────┐
│  KPI 1   │  KPI 2   │  KPI 3   │  KPI 4               │
├──────────┴──────────┴──────────┴──────────────────────┤
│  Primary chart (trend)          │  Secondary chart      │
├─────────────────────────────────┴───────────────────── ┤
│  Data table (filterable, paginated)                    │
└────────────────────────────────────────────────────────┘
Metrics count: 6–12 KPIs, 3–5 charts
```

**Pattern C: Analytical Dashboard (analysts, power users)**
```
Sidebar filters | Main canvas (flexible grid)
More metrics, drill-down capable, dense layout
Metrics count: 12+ KPIs, many charts, raw data accessible
```

---

### Point 6: Data Table Design

Tables are the most abused component in dashboards. Apply these rules:

```css
.data-table {
  width: 100%;
  border-collapse: collapse;
  font-size: var(--text-sm);
}

.data-table thead tr {
  border-bottom: 2px solid var(--color-border);
}

.data-table th {
  padding: var(--space-3) var(--space-4);
  text-align: left;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--color-text-secondary);
  white-space: nowrap;
  cursor: pointer;
  user-select: none;
}

.data-table th.sortable:hover { color: var(--color-text-primary); }
.data-table th.sorted { color: var(--color-brand); }

.data-table td {
  padding: var(--space-3) var(--space-4);
  color: var(--color-text-primary);
  border-bottom: 1px solid var(--color-border);
  font-variant-numeric: tabular-nums;
}

.data-table tbody tr:hover { background: var(--color-bg); }
.data-table tbody tr:last-child td { border-bottom: none; }

/* Numeric columns — always right-align */
.data-table td.num, .data-table th.num { text-align: right; }

/* Column width guidelines */
/* ID/Status: 80-100px | Name: 180-220px | Number: 100-120px | Date: 120px | Actions: 80-100px */
```

**Table rules:**
- Numbers → right-align always
- Text → left-align always
- Status → center-align (with badge)
- Add column sorting indicators
- Sticky header on scroll for long tables
- Pagination or virtual scroll for > 50 rows
- Row hover state always present

---

### Point 7: Dashboard Color Encoding

For data visualization colors, use a purposeful, accessible palette:

```javascript
// Categorical colors (up to 8 series)
const categoricalColors = [
  '#2563EB',  // blue       — primary series
  '#7C3AED',  // violet     — secondary
  '#0891B2',  // cyan       — tertiary
  '#059669',  // emerald    — quaternary
  '#D97706',  // amber
  '#DC2626',  // red
  '#DB2777',  // pink
  '#6B7280',  // gray       — "other/misc"
];

// Sequential (single metric, intensity = magnitude)
// Use a single hue, vary lightness:
// #DBEAFE → #93C5FD → #3B82F6 → #1D4ED8 → #1E3A5F

// Diverging (positive vs negative, above/below target)
// Negative: #EF4444 → #FCA5A5 → neutral → #86EFAC → #16A34A :Positive
```

**Never:**
- Use red/green as only encoding (colorblind failure — also add icons/patterns)
- Use more than 8 categorical colors on one chart
- Use rainbow palettes
- Use colors with insufficient contrast against background

---

## KPI Prioritization Framework

When a dashboard has too many metrics, help the user prioritize:

### North Star Metric
One single metric that best represents the product's core value delivery.
Every other metric either influences it or is influenced by it.

### OMTM (One Metric That Matters) per team:
- Product team: DAU / MAU, Activation rate, Feature adoption
- Revenue team: MRR, ARR, Expansion MRR, Churn MRR
- Growth team: CAC, LTV, LTV:CAC ratio, Conversion rate
- Operations: Ticket resolution time, NPS, CSAT
- Engineering: DORA metrics, Error rate, P95 latency, Uptime

### The Pirate Funnel (AARRR) — for product dashboards:
```
Acquisition  → Users arrived
Activation   → Users experienced core value
Retention    → Users came back
Referral     → Users referred others
Revenue      → Users paid
```
Map each KPI to a funnel stage. If you can't, question whether it belongs on the dashboard.
