# Run: Start Season vs previous event — extended daily table, day-by-day, where it failed (DB + GA4 + GSC) — 2026-09-29
Row: NORMAL (analysis deliverable, no prod). Builder: orchestrator (postgres MCP read-only; GA4 Data API + Search Console via service account).
Team: verifier (3 passes).

## Inputs
- Owner ask (2026-09-29): add reg→FTD conversion, repeat deposits, avg new/repeat deposit etc. to the 01.08–28.09 daily table; compare the
  new event day by day with the previous one; find where we failed; check GA4 + Search Console; one comprehensive summary table.
- Live DB `bloody` (public.clients / deposits / client_login_records, analytics.first_deposit, stats.event_transactions,
  public_fwd.payment_systems), GA4 property 282943360, Search Console bloodycase.com — all queried 2026-09-29.

## Verdict: GREEN
verifier pass 1 RED (4 over-claims + 5 non-critical; all numbers correct) → pass 2 RED (1 broken sentence) → pass 3 GREEN.

## Findings (all closed)
- CLOSED [HIGH] h1 stated cause as fact → observation ("Новачки на рівні; просіли повторні депозити й успішність оплати").
- CLOSED [HIGH] "drop started before the event" on one week → both baselines shown (week before −1%, 20-day window −18%).
- CLOSED [MED] "event activity did not drop" → "daily XP activity" (3+/7+ day retention is −6%/−8%).
- CLOSED [MED] GSC 20 vs 19 days raw → per day (Turkey −18%).
- CLOSED [LOW] ×6: bot-country wording (×2), key events ≠ payments, KPI rounding, "card" for Zen, R4 missing.

## Key result
New players flat/up (FTD/day +5%); repeat GMV/day −28%; payment attempts +3% but client success 53.7% → 47.4%; Turkey −$16.0k of
−$19.3k, Zen success in TR 69% → 42% from w/c 09-07. SEO not the cause (+11% clicks/day).

## Artifacts
- _reports/start-season-event_2026-09-29_v2.html (client page, UA) — proof: temp/ss-v2-part0..4.png, temp/ss-v2-ga.png, temp/ss-v2-mobile-top.png (no horizontal overflow at 390px; 0 clipped cards at 1280px)
- _reports/blc-data_2026-09-29_2114_v1.md (all numbers + SQL + GA4/GSC method)
- .agent/capsules/blc-db-schema.md (payment methods + deposit statuses) · tasks/lessons.md (+1)

## Open (owner / client)
- Zen decline codes for Turkey since 07.09 (bank decline / 3DS / limit / abandoned) and whether anything changed in Zen or the cashier ~07.09.
