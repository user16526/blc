# Run: Turkey payments — DB + GA4, weekly from May 2026, monthly from May 2025, Sep vs Sep — 2026-09-29
Row: NORMAL (analysis deliverable, no prod). Builder: orchestrator (postgres MCP read-only; GA4 Data API via service account).
Team: verifier (2 passes).

## Inputs
- Owner ask (2026-09-29): Turkey only — payments from DB and GA4 from May, by weeks and by month (month total + Sep 1–28),
  Sep 2026 vs Sep 2025: Zen success, payments, deposits overall, attempts.
- Live DB `bloody` (public.deposits country='TR', analytics.first_deposit), GA4 country = Türkiye — queried 2026-09-29.

## Verdict: GREEN
verifier pass 1 RED (3 MED + 5 LOW; all numbers correct) → pass 2 GREEN.

## Findings (all closed)
- CLOSED [MED] GA4 purchase gap dates wrong (25.05–21.06) → 20.05–23.06 from raw daily data, weeks 18.05 / 22.06 partial.
- CLOSED [MED] "same drop in every group" overstated → "drop in every group" (−9 pp new vs −17 pp repeat).
- CLOSED [MED] paid-deposit counts missing from tables → YoY rows (Zen attempts, paid deposits) + weekly/monthly column.
- CLOSED [LOW] ×5: break date 06.09 precedes the event (not caused by it), UA grammar "221 клієнт", other-countries Zen hedge,
  vs-August comparison added, stale screenshots re-shot.

## Key result
TR Zen success Sep 1–28 46.0% vs 63.3% (Sep 2025) and 63.7% (Jun–Aug 2026); break from 06.09. Clients trying to pay +69% YoY,
payers +33%, paid deposits −27%, GMV −3%. Drop in all segments (new/repeat, all amounts < $100) → payment side. ≈37 payers /
≈$5.5k GMV lost in 28 days (estimate). No decline reasons in the replica.

## Artifacts
- _reports/turkey-payments_2026-09-29_v1.html (client page, UA) — proof: temp/ss-tr-part0..2.png, temp/ss-tr-desk.png,
  temp/ss-tr-month.png, temp/ss-tr-mob.png (0 overflowing cards at 1280px; scrollWidth 390 at 390px)
- _reports/blc-data_2026-09-29_2135_v1.md (all numbers + SQL + GA4 method)
- .agent/capsules/blc-db-schema.md (+ empty payment_system_response, status-1 change, GA4 TR purchase gap) · tasks/lessons.md (+1)

## Open
- Backlog [LOW]: label the «оплачені деп.» basis (weekly = by created, monthly = by paid_at) in HTML s.2 note + md section 2 heading.
- Owner / client: Zen decline codes for Turkey since 01.09 and any change 06–08.09.
