# UI Audit Framework — Review, Critique & Fix

## How to Run a UI Audit

Run through these 8 layers in order. Every issue gets a severity:
- 🔴 **Critical** — Blocks usability or is embarrassing in a professional context. Fix immediately.
- 🟠 **Major** — Noticeably degrades quality or UX. Fix before shipping.
- 🟡 **Minor** — Polish item. Fix when possible.

---

## Layer 1: Visual Hierarchy

**Check:**
- Is there a clear primary focal point on every screen?
- Does the type scale create clear H1 > H2 > H3 > body > caption hierarchy?
- Are CTAs visually dominant over secondary actions?
- Is there only ONE primary action per screen/card?

**Common failures:**
- 🔴 Everything is the same size — nothing is clearly primary
- 🔴 Multiple "primary" buttons competing on the same screen
- 🟠 Headlines and body text are too similar in weight/size
- 🟡 Supporting text isn't visually receded enough (needs lighter color, not just smaller size)

**Fix pattern:**
```
Hero metric:   48–72px, weight 700, primary color
Section title: 20–24px, weight 600, primary text
Card title:    16–18px, weight 600
Body:          14–15px, weight 400
Caption/label: 11–13px, weight 400–500, muted color (#6B7280 or similar)
```

---

## Layer 2: Spacing & Layout

**Check:**
- Is spacing derived from a consistent scale (4pt, 8pt, or 12pt grid)?
- Are related items grouped with tight spacing, and unrelated items separated with loose spacing (proximity principle)?
- Is there sufficient padding inside cards and containers?
- Are columns/grids consistent across the layout?

**Common failures:**
- 🔴 Random spacing (21px here, 13px there) — no underlying grid
- 🔴 Content touching container edges (insufficient padding)
- 🟠 Elements too tightly packed — no breathing room
- 🟠 Inconsistent padding between similar components (one card has 16px, another has 24px)
- 🟡 Sections not clearly separated — layout feels like one blob

**Spacing scale to enforce:**
```
4px   — icon gap, inline spacing
8px   — tight component spacing
12px  — component internal padding (small)
16px  — standard component padding
24px  — card padding, section gaps
32px  — major section separation
48px  — page section breaks
64px+ — hero / feature section breathing room
```

---

## Layer 3: Color System

**Check:**
- Is there a primary brand color used consistently for CTAs and key interactions?
- Are semantic colors (success/warning/error/info) consistent throughout?
- Is the color palette restrained (≤5 named colors + semantic set)?
- Does the background hierarchy use neutral shades correctly (page bg → card bg → elevated bg)?

**Common failures:**
- 🔴 Semantic colors inconsistent (red used for both danger AND decoration)
- 🔴 Too many brand colors (looks like a gradient accident)
- 🟠 Card backgrounds same color as page background — no depth
- 🟠 Links/actions not using brand color consistently
- 🟡 Hover states change background AND border AND text — too much change

**Professional color system:**
```
Page background:  #F9FAFB (light) | #0F172A (dark)
Card background:  #FFFFFF (light) | #1E293B (dark)
Elevated/modal:   #FFFFFF (light) | #293548 (dark)
Border:           #E5E7EB (light) | #334155 (dark)
Primary text:     #111827 (light) | #F1F5F9 (dark)
Secondary text:   #6B7280 (light) | #94A3B8 (dark)
Muted text:       #9CA3AF (light) | #64748B (dark)
Brand primary:    (client's brand)
Success:          #10B981
Warning:          #F59E0B
Error:            #EF4444
Info:             #3B82F6
```

---

## Layer 4: Typography

**Check:**
- Is only 1 typeface used (2 max: display + body)?
- Is the type scale harmonious (1.25x or 1.333x ratio between steps)?
- Are line-heights appropriate (1.5 for body, 1.2–1.3 for headings)?
- Is letter-spacing applied to labels/caps (0.05em) and headings (-0.02em)?

**Common failures:**
- 🔴 Using 3+ different fonts
- 🔴 Body text > 16px on dense UI (wastes space, looks bloated)
- 🔴 Body text < 13px anywhere (accessibility failure)
- 🟠 Headings at default letter-spacing (should be slightly tight: -0.01 to -0.03em)
- 🟠 All-caps labels with no letter-spacing (0.05–0.08em for caps readability)
- 🟡 Line-height too tight on body text (< 1.4)

---

## Layer 5: Component Consistency

**Check:**
- Do all buttons at the same hierarchy level look identical?
- Do all input fields follow the same pattern (border, radius, padding, label position)?
- Are all cards/panels using the same border, radius, and shadow style?
- Are icon sizes consistent (16px / 20px / 24px — not a mix of random sizes)?

**Common failures:**
- 🔴 Buttons with different border-radii on the same page
- 🔴 Some inputs have labels above, others have placeholder-only
- 🟠 Mix of bordered and borderless cards
- 🟠 Icons at 15px, 17px, 19px (random sizes, not on the scale)
- 🟡 One component has box-shadow, another identical component doesn't

---

## Layer 6: Interactive States

Every interactive element MUST define ALL states:

| Element | States Required |
|---|---|
| Button | default, hover, active/pressed, disabled, loading |
| Input/field | default, focus, filled, error, disabled |
| Link | default, hover, visited, focus |
| Table row | default, hover, selected |
| Card/item | default, hover, active/selected |
| Checkbox/Radio | unchecked, checked, indeterminate, disabled |

**Common failures:**
- 🔴 No focus ring (keyboard nav broken — also an a11y critical)
- 🔴 Disabled state same as enabled (users can't tell what's interactive)
- 🟠 Hover state only changes color (should also change cursor to pointer)
- 🟡 No loading state on async buttons

---

## Layer 7: Responsiveness & Density

**Check:**
- Does the layout work at 1440px (desktop), 1024px (laptop), 768px (tablet), 375px (mobile)?
- Is touch target size ≥ 44×44px for all interactive elements?
- Does the information density match the context (dense for power users, airy for consumers)?

**Density presets:**
```
Compact (power users, data tables):  padding: 8px 12px, font: 13px
Default (SaaS, enterprise):          padding: 12px 16px, font: 14px
Comfortable (consumer, marketing):   padding: 16px 24px, font: 15–16px
```

---

## Layer 8: Professionalism Checklist

Final scan for things that immediately signal amateur work:

- [ ] No default browser button/input styles remaining
- [ ] No placeholder images (grey boxes) in deliverables
- [ ] No lorem ipsum in final UI
- [ ] No emojis in professional enterprise UI
- [ ] No gradient text unless intentionally on-brand
- [ ] No box shadows that are too dark/harsh (use very low opacity: 0 1px 3px rgba(0,0,0,0.08))
- [ ] No underlined text used for decoration (only for actual links)
- [ ] No centered body text > 60 characters wide
- [ ] All icons from a single icon library (no mixing Heroicons + FontAwesome + Material)
- [ ] All images use consistent aspect ratios within the same grid

---

## Audit Report Format

When delivering an audit, use this format:

```markdown
## UI Audit Report

### Critical Issues (must fix)
1. [CRITICAL] Issue description — Impact: X — Fix: Y

### Major Issues (fix before shipping)
2. [MAJOR] Issue description — Impact: X — Fix: Y

### Minor Issues (polish)
3. [MINOR] Issue description — Fix: Y

### Upgrade Recommendations
- Recommendation A
- Recommendation B

### Upgraded Version
[Code or detailed spec follows]
```
