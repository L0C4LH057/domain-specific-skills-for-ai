# Data Visualization Reference — Charts, Tables & Analytics

## Chart Selection Guide

### Decision Tree
```
What do you want to show?
├── Trend over time          → Line chart (multiple series), Area chart (single)
├── Compare values           → Bar chart (vertical), Horizontal bar (long labels)
├── Part-of-whole            → Donut chart (≤6 segments), Stacked bar (time series)
├── Distribution             → Histogram, Box plot
├── Correlation              → Scatter plot
├── Flow / conversion        → Funnel chart, Sankey diagram
├── Geographic               → Choropleth map, Bubble map
└── Single KPI over time     → Sparkline (inline), Area sparkline
```

### When NOT to use each chart
```
Pie chart      → Never for >6 segments; never when values are close; prefer donut
3D charts      → Never — adds complexity, loses accuracy, always has a 2D equiv
Dual-axis      → Use sparingly; only when units are truly incomparable
Gauge/speedometer → Avoid; wastes space; a number + delta communicates more
```

---

## Chart Implementation (Recharts / React)

### Line Chart (KPI trend)
```tsx
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="chart-tooltip">
      <p className="tooltip-label">{label}</p>
      {payload.map(p => (
        <div key={p.name} className="tooltip-item">
          <span className="tooltip-dot" style={{ background: p.color }} />
          <span className="tooltip-name">{p.name}:</span>
          <span className="tooltip-value">{formatValue(p.value)}</span>
        </div>
      ))}
    </div>
  );
};

<ResponsiveContainer width="100%" height={240}>
  <LineChart data={data} margin={{ top: 4, right: 4, bottom: 0, left: 0 }}>
    <CartesianGrid
      strokeDasharray="3 3"
      stroke="var(--color-border)"
      vertical={false}   /* horizontal grid only — less visual noise */
    />
    <XAxis
      dataKey="date"
      tick={{ fontSize: 12, fill: 'var(--color-text-muted)' }}
      axisLine={false}
      tickLine={false}
    />
    <YAxis
      tick={{ fontSize: 12, fill: 'var(--color-text-muted)' }}
      axisLine={false}
      tickLine={false}
      tickFormatter={formatValue}
      width={56}
    />
    <Tooltip content={<CustomTooltip />} />
    <Line
      type="monotone"
      dataKey="revenue"
      name="Revenue"
      stroke="var(--color-brand)"
      strokeWidth={2}
      dot={false}          /* no dots on line = cleaner */
      activeDot={{ r: 4, strokeWidth: 2, fill: 'var(--color-brand)' }}
    />
  </LineChart>
</ResponsiveContainer>
```

### Bar Chart (comparison)
```tsx
<ResponsiveContainer width="100%" height={200}>
  <BarChart data={data} barCategoryGap="30%">
    <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" vertical={false} />
    <XAxis dataKey="name" tick={{ fontSize: 12 }} axisLine={false} tickLine={false} />
    <YAxis tick={{ fontSize: 12 }} axisLine={false} tickLine={false} />
    <Tooltip content={<CustomTooltip />} />
    <Bar dataKey="value" fill="var(--color-brand)" radius={[4,4,0,0]} maxBarSize={40} />
  </BarChart>
</ResponsiveContainer>
```

### Sparkline (inline KPI trend)
```tsx
<ResponsiveContainer width={80} height={32}>
  <LineChart data={sparkData}>
    <Line type="monotone" dataKey="v" stroke="var(--color-brand)"
          strokeWidth={1.5} dot={false} />
  </LineChart>
</ResponsiveContainer>
```

---

## Data Tables (Enterprise Standard)

