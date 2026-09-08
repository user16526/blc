# BLC data: Happy Hour REACH per window (live DB, 2026-09-08)
Source: DB `bloody` via /mcpb (read-only), `public.client_login_records`, `public.deposits`.
Window = hour-of-day of `logged_at` (timestamp w/o tz, assumed UTC). Horizon = last 21 days
(= one test run). Reach = client had >= 1 login inside the window at least once in 21 days.
Purpose: the exposure/dilution input that the 2026-09-02 power analysis
(`_reports/blc-data_2026-09-02_1830_v1.md`) did NOT have — it assumed 100 % exposure.

## Headline
**A 3-hour Happy Hour window reaches only 20.3 % of logged-in clients (evening) and 7.0 %
(morning) over a whole 21-day run.** The arm-level MDE of ~19 % relative on depositor rate
therefore requires a lift of ~+62 % (evening) or ~+145 % (morning) among the clients who can
actually SEE the modal. The morning window is arithmetically untestable in 3 weeks.
**Widening the evening window to 5 h raises reach to 32.1 %, to 7 h -> 42.6 %.** Window
DURATION is the largest power lever available and costs no dev work (planner `duration` field).

## Q1. Reach by window, 21 days
| segment | clients | reach 02-05 UTC | reach 18-21 UTC |
|---|---|---|---|
| all logged-in | 26 551 | 1 857 (**7.0 %**) | 5 384 (**20.3 %**) |
| depositors (21 d) | 1 254 | 162 (12.9 %) | 376 (30.0 %) |

Depositors are over-represented in both windows, i.e. exposed clients have a HIGHER baseline
depositor rate than the arm average:
- evening exposed: 376 / 5 384 = **6.98 %** vs non-exposed 878 / 21 167 = 4.15 %
- morning exposed: 162 / 1 857 = **8.72 %**

## Q2. Reach vs window length (evening, 21 days)
| window (UTC) | length | reach | required lift among exposed to hit arm MDE |
|---|---|---|---|
| 18-21 | 3 h | **20.3 %** | ~ +62 % rel |
| 17-22 | 5 h | **32.1 %** | ~ +42 % rel |
| 16-23 | 7 h | **42.6 %** | ~ +33 % rel |
| 14-24 | 10 h | 57.4 % | ~ +25 % rel |
(n = 26 549 for this pull; 2 clients dropped between pulls — CDC replica moves.)

## Derivation of the "required lift among exposed"
Arm depositor rate = (1-p)*r_off + p*r_on. Only exposed clients can respond, so an arm-level
relative lift L needs an exposed-subgroup relative lift of roughly L * (arm rate) / (p * r_on).
With arm rate 4.72 %, p = 0.203, r_on = 6.98 %, L = 0.187 -> +62 %.
Morning: p = 0.070, r_on = 8.72 %, same L -> +145 %.

## Implications
1. The 02-05 UTC arm cannot produce a readable result in 3 weeks at any plausible prize
   strength. A timing test that includes it is a wasted run -> **drop the morning window**.
2. A 3-hour evening window is borderline; **5 h (17-22 UTC = 20:00-01:00 Kyiv) is the cheapest
   real power gain** (reach 20.3 % -> 32.1 %), planner `duration = 300`, no dev work.
3. This does not change the primary metric (depositor rate) or the guardrail (capped revenue).
4. Secondary read that stays free: among EXPOSED clients only (those with `happy_hour_shown`),
   treatment vs control-with-same-login-pattern — higher power, weaker causal claim (post-hoc
   conditioning on exposure), so it is a supporting read, never the decision.

## SQL used
```sql
-- reach: WITH l AS (SELECT client_id, max(CASE WHEN extract(hour from logged_at) IN (...) THEN 1 ELSE 0 END) ...
--   FROM public.client_login_records WHERE logged_at >= now() - interval '21 days'
--   AND _ab_cdc_deleted_at IS NULL GROUP BY client_id) SELECT count(*), sum(...)/count(*) FROM l;
-- depositor cut: JOIN (SELECT DISTINCT client_id FROM public.deposits
--   WHERE paid_at >= now() - interval '21 days' AND _ab_cdc_deleted_at IS NULL AND amount > 0)
```
## Caveats
- `logged_at` timezone assumed UTC (unverified, same assumption as all prior pulls).
- Login != seeing the modal: a client logged in at 18:05 who leaves at 18:10 counts as reached
  here but may still miss the gate. So these reach numbers are an UPPER bound; real exposure is
  lower, which makes the conclusion stronger, not weaker.
- Bots/bloggers not excluded; multiple accounts per person possible.
- 21-day login population is a proxy for "clients who will get `happy_hour_gate_shown`".

## Q3. Exposed-subset baseline for the recommended 17-22 UTC window (added after review)
| metric | value |
|---|---|
| clients reachable 17-22 UTC, 21 d | 8 529 (32.1 % of 26 549) |
| of them, depositors in 21 d | 565 |
| exposed depositor rate | **6.62 %** |
| n per arm (exposed, 3 arms) | 2 843 |
| MDE on the exposed subset | **1.85 pp = 27.9 % relative** (30.7 % with x1.10 multiplicity) |
Formula: MDE_abs = 2.8 * sqrt(2p(1-p)/n), p = 0.0662, n = 2843. Verified 2026-09-08.
This replaces the arm-level ITT as the PRIMARY analysis: the effect is undiluted there,
so the required TRUE effect drops from +42 % (ITT at 32.1 % exposure) to +28 %.
Precondition: `happy_hour_gate_shown` must fire for the CONTROL arm on the same in-window
trigger, otherwise the exposed subset is not comparable across arms.

## Review trail (2026-09-08)
CS2-CMO agent, data-analyst agent and SHERIFF (codex, cross-vendor) reviewed the design
independently. Convergent: kill the 02-05 arm, hold the window constant, vary the prize.
Sheriff findings closed in `docs/happy-hour-simple-final_2026-09-08_v1.md`:
[1] power/prespecification -> section C (named primary comparison, alpha 0.025, inconclusive
    rule, exposed-subset MDE computed); [2] mixed-pool fallback -> removed (prize is rolled
    AFTER the qualifying deposit, so it cannot explain it); [3] guardrail spec -> arm-difference
    method, needs no new events; [4] "config-only" claim -> corrected, routing IS dev work and
    the free-case prize type is an explicit go/no-go question; [5] group persistence -> softened
    to "persist OR hand us the deterministic hash mapping".
