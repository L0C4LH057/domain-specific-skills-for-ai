# DASHBOARD Mode — KPI Design, Layout & Metrics

## Table of Contents
1. [Dashboard Design Principles](#dashboard-design-principles)
2. [KPI Card Anatomy](#kpi-card-anatomy)
3. [Layout Templates](#layout-templates)
4. [Metric Selection & Hierarchy](#metric-selection--hierarchy)
5. [KPI Anti-Patterns & Fixes](#kpi-anti-patterns--fixes)
6. [Full Dashboard Template](#full-dashboard-template)

---

## Dashboard Design Principles

### The Dashboard Contract
A dashboard makes ONE promise: **"You can understand the state of [thing] in under 30 seconds."**
If it takes longer, the dashboard has failed — regardless of how beautiful it is.

### The 4 Questions Every Dashboard Must Answer
1. **Health** — Is everything OK right now? (green/yellow/red)
2. **Trend** — Is it getting better or worse? (sparklines, delta %)
3. **Context** — Is the number good or bad? (vs target, vs period)
4. **Action** — If something is wrong, what do I do? (links, drilldowns)

### KPI Hierarchy (always enforce)
```
Level 1 — Primary KPIs    (3–4 max)  → 32–40px number, full card
Level 2 — Supporting KPIs (4–8 max)  → 24px number, half card
Level 3 — Detail metrics  (many)     → 14–16px, in tables/charts
```

---

## KPI Card Anatomy

### Professional KPI Card
```html
<div class="kpi-card">
  <div class="kpi-header">
    <span class="kpi-label">Monthly Recurring Revenue</span>
    <span class="kpi-period">vs last month</span>
  </div>
  <div class="kpi-body">
    <span class="kpi-value">$124,580</span>
    <div class="kpi-delta positive">
      <svg><!-- up arrow --></svg>
      <span>+12.3%</span>
    </div>
  </div>
  <div class="kpi-footer">
    <div class="kpi-sparkline"><!-- mini chart --></div>
    <span class="kpi-target">Target: $130,000 (96%)</span>
  </div>
</div>
```

```css
.kpi-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: var(--space-6);
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  box-shadow: var(--shadow-sm);
  transition: box-shadow 150ms;
}
.kpi-card:hover { box-shadow: var(--shadow-md); }

.kpi-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.kpi-label {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--color-text-secondary);
  letter-spacing: var(--tracking-wide);
}
.kpi-period {
  font-size: var(--text-xs);
  color: var(--color-text-muted);
}

.kpi-body {
  display: flex;
  align-items: flex-end;
  gap: var(--space-3);
}
.kpi-value {
  font-size: var(--text-4xl);
  font-weight: 700;
  color: var(--color-text);
  letter-spacing: var(--tracking-tight);
  line-height: 1;
}
.kpi-delta {
  display: flex;
  align-items: center;
  gap: 3px;
  font-size: var(--text-sm);
  font-weight: 600;
  padding: 2px 8px;
  border-radius: var(--radius-full);
  margin-bottom: 3px;  /* align with value baseline */
}
.kpi-delta.positive {
  background: var(--color-success-subtle);
  color: var(--color-success-text);
}
.kpi-delta.negative {
  background: var(--color-danger-subtle);
  color: var(--color-danger-text);
}
.kpi-delta.neutral {
  background: var(--color-neutral-100);
  color: var(--color-text-muted);
}

.kpi-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: var(--space-3);
  border-top: 1px solid var(--color-border);
}
.kpi-target {
  font-size: var(--text-xs);
  color: var(--color-text-muted);
}
```

### KPI Card Variants

**With target progress bar:**
```html
<div class="kpi-footer">
  <div class="progress-bar" style="--progress: 76%">
    <div class="progress-fill"></div>
  </div>
  <span class="kpi-target">76% of $10M target</span>
</div>
```
```css
.progress-bar {
  flex: 1;
  height: 4px;
  background: var(--color-neutral-200);
  border-radius: var(--radius-full);
  margin-right: var(--space-3);
  overflow: hidden;
}
.progress-fill {
  height: 100%;
  width: var(--progress);
  background: var(--color-brand);
  border-radius: var(--radius-full);
  transition: width 600ms ease;
}
```

**Status indicator variant (health monitoring):**
```html
<div class="kpi-card status-card">
  <div class="status-indicator online"></div>
  <div class="kpi-label">API Uptime</div>
  <div class="kpi-value">99.98%</div>
  <div class="kpi-sub">Last incident: 14 days ago</div>
</div>
```

---

## Layout Templates

### Executive Dashboard (4+2+1 grid)
```
┌─────────┬─────────┬─────────┬─────────┐  ← 4 primary KPIs
│  MRR    │  ARR    │  Churn  │  NPS    │
├─────────┴──────┬──┴──────┬──┴─────────┤  ← 2 charts
│ Revenue Trend  │Cohort   │ Pipeline  │
│    (line)      │Analysis │  (funnel) │
├────────────────┴────────┬┴───────────┤  ← detail table
│  Top Accounts           │  Activity │
│  (table)                │  (feed)   │
└─────────────────────────┴───────────┘
```

```css
.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-template-rows: auto auto 1fr;
  gap: var(--space-4);
  height: calc(100vh - var(--topbar-height));
  overflow-y: auto;
  padding: var(--space-6);
}
.kpi-row     { grid-column: 1/-1; display: grid; grid-template-columns: repeat(4,1fr); gap: var(--space-4); }
.chart-main  { grid-column: span 2; }
.chart-side  { grid-column: span 1; }
.table-main  { grid-column: span 3; }
.feed-side   { grid-column: span 1; }
```

### Operations Dashboard (dense, real-time)
```
┌──────────────────────────────────────────┐
│ SYSTEM HEALTH ● 3 services   ⚠ 1 warning │  ← status bar
├──────┬──────┬──────┬──────┬──────┬───────┤  ← 6 small KPIs
│ p50  │ p95  │ p99  │ Err% │ RPS  │ Queue │
├──────┴──────┴──────┴──────┴──────┴───────┤
│  Live Request Rate  │  Error Distribution │  ← 2 charts
├─────────────────────┴─────────────────────┤
│  Active Incidents (sortable table)        │  ← table
└───────────────────────────────────────────┘
```

---

## Metric Selection & Hierarchy

### The Metric Pyramid
```
        [1-2 Northstar Metrics]
       /  Revenue, DAU, NPS, etc.
      ——————————————————————————
    [3-5 Primary Drivers]
   /  Conversion, Retention, ARPU
  ————————————————————————————————
[6-12 Supporting Metrics]
/  Feature adoption, funnel steps, segment breakdowns
————————————————————————————————————————————————————
[Unlimited Diagnostic Metrics]
/  Error rates, latency, queue depth, cache hit rate
```

### Metrics by Product Type

**SaaS / Subscription:**
- Northstar: MRR, ARR, Net Revenue Retention
- Primary: New MRR, Churned MRR, Expansion MRR, CAC, LTV
- Supporting: Trial conversion, feature activation, support tickets

**E-commerce:**
- Northstar: Revenue, Gross Profit, Orders
- Primary: Conversion rate, AOV, Cart abandonment, ROAS
- Supporting: Product views, add-to-cart, checkout steps

**B2B Platform:**
- Northstar: Active seats, Contract value, NPS
- Primary: Adoption by feature, Time to value, Renewal rate
- Supporting: API usage, integrations active, admin logins

**Consumer App:**
- Northstar: DAU/MAU ratio, Retention D7/D30
- Primary: Sessions, Session length, Core action rate
- Supporting: Feature usage, notification opt-in, ratings

---

## KPI Anti-Patterns & Fixes

### Anti-Pattern 1: Numberless dashboard
```
❌ A pie chart showing "distribution" with no absolute values
❌ A bar chart with relative % but no totals
✅ Always show both: absolute value AND relative comparison
```

### Anti-Pattern 2: Context-free numbers
```
❌ "Users: 12,450"
✅ "Users: 12,450  ↑ 8.2% vs last month  •  Target: 15,000 (83%)"
```

### Anti-Pattern 3: Too many KPIs
```
❌ 12 KPI cards in the top row
✅ Max 4 primary KPIs; collapse rest into expandable section
```

### Anti-Pattern 4: Mixed time periods
```
❌ Card 1: "last 7 days"  Card 2: "last month"  Card 3: "last quarter"
✅ One global time picker; all KPIs use same period
```

### Anti-Pattern 5: No trend context
```
❌ Static number with no sparkline, no delta, no history
✅ Every KPI has at minimum: value + delta + time period
```

### Anti-Pattern 6: Color misuse
```
❌ Red for "low churn" (good thing, but coded as danger)
❌ Green for "high error rate"
✅ Color semantic: green = positive direction, red = negative direction
   (Note: "positive direction" is context-dependent — define per metric)
```

---

## Full Dashboard Template

```html
<!-- Professional SaaS Dashboard -->
<div class="dashboard">
  <header class="dashboard-header">
    <div class="dashboard-title">
      <h1>Overview</h1>
      <p class="dashboard-subtitle">All metrics · Updated 2 min ago</p>
    </div>
    <div class="dashboard-controls">
      <select class="time-picker">
        <option>Last 7 days</option>
        <option selected>Last 30 days</option>
        <option>Last quarter</option>
        <option>Custom range</option>
      </select>
      <button class="btn btn-secondary btn-sm">
        <svg><!-- download icon --></svg>
        Export
      </button>
    </div>
  </header>

  <!-- Primary KPIs -->
  <section class="kpi-row" aria-label="Primary metrics">
    <!-- 4x KPI cards using .kpi-card template above -->
  </section>

  <!-- Charts row -->
  <section class="charts-row">
    <div class="card chart-main">
      <div class="card-header">
        <div>
          <h3 class="card-title">Revenue Over Time</h3>
          <p class="card-description">MRR and ARR trend</p>
        </div>
        <div class="chart-legend"><!-- legend items --></div>
      </div>
      <div class="chart-container" style="height:240px">
        <!-- chart here -->
      </div>
    </div>
    <div class="card chart-side">
      <div class="card-header">
        <h3 class="card-title">Revenue by Segment</h3>
      </div>
      <div class="chart-container" style="height:240px">
        <!-- donut chart here -->
      </div>
    </div>
  </section>

  <!-- Detail table -->
  <section class="card">
    <div class="card-header">
      <h3 class="card-title">Top Accounts</h3>
      <div class="table-controls">
        <input class="input" placeholder="Search accounts...">
        <button class="btn btn-secondary btn-sm">Filters</button>
        <button class="btn btn-secondary btn-sm">Export</button>
      </div>
    </div>
    <!-- table here -->
  </section>
</div>
```
