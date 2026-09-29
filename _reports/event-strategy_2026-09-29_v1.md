# Event strategy: why events don't drive deposits, and what to change
2026-09-29 · gaming-product-owner · Evidence: `blc-event-deep-dive_2026-09-29_v1.md` (DD), `competitor-events_2026-09-29_v1.md` (CE),
`blc-data_2026-09-29_2002_v1.md` (W, 20-day windows). No new queries. Numbers labelled *estimate* show their arithmetic.

## Decision
The event is an **always-on, automatic deposit rebate in a new skin**. It pays ≈13% of GMV to deposits that would happen anyway and gives
mid and high depositors nothing to aim for. Fix the config for the Oct 7 event (the first reward on the minimum deposit, value moved to the middle
levels, a whale race, a smaller flat rebate). Ship a 20% hold-out so the event has to prove it is incremental. Be clear with the owner: **the payer
base and reg→FTD collapse are bigger than anything an event can fix.** The event is a margin and retention lever, not the fix for the revenue drop.

## 1. Diagnosis: root causes, ranked by revenue impact
| # | Root cause | Evidence | Label |
|---|---|---|---|
| 1 | Mid and high depositors have nothing to chase | $50+ deposits $35.0k → $22.6k (−35%, −$12.4k) while <$50 stayed flat; top-10 GMV −31%; payers ≥$500 22 → 15; deposits >$500 earn 0 XP; 80% of skin value sits in L22–25 (≈$1.2–2.2k of deposits away) (DD, W, CE) | hypothesis: the drop is proven, the event's share of it is not (ARPPU excl. top-10 was already falling 40 → 35.5 → 31.4) |
| 2 | Deposit XP and coins are automatic and flat, so the cost buys baseline deposits | ≈$8k = 13% of GMV in 20 days; payers +1% this launch; 12 launches range −22%…+6%, typical +1% (DD). Coin rebate is up to ≈10–13% of each deposit (160–220 XP/$ × ~0.6 coins/XP ÷ 1,000 coins/$) | data-proven |
| 3 | Payout leakage outside real players | $6.0k of $500 skins to one `flags=128` account with $0 deposits and 10M manually granted coins; source 6 (unmapped) = 11.9% of all XP for 134 players, and 3 L25 finishers at ~835k XP each (DD) | data-proven (intent unknown) |
| 4 | The first deposit gets no reward | $5 minimum = 800 XP, L1 = 1,000 XP; 12,993 of 14,024 participants (93%) never reach L1, 337 of them depositors (DD) | data-proven |
| 5 | Same template 11 times, back to back, so there is no novelty or urgency | Identical `rewards` md5 since 2025-07-29, no gap between events. Launch spikes joins (1,320 / 2,830 on Sep 8–9) and actives (+20%), not payers (DD, W) | hypothesis (the template is proven, the effect is not) |
| 6 | Nothing can be measured | Every depositor earns event XP automatically and there is no control group, so no deposit can be credited to the event (W, CE) | data-proven |

## 2. Why events in general don't drive deposits here
- **Design (fixable):** the reward is attached to the deposit, not to *an extra* deposit. A player gets the same rebate whether or not the event
  exists, so the event cannot change behaviour by construction (causes 2, 6).
- **Design (fixable):** the next reward is never one deposit away. Small payers stall before L1, and mid payers ($20–150, most of GMV) see
  $0.24–5 skins. The real prizes sit behind ≈$1.2k+ (CE).
- **Macro (not fixable by an event):** payers/month 3,418 (Mar 2025) → ~1,800 (Sep 2026). Registrations are +54% YoY (per day) while reg→FTD fell
  7.6% → 4.1% (DD). Payment success broke from 2026-08-17 (PS 82 ~57–58% → ~47–51%) and the geo mix moved to markets that don't pay
  (`blc-aug-sep-yoy_2026-09-18_v1.md`, `blc-geo-quality_2026-09-18_v1.md`). An event only reaches people who already reached the cashier.
- **Which is bigger:** macro, by roughly an order of magnitude. *Estimate:* even the best launch in 12 (+6% payers) on ~1,800 payers/month
  ≈ +108 payers, against ≈1,600/month lost since the peak (3,418 − ~1,800), so ≈7% of the gap. Payment and acquisition fixes come first.
  The event's job is to stop wasting 13% of GMV and to lift frequency and size among existing payers.

