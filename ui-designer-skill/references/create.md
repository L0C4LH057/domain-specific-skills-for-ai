# CREATE Mode — Building UIs From Scratch

## Table of Contents
1. [Discovery Process](#discovery-process)
2. [Layout Patterns](#layout-patterns)
3. [Component Library](#component-library)
4. [Interaction Patterns](#interaction-patterns)
5. [Production Checklist](#production-checklist)

---

## Discovery Process

Before writing a single line of code, answer:

```
Product type:    [ ] SaaS app  [ ] Admin panel  [ ] Marketing  [ ] Mobile  [ ] Dashboard
User type:       [ ] Internal (power user)  [ ] External (consumer)  [ ] B2B enterprise
Density target:  [ ] Airy (consumer)  [ ] Balanced (SaaS)  [ ] Dense (data/enterprise)
Key action:      What is the ONE thing users must do on this screen?
Emotional tone:  [ ] Trustworthy  [ ] Energetic  [ ] Minimal  [ ] Premium  [ ] Playful
```

These answers drive every design decision. Write them in a comment at the top of your output.

---

## Layout Patterns

### App Shell (SaaS standard)
```html
<!--
  Pattern: Fixed sidebar + scrollable content area
  Used by: Linear, Notion, GitHub, Vercel, Figma
-->
<div class="app-shell">
  <aside class="sidebar">          <!-- 240–280px fixed width -->
    <div class="sidebar-header">   <!-- Logo + workspace switcher -->
    <nav class="sidebar-nav">      <!-- Primary navigation -->
    <div class="sidebar-footer">   <!-- User avatar + settings -->
  </aside>

  <div class="content-area">
    <header class="topbar">        <!-- Breadcrumb + actions + search -->
    <main class="page-content">    <!-- Scrollable page body -->
  </div>
</div>
```

```css
.app-shell {
  display: grid;
  grid-template-columns: 260px 1fr;
  height: 100vh;
  overflow: hidden;
}
.sidebar {
  display: flex;
  flex-direction: column;
  border-right: 1px solid var(--color-border);
  background: var(--color-surface-subtle);
  overflow-y: auto;
}
.content-area {
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.page-content {
  flex: 1;
  overflow-y: auto;
  padding: var(--space-8);
}
```

### Card Grid (Dashboard / Overview)
```css
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: var(--space-6);
}
/* Stat cards: always 4-up on desktop */
.stat-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: var(--space-4);
}
@media (max-width: 1024px) { .stat-grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 640px)  { .stat-grid { grid-template-columns: 1fr; } }
```

### Content + Sidebar (Settings / Detail pages)
```css
.two-column {
  display: grid;
  grid-template-columns: 1fr 320px;
  gap: var(--space-8);
  align-items: start;
}
```

---

## Component Library

### Button System
```css
/* Base */
.btn {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-weight: 500;
  font-size: 14px;
  line-height: 1;
  border-radius: var(--radius-md);
  border: 1px solid transparent;
  cursor: pointer;
  transition: all 120ms ease;
  white-space: nowrap;
  outline: none;
}
.btn:focus-visible {
  box-shadow: 0 0 0 3px var(--color-brand-ring);
}
.btn:disabled { opacity: 0.5; cursor: not-allowed; pointer-events: none; }

/* Sizes */
.btn-sm { height: 32px; padding: 0 12px; font-size: 13px; }
.btn-md { height: 36px; padding: 0 16px; }
.btn-lg { height: 40px; padding: 0 20px; font-size: 15px; }

/* Variants */
.btn-primary {
  background: var(--color-brand);
  color: white;
  border-color: var(--color-brand);
}
.btn-primary:hover { background: var(--color-brand-700); border-color: var(--color-brand-700); }

.btn-secondary {
  background: var(--color-surface);
  color: var(--color-text);
  border-color: var(--color-border);
}
.btn-secondary:hover { background: var(--color-surface-hover); }

.btn-ghost {
  background: transparent;
  color: var(--color-text-muted);
}
.btn-ghost:hover { background: var(--color-surface-hover); color: var(--color-text); }

.btn-danger {
  background: var(--color-danger);
  color: white;
  border-color: var(--color-danger);
}
```

### Form Controls
```css
/* Input */
.input {
  width: 100%;
  height: 36px;
  padding: 0 var(--space-3);
  font-size: 14px;
  color: var(--color-text);
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  outline: none;
  transition: border-color 150ms, box-shadow 150ms;
}
.input::placeholder { color: var(--color-text-placeholder); }
.input:hover  { border-color: var(--color-border-hover); }
.input:focus  {
  border-color: var(--color-brand);
  box-shadow: 0 0 0 3px var(--color-brand-ring);
}
.input.error  { border-color: var(--color-danger); }
.input.error:focus { box-shadow: 0 0 0 3px var(--color-danger-ring); }

/* Field wrapper */
.field       { display: flex; flex-direction: column; gap: var(--space-1-5); }
.field-label { font-size: 13px; font-weight: 500; color: var(--color-text); }
.field-hint  { font-size: 12px; color: var(--color-text-muted); }
.field-error { font-size: 12px; color: var(--color-danger); }
```

### Card
```css
.card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: var(--space-6);
  box-shadow: var(--shadow-sm);
}
.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-4);
  padding-bottom: var(--space-4);
  border-bottom: 1px solid var(--color-border);
}
.card-title { font-size: 15px; font-weight: 600; color: var(--color-text); }
.card-description { font-size: 13px; color: var(--color-text-muted); margin-top: var(--space-1); }
```

### Badge / Status Pill
```css
.badge {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 2px 8px;
  font-size: 12px;
  font-weight: 500;
  border-radius: 9999px;
  white-space: nowrap;
}
.badge-success { background: var(--color-success-subtle); color: var(--color-success-text); }
.badge-warning { background: var(--color-warning-subtle); color: var(--color-warning-text); }
.badge-danger  { background: var(--color-danger-subtle);  color: var(--color-danger-text);  }
.badge-neutral { background: var(--color-neutral-100);    color: var(--color-neutral-700);  }
.badge-brand   { background: var(--color-brand-subtle);   color: var(--color-brand-700);    }

/* Status dot */
.badge::before {
  content: "";
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: currentColor;
}
```

---

## Interaction Patterns

### Loading States (never skip these)
```css
/* Skeleton loader */
.skeleton {
  background: linear-gradient(
    90deg,
    var(--color-neutral-100) 25%,
    var(--color-neutral-200) 50%,
    var(--color-neutral-100) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: var(--radius-sm);
}
@keyframes shimmer { to { background-position: -200% 0; } }

/* Spinner */
.spinner {
  width: 20px; height: 20px;
  border: 2px solid var(--color-border);
  border-top-color: var(--color-brand);
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
```

### Empty States
```html
<!-- Every list, table, and chart needs this -->
<div class="empty-state">
  <div class="empty-icon"><!-- relevant SVG icon --></div>
  <h3 class="empty-title">No [items] yet</h3>
  <p class="empty-description">
    [What this section does]. [How to add the first item].
  </p>
  <button class="btn btn-primary">Add first [item]</button>
</div>
```

---

## Production Checklist

- [ ] All states implemented: default, hover, active, focus, disabled, loading, empty, error
- [ ] 8pt grid — every spacing value is 4, 8, 12, 16, 24, 32, 48, or 64px
- [ ] No z-index values above 9999 without comment
- [ ] Transitions on all interactive elements (120–200ms ease)
- [ ] `cursor: pointer` on all clickable elements
- [ ] `outline: none` only paired with `focus-visible` replacement
- [ ] All images have `alt` text
- [ ] Color contrast verified for all text
- [ ] Touch targets ≥ 44×44px on mobile
