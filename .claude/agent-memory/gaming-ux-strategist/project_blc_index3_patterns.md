---
name: blc-index3-ux-patterns
description: Key UX decisions made building index3.html — BloodyCase main page prototype with competitor-informed improvements
metadata:
  type: project
---

## BloodyCase index3.html — UX Pattern Decisions (2026-05-18)

### Competitor Research Findings
- Key-Drop: Single nav row, "Get Free" hook as primary CTA, live online badge, novelty tags (NEW badge on cases). Dark teal dominant.
- Hellcase: Full-width live drop ticker below hero, 2-column hero with weapon art right, 5-6 col case grid, large circular bonus badge. 403 on fetch but well-known pattern.
- skin.fans: "Prime CS2 unboxing" — quality/premium copy positioning.

### Key UX Improvements Over index2.html
1. **Hero layout**: Changed from single-column left-only to 2-column grid — content left, real weapon <img> assets right. Eliminates placeholder boxes that were the main negative in index2.
2. **Weapon art**: Uses actual awp-asiimov.webp + ak-47-fire-serpent.webp + knife assets with CSS float animations + layered radial glow orbs behind them. Much higher visual fidelity.
3. **Case cards**: Added real case image <img> tags (case-dreams.png etc) replacing placeholder colored boxes. Added rarity distribution bar below price. Added HOT/NEW badges.
4. **Filter tabs**: Added above case grid — ALL/HOT/NEW/CS2/RUST/BUDGET. Key-Drop pattern.
5. **Recent Winners section**: 6-card grid using actual weapon art assets. Rarity-colored skin names.
6. **First Deposit Banner**: Full-width green gradient panel with large +25% circle, positioned before join section. Converts warm visitors.
7. **Footer**: Expanded from 1-row to full 4-column footer with Platform/Support/Legal/Auth columns.
8. **Ticker**: Avatar img tag using avatar.png asset instead of colored initials box.

### Design Token Consistency
All tokens preserved from v1/v2 reference. Nav background: rgba(6,12,24,0.92) + blur(14px). Body background: dual radial-gradient fixed attachment. Font: Montserrat local from css2.css.

**Why:** index2 was marked "negative result" — primary issue was placeholder boxes where real weapon art should appear. index3 fixes this with actual <img> tags and proper float/glow composition.

**How to apply:** When reviewing or iterating BLC pages, real asset <img> tags are mandatory. CSS placeholder boxes for weapons/cases are a known regression pattern to avoid.
