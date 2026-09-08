# Run report — Happy Hour: simple final design (2026-09-08)
Row: NORMAL (product/strategy deliverable, client-facing; no application code touched).
Owner ask: "take the SMM/CMO CS2 marketer + data analyst skills, think with the sheriff,
write me a very simple final variant" — owner's own framing: one prize per window,
case in one range, deposit bonus in the other.

## Verdict: GREEN
Deliverable written, reviewed by three independent passes, all findings closed.

## What was produced
- `docs/happy-hour-simple-final_2026-09-08_v1.md` — the plan (UA), supersedes the
  2026-09-02 two-run plan.
- `_reports/blc-data_2026-09-08_reach_v1.md` — new live-DB pull (window reach + the
  exposed-subset power calculation) with SQL.
- `.agent/capsules/happy-hour-ab-test.md` — SUPERSEDING FINAL section prepended.
- `.agent/state/current.json` / `current.md` — patch #22.
- `tasks/lessons.md` — one lesson (size a test on REACH, not on arm size).

## Inputs
- Owner request (2026-09-08): "take the SMM/CMO CS2 marketer + data analyst skills, think
  with the sheriff, write me a very simple final variant"; owner's design: case in the
  02-05 UTC range, deposit bonus in the 18-21 UTC range, compare deposits.
- `.agent/capsules/happy-hour-ab-test.md` (design history, backend mechanics, admin-panel
  prize types verified by screenshot 2026-08-27).
- `docs/happy-hour-final_2026-09-02_v1.md` (the two-run plan being superseded).
- `_reports/blc-data_2026-09-02_1830_v1.md` (power/MDE), `_reports/blc-data_2026-09-02_0030_v1.md`
  (standing deposit bonus tiers), `_reports/happy-hour-test-design-options_2026-09-02_v1.md`.
- Live DB `bloody` via /mcpb (read-only): `public.client_login_records`, `public.deposits`.
- `.agent/capsules/blc-db-schema.md` (table map, query constraints).

## Reviewers (parallel, independent)
| reviewer | verdict | material contribution |
|---|---|---|
| gaming-product-owner (CS2 CMO lens) | design as proposed by owner: do not ship on it | reach asymmetry rigs the race; free case is the re-engagement hook, bonus is the conversion multiplier; cut Run 2, cut the 30/40/50 pool |
| data analyst (general-purpose) | owner's B-vs-C contrast not identifiable | formal aliasing proof; the +79-vs-37 depositor arithmetic; the exposed-subset primary analysis that halves the required true effect |
| SHERIFF (codex, cross-vendor) | 5 findings, 4x P1 + 1x P2 | see below |

## Sheriff findings — all closed
1. [P1] 21-day decision not supported by the power calc; no prespecification →
   section C now names ONE primary comparison (G1 vs G2), alpha 0.025, the
   inconclusive rule, and the exposed-subset MDE recomputed from live data
   (n=2843/arm, base 6.62 %, MDE 27.9 % rel). Sheriff independently reproduced and
   confirmed the +62 % / +145 % exposure figures; the +42 % five-hour figure it could
   not verify is now derived from a pull it did not have (17-22 exposed depositor rate).
2. [P1] Mixed-pool fallback destroys the causal comparison (prize is rolled AFTER the
   qualifying deposit) → fallback REMOVED, recorded in failed_rejected.
3. [P1] Guardrail had no measurement spec → arm-difference method specified; needs no
   new events.
4. [P1] "Config-only" claim false — routing is dev work → section D rewritten as three
   explicit dev asks; the free-case prize type raised to a go/no-go.
5. [P2] Mandatory group persistence is an unnecessary blocker → softened to "persist OR
   hand over the deterministic hash mapping".

## Finding found by the author after the sheriff pass (own re-read of the capsule)
The 2026-08-27 admin-panel screenshot already records that the planner offers
**Deposit Bonus / Coins / Free Ticket only — no PromoCode**, i.e. a real free case
cannot be a prize today. The doc originally treated this as an open question; it is now
an explicit ⚠ section with three ranked G2 options (Coins > Free Ticket > PromoCode+dev)
and a go/no-go to eugene_s. Without G2 there is nothing to compare the bonus against.

## Artifacts
- `docs/happy-hour-simple-final_2026-09-08_v1.md` — the plan (UA), owner-facing.
- `_reports/blc-data_2026-09-08_reach_v1.md` — reach + exposed-subset power, with SQL.
- `_reports/runs/happy-hour-simple-final_2026-09-08.md` — this report.
- `.agent/capsules/happy-hour-ab-test.md` — SUPERSEDING FINAL section.
- `.agent/state/current.json` + `current.md` — patch #22.
- `tasks/lessons.md` — one lesson appended.
- Commit `cabed04` (also lands the four uncommitted 2026-09-02 happy-hour artifacts).

## Evidence
- Live DB pulls this run (read-only, via /mcpb): window reach 21 d; depositor cut;
  reach vs window length; 17-22 exposed depositor rate. SQL in the data report.
- MDE arithmetic re-derived in-session: n=2843, p=0.0662 → 1.85 pp = 27.9 % rel
  (30.7 % with x1.10 multiplicity). Matches the sheriff's independent 18.9 %/21.8 %
  full-arm figures under the same formula.

## Not done / out of scope
- Nothing sent to the dev team — the owner sends section D.
- No application code touched (SCOPE LIMIT).
- Free Ticket / Coins economics remain unknown: not in the DB replica, must come from dev.

cross_review: closed 2026-09-08 [5 findings, all fixed]
