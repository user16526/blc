# Run report — Happy Hour TZ v2 + SHERIFF (2026-09-23)
Row: NORMAL (product spec; no application code). Owner: "look at the admin screenshot and discuss with the sheriff".

## Verdict: GREEN (spec rewritten to admin-only; all 5 sheriff findings addressed)

## Inputs
- `docs/happy-hour-tz_2026-09-23_0300_v1.md`; admin screenshot `temp/Screenshot 2026-09-23 214025.png`;
  manager's admin description (owner-pasted); Ivan/Eugene answers 2026-09-23; live DB case data.

## Sheriff findings (codex, cross-vendor) -> resolution
1. [High] Prize A/B in one window not configurable — groups map to WINDOWS (02/18 UTC), no audience field
   -> v2 tests ONE prize: H2 (18 UTC) vs H0 primary; H1 (02 UTC) secondary; prize A/B deferred to a dev ask.
2. [High] 3-week "winner" unsupported by power; daily net revenue cannot identify arm effect
   -> one primary question (depositor rate H2 vs H0, MDE ~27 %), inconclusive rule, cost = guardrail.
3. [High] $100 cap not settable; bonus applies to a LATER deposit, may be superseded
   -> default prize = case (immediate); bonus alternative uses the admin's deposit range $5-200 + 24 h validity (manager's field list).
4. [Medium] exposed-subset selection bias -> cohort fixed at first in-window visit, nobody dropped later.
5. [Medium] deposit-tier cases not configurable (Case ID only) -> single case ak-47 (id 3).

## Artifacts
- `docs/happy-hour-tz_2026-09-23_2200_v2.md` — admin-only TZ (UA).
- `_reports/runs/happy-hour-tz-sheriff_2026-09-23.md` — this report.

## Evidence
- Sheriff findings file: /tmp/tmp.7Tf3gM3p8e/sheriff-findings.txt (wrapper exit 0).

cross_review: closed 2026-09-23 [5 findings: 3 High + 2 Medium, all addressed in v2]
