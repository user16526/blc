# BloodyCase — v1 vs v2 Product Brief
**File:** main003/index.html (v2) vs main002/BloodyCase — Home.htm (v1)
**Date:** 2026-05-18

---

## 1. V1 vs V2 Comparison — Section by Section

### Navigation / Header

**V1 (main002)**
- Two-row sticky header. Row 1: logo (image), online count, utility links ("Promo code", "Affiliate system"), game-switcher tabs (CS2 / Rust / Dota 2), language + currency selectors. Row 2: full-width icon-nav with 11 items (Cases, Dragon Cases, Daily Free, Case Battle, Sniper Battle, Event, Tournament, Giveaways, Upgrader, Contract, Bonuses) + right-side balance widget showing dollar amount, tickets, coins, and a Deposit button.
- Designed as an **authenticated user's dashboard nav** — balance widget implies a logged-in state even on landing.
- Total header height: ~138px of reserved space (two rows).
- Nav items use custom `fantaicon` icon font + text labels; heavy visual weight.

**V2 (main003)**
- Single-row sticky nav, 60px tall. Left: text logo ("BloodyCase"). Center: 5 text links only (Cases, Case Battles, Sniper Battle, Upgrader, Giveaways). Right: animated online counter + Login + Register Free buttons.
- No balance widget, no game tabs, no language/currency selectors.
- Designed for **unauthenticated first-visit users** — the entire nav serves acquisition, not retention.

**Delta:** V2 reduces header height by ~56% and eliminates ~8 nav items. This is a fundamental reframe from app-shell navigation to landing-page navigation. The game tabs (CS2/Rust/Dota 2 switcher) were removed — the v2 homepage implicitly defaults to CS2.

---

### Hero Section

**V1 (main002)**
- A rotating image slider (240px tall, 3 slides) positioned *below* the timer panels. Each slide has: background image, headline, short subtitle, one CTA button.
- Slide 1: "Champions Offer" — deposit from $24.99, get Arena Champion Case free. CTA: "Top up" (blue rounded button, 40px).
- Slide 2: "Dragon Cases" — themed loot headline. CTA: "Open now".
- Slide 3: "Sniper Battle" — $10,000 prize pool. CTA: "Enter arena".
- No trust signals in hero. No registration prompt. Assumes user is already logged in.
- CTAs are promotional (event-specific), not evergreen.

**V2 (main003)**
- Full-viewport hero (100vh) with ambient radial glow background, CSS grid overlay, and three floating weapon art elements (AK-47 Vulcan, AWP Dragon Lore, Karambit) with parallax float animations.
- Eyebrow pill: "8,412 players online right now" (social proof, above fold).
- H1: "Open CS2 Cases. / Win Real Skins." (two-line, gradient on line 2).
- Subtitle: "Open custom cases from $0.39. Win knives, AWPs, AK-47s and more — then withdraw to Steam instantly."
- CTA row: Primary green button "Start Opening — It's Free" + ghost button "Watch Live Drops".
- Three trust pills inline under CTAs: Provably Fair / 8,400+ Online Now / Instant Steam Withdrawal.
- Gold circular bonus badge (top-right of hero, 110px): "+25% First Deposit" with pulsing glow animation.

**Delta:** V2 hero is 4-5x taller and purpose-built for new user conversion. V1 hero is a promotions carousel for returning users. V2 anchors the value proposition in one persistent statement vs three rotating messages. The "+25% First Deposit" badge is now a persistent visual element rather than buried in a slide.

---

### Live Wins Feed / Social Proof

**V1 (main002)**
- Right-side vertical rail of live drop cards (fixed position, 126px wide), showing actual weapon images (real PNGs: AK-47 Vulcan, AWP Asiimov, AK-47 Fire Serpent, etc.) with rarity-colored borders.
- Cards have full artwork + weapon name + skin name.
- No ticker. No username. No dollar value. Rail appears immediately on load with seeded content.
- Auto-adds cards every 2.2–4.6 seconds.

**V2 (main003)**
- Two social proof systems running in parallel:
  1. **Horizontal ticker** (46px bar, full width, directly below hero): scrolls username + "won" + skin name + dollar value. Includes usernames (xX_NoScope, Vladislav_K, etc.), rarity dot, and value ($487.00, $1,240.00, etc.). Pauses on hover.
  2. **Vertical live drops rail** (right side, 120px wide): same concept as v1 but with CSS-only placeholder art (no real images), rarity gradient border.
