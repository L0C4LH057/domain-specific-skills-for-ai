# Upgrade Patterns — Transforming UIs to Professional Standard

## The Upgrade Stack (apply in this order)

When upgrading an existing UI, apply these transformations sequentially.
Each layer builds on the previous one.

---

## Step 1: Establish the Token Layer

Before touching visuals, define design tokens. All values come from these — never hardcode.

```css
:root {
  /* Spacing (4pt grid) */
  --space-1:  4px;
  --space-2:  8px;
  --space-3:  12px;
  --space-4:  16px;
  --space-5:  20px;
  --space-6:  24px;
  --space-8:  32px;
  --space-10: 40px;
  --space-12: 48px;
  --space-16: 64px;

  /* Type scale (1.25 ratio) */
  --text-xs:   11px;
  --text-sm:   13px;
  --text-base: 14px;
  --text-md:   16px;
  --text-lg:   18px;
  --text-xl:   20px;
  --text-2xl:  24px;
  --text-3xl:  30px;
  --text-4xl:  36px;
  --text-5xl:  48px;

  /* Font weights */
  --font-regular: 400;
  --font-medium:  500;
  --font-semibold: 600;
  --font-bold:    700;

  /* Border radius */
  --radius-sm:  4px;
  --radius-md:  6px;
  --radius-lg:  8px;
  --radius-xl:  12px;
  --radius-2xl: 16px;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-xs:  0 1px 2px rgba(0,0,0,0.05);
  --shadow-sm:  0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04);
  --shadow-md:  0 4px 6px rgba(0,0,0,0.07), 0 2px 4px rgba(0,0,0,0.05);
  --shadow-lg:  0 10px 15px rgba(0,0,0,0.07), 0 4px 6px rgba(0,0,0,0.04);
  --shadow-xl:  0 20px 25px rgba(0,0,0,0.07), 0 10px 10px rgba(0,0,0,0.03);

  /* Colors */
  --color-bg:       #F9FAFB;
  --color-surface:  #FFFFFF;
  --color-surface-raised: #FFFFFF;
  --color-border:   #E5E7EB;
  --color-border-strong: #D1D5DB;

  --color-text-primary:   #111827;
  --color-text-secondary: #6B7280;
  --color-text-muted:     #9CA3AF;
  --color-text-disabled:  #D1D5DB;

  --color-brand:          #2563EB;  /* replace with actual brand */
  --color-brand-light:    #EFF6FF;
  --color-brand-dark:     #1D4ED8;

  --color-success:        #059669;
  --color-success-light:  #ECFDF5;
  --color-warning:        #D97706;
  --color-warning-light:  #FFFBEB;
  --color-error:          #DC2626;
  --color-error-light:    #FEF2F2;
  --color-info:           #2563EB;
  --color-info-light:     #EFF6FF;

  /* Transitions */
  --transition-fast: 100ms ease;
  --transition-base: 150ms ease;
  --transition-slow: 250ms ease;
}
```

---

## Step 2: Typography Upgrade

```css
/* Replace ALL font-size and font-weight declarations with token references */

body {
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  font-size: var(--text-base);
  font-weight: var(--font-regular);
  line-height: 1.5;
  color: var(--color-text-primary);
  -webkit-font-smoothing: antialiased;
}

h1 { font-size: var(--text-4xl); font-weight: var(--font-bold);    line-height: 1.2; letter-spacing: -0.025em; }
h2 { font-size: var(--text-2xl); font-weight: var(--font-semibold); line-height: 1.25; letter-spacing: -0.02em; }
h3 { font-size: var(--text-xl);  font-weight: var(--font-semibold); line-height: 1.3; letter-spacing: -0.015em; }
h4 { font-size: var(--text-lg);  font-weight: var(--font-semibold); line-height: 1.35; }
h5 { font-size: var(--text-md);  font-weight: var(--font-medium);   line-height: 1.4; }

/* Label / overline (for form labels, table headers, stat labels) */
.label {
  font-size: var(--text-xs);
  font-weight: var(--font-semibold);
  text-transform: uppercase;
  letter-spacing: 0.07em;
  color: var(--color-text-secondary);
}

/* Numeric (tabular figures for aligned numbers in tables/dashboards) */
.numeric {
  font-variant-numeric: tabular-nums;
  font-feature-settings: "tnum";
}
```

---

## Step 3: Button System Upgrade

