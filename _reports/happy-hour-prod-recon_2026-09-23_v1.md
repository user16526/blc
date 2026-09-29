# Happy Hour on prod — what is actually built (recon, 2026-09-23)
Sources (all read-only): public prod frontend bundle `web.bloodycase.com/2026-09-linux-amd64/prod/`
(294 JS chunks, protobuf descriptors decoded), live DB `bloody` via /mcpb, GA4 Data API.
Owner statement 2026-09-23: "it is on prod but not launched; control-group work is done".

## Headline
**HH is shipped to prod but hidden behind a tester cookie (`HappyHourAccess`). The prize model
is richer than the 2026-08-27 admin screenshot: a REAL CASE prize exists, and the deposit bonus
has a rate range, deposit range and expiry.** The repo already has an A/B-test pipeline that
stores exposures and deposits per variant (`bloody_analytics.experiment_exposures`); Happy Hour
is NOT registered in it yet, and no HH events reach GA4 or that table.

## 1. Prize and condition options (proto `bloody/happy_hour/v1`, prod bundle)
- PrizeType: `CASE` (case_id) · `FREE_TICKET` · `EVENT_COINS` (amount) · `BONUS_DEPOSIT`.
- Prize fields: `type, amount, weight, case_id, bonus_id, min_rate, max_rate,
  min_deposit_amount, max_deposit_amount, duration_seconds, id`.
- Spin reward: `case_reward {case}` or `deposit_bonus_reward {bonus_id, rate, min/max_deposit_amount,
  duration_seconds}` -> the HH bonus is a bonus on a LATER deposit, valid for `duration_seconds`.
- Accounting: `PERSONAL_DEPOSIT_BONUS_CATEGORY_HAPPY_HOUR` — the HH bonus is its own personal-bonus
  category (interaction with the standing 20/25 % bonus — winner-take-max? — not visible client-side).
- ConditionType: `NO_CONDITION` · `OPEN_CASE` (count, specific_case_ids) · `MAKE_DEPOSIT` (count) ·
  `NOT_PARTICIPATED_24_HOURS`.
- HappyHour: `planner_id, starts_at, ends_at, status PLANNED/ACTIVE/FINALIZED`; realtime events
  `happy_hour_started / finished / all_completed`; balance ledger type `HAPPY_HOUR = 11`.
- UI: modal with roulette wheel + prize tabs (case / deposit / coins / tickets), fixed side
  trigger button, "you received X to your deposit" notification, page dims while active.
- Gate: frontend shows HH only when cookie `HappyHourAccess` equals a hard-coded token -> "on prod,
  not launched" confirmed.

## 2. Experiment infrastructure already live
`bloody_analytics.experiments / experiment_variants / experiment_exposures`
(exposure row: client_id, experiment_id, variation_id, event_type, deposit_id, created_at).
Running now: `payment-modal` (variants 0-4, since 2026-09-01; events show_payment_modal_variant,
click_make_deposit, purchase WITH deposit_id) and `kyc-withdrawal-verification` (0/1,
kyc_withdrawal_gate_shown, kyc_deposit_clicked). No `happy-hour` experiment row, no HH event_type.
GA4: zero events containing "happy" or "hh_" since 2026-08-01.

## 3. What this closes / changes in plan v2
- G2 go/no-go: **a real free case is a supported prize type** (`CASE`). Coins/Free Ticket fallbacks
  are no longer needed — confirm it is exposed in the admin planner.
- Dev asks 2+3 (control `gate_shown`, group -> deposit link) map 1:1 onto the existing pipeline:
  register experiment `happy-hour` with variants 0/1/2, fire `happy_hour_gate_shown` for ALL
  variants in-window, plus `purchase` with deposit_id — the same pattern `payment-modal` uses.
  Verifiable by us from the DB on day 1.
- G1 set-up: `min_rate = max_rate = 50`, `max_deposit_amount = $200` (= $100 cap), and a
  `duration_seconds` long enough to use it (the bonus applies to the NEXT deposit).
- New secondary metric: deposits per depositor — G1's value is realised only on a follow-up deposit.
- Concurrent experiments (payment-modal, KYC) randomise independently; record them, no action.

## Unverified
- Where the dev's "control-group" change lives — no HH experiment events in the prod frontend
  bundle or the DB; may be server-side and simply not yet emitting (HH not launched).
- Whether `weight` is still ignored and whether the HH bonus is winner-take-max vs standing bonus.