- Ticker adds username attribution and dollar amounts — neither existed in v1.
- Drop card animation in v2 uses simpler keyframes; v1 used `filter: blur` transition for higher perceived quality.

**Delta:** V2 adds dollar-value visibility to social proof — a major change. Seeing "$1,240.00 AWP Dragon Lore" is far more compelling than seeing a generic card. The horizontal ticker also places social proof directly in the conversion funnel (between hero and case grid), while v1's vertical rail is peripheral. V2 loses real weapon images in the rail (placeholder only), which reduces visual quality.

---

### Stats Bar (V2 only — new section)

V2 adds a 4-column stats bar immediately after the ticker: "2.3M+ Cases Opened", "847K+ Registered Players", "$12.4M+ Paid Out to Players", "Since 2019 / Established & Trusted". Not present in v1.

---

### Case Grid

**V1 (main002)**
- 7-column grid, section header "Hot Summer Cases" (centered, gold text, small, decorative caret).
- Cards: image-only art on transparent background (real PNG case images), name below (blue-grey, 15px, weight 400), price pill (dark bg, rounded, price 16px weight 400). No CTA button on individual cards — clicking the card presumably opens the case.
- Hover: only translateY(-3px) + drop-shadow glow on image. No card border change.

**V2 (main003)**
- 7-column grid, section header "Featured Cases" (left-aligned, bold accent bar, white, "View All" link on right).
- Cards: colored placeholder art with rarity-color gradient background per card (`--rarity-clr` custom property drives card glow, hover border color, and box-shadow). Name (12px, weight 600, white). Price pill (smaller, 14px). Explicit "Open" button at the bottom of each card (30px height, blue tinted).
- Hover: translateY(-4px) + rarity-matched border color + rarity-matched box-shadow glow.

**Delta:** Three meaningful changes:
1. V2 adds an explicit "Open" button per card — eliminates ambiguity about what clicking does.
2. V2's rarity-color theming per card creates visual hierarchy (gold = $49 Gradient Case stands out immediately).
3. V2 section header is left-aligned with a "View All" link — cleaner, standard e-commerce pattern.

---

### Timer Panels (V1 only — absent in V2)

V1 has two timer panels above the hero slider: "Tournament — 02d 14h 37m 59s" and "Major Event — 01d 09h 24m 15s". These create FOMO for returning users. V2 removes them entirely — they are retention mechanics, not acquisition mechanics, and don't belong on a landing-page-style homepage.

---

### Game Modes

**V1 (main002)**
- Case Battles section uses a card grid showing live battle data (rounds, case images, players count, value, Join button). 6-column grid, 5 live battles + 1 "Create Battle" card. Real battle data (e.g., "3/5 players, $12.25 value"). Focused exclusively on Case Battles.

**V2 (main003)**
- 4-column "More Ways to Win" grid with mode cards: Case Battles, Sniper Battle, Upgrader, Trade-Up Contract.
- Each card has an icon, name, description (2 sentences), and a labeled CTA ("Join a Battle", "Enter Arena", "Start Upgrade", "Trade Up").
- No live data shown. Mode cards are informational/navigational, not action items.

**Delta:** V2 trades depth (live battle data) for breadth (all 4 modes introduced). This is correct for a landing page — a new user needs to understand all modes exist before they see live data for one. The live battle listing belongs on the Case Battles sub-page.

---

### Trust Signals / Provably Fair

**V1 (main002)**
- No dedicated trust section on the homepage.
- "Provably Fair" appears only in the footer links (one of 6 footer links).

**V2 (main003)**
- Four-card "Why Players Choose BloodyCase" trust grid (full-width section):
  1. Provably Fair System — SHA-256 hashing, verifiable any time.
  2. Instant Steam Withdrawal — no manual requests, no 24-hour delays.
  3. 5 Free Cases on Signup — no deposit needed.
  4. 25% First Deposit Bonus — deposit $20, play with $25.
- Additionally: three inline trust pills in the hero (Provably Fair, 8,400+ Online, Instant Withdrawal).
- Provably Fair appears in 3 places in v2 vs 1 place (footer link) in v1.

**Delta:** V2 elevates Provably Fair from footer link to featured section. This is one of the single most important changes given that gamer skepticism about rigged outcomes is a primary conversion blocker.

---

### Bonuses