```css
/* Base */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  line-height: 1;
  border-radius: var(--radius-md);
  border: 1px solid transparent;
  cursor: pointer;
  transition: all var(--transition-base);
  white-space: nowrap;
  user-select: none;
  text-decoration: none;
}

/* Sizes */
.btn-sm  { height: 32px; padding: 0 var(--space-3); font-size: var(--text-xs); }
.btn-md  { height: 36px; padding: 0 var(--space-4); }
.btn-lg  { height: 40px; padding: 0 var(--space-5); font-size: var(--text-base); }
.btn-xl  { height: 48px; padding: 0 var(--space-6); font-size: var(--text-md); }

/* Variants */
.btn-primary {
  background: var(--color-brand);
  color: #fff;
  box-shadow: 0 1px 2px rgba(0,0,0,0.1);
}
.btn-primary:hover { background: var(--color-brand-dark); box-shadow: var(--shadow-sm); }
.btn-primary:active { background: var(--color-brand-dark); transform: translateY(1px); box-shadow: none; }

.btn-secondary {
  background: var(--color-surface);
  color: var(--color-text-primary);
  border-color: var(--color-border);
  box-shadow: var(--shadow-xs);
}
.btn-secondary:hover { background: var(--color-bg); border-color: var(--color-border-strong); }

.btn-ghost {
  background: transparent;
  color: var(--color-text-secondary);
}
.btn-ghost:hover { background: var(--color-bg); color: var(--color-text-primary); }

.btn-danger {
  background: var(--color-error);
  color: #fff;
}
.btn-danger:hover { background: #B91C1C; }

/* States */
.btn:disabled, .btn[aria-disabled="true"] {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
}
.btn:focus-visible {
  outline: 2px solid var(--color-brand);
  outline-offset: 2px;
}
```

---

## Step 4: Card / Surface Upgrade

```css
/* Base card — use this everywhere instead of arbitrary borders/backgrounds */
.card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-xs);
}

.card-sm  { padding: var(--space-4); }
.card-md  { padding: var(--space-6); }
.card-lg  { padding: var(--space-8); }

/* Interactive card */
.card-interactive {
  cursor: pointer;
  transition: border-color var(--transition-base), box-shadow var(--transition-base);
}
.card-interactive:hover {
  border-color: var(--color-border-strong);
  box-shadow: var(--shadow-md);
}

/* Stat/KPI card — elevated look */
.card-stat {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-xl);
  padding: var(--space-6);
  box-shadow: var(--shadow-sm);
}
```

---

## Step 5: Form Input Upgrade

```css
.form-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.form-label {
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  color: var(--color-text-primary);
}

.form-input {
  height: 36px;
  padding: 0 var(--space-3);
  font-size: var(--text-sm);
  color: var(--color-text-primary);
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  outline: none;
  transition: border-color var(--transition-base), box-shadow var(--transition-base);
  width: 100%;
}
.form-input::placeholder { color: var(--color-text-muted); }
.form-input:hover  { border-color: var(--color-border-strong); }
.form-input:focus  {
  border-color: var(--color-brand);
  box-shadow: 0 0 0 3px rgba(37,99,235,0.12);
}
.form-input.error  {
  border-color: var(--color-error);
  box-shadow: 0 0 0 3px rgba(220,38,38,0.1);
}
.form-input:disabled {
  background: var(--color-bg);
  color: var(--color-text-muted);
  cursor: not-allowed;
}

.form-hint  { font-size: var(--text-xs); color: var(--color-text-secondary); }
.form-error { font-size: var(--text-xs); color: var(--color-error); }
```

---

## Step 6: Status Badge Upgrade

```css
.badge {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  padding: 2px var(--space-2);
  font-size: var(--text-xs);
  font-weight: var(--font-medium);
  border-radius: var(--radius-full);
  line-height: 1.5;
}

.badge-success { background: var(--color-success-light); color: var(--color-success); }
.badge-warning { background: var(--color-warning-light); color: var(--color-warning); }
.badge-error   { background: var(--color-error-light);   color: var(--color-error);   }
.badge-info    { background: var(--color-info-light);    color: var(--color-info);    }
.badge-neutral { background: var(--color-bg);            color: var(--color-text-secondary); border: 1px solid var(--color-border); }

/* With dot indicator */
.badge-dot::before {
  content: '';
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: currentColor;
  flex-shrink: 0;
}
```

---

## Step 7: Page Layout Upgrade

```css
/* App shell */
.app-shell {
  display: grid;
  grid-template-columns: 240px 1fr;  /* sidebar + main */
  grid-template-rows: auto 1fr;
  min-height: 100vh;
  background: var(--color-bg);
}

/* Page container */
.page {
  padding: var(--space-8) var(--space-8);
  max-width: 1440px;
  width: 100%;
}

/* Page header */
.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-4);
  margin-bottom: var(--space-8);
}

/* Grid layouts */
.grid-4  { display: grid; grid-template-columns: repeat(4, 1fr); gap: var(--space-6); }
.grid-3  { display: grid; grid-template-columns: repeat(3, 1fr); gap: var(--space-6); }
.grid-2  { display: grid; grid-template-columns: repeat(2, 1fr); gap: var(--space-6); }

/* Responsive */
@media (max-width: 1024px) { .grid-4 { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 640px)  { .grid-4, .grid-3, .grid-2 { grid-template-columns: 1fr; } }
```
