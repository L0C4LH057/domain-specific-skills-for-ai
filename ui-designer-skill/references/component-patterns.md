# Production Component Patterns

## Empty States

The most overlooked component. Every list, table, and chart needs one.

```html
<!-- Standard empty state -->
<div class="empty-state">
  <div class="empty-state-icon">
    <svg><!-- contextually relevant icon --></svg>
  </div>
  <h3 class="empty-state-title">No [items] yet</h3>
  <p class="empty-state-desc">
    [One sentence explaining how items appear here or what this section does.]
  </p>
  <button class="btn btn-primary btn-md">Create your first [item]</button>
</div>
```

```css
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-16) var(--space-8);
  gap: var(--space-3);
  text-align: center;
}
.empty-state-icon {
  width: 48px; height: 48px;
  color: var(--color-text-muted);
  margin-bottom: var(--space-2);
}
.empty-state-title { font-size: var(--text-lg); font-weight: var(--font-semibold); }
.empty-state-desc  { font-size: var(--text-sm); color: var(--color-text-secondary); max-width: 320px; }
```

---

## Skeleton Loaders

Never show spinners for content that has a known shape. Use skeletons.

```css
.skeleton {
  background: linear-gradient(90deg,
    var(--color-border) 25%,
    #f0f0f0 50%,
    var(--color-border) 75%
  );
  background-size: 200% 100%;
  animation: skeleton-shimmer 1.5s infinite;
  border-radius: var(--radius-sm);
}

@keyframes skeleton-shimmer {
  0%   { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

/* Dark mode */
[data-theme="dark"] .skeleton {
  background: linear-gradient(90deg, #1E293B 25%, #2D3748 50%, #1E293B 75%);
  background-size: 200% 100%;
}

/* Usage */
.skeleton-text  { height: 14px; border-radius: var(--radius-sm); }
.skeleton-title { height: 20px; border-radius: var(--radius-sm); }
.skeleton-kpi   { height: 40px; border-radius: var(--radius-sm); }
.skeleton-chart { height: 200px; border-radius: var(--radius-lg); }
.skeleton-avatar { width: 40px; height: 40px; border-radius: 50%; }
```

---

## Toast Notifications

```css
.toast-container {
  position: fixed;
  bottom: var(--space-6);
  right: var(--space-6);
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  z-index: 9999;
  pointer-events: none;
}

.toast {
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  background: var(--color-text-primary);  /* inverse of page */
  color: var(--color-bg);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-xl);
  font-size: var(--text-sm);
  max-width: 380px;
  pointer-events: all;
  animation: toast-in 200ms ease-out;
}

@keyframes toast-in {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}

.toast-success { border-left: 3px solid var(--color-success); }
.toast-error   { border-left: 3px solid var(--color-error); }
.toast-warning { border-left: 3px solid var(--color-warning); }
.toast-info    { border-left: 3px solid var(--color-info); }
```

---

## Confirmation Dialog Pattern

```html
<div class="dialog-overlay">
  <div class="dialog" role="dialog" aria-modal="true"
       aria-labelledby="dialog-title" aria-describedby="dialog-desc">

    <div class="dialog-header">
      <div class="dialog-icon dialog-icon-danger">
        <svg><!-- warning icon --></svg>
      </div>
      <div>
        <h2 id="dialog-title" class="dialog-title">Delete workspace</h2>
        <p id="dialog-desc" class="dialog-desc">
          This will permanently delete <strong>Acme Corp</strong> and all its data.
          This action cannot be undone.
        </p>
      </div>
    </div>

    <div class="dialog-actions">
      <button class="btn btn-secondary btn-md">Cancel</button>
      <button class="btn btn-danger btn-md">Delete workspace</button>
    </div>
  </div>
</div>
```

