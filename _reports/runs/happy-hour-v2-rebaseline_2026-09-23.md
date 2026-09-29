# Run report — Happy Hour plan v2: re-baseline + start 24.09 (2026-09-23)
Row: NORMAL (product/strategy deliverable; no application code touched). Automode on.
Owner ask: "taking into account deposits for the last 2 weeks and their behavior + a start date
of ~24.09, adjust the plan, text in Ukrainian".

## Verdict: GREEN
verifier: first pass RED (4 wording findings, every number and design decision confirmed);
all 4 fixed; re-check GREEN.

## What was produced
- `docs/happy-hour-simple-final_2026-09-23_0050_v2.md` — plan v2 (Ukrainian), supersedes v1 of 2026-09-08.
- `_reports/blc-data_2026-09-23_0050_v1.md` — live-DB re-baseline with SQL.
- `.agent/capsules/happy-hour-ab-test.md` — v2 section.

## Inputs
- Owner request 2026-09-23 (above).
- `docs/happy-hour-simple-final_2026-09-08_v1.md`, `_reports/blc-data_2026-09-08_reach_v1.md`,
  `.agent/capsules/happy-hour-ab-test.md`, `.agent/capsules/blc-db-schema.md`.
- Live DB `bloody` via /mcpb (read-only): `public.deposits`, `public.clients`,
  `public.client_login_records`, `public.deposit_promotions`, `analytics.first_deposit`.

## Key findings
- Design holds: last 14 d ≈ prior 14 d (965 vs 955 depositors); 17-22 UTC = 28.9 % of paid deposits.
- Power: reach 32.9 %, exposed depositor rate 7.01 %, n 2 929/arm, MDE 26.6 % rel (was 27.9 %).
- NEW: promo #104 (>= $25 -> case 809) ends 07.10 23:59 UTC -> days 15-21 without it; ask to extend to 15.10.
- NEW: first deposits 33 % of in-window deposits, avg $11.58 -> 50 % bonus adds ~$3.2 (new) vs ~$11.5
  (returning); blended $8.8 keeps cost parity; new/returning cut pre-registered as secondary.
- 24.09 is conditional: go/no-go checklist in section D (dev items 1-3 on prod, G2 type, promo, planners).

## Verifier findings — all closed
1. [MEDIUM] promo end mis-stated as "day 15" -> ends after the day-14 window; fixed in plan + data report.
2. [LOW] "2-3x" -> "1.5-3x". 3. [LOW] "Треть" -> "Третина". 4. [LOW] contradictory slip rule -> one rule.

## Artifacts
- `docs/happy-hour-simple-final_2026-09-23_0050_v2.md`
- `_reports/blc-data_2026-09-23_0050_v1.md`
- `_reports/runs/happy-hour-v2-rebaseline_2026-09-23.md` (this report)
- `.agent/capsules/happy-hour-ab-test.md`, `.agent/state/current.json` (patch #28)

## Evidence
- 5 read-only /mcpb pulls (SQL in the data report); arithmetic independently recomputed by verifier.

## Not done / out of scope
- Nothing sent to the dev team or the manager; the owner sends section D and the promo-extension ask.
- No application code touched (SCOPE LIMIT).
