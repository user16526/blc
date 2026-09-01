# Capsule: BLC Mockups & Approved Design System
Last updated: 2026-09-01
Owner lens: UX / Product (gaming-ux-strategist)

## Current facts
- Mockups live in `mockups/main002/`. Assets (images, CSS, fonts) live in
  `index_files/` **relative to the mockup file** — never external CDN URLs.
- Versioning: `index.htm` = v1 baseline (never overwrite). New iterations are
  `index2.html`, `index3.html`, `index4.html`, … Current newest: `index4.html`.
- `index.htm` is the AUTHENTICATED USER view (app shell). When improving it, preserve
  the full two-row header, game tabs, balance widget and nav icons. Do not convert
  it into a landing-page layout.
- `fantaicon` is BloodyCase's custom icon font: `index_files/fantaicon.woff2` +
  `.woff`, sourced from `https://chipper-manatee-749c59.netlify.app/fonts/fantaicon/`.
  `index_files/fantaicon.css` references them with cache-busting query strings;
  Python's `http.server` strips query strings, so the local files resolve correctly.
- `file://` is blocked in Playwright. Always serve first:
  `cd mockups/main002 && python -m http.server 8099`, then screenshot `localhost:8099`.
- Competitor references collected 2026-05-18 (`mockups/competitors/`): Key-Drop
  (single nav row, "Get Free" primary CTA, live-online badge, NEW tags, dark teal),
  Hellcase (full-width live-drop ticker under hero, 2-column hero with weapon art
  right, 5-6 col case grid, large circular bonus badge), skin.fans (premium
  "Prime CS2 unboxing" copy positioning).

## Non-negotiables — approved design system (validated 2026-05-18)
Apply to every future BLC HTML mockup.
- **Typography** — headings / hero titles: `'Russo One', sans-serif` (gaming/esports
  feel). Body / UI: the existing Montserrat stack from `index_files/css2.css`, loaded
  LOCALLY. Never reintroduce an external Google Fonts `<link>` while `css2.css` is present.
- **Color tokens** — cyan accent `#00e5ff` (neon glow, CTAs, highlights); gold accent
  `#ffc53a` (badges, deposit button, live-drop values, rarity glow); surface
  `rgba(10,14,23,0.85)` with `backdrop-filter: blur(12px)`.
- **Background** — v1's dual radial-gradient, fixed attachment (not a flat `#0a1220`).
- **Logo** — `<img src="logo-bloodycase.svg">` in nav and footer; never a text/CSS logo.
- **Nav** — background `rgba(6,12,24,0.92)` + `blur(14px)`; border uses `--border`
  (30% blue), not `--border-soft`; links use the `--nav-default` / `--nav-hover` /
  `--nav-active` token chain. v1 remains the token authority.
- **Hero** — min-height 420px (240px is not enough). Two-column grid: content left
  (min 380px), weapon art right. Weapon art = one primary (large, `weapon-float`
  keyframe) + one smaller offset secondary. CRT scanline overlay:
  `repeating-linear-gradient(0deg, rgba(0,0,0,0) 0px, rgba(0,0,0,0) 2px, rgba(0,0,0,0.04) 2px, rgba(0,0,0,0.04) 4px)`.
  Pulsing deposit badge: `badge-pulse` keyframe, 96px circle, hero top-right.
- **Trust signals (approved copy)** — three inline pills inside the hero below the
  CTAs: "Provably Fair" | "Instant Withdrawal" | "From $<cheapest case price>".
  The first two are fixed strings (both confirmed live on bloodycase.com,
  2026-09-01). The third is **LIVE DATA, not a design token** — the invariant is:
  *the pill must equal the cheapest case price actually displayed on that same page.*
  Never hardcode it into the design system; that is exactly how it went stale.
  - Live site cheapest case: **$0.11** [verified 2026-09-01 via WebFetch] — a POINTER
    that decays, re-pull before quoting it publicly (`verify-external-state.md`).
  - `index4.html` shows $0.39 in the pill and $0.39 as its cheapest case card, so it
    is internally consistent and correct as a mockup. The old "From $0.06" figure in
    the pre-v8 CLAUDE.md was a snapshot of the live minimum on 2026-05-18 and is dead.

- **Glassmorphism header** — `backdrop-filter: blur(12px);`
  `box-shadow: inset 0 1px 0 rgba(255,255,255,0.04), 0 4px 20px rgba(0,0,0,0.3);`
- **Header accent strip** — `.page-header::before { height: 2px; background:
  linear-gradient(90deg, transparent 0%, var(--cyan) 30%, var(--gold) 60%, var(--cyan) 80%, transparent 100%); }`
- **Deposit bonus copy** — always "DEPOSIT +25%". The first-deposit bonus is 25%, not 15%.
- **Real assets are mandatory.** Weapon and case art must be real `<img>` tags
  (`awp-asiimov.webp`, `ak-47-fire-serpent.webp`, `case-dreams.png`, `avatar.png`, …).
  CSS placeholder boxes are a known regression — that is exactly why index2 was
  marked a negative result.

## Active risks
- [open] The fantaicon font is fetched from a third-party Netlify host. The local
  copies in `index_files/` are the only guarantee — if a mockup ever references the
  remote URL, icons break offline.

## Read when
- mockup, index.htm, index2/3/4.html, main002, hero, design system, design tokens,
  fantaicon, weapon art, case grid, live drop ticker, screenshot, Playwright, http.server