```css
.dialog-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.4);
  backdrop-filter: blur(4px);
  display: flex; align-items: center; justify-content: center;
  z-index: 1000;
  padding: var(--space-4);
}

.dialog {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-2xl);
  box-shadow: var(--shadow-xl);
  padding: var(--space-6);
  width: 100%;
  max-width: 440px;
  animation: dialog-in 150ms ease-out;
}

@keyframes dialog-in {
  from { opacity: 0; transform: scale(0.97) translateY(-4px); }
  to   { opacity: 1; transform: scale(1) translateY(0); }
}

.dialog-header { display: flex; gap: var(--space-4); margin-bottom: var(--space-6); }
.dialog-icon   { width: 40px; height: 40px; border-radius: var(--radius-lg);
                 display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.dialog-icon-danger { background: var(--color-error-light); color: var(--color-error); }
.dialog-title  { font-size: var(--text-lg); font-weight: var(--font-semibold); }
.dialog-desc   { font-size: var(--text-sm); color: var(--color-text-secondary); margin-top: var(--space-1); }
.dialog-actions { display: flex; justify-content: flex-end; gap: var(--space-3); }
```

---

## Command Palette (Cmd+K)

Essential for power-user SaaS products.

```html
<div class="cmdk-overlay">
  <div class="cmdk" role="dialog" aria-modal="true" aria-label="Command palette">
    <div class="cmdk-input-wrap">
      <svg class="cmdk-search-icon" aria-hidden="true"><!-- search --></svg>
      <input class="cmdk-input" type="text"
             placeholder="Search or run a command..."
             autofocus
             aria-label="Search commands" />
      <kbd class="cmdk-esc">esc</kbd>
    </div>

    <div class="cmdk-list" role="listbox">
      <div class="cmdk-group">
        <div class="cmdk-group-label">Navigation</div>
        <div class="cmdk-item" role="option">
          <svg class="cmdk-item-icon"><!-- icon --></svg>
          Go to Dashboard
          <kbd class="cmdk-shortcut">G D</kbd>
        </div>
      </div>
    </div>
  </div>
</div>
```

```css
.cmdk-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex; align-items: flex-start; justify-content: center;
  padding-top: 15vh;
  z-index: 9999;
}

.cmdk {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-xl);
  width: 100%; max-width: 560px;
  overflow: hidden;
}

.cmdk-input-wrap {
  display: flex; align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  border-bottom: 1px solid var(--color-border);
}
.cmdk-input {
  flex: 1; border: none; background: transparent;
  font-size: var(--text-md); outline: none;
  color: var(--color-text-primary);
}

.cmdk-item {
  display: flex; align-items: center; gap: var(--space-3);
  padding: var(--space-2) var(--space-4);
  font-size: var(--text-sm); cursor: pointer;
  border-radius: var(--radius-md);
  margin: 1px var(--space-2);
}
.cmdk-item:hover, .cmdk-item[aria-selected="true"] {
  background: var(--color-bg);
}

.cmdk-shortcut {
  margin-left: auto;
  font-size: 11px;
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: 4px;
  padding: 1px 5px;
  color: var(--color-text-secondary);
}
```

---

## Filter Bar Pattern

```html
<div class="filter-bar">
  <div class="filter-bar-left">
    <div class="search-input-wrap">
      <svg class="search-icon" aria-hidden="true"><!-- search --></svg>
      <input type="search" placeholder="Search..." class="search-input" />
    </div>

    <div class="filter-group">
      <select class="filter-select" aria-label="Filter by status">
        <option value="">All statuses</option>
        <option value="active">Active</option>
        <option value="inactive">Inactive</option>
      </select>
    </div>

    <!-- Active filter chips -->
    <div class="filter-chips">
      <div class="filter-chip">
        Status: Active
        <button type="button" aria-label="Remove status filter">×</button>
      </div>
    </div>
  </div>

  <div class="filter-bar-right">
    <span class="filter-count">24 results</span>
    <button class="btn btn-ghost btn-sm">Export</button>
  </div>
</div>
```
