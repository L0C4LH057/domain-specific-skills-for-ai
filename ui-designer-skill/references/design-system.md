# Design System Reference — Tokens, Components & Documentation

## Table of Contents
1. [Complete Token System](#complete-token-system)
2. [Component API Patterns](#component-api-patterns)
3. [Dark Mode](#dark-mode)
4. [Design System Documentation](#design-system-documentation)

---

## Complete Token System

### Full CSS Custom Properties (Copy-paste starter)
```css
:root {
  /* ─── Spacing ─────────────────────────────── */
  --space-px:  1px;
  --space-0-5: 2px;
  --space-1:   4px;
  --space-1-5: 6px;
  --space-2:   8px;
  --space-2-5: 10px;
  --space-3:   12px;
  --space-3-5: 14px;
  --space-4:   16px;
  --space-5:   20px;
  --space-6:   24px;
  --space-7:   28px;
  --space-8:   32px;
  --space-9:   36px;
  --space-10:  40px;
  --space-12:  48px;
  --space-14:  56px;
  --space-16:  64px;
  --space-20:  80px;
  --space-24:  96px;

  /* ─── Typography ──────────────────────────── */
  --font-sans:   'Geist', 'Inter', ui-sans-serif, system-ui, sans-serif;
  --font-mono:   'Geist Mono', 'Fira Code', ui-monospace, monospace;
  --font-display: var(--font-sans);

  --text-xs:   0.75rem;    /* 12px */
  --text-sm:   0.8125rem;  /* 13px */
  --text-base: 0.875rem;   /* 14px */
  --text-md:   1rem;       /* 16px */
  --text-lg:   1.125rem;   /* 18px */
  --text-xl:   1.25rem;    /* 20px */
  --text-2xl:  1.5rem;     /* 24px */
  --text-3xl:  1.875rem;   /* 30px */
  --text-4xl:  2.25rem;    /* 36px */
  --text-5xl:  3rem;       /* 48px */

  --weight-normal:   400;
  --weight-medium:   500;
  --weight-semibold: 600;
  --weight-bold:     700;
  --weight-extrabold:800;

  --leading-none:    1;
  --leading-tight:   1.25;
  --leading-snug:    1.375;
  --leading-normal:  1.5;
  --leading-relaxed: 1.625;
  --leading-loose:   2;

  --tracking-tighter: -0.05em;
  --tracking-tight:   -0.025em;
  --tracking-snug:    -0.015em;
  --tracking-normal:   0;
  --tracking-wide:     0.025em;
  --tracking-wider:    0.05em;
  --tracking-widest:   0.1em;

  /* ─── Border Radius ───────────────────────── */
  --radius-none: 0;
  --radius-sm:   0.25rem;  /* 4px */
  --radius-md:   0.375rem; /* 6px */
  --radius-lg:   0.5rem;   /* 8px */
  --radius-xl:   0.75rem;  /* 12px */
  --radius-2xl:  1rem;     /* 16px */
  --radius-3xl:  1.5rem;   /* 24px */
  --radius-full: 9999px;

  /* ─── Shadows ─────────────────────────────── */
  --shadow-xs:    0 1px 2px rgba(0,0,0,.05);
  --shadow-sm:    0 1px 3px rgba(0,0,0,.1), 0 1px 2px -1px rgba(0,0,0,.1);
  --shadow-md:    0 4px 6px -1px rgba(0,0,0,.1), 0 2px 4px -2px rgba(0,0,0,.1);
  --shadow-lg:    0 10px 15px -3px rgba(0,0,0,.1), 0 4px 6px -4px rgba(0,0,0,.1);
  --shadow-xl:    0 20px 25px -5px rgba(0,0,0,.1), 0 8px 10px -6px rgba(0,0,0,.1);
  --shadow-2xl:   0 25px 50px -12px rgba(0,0,0,.25);
  --shadow-inner: inset 0 2px 4px rgba(0,0,0,.05);
  --shadow-none:  none;

  /* ─── Z-Index Scale ───────────────────────── */
  --z-below:    -1;
  --z-base:      0;
  --z-raised:   10;
  --z-dropdown: 100;
  --z-sticky:   200;
  --z-overlay:  300;
  --z-modal:    400;
  --z-toast:    500;
  --z-tooltip:  600;

  /* ─── Transitions ─────────────────────────── */
  --transition-fast:   120ms ease;
  --transition-base:   200ms ease;
  --transition-slow:   300ms ease;
  --transition-spring: 400ms cubic-bezier(0.34, 1.56, 0.64, 1);

  /* ─── Breakpoints (for reference in JS) ───── */
  --screen-sm:  640px;
  --screen-md:  768px;
  --screen-lg:  1024px;
  --screen-xl:  1280px;
  --screen-2xl: 1536px;
}
```

### Semantic Color Tokens (Light Mode)
```css
:root {
  /* Backgrounds */
  --color-bg:             #ffffff;
  --color-bg-subtle:      #f8fafc;
  --color-bg-muted:       #f1f5f9;

  /* Surfaces (elevated) */
  --color-surface:        #ffffff;
  --color-surface-raised: #ffffff;
  --color-surface-overlay:#ffffff;
  --color-surface-hover:  #f8fafc;
  --color-surface-active: #f1f5f9;
  --color-surface-subtle: #f8fafc;

  /* Borders */
  --color-border:         #e2e8f0;
  --color-border-hover:   #cbd5e1;
  --color-border-strong:  #94a3b8;

  /* Text */
  --color-text:           #0f172a;
  --color-text-secondary: #475569;
  --color-text-muted:     #94a3b8;
  --color-text-placeholder:#cbd5e1;
  --color-text-disabled:  #e2e8f0;
  --color-text-inverse:   #ffffff;

  /* Brand */
  --color-brand:          #2563eb;
  --color-brand-hover:    #1d4ed8;
  --color-brand-subtle:   #eff6ff;
  --color-brand-muted:    #dbeafe;
  --color-brand-ring:     rgba(37,99,235,0.25);

  /* Semantic */
  --color-success:        #16a34a;
  --color-success-hover:  #15803d;
  --color-success-subtle: #f0fdf4;
  --color-success-muted:  #dcfce7;
  --color-success-text:   #166534;

  --color-warning:        #d97706;
  --color-warning-hover:  #b45309;
  --color-warning-subtle: #fffbeb;
  --color-warning-muted:  #fef3c7;
  --color-warning-text:   #92400e;

  --color-danger:         #dc2626;
  --color-danger-hover:   #b91c1c;
  --color-danger-subtle:  #fef2f2;
  --color-danger-muted:   #fee2e2;
  --color-danger-text:    #991b1b;
  --color-danger-ring:    rgba(220,38,38,0.25);

  --color-info:           #2563eb;
  --color-info-subtle:    #eff6ff;
  --color-info-text:      #1e40af;
}
```

---

## Dark Mode

```css
.dark, [data-theme="dark"] {
  --color-bg:             #0a0a0f;
  --color-bg-subtle:      #0f0f14;
  --color-bg-muted:       #161620;

  --color-surface:        #13131a;
  --color-surface-raised: #1a1a24;
  --color-surface-hover:  #1f1f2d;
  --color-surface-active: #252533;
  --color-surface-subtle: #0f0f14;

  --color-border:         #22222e;
  --color-border-hover:   #2e2e3f;
  --color-border-strong:  #3e3e56;

  --color-text:           #f0f0f7;
  --color-text-secondary: #9898b4;
  --color-text-muted:     #5a5a78;
  --color-text-placeholder:#3a3a55;

  --color-brand:          #4f8ef7;
  --color-brand-hover:    #6ba3fa;
  --color-brand-subtle:   #1a2035;
  --color-brand-muted:    #1e2a45;

  --color-success:        #22c55e;
  --color-success-subtle: #0d2018;
  --color-success-text:   #4ade80;

  --color-warning:        #f59e0b;
  --color-warning-subtle: #1f1800;
  --color-warning-text:   #fbbf24;

  --color-danger:         #f87171;
  --color-danger-subtle:  #2a1010;
  --color-danger-text:    #fca5a5;

  --shadow-sm:  0 1px 3px rgba(0,0,0,.4), 0 1px 2px rgba(0,0,0,.4);
  --shadow-md:  0 4px 6px -1px rgba(0,0,0,.4), 0 2px 4px -2px rgba(0,0,0,.4);
  --shadow-lg:  0 10px 15px -3px rgba(0,0,0,.5), 0 4px 6px -4px rgba(0,0,0,.4);
}
```

---

## Component API Patterns

### React Component API (enterprise standard)
```tsx
// ✅ Professional component API pattern
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger' | 'outline';
  size?: 'xs' | 'sm' | 'md' | 'lg';
  loading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  fullWidth?: boolean;
  asChild?: boolean;  // Radix UI pattern for polymorphism
}

// ✅ Compound component pattern
<Card>
  <Card.Header>
    <Card.Title>...</Card.Title>
    <Card.Description>...</Card.Description>
  </Card.Header>
  <Card.Body>...</Card.Body>
  <Card.Footer>...</Card.Footer>
</Card>
```

---

## Design System Documentation

### Component Documentation Template
```markdown
## ComponentName

Brief description of what it is and when to use it.

### Usage
\`\`\`tsx
<ComponentName variant="primary" size="md">Label</ComponentName>
\`\`\`

### Props
| Prop | Type | Default | Description |
|------|------|---------|-------------|
| variant | string | 'primary' | Visual style |
| size | string | 'md' | Component size |
| disabled | boolean | false | Disables interaction |

### Variants
[screenshots or live examples]

### Do / Don't
✅ Do: Use primary for the single most important action on a page
❌ Don't: Use multiple primary buttons in the same view

### Accessibility
- Keyboard: Tab to focus, Enter/Space to activate
- Screen reader: Announces label + role
- Touch target: Min 44×44px
```
