# Data Visualization Reference

## Chart Type Selection Matrix

| You have... | You want to show... | Use |
|---|---|---|
| 1 metric over time | Trend | Line chart |
| 2–4 metrics over time | Comparison trend | Multi-line chart |
| Many time periods, 1 metric | Volume over time | Area chart |
| Categories, comparing values | Ranking | Horizontal bar |
| Categories, fewer than 8 | Comparison | Vertical bar |
| Stacked composition over time | Part-to-whole trend | Stacked area |
| Single part-to-whole, ≤5 parts | Proportion | Donut chart |
| Single part-to-whole, >5 parts | Proportion | Stacked bar |
| Two continuous variables | Relationship | Scatter plot |
| Single value vs target | Progress | Progress bar / gauge |
| Funnel / conversion steps | Flow | Funnel chart |
| Geographic data | Location | Choropleth map |
| Correlation matrix | Relationships | Heatmap |
| Distribution shape | Spread | Histogram / violin |

---

## Chart Design Rules

### The 10 Rules of Clean Data Visualization

1. **Remove all chart junk** — no 3D, no gradients on bars, no decorative backgrounds
2. **Direct labeling over legends** — label series at the end of lines when possible
3. **Reduce tick marks** — show 3–5 axis labels, not one per data point
4. **Use gridlines sparingly** — light horizontal only, no vertical gridlines
5. **Don't truncate Y-axis** — start at 0 unless showing rate of change (then annotate)
6. **Color with purpose** — one color for single series; highlight one series in multi-series
7. **Annotate the interesting points** — label peaks, drops, events directly on chart
8. **Consistent time format** — don't mix "Jan 24" and "January 2024" in the same chart
9. **Units always labeled** — axis title includes unit: "Revenue ($K)", "Users (#)"
10. **Responsive tooltips** — tooltip on hover must show exact value + label + date

### CSS Chart Container Pattern
```css
.chart-container {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-xl);
  padding: var(--space-6);
  box-shadow: var(--shadow-xs);
}

.chart-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: var(--space-4);
}

.chart-title {
  font-size: var(--text-base);
  font-weight: var(--font-semibold);
  color: var(--color-text-primary);
}

.chart-subtitle {
  font-size: var(--text-sm);
  color: var(--color-text-secondary);
  margin-top: var(--space-1);
}

.chart-body {
  height: 240px;  /* default; override per chart */
  position: relative;
}

.chart-footer {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  margin-top: var(--space-4);
  font-size: var(--text-xs);
  color: var(--color-text-secondary);
}
```

---

## Chart Library Recommendations

| Library | Best for | Trade-offs |
|---|---|---|
| Recharts | React dashboards; great defaults | Limited customization |
| Chart.js | Quick, any framework | Older API, canvas-based |
| D3.js | Custom/complex viz | High learning curve |
| Nivo | Beautiful, accessible React | Large bundle |
| Tremor | Enterprise React dashboards | Opinionated |
| ApexCharts | Interactive, feature-rich | Heavy |
| Vega-Lite | Declarative, research-grade | JSON-heavy |

**Recommendation for enterprise SaaS:** Recharts (React) or Chart.js (any framework).

---

## Sparklines (inline trend indicators)

Sparklines are miniature trend charts embedded in KPI cards or table cells.

```jsx
// React + Recharts sparkline
import { LineChart, Line, ResponsiveContainer, Tooltip } from 'recharts';

function Sparkline({ data, positive = true }) {
  const color = positive ? '#10B981' : '#EF4444';
  return (
    <ResponsiveContainer width="100%" height={40}>
      <LineChart data={data}>
        <Line
          type="monotone"
          dataKey="value"
          stroke={color}
          strokeWidth={2}
          dot={false}
          isAnimationActive={false}
        />
        <Tooltip
          contentStyle={{ fontSize: 12, padding: '4px 8px' }}
          labelFormatter={() => ''}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}
```

---

## Tooltip Design Standard

```css
.chart-tooltip {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: var(--space-3) var(--space-4);
  box-shadow: var(--shadow-lg);
  font-size: var(--text-sm);
  min-width: 140px;
}

.tooltip-label {
  font-size: var(--text-xs);
  color: var(--color-text-secondary);
  margin-bottom: var(--space-2);
  font-weight: var(--font-medium);
}

.tooltip-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
}

.tooltip-series-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.tooltip-value {
  font-weight: var(--font-semibold);
  font-variant-numeric: tabular-nums;
}
```

---

## Empty States for Charts

Never show blank space when data is missing. Every chart needs an empty state.

```html
<div class="chart-empty">
  <svg class="chart-empty-icon"><!-- relevant icon --></svg>
  <p class="chart-empty-title">No data yet</p>
  <p class="chart-empty-desc">Data will appear here once your first event is tracked.</p>
  <a class="btn btn-sm btn-secondary" href="/docs/tracking">Learn how to add data</a>
</div>
```

```css
.chart-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-12);
  gap: var(--space-2);
  text-align: center;
}
.chart-empty-icon { width: 40px; height: 40px; color: var(--color-text-muted); }
.chart-empty-title { font-weight: var(--font-semibold); color: var(--color-text-primary); }
.chart-empty-desc  { font-size: var(--text-sm); color: var(--color-text-secondary); max-width: 280px; }
```

---

## Number Formatting Standards

```javascript
// Revenue / currency
const formatCurrency = (n) => {
  if (n >= 1_000_000) return `$${(n/1_000_000).toFixed(1)}M`;
  if (n >= 1_000)     return `$${(n/1_000).toFixed(1)}K`;
  return `$${n.toLocaleString()}`;
};

// Percentages
const formatPct = (n, decimals = 1) => `${n.toFixed(decimals)}%`;

// Large numbers
const formatNum = (n) => {
  if (n >= 1_000_000) return `${(n/1_000_000).toFixed(1)}M`;
  if (n >= 1_000)     return `${(n/1_000).toFixed(1)}K`;
  return n.toLocaleString();
};

// Duration
const formatDuration = (ms) => {
  if (ms < 1000)   return `${ms}ms`;
  if (ms < 60000)  return `${(ms/1000).toFixed(1)}s`;
  return `${Math.floor(ms/60000)}m ${Math.floor((ms%60000)/1000)}s`;
};
```
