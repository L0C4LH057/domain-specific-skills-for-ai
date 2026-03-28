# Accessibility Reference — WCAG 2.2 & Inclusive Design

## Quick Audit Checklist (run on every UI)

### Level A (required — blocking issues)
- [ ] All images have `alt` text (decorative: `alt=""`)
- [ ] All form inputs have `<label>` or `aria-label`
- [ ] Page has a `<h1>` and logical heading hierarchy (no skipped levels)
- [ ] No content depends on color alone to convey meaning
- [ ] All interactive elements reachable by keyboard (Tab key)
- [ ] No keyboard traps (Escape closes all modals/dropdowns)

### Level AA (required for enterprise/SaaS)
- [ ] Text contrast ≥ 4.5:1 (body), ≥ 3:1 (large text ≥ 18px)
- [ ] UI component contrast ≥ 3:1 (buttons, inputs, icons)
- [ ] Focus indicators visible and have ≥ 3:1 contrast
- [ ] Error messages associated with their form field (aria-describedby)
- [ ] No content flashes more than 3 times per second
- [ ] Target size ≥ 24×24px (AA 2.2), preferably ≥ 44×44px

---

## Implementation Patterns

### Focus Management
```css
/* Always replace outline:none with custom focus-visible */
:focus { outline: none; }

:focus-visible {
  outline: 2px solid var(--color-brand);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}

/* High-contrast focus for dark backgrounds */
.on-dark:focus-visible {
  outline-color: white;
  box-shadow: 0 0 0 4px rgba(255,255,255,0.3);
}
```

### ARIA Patterns for Common Components

**Modal dialog:**
```html
<div role="dialog" aria-modal="true" aria-labelledby="modal-title"
     aria-describedby="modal-desc">
  <h2 id="modal-title">Confirm deletion</h2>
  <p id="modal-desc">This action cannot be undone.</p>
  <!-- Focus trap: Tab cycles through focusable elements inside -->
  <button autofocus>Cancel</button>
  <button>Delete</button>
</div>
```

**Data table:**
```html
<table role="grid" aria-label="User accounts" aria-rowcount="248">
  <caption class="sr-only">248 user accounts, sorted by name ascending</caption>
  <thead>
    <tr>
      <th scope="col" aria-sort="ascending">
        Name <button aria-label="Sort by name">↕</button>
      </th>
      <th scope="col" aria-sort="none">Email</th>
    </tr>
  </thead>
</table>
```

**Live KPI (real-time data):**
```html
<!-- Use aria-live to announce KPI updates to screen readers -->
<div aria-live="polite" aria-atomic="true">
  <span class="kpi-value">$124,580</span>
  <span class="sr-only">Monthly recurring revenue, updated</span>
</div>
```

**Loading state:**
```html
<button aria-busy="true" aria-disabled="true">
  <span aria-hidden="true" class="spinner"></span>
  <span>Saving...</span>
</button>
```

**Toast notifications:**
```html
<div role="alert" aria-live="assertive" aria-atomic="true" class="toast toast-error">
  <svg aria-hidden="true"><!-- error icon --></svg>
  <p>Failed to save changes. Please try again.</p>
</div>
```

### Screen Reader Utilities
```css
/* Hide visually but keep for screen readers */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0,0,0,0);
  white-space: nowrap;
  border: 0;
}

/* Show only on focus (skip nav links) */
.skip-link {
  position: absolute;
  top: -100%;
  left: var(--space-4);
  padding: var(--space-2) var(--space-4);
  background: var(--color-brand);
  color: white;
  border-radius: var(--radius-md);
  z-index: var(--z-tooltip);
  font-weight: var(--weight-semibold);
}
.skip-link:focus { top: var(--space-4); }
```

---

## Color Contrast Reference

| Combination | Required Ratio | Example |
|---|---|---|
| Body text on white | 4.5:1 | `#767676` on white = exactly 4.5:1 |
| Large text on white | 3:1 | `#959595` on white = exactly 3:1 |
| Text on brand-500 | Check! | White on `#3b82f6` = 3.9:1 (AA large only) |
| White on brand-600 | ✅ | White on `#2563eb` = 5.1:1 (AA) |
| Gray text on gray bg | Check! | `#6b7280` on `#f9fafb` = 4.6:1 ✅ |

**Tool**: Use `https://webaim.org/resources/contrastchecker/` or implement:
```js
function getContrastRatio(hex1, hex2) {
  const getLum = hex => {
    const rgb = parseInt(hex.slice(1), 16);
    const r = ((rgb >> 16) & 0xff) / 255;
    const g = ((rgb >>  8) & 0xff) / 255;
    const b = ((rgb >>  0) & 0xff) / 255;
    const toLinear = c => c <= 0.03928 ? c/12.92 : ((c+0.055)/1.055)**2.4;
    return 0.2126*toLinear(r) + 0.7152*toLinear(g) + 0.0722*toLinear(b);
  };
  const l1 = getLum(hex1), l2 = getLum(hex2);
  const lighter = Math.max(l1,l2), darker = Math.min(l1,l2);
  return (lighter + 0.05) / (darker + 0.05);
}
```

---

## Keyboard Navigation Patterns

```
Tab              → Next focusable element
Shift+Tab        → Previous focusable element
Enter/Space      → Activate button, link, checkbox
Arrow keys       → Navigate within: menus, tabs, radio groups, sliders
Escape           → Close modal, dropdown, tooltip
Home/End         → First/last item in a list
Page Up/Down     → Scroll or large step in sliders
```

### Dropdown Menu (WAI-ARIA pattern)
```html
<div>
  <button id="menu-btn" aria-haspopup="true" aria-expanded="false"
          aria-controls="menu">Options</button>
  <ul id="menu" role="menu" aria-labelledby="menu-btn" hidden>
    <li role="menuitem" tabindex="-1">Edit</li>
    <li role="menuitem" tabindex="-1">Delete</li>
  </ul>
</div>
<!-- Arrow keys navigate between menuitem elements -->
<!-- Escape closes and returns focus to trigger button -->
```
