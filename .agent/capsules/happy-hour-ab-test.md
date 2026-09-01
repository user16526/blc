# Capsule: Happy Hour A/B test (BloodyCase)
Last updated: 2026-09-02 (restored from the remote host's Claude memory
`~/.claude/projects/-home-sparrow/memory/happy_hour_ab_test.md`, last real work 2026-08-27;
sessions 2026-08-31 and 2026-09-01 on the host were restores only, no new decisions)
Owner lens: Product / Growth

## Current facts
**Test design (agreed with manager):** 3-week A/B split by hash of `client_id`, fixed for the whole test,
same daily cycle all 21 days, no day-of-week variation:
- H0 control (1/3): no feature
- H1 (1/3): window 02:00–05:00 UTC — lowest-traffic window: cleaner incremental signal, small reach
- H2 (1/3): window 18:00–21:00 UTC — near-peak: large reach, highest cannibalization risk
- Participation (H1 = H2): min deposit $5–10 + "not participated in last 24 h" anti-farm. No unconditional arm.
- Primary metric: net incremental revenue = Δ deposits − prize cost over the FULL day (not the window),
  to catch timing cannibalization. New vs returning = post-hoc cut, not a randomization arm.
- Required logging: client_id, group, is_new_client, timestamp, prize, prize_cost.
- Business goal stated explicitly: Happy Hour is a re-engagement lever (lift deposits + case battles),
  not a pure measurement exercise. 6-month trend supports it (weekly deposits ~1600–1700 in March →
  ~1050–1260 in August; case bets ~700–770K/wk → ~560–600K/wk).

**Manager's finalized prize plan (2026-08-26):** ONE prize type, Deposit Bonus, for both H1 and H2.
Admin panel (verified by screenshot 2026-08-27): "Deposit Bonus" has a single fixed percent field —
variety = several separate Prize slots (10 % / 20 % / 30 % …), uniform random pick because `Weight` is
ignored. Bonus % 1–100, amount capped at $100 absolute. Planner prize types available: Deposit Bonus,
Coins, Free Ticket (NO PromoCode → Dragon Cases cannot be a prize here). Condition types: None,
Make Deposit, Open Case(Cases) (case ids + amount), Not Participated in 24 hours.
Planner fields: Cron Regex, Duration (minutes), Is Cyclic, Is Active. Cron H1 `0 2 * * *`,
H2 `0 18 * * *`, duration 180.

**Backend mechanics that matter:**
- BonusDeposit processor implemented (confirmed 2026-08-26). Winner-take-max, NOT additive: at deposit
  time only the LARGER of the client's eligible bonuses applies (HH bonus vs standing first-deposit bonus).
- `Weight` (rarity) ignored by the backend → equal probability per slot; duplicate slots fake weighting.
- Spin-once-per-day check disabled for testing (`pkg/prizes/service.go:51-53`, as of 2026-08).
- Planners have no end-date field → manual `is_active=false` after day 21, or a dev ticket.
- No A/B-group concept in the service: H0/H1/H2 assignment needs an experiment/feature-flag layer or a
  frontend gate — not designed yet.
- Median first deposit: new clients $5.99 vs returning $19.99.

**6-month hour-of-day analysis (queried 2026-08-26, DB `bloody`, UTC, bots/bloggers excluded):**
deposits trough 02–05 UTC (457–630/hr) vs peak 18–21 (2144–2342/hr) ≈ 3.5–5×; case bets ≈ 2× gap;
battles lowest 05 UTC, highest 22–23 UTC (right after H2). New-client share of deposits ~20–28 % in
every hour → time of day is not a lever for new vs returning.

## Non-negotiables
- Only prize types that work today go into the initial test; anything needing dev work is a ticket, not a slot.
- `prize_cost` must record the % actually APPLIED (post max-comparison), else the primary metric is wrong.
- Keep H1/H2 prize pools identical — the test isolates timing, not prize richness.
- Superseded: the 10-slot mixed pool drafted 2026-08-25 (EventCoins/PromoCode/FreeTicket). Manager's
  Deposit-Bonus-only plan is the source of truth unless renegotiated.

## Active risks / open blockers (as of 2026-08-27)
1. Winner-take-max vs standing first-deposit bonus: HH bonus is a no-op for new clients if the standing
   bonus % is higher. Standing first-deposit bonus % still UNKNOWN — must be obtained first.
2. Follow-on: give NEW clients Free Ticket / Coins and reserve Deposit Bonus for RETURNING clients?
3. Unverified with dev: what `prize_won` / `prize_cost` actually log (nominal roll vs applied %).
4. Habituation: one static prize × 21 days may decay by week 2–3. Proposed: 3–5 bonus % slots now,
   vary composition by WEEK (not day), keep H1/H2 symmetric. Not decided with manager.
5. No planner end date → manual stop or dev ticket.
6. A/B assignment layer (hash of client_id → H0/H1/H2) has no home yet.
Dev tickets identified: real `Weight` selection; re-enable spin-once check; planner end-date field.

## Read when
- happy hour, HH, deposit bonus, A/B test, H0/H1/H2, planner, prize pool, anti-farm, cannibalization,
  re-engagement, hour-of-day deposits
- Remote sources: host `bloodyanalytics02` → `~/docs/features/happy-hour-backend.md` (dev doc),
  DB `bloody` via `/mcpb` for live numbers.
