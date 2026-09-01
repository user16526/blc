---
name: blc-v2-design-alignment
description: Design system alignment pass on index2.html — tokens, background, logo, font, nav game tabs, compact selectors applied from v1 reference.
metadata:
  type: project
---

BloodyCase v2 prototype (index2.html) received a full design system alignment pass against v1 (BloodyCase — Home.htm).

**Changes applied (2026-05-18):**
- Font loading switched from external Google Fonts URL to local `BloodyCase — Home_files/css2.css` + `fantaicon.css`
- Body background upgraded from flat `#0a1220` to v1's dual radial-gradient (fixed attachment)
- Text logo replaced with `<img src="logo-bloodycase.svg">` in both nav and footer
- 11 missing design tokens added to `:root` (see gap list in task spec)
- Nav border upgraded from `--border-soft` (5% white) to `--border` (30% blue)
- Nav links now use `--nav-default` / `--nav-hover` / `--nav-active` token chain
- Game tabs component (CS2/Rust/Dota) added to nav right zone with icon images, active expand animation, JS toggle
- Compact currency (USD) and language (EN) selectors added to nav right zone with dropdown menus and keyboard support

**Why:** Acquisition-focused v2 page lacked visual fidelity to v1 design system — flat background, generic CSS logo, wrong nav contrast.

**How to apply:** When reviewing v2 for further iterations, v1 remains the token authority. Never reintroduce external Google Fonts link while local css2.css is present.