### Table Component Pattern
```html
<div class="table-wrapper">
  <div class="table-toolbar">
    <input class="input table-search" placeholder="Search...">
    <div class="table-filters">
      <button class="btn btn-secondary btn-sm">
        <svg><!-- filter icon --></svg>
        Filters
        <span class="badge badge-brand">2</span>
      </button>
      <button class="btn btn-secondary btn-sm">Columns</button>
    </div>
    <div class="table-actions">
      <button class="btn btn-secondary btn-sm" id="bulk-actions" hidden>
        Actions
      </button>
    </div>
  </div>

  <table class="table" aria-label="Accounts">
    <thead>
      <tr>
        <th class="th-check">
          <input type="checkbox" aria-label="Select all">
        </th>
        <th class="th sortable" aria-sort="ascending" data-col="name">
          Name
          <svg class="sort-icon"><!-- chevron --></svg>
        </th>
        <th class="th sortable" data-col="mrr">MRR</th>
        <th class="th">Status</th>
        <th class="th">Last active</th>
        <th class="th th-actions"></th>
      </tr>
    </thead>
    <tbody>
      <tr class="tr">
        <td class="td-check">
          <input type="checkbox" aria-label="Select row">
        </td>
        <td class="td">
          <div class="cell-primary">
            <img class="avatar" src="..." alt="">
            <div>
              <div class="cell-name">Acme Corp</div>
              <div class="cell-sub">acme.com</div>
            </div>
          </div>
        </td>
        <td class="td td-number">$4,200</td>
        <td class="td"><span class="badge badge-success">Active</span></td>
        <td class="td td-muted">2 hours ago</td>
        <td class="td td-actions">
          <button class="btn btn-ghost btn-sm">···</button>
        </td>
      </tr>
    </tbody>
  </table>

  <div class="table-footer">
    <span class="table-count">Showing 1–25 of 248 results</span>
    <div class="pagination">
      <button class="btn btn-secondary btn-sm" aria-label="Previous">‹</button>
      <button class="btn btn-secondary btn-sm active">1</button>
      <button class="btn btn-secondary btn-sm">2</button>
      <button class="btn btn-secondary btn-sm">3</button>
      <span>...</span>
      <button class="btn btn-secondary btn-sm">10</button>
      <button class="btn btn-secondary btn-sm" aria-label="Next">›</button>
    </div>
    <select class="input" style="width:auto">
      <option>25 per page</option>
      <option>50 per page</option>
      <option>100 per page</option>
    </select>
  </div>
</div>
```

```css
.table-wrapper { overflow: hidden; border-radius: var(--radius-lg); border: 1px solid var(--color-border); }
.table { width: 100%; border-collapse: collapse; }
.th {
  padding: var(--space-3) var(--space-4);
  text-align: left;
  font-size: var(--text-xs);
  font-weight: var(--weight-semibold);
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: var(--tracking-widest);
  background: var(--color-bg-subtle);
  border-bottom: 1px solid var(--color-border);
  white-space: nowrap;
}
.th.sortable { cursor: pointer; user-select: none; }
.th.sortable:hover { color: var(--color-text); }
.td {
  padding: var(--space-3) var(--space-4);
  font-size: var(--text-base);
  color: var(--color-text);
  border-bottom: 1px solid var(--color-border);
}
.tr:last-child .td { border-bottom: none; }
.tr:hover .td { background: var(--color-surface-hover); }
.tr.selected .td { background: var(--color-brand-subtle); }
.td-number { font-variant-numeric: tabular-nums; text-align: right; font-weight: var(--weight-medium); }
.td-muted  { color: var(--color-text-muted); font-size: var(--text-sm); }
.td-actions { width: 40px; text-align: right; }
```

---

## Number Formatting

```js
// Always format numbers for human readability in dashboards
const formatValue = (value, type = 'number') => {
  switch(type) {
    case 'currency':
      return new Intl.NumberFormat('en-US', {
        style: 'currency', currency: 'USD',
        maximumFractionDigits: value >= 1000 ? 0 : 2
      }).format(value);
    case 'compact':
      // 1,234,567 → $1.2M
      return new Intl.NumberFormat('en-US', {
        style: 'currency', currency: 'USD', notation: 'compact', maximumFractionDigits: 1
      }).format(value);
    case 'percent':
      return `${value >= 0 ? '+' : ''}${value.toFixed(1)}%`;
    case 'number':
      return new Intl.NumberFormat('en-US').format(value);
    default:
      return value;
  }
};
```