## 3. What to change (ranked; config-only first, all ready for the Oct 7 event)
Effort key: **config** = `stats.events` JSON the ops team already edits · **ops** = CRM/marketing · **dev** = client dev team (spec from us).

**R1. First deposit = first reward.** config · risk low
- Change: re-set the deposit band table to a flat ≈200 XP per $ at each band floor, without cliffs:
  $5 → 1,000 · $10 → 2,000 · $20 → 4,000 · $50 → 10,000 · $100 → 20,000 · $150 → 30,000 · $200 → 40,000 · $250 → 50,000.
  Today it is 800 / 1,650 / 3,500 / 9,000 / 19,000 / 30,000 / 42,000 / 55,000 (160–220 XP/$). Keep the L1–15 curve as it is.
- Mechanism: the $5 minimum completes L1 and opens a skin, which gives new and small payers a reward moment.
- KPI: share of first depositors who make a 2nd deposit within the event; FTD among new registrants (hold-out arm, see §5).
- *Estimate* of cost: ≤337 extra L1 unlocks (depositors stuck <L1) × ≤$1.12 (value of L1–3 rewards, CE) ≈ **≤$0.4k per event**.

**R2. Move the value to the middle: milestone chests at L5 / L10 / L15.** config · risk: payout up if reach rises
- Change: mark L5, L10 and L15 as "chest" levels worth ≈5% of the deposits needed to reach them (at ≈200 XP/$):
  L5 (7,400 XP ≈ $37) → ~$2 skin · L10 (26k ≈ $130) → ~$6.5 · L15 (72k ≈ $360) → ~$18. Keep the $116 Kukri at L25 as the chase item.
  Cut L22–24 ($28 + $82 + $93) to coins. Show "N XP / $X to next chest" on the event page.
- Mechanism: goal gradient. A $20–50 payer is always one deposit from something worth depositing for.
- KPI: share of payers who move up a deposit band within the event; deposits per payer.
- *Estimate* of cost at this event's reach: 222 (≥L5) × $2 + 68 (≥L10) × $6.5 + 16 (≥L15) × $18 ≈ $0.44k + $0.44k + $0.29k
  ≈ **$1.2k**, minus L22–24 savings (3 finishers × $203 ≈ $0.6k), so **net ≈ +$0.6k per 20 days**.

**R3. Whale race on deposits, with a published pool.** config + ops (config only if the Leaderboard ranks on event XP; see Q3) · risk: RG scrutiny, whale concentration
- Change: add bands $500–999.99 → 100,000 XP and $1,000+ → 200,000 XP, so the >$500 hole is closed. Rank the Leaderboard on XP,
  exclude internal `flags`, and publish the pool on the event page and in Discord.
  Pool = 5% of the pre-launch top-10 GMV ($28.6k × 5% ≈ **$1.4k per 20 days**; this is a design choice, not an effect estimate).
- Mechanism: status plus a visible prize for the players whose GMV fell most (−31%). This is CaseBattle/Skin.club's lever, but built on
  deposits so it doesn't reward balance-churners (CE).
- KPI: GMV of the top-50 payers per week vs the control arm; payers ≥$500.

**R4. Halve the flat coin rebate and fund R2 and R3 with it.** config · risk: backlash from coin grinders (small, since the pass stays free)
- Change: deposit coins from ≈0.6× XP to ≈0.3× XP. Case-open coins unchanged.
- *Estimate* of saving: shop redemptions $2.8k × 58% deposit share × 50% ≈ **$0.8k per 20 days**, assuming redemptions scale with coins.
- Net of R1–R4 ≈ +0.4 + 0.6 + 1.4 − 0.8 ≈ **+$1.6k per 20 days (≈ +2.7pp of GMV)**. Stopping the $6k internal grant (see §4) more than
  covers it. The hold-out (R5) decides whether the spend stays.

**R5. 20% hold-out: randomly selected users get no event.** dev (feature flag by `client_id` hash) · risk: low
- The only way to learn whether the ≈$8k per 20 days buys anything. Design in §5. If dev can't ship it by Oct 7, ship R1–R4 anyway and
  run the hold-out on the following event.

**R6. "$X to your next chest" on the cashier screen.** dev (frontend) · risk: low
- Mechanism: puts the goal at the moment of choosing the amount (Hellcase refill thresholds, CE). This matters more than the event page.
- KPI: average deposit size and the share of deposits that land exactly on a milestone.