**V1 (main002)**
- "Bonuses" is a nav item (icon + label in the main nav).
- Deposit button shows "Deposit + 15%" (a different bonus % than v2).
- No dedicated bonus placement in the hero or page body.

**V2 (main003)**
- "+25% First Deposit" as an animated floating badge in the hero (110px circle, gold pulsing glow).
- "25% First Deposit Bonus" as one of the four trust cards.
- "5 Free Cases on Signup" as another trust card — v1 has no equivalent free cases offer visible on the homepage.
- The bonus is mentioned in the registration section copy: "Claim 5 free cases instantly — no deposit required."

**Delta:** V2 multiplies bonus touchpoints and increases the first-deposit bonus from 15% to 25% (or this may have been an actual product decision rather than a design choice). The "5 free cases on signup" offer is new and prominent in v2 — a zero-risk entry point that should materially reduce registration friction.

---

### Registration / Join Section

**V1 (main002)**
- No registration section on the homepage. Auth presumably happens via the balance widget or a modal triggered by nav items.

**V2 (main003)**
- Dedicated "Join 847,000+ Players" section at bottom of page with:
  - Eyebrow: "Get Started Free"
  - H2: "Join 847,000+ Players" (847K highlighted in gold/cyan gradient)
  - Sub: "Register in seconds with your Steam account. Claim 5 free cases instantly — no deposit required."
  - Five auth buttons: Steam, Google, Discord, Facebook, Twitch (matching the actual product's supported auth methods).
  - Footnote: "No deposit needed to start — get 5 free cases just for signing up."

**Delta:** V2 adds an explicit conversion goal section that v1 completely lacks. This is the most structurally significant addition for new user acquisition.

---

### Footer

**V1 (main002)**
- Not visible in the inspected HTML sections — footer content was at the bottom of a very long file but the structure shows footer links include Provably Fair.

**V2 (main003)**
- Simple horizontal footer: logo, 6 links (Provably Fair, FAQ, Terms of Service, Privacy Policy, About Us, Affiliate Program), legal disclaimer.
- Legal copy: "BloodyCase is a skin entertainment platform. All cases and items are virtual cosmetics only. Players must be 18+ or the legal age of majority in their jurisdiction. Play responsibly."

**Delta:** V2 footer is appropriately minimal for a marketing-style page. The affiliate program link in the footer is a growth lever v1 may not have surfaced there.

---

## 2. Conversion Hypotheses

### H1 — Hero CTA Wording and Placement

**We believe** replacing the rotating slide CTA ("Top up", "Open now") with a persistent primary CTA "Start Opening — It's Free" **will increase** new user registration rate (click-to-register) **because** a zero-cost entry point removes the primary objection (financial risk) at the moment of first consideration, and a stable CTA builds confidence vs a rotating message that may not align with what a user is thinking when they land.

The word "Free" in the primary CTA is the key element — users searching "cs2 case opening site" are often evaluating platforms and haven't committed money yet. Reducing perceived risk at the hero level should shorten time-to-first-action.

---

### H2 — Live Wins Feed with Dollar Values

**We believe** adding dollar values to the live wins ticker (e.g., "Vladislav_K won AWP Dragon Lore — $1,240.00") **will increase** session depth and case open rate **because** visible high-value drops create aspiration and validate that real money can be won. The original feed showed item names without values, which communicates "items drop" but not "high-value items drop regularly and visibly." Putting this in a horizontal bar directly between the hero and the case grid places it at the peak decision moment.

---

### H3 — First-Deposit Bonus Prominence (+25% Badge in Hero)

**We believe** the persistent animated "+25% First Deposit" circular badge in the hero **will increase** first-deposit conversion rate among newly registered users **because** bonus visibility at the moment of registration consideration primes the user to expect a reward when they deposit, increasing perceived value of the first deposit action. In v1 the deposit bonus appeared only in the nav button ("Deposit + 15%") which is only visible to logged-in users.

Secondary hypothesis: increasing the bonus from 15% (v1) to 25% (v2) should also mechanically improve first-deposit conversion.

---

### H4 — Provably Fair / Trust Signal Placement

**We believe** elevating Provably Fair from a footer link to a hero trust pill + dedicated trust card section **will reduce** cart abandonment at the deposit confirmation stage **because** CS2 trading communities have strong scam-detection instincts. Users who are unfamiliar with BloodyCase will ask "is this rigged?" before depositing. Surfacing the SHA-256 verifiability claim early in the funnel addresses this objection before it becomes a reason to leave. CSFloat and other established platforms surface Provably Fair prominently — this is a table-stakes trust signal for this audience.

---

### H5 — Case Grid: Explicit "Open" Button vs Click-the-Card

**We believe** adding an "Open" button per case card **will increase** case page click-through rate (CTR from homepage case grid) **because** a labeled action button eliminates ambiguity. Users who haven't used a case opening site before may not know that clicking the card opens the case. "Open" is also the verb the CS2 community uses — it's native language, not generic "Buy" or "Select."

Secondary benefit: the button creates a clear affordance on mobile where hover states don't exist.

---

### H6 — Registration Section at Page Bottom

**We believe** adding a dedicated registration section with social auth buttons (Steam, Google, Discord, Facebook, Twitch) at the bottom of the page **will increase** registration completion rate among users who scroll the page but don't immediately click the hero CTA **because** it provides a second explicit conversion opportunity for users who needed to see case selection, social proof, game modes, and trust signals before committing.

---

## 3. A/B Test Priority List

Ranked by impact potential × feasibility × learning value. Success metrics are measured over a minimum 2-week test window with statistical significance at 95% confidence.

| Rank | Test | Variant A (Control) | Variant B (Test) | Success Metric | Sample Size Note |
|------|------|---------------------|------------------|----------------|------------------|
| 1 | **Hero CTA: "Start Opening — It's Free" vs "Open Cases Now"** | "Start Opening — It's Free" (v2) | "Open Cases Now" (urgency-focus) | Registration rate of landing page visitors | High-traffic, fast results |
| 2 | **Live ticker: dollar values on/off** | Ticker with $$ values (v2) | Ticker with no dollar values (just names) | Click-through to case page from ticker interaction; case open rate | Split by new vs returning |
| 3 | **Trust section position: above vs below case grid** | Trust grid below game modes (v2) | Trust grid immediately below stats bar, above case grid | Registration rate; time-on-page; deposit conversion | Tests whether trust unblocks case browsing |
| 4 | **Bonus badge: floating hero badge vs inline hero copy** | Floating "+25% First Deposit" badge in hero | "First deposit: +25% bonus — deposit $20, play with $25" as inline sub-headline | First-deposit conversion rate among new registrants | Measure within 7 days of registration |
| 5 | **Case card CTA button: "Open" button vs no button (card click)** | Card with "Open" button | Card without button, full card clickable | Case page CTR from homepage grid; mobile vs desktop split | Mobile segment likely to show larger delta |

---

## 4. Dev Implementation Priority — MoSCoW

### Must Have (ship v2 without these = broken value proposition)

| Item | Rationale |
|------|-----------|
| Persistent "Start Opening — It's Free" CTA in hero | Core conversion hook; v1 equivalent was purely promotional |
| Stats bar (cases opened, players, paid out, est. date) | Social proof that answers "is this site legit?" for first-time visitors |
| Provably Fair trust section (4-card grid) | Directly addresses #1 objection for CS2 audience; was absent in v1 |
| Registration section with 5 auth buttons (Steam, Google, Discord, Facebook, Twitch) | Without this, new-user funnel has no bottom-of-page conversion point |
| Live wins ticker with dollar values | Social proof + aspiration signal; must be real data from backend, not static |
| Case grid "Open" button per card | Removes UX ambiguity; critical for mobile |
| "+25% First Deposit" hero badge | Must match actual current bonus %; confirm with product before shipping |
| Trust pills in hero (Provably Fair, Online count, Instant Withdrawal) | Headline-level trust signals for new visitors; low dev cost, high impact |

### Should Have (ship with these if sprint allows)

| Item | Rationale |
|------|-----------|
| Animated online counter that fluctuates in real-time | V2 implements a JS interval; needs real data feed or believable simulation |
| Rarity-color theming on case cards (CSS custom property per card) | Visual hierarchy in case grid; low dev effort, drives premium perception |
| "5 Free Cases on Signup" visible in hero/trust section | Mentioned in registration copy; must also surface in the trust card to be credible |
| Game modes section (4-card "More Ways to Win") | Educates new users about platform depth; navigation should link to real pages |
| Live drops vertical rail | Social proof complement to ticker; already existed in v1, needs v2 styling |
| "View All" link on case grid | Standard e-commerce navigation; low effort |

### Could Have (next sprint or post-launch optimization)

| Item | Rationale |
|------|-----------|
| Floating weapon art elements in hero (CSS animations) | Visual polish; no conversion impact, pure aesthetic |
| Hover pause on ticker | UX micro-detail; implemented in v2 but low priority |
| Game tabs (CS2 / Rust / Dota 2 switcher) | Existed in v1; v2 removed for simplicity; add back once CS2 core is stable |
| Language + currency selectors in nav | Internationalization; add when traffic analysis confirms non-EN segments |
| Case Battles live feed on homepage | V1 showed this; it belongs on the Case Battles sub-page, not homepage |
| Timer panels (Tournament, Major Event) | Retention mechanic for returning users; not a new-user acquisition tool |

### Won't Have (intentionally excluded from v2)

| Item | Rationale |
|------|-----------|
| Balance widget in nav on homepage | This is a post-login state; homepage is pre-login acquisition |
| Deposit button in nav (pre-login state) | Premature; user needs to register first |
| "Promo code" and "Affiliate system" utility links in top bar | Valuable for retention, wrong placement for acquisition-focused homepage |
| 11-item navigation with icon labels | App-shell nav creates cognitive overload for new visitors; reduce to 5 clean text links |

---

## 5. CS2 Gamer Search Intent Alignment

The primary audience arriving via organic search is split into three intent buckets:

### Bucket 1: "cs2 case opening site" / "best cs2 case site"

Intent: discovery. User is comparing platforms. They have never used BloodyCase.

**V1 problem:** Landing page looked like an authenticated app dashboard (balance widget, complex nav, event timers). A new visitor has no context for this UI and no clear instruction on what to do first.

**V2 solution:**
- H1 "Open CS2 Cases. Win Real Skins." directly answers the query.
- "$0.39" price mention in the subtitle immediately shows entry-level cost (a common comparison point).
- Stats bar ("2.3M+ Cases Opened, 847K+ Registered Players") gives platform legitimacy.
- "Start Opening — It's Free" removes cost barrier at the decision moment.

**Remaining gap:** No SEO-relevant text on the page mentioning specific popular CS2 cases (AK-47 Redline, AWP Dragon Lore, Karambit Fade). The hero weapon art uses those skin names, but as CSS placeholder text, not real HTML content. Dev needs to ensure these skin names appear in actual text elements for on-page SEO.

---

### Bucket 2: "cs2 case opening provably fair" / "is [site] legit"

Intent: trust verification. User has likely read Reddit threads about scam sites and wants proof before depositing.

**V1 problem:** "Provably Fair" appeared only as a footer link — the last place a trust-seeking user would look, after they had already decided to leave.

**V2 solution:**
- "Provably Fair" appears in three places: hero trust pill, standalone trust card with SHA-256 explanation, footer link.
- The trust card explicitly says "Every case opening is cryptographically verifiable. SHA-256 hashing — check any result yourself, any time." This is exactly what a skeptical user needs to read.
- The live wins ticker with named users and exact dollar amounts reinforces legitimacy ("real people are winning real amounts right now").

**Remaining gap:** The trust card should include a link to an actual verification page. "Check any result yourself" is a promise — if there's no link to a verification tool, it reads as empty marketing copy. This is a dev dependency.

---

### Bucket 3: "cs2 case opening cheap" / "open cs2 cases from $0.39"

Intent: price-driven. User is specifically looking for low entry cost.

**V1 problem:** Prices appear on case cards but the cheapest price ($0.39) wasn't surfaced above the fold. The hero slides were about event promotions, not price accessibility.

**V2 solution:**
- "$0.39" is mentioned directly in the hero subtitle — above the fold, before the user scrolls.
- Case grid shows price range from $0.39 to $49.00, giving immediate price context.
- "5 Free Cases on Signup" plus "25% First Deposit Bonus" means the perceived entry cost is functionally zero.

**Remaining gap:** V2 doesn't have a filter on the case grid for price sorting (sort by price: low to high). A user searching for cheap cases expects to be able to filter to the cheapest options immediately. This is a Should Have for the case grid page (not necessarily the homepage, but it needs to exist somewhere users following this intent can complete the task).

---

**Structural SEO note for dev team:** The v2 homepage title tag is "BloodyCase — Open CS2 Cases, Win Real Skins" — this is a direct improvement over v1's "BloodyCase — Home". The title includes two high-intent keywords ("Open CS2 Cases", "Win Real Skins") in 50 characters. Maintain this pattern. Ensure meta description includes "$0.39", "Provably Fair", and "Steam withdrawal" — all three match actual user search terms.
