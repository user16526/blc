# Capsule: Happy Hour A/B test (BloodyCase)
Last updated: 2026-09-08 (SUPERSEDING FINAL section below is the current plan; earlier: reply draft for eugene_s: docs/happy-hour-reply-eugene_2026-09-02_v1.md; dev update from eugene_s added; earlier: restored from the remote host's Claude memory
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
- Median first deposit: new clients $5.99 vs returning $19.99. Standing deposit bonus (live DB 2026-09-02):
  1st deposit 20 % / 25 % (>= ~$20), 2+ deposits 6-10 %; bonus_amount is logged per deposit in public.deposits.

**6-month hour-of-day analysis (queried 2026-08-26, DB `bloody`, UTC, bots/bloggers excluded):**
deposits trough 02–05 UTC (457–630/hr) vs peak 18–21 (2144–2342/hr) ≈ 3.5–5×; case bets ≈ 2× gap;
battles lowest 05 UTC, highest 22–23 UTC (right after H2). New-client share of deposits ~20–28 % in
every hour → time of day is not a lever for new vs returning.

## Dev update (eugene_s, comments dated ~2026-08-27 and 2026-09-01)
- Question asked 2026-08-27, unanswered by us: show HH to guests too (needs backend work, variant can be
  reset by clearing cookies, no cross-device consistency) or logged-in only (one variant per user everywhere,
  minimal changes). Dev recommended logged-in only.
- IMPLEMENTED 2026-09-01 without waiting: logged-in users only, experiment on 100 % of logged-in traffic,
  33.3 % each: control (not shown) / 02 UTC group / 18 UTC group. Live on UAT only; dev will enable on prod
  when the code ships. Guests and control see nothing.
- Events sent: `happy_hour_gate_shown` (group resolved), `happy_hour_shown` (modal shown; groups 1-2, in
  window only), `happy_hour_spun` (conditions met, spin started). Dev asks what else to track.
- Effect on blockers: #6 (A/B assignment layer) CLOSED for logged-in users. #3 (what prize_cost logs) and
  #5 (end date) still open; the event list has no prize/bonus-applied event yet.

## Non-negotiables
- Only prize types that work today go into the initial test; anything needing dev work is a ticket, not a slot.
- `prize_cost` must record the % actually APPLIED (post max-comparison), else the primary metric is wrong.
- Keep H1/H2 prize pools identical — the test isolates timing, not prize richness.
- Superseded: the 10-slot mixed pool drafted 2026-08-25 (EventCoins/PromoCode/FreeTicket). Manager's
  Deposit-Bonus-only plan is the source of truth unless renegotiated.

## Active risks / open blockers (as of 2026-08-27)
1. RESOLVED 2026-09-02 from live DB (_reports/blc-data_2026-09-02_0030_v1.md): standing 1st-deposit bonus =
   20 % (< ~$19) / 25 % (>= ~$19.76), applied on 99.9 % of first deposits; deposits 2+ get 6-10 % (mostly
   6-7 %). Consequence (winner-take-max): HH slots <= 25 % are a no-op for new clients; any slot >= 10 %
   beats the standing bonus for returning clients. Decision still owed: slots 30 %+ or a different prize
   type for new clients (see #2).
2. Follow-on: give NEW clients Free Ticket / Coins and reserve Deposit Bonus for RETURNING clients?
3. PARTLY ANSWERED from the backend doc (2026-09-02): `client_happy_hours.prize_won` JSONB stores the NOMINAL
   roll only (type/weight/amount/case_id); there is no prize-cost column at all. Applied % exists only in
   `public.deposits.bonus_amount`. Ask dev for a `happy_hour_prize_applied` event or confirm the join path
   (prize_won + deposits.bonus_amount by client_id/time) and that `group` is persisted in DB.
4. Habituation: one static prize × 21 days may decay by week 2–3. Proposed: 3–5 bonus % slots now,
   vary composition by WEEK (not day), keep H1/H2 symmetric. Not decided with manager.
5. No planner end date → manual stop or dev ticket.
6. CLOSED 2026-09-01: dev implemented the split for logged-in users (see Dev update). Still to confirm: assignment persisted in DB and joinable to deposits by client_id.
Dev tickets identified: real `Weight` selection; re-enable spin-once check; planner end-date field.

## SUPERSEDING FINAL 2026-09-08 (docs/happy-hour-simple-final_2026-09-08_v1.md)
The two-run plan below (Run 1 prize + Run 2 timing) is SUPERSEDED. One run only:
21 days, ONE window **17:00-22:00 UTC** (duration 300, cyclic), three arms
G0 control / G1 Deposit Bonus 50 % cap $100 (single slot) / G2 one free case $5-10.
Start >= 2026-09-10, manual stop day 22.
**Why the timing question is dead, not deferred:** 21-day reach of a window
(live DB 2026-09-08, `_reports/blc-data_2026-09-08_reach_v1.md`): 02-05 UTC reaches
7.0 % of 26 551 logged-in clients, 18-21 UTC 20.3 %, 17-22 UTC 32.1 %, 16-23 UTC 42.6 %.
The 02-05 arm would need ~+79 net-new depositors where its window yields ~37 depositors
of any kind per 21 days. No prize strength rescues it.
**Primary metric changed:** depositor rate on the IN-WINDOW EXPOSED subset in all three
arms (n = 2 843/arm, base 6.62 %, MDE 27.9 % rel / 30.7 % with multiplicity), with the
arm-level ITT reported alongside as the shipping number. This REQUIRES
`happy_hour_gate_shown` to fire for the CONTROL arm on the same in-window trigger —
hard blocker. Guardrail needs no new events: arm differences on capped revenue minus
arm differences on `deposits.bonus_amount` minus (cases awarded x fixed case cost).
**Rejected 2026-09-08:** the mixed-pool single-planner fallback — the prize is rolled
AFTER the qualifying deposit, so it cannot explain that deposit, and one client can draw
both prizes. If group -> planner routing is impossible, that is a stop-and-replan.
Reviewed independently by a CS2-CMO agent, a data-analyst agent and SHERIFF (codex);
5 sheriff findings, all closed in the doc.

## FINAL 2026-09-02 (docs/happy-hour-final_2026-09-02_v1.md): two runs — Run 1 prize test at 18 UTC
(control / DB 30-40-50 % / case), 3 wk; 1 wk pause; Run 2 timing test with the winner, re-randomized, 3 wk.
Primary metric = depositor rate + deposits per logged-in client (MDE ~19 % at 3 wk); capped revenue = guardrail.
Needs dev: group → planner routing at one cron. Reply to eugene_s written in RU in the same file.

## Pending owner decisions (2026-09-02, from the Ukrainian session — resolved by FINAL above unless owner objects)
D1 prize design: A = Deposit Bonus 30/40/50 % all; B = segmented new/returning (needs dev condition type);
C = mixed pool for all (DB 30/40/50 % + 1 Free Ticket slot, identical H1/H2) - RECOMMENDED, no dev work.
D2 prod start after 2026-09-09 (deposit_promotions case 776 ends 09-09). D3 events: prize_won + prize_applied
with applied_pct and prize_cost delta. D4 habituation: no weekly rotation in run 1.
Owner's own framing (2026-09-02): 'no Deposit Bonus in one mode, free case in another' - valid only if mode =
client type (new/returning), NEVER H1 vs H2 (would break the timing isolation).

## Read when
- happy hour, HH, deposit bonus, A/B test, H0/H1/H2, planner, prize pool, anti-farm, cannibalization,
  re-engagement, hour-of-day deposits
- Remote sources: host `bloodyanalytics02` → `~/docs/features/happy-hour-backend.md` (dev doc),
  DB `bloody` via `/mcpb` for live numbers.