**R7. Paid premium track (~$5 from balance): every level gets a second, better reward.** dev · risk: pay-to-win and loot-box optics,
so publish the value per tier
- Mechanism: commitment. The player has paid, so later deposits "protect" the purchase (Key-Drop $5 pass; Hellcase/Farmskins subs, CE).
- KPI: attach rate among payers; deposits per buyer vs matched non-buyers. Test only after R5 exists; otherwise it is unmeasurable too.

Not now: decaying status (DatDrop) and rotating the mechanic every event. Revisit once R5 shows what moves payers.

## 4. Current event (ends 2026-10-06, 8 days left): quick wins and stop-doing
Quick wins (ops/config, no XP changes):
- **Fix `MainTitleToken: "NO NAME RESORT"`** in the Start Season config. Today it is the previous event's title in alt text and crawlers.
- **Final-week CRM push** to the 963 players at L1–9 (809 + 154): "N XP to your next skin, ends Oct 6". Send to a random 80% and hold
  out 20% (the unsent 20% is the control). It is small, so treat the result as directional, but it is our first causal read on any event lever.
- **Don't change XP rules mid-event.** It is unfair to players who already deposited and it breaks the before/after read.

Stop doing:
- **The `flags=128` grant** ($6.0k of $500 skins, 10M manual coins) unless the owner confirms it is an intended promo. If it is, book it as
  marketing spend and exclude that account from the leaderboard and from event reports.
- **Unexplained source-6 XP** (11.9% of all XP, 3 finishers ~835k each) until the dev team says what it is.
- **Relaunching the same template back to back** as "a new event".
- **Judging events on raw GMV or joins.** Whales swing GMV −24%…+23% regardless of the event (DD).

## 5. How to measure the next event
- **Design:** user-level hold-out. 80% treatment (new event config) vs 20% control (no event page, no XP/coins). Assignment by `client_id`
  hash, sticky, applied to all logged-in users including new registrations. Internal `flags` accounts excluded. Pre-register the metrics below.
- **Primary metric:** depositor rate per arm over the event (= incremental payers).
  Secondary: deposits per payer; GMV per user winsorized at $500; net revenue (deposits − withdrawals) per user; FTD rate of new registrants.
  Guardrails: D30 retention, withdrawal ratio, and a 7-day post-event window to catch pulled-forward deposits.
- **Power (*estimate*):** baseline 1,279 payers / 13,630 event-active = 9.4% per 20 days (W). At 80/20 (10,904 / 2,726),
  SE = √(0.094 × 0.906 × (1/10,904 + 1/2,726)) ≈ 0.62pp, so **MDE ≈ 2.8 × 0.62 ≈ 1.75pp (≈ +19% relative)**. A 50/50 split gives
  ≈1.4pp (+15%). Revenue metrics will be underpowered (heavy tails), so report them with a CI and don't use them as a gate.
- **Duration:** the full event, minimum 21 days (three weekly cycles plus the final-week spike), then the 7-day post window.
- **Success in numbers:** treatment depositor rate ≥ control + 1.75pp (e.g. 9.4% → ≥11.2%) with the CI above 0, AND winsorized GMV per
  user not below control. Why this bar is right: an event costing ≈13% of GMV has to lift GMV by **≥13% just to cover the payout at buyout
  price**, before any margin. Lifts smaller than the MDE aren't worth this budget anyway. Caveat: buyout overstates the true cost if
  reward skins are re-spent on site instead of withdrawn (Q5).
- **If it fails:** cut the event budget to what the hold-out shows it earns, and keep the event as a cheap engagement feature
  (actives +20% is real, W).

## 6. Open questions for the client (max 5)
1. The `flags=128` account: are the 10M manual coins and $6.0k of $500 skins an intended promo (streamer, giveaway)? Who approves grants like this?
2. What is XP source 6 (and 2, 3, 8)? Three players finished at ~835k XP mostly from source 6. Is it a manual grant, a bug or abuse?
3. What does the Leaderboard rank on, and can the config take deposit bands above $500? This decides whether R3 is config-only.
4. Can the dev team serve the event to a hashed user subset (R5) by Oct 7? What would a cashier progress bar (R6) and a paid track (R7) cost?
5. What does a reward skin really cost (sourcing vs buyout; share withdrawn vs re-spent), and do coins expire at event end? These set the
   true event cost and whether a "spend it before it expires" push is possible.
