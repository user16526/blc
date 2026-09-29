# Run: Event deep-dive (Start Season 2026) + why events don't drive deposits + report base style — 2026-09-29
Row: NORMAL (analysis deliverable, no prod). Builder: orchestrator (live DB via postgres MCP).
Team: gaming-ux-strategist (competitor research) · gaming-product-owner (diagnosis + strategy) · verifier (2 passes).

## Inputs
- Owner ask (2026-09-29): polish the report style into a base; deep-dive the event (what's in it, where it went); why events don't drive; analyst + trends + competitors.
- Live DB `bloody` (stats.events / event_clients / event_transactions / event_exchanges(+_transactions), public.deposits / clients / client_items, analytics.first_deposit), queried 2026-09-29.
- Live bloodycase.com/ua/events config; competitor sites (URLs in competitor report); prior reports blc-aug-sep-yoy_2026-09-18, blc-geo-quality_2026-09-18.

## Verdict: GREEN
verifier pass 1 RED (2 critical, 6 over-claims, 5 non-critical) → all fixed → pass 2 GREEN.

## Findings (all closed)
- CLOSED [HIGH] "98% of L1+ are depositors" → ≈94% (974/1,031) — HTML + md.
- CLOSED [HIGH] 14 chart values lived only in the HTML → full 21-month series + SQL added to deep-dive md.
- CLOSED [MED] counterfactual headline ("deposits that would happen anyway") → "not proven incremental".
- CLOSED [MED] ">$500 = 0 XP" as fact → "no tier, likely 0 XP, unverified".
- CLOSED [MED] source-6 "~835k from it" → "mostly from it".
- CLOSED [MED] "all the drop is in big deposits, no goal for them" → "almost all (−$12.4k of −$13.4k); hypothesis".
- CLOSED [MED] competitor synthesis contradicted table → "extra commitment", wagering noted.
- CLOSED [MED] R3 config-only unconditional → conditional on leaderboard ranking on XP; chip shows pool cost.
- CLOSED [LOW] ×5: "з червня 2025", UTC assumed, ≈15× (estimate), ≥11.2%, delta-chip width.
- Own catch: Sep 2026 (28 d) vs Sep 2025 (30 d) raw → per-day comparison (+54% regs/day, −17% FTD/day).

## Artifacts
- _reports/event-deep-dive_2026-09-29_v1.html (client page, UA) — proof: temp/event-deep-dive-desktop.png, temp/event-deep-dive-desktop-v2.png, temp/event-deep-dive-mobile.png
- _reports/blc-event-deep-dive_2026-09-29_v1.md (data + SQL)
- _reports/event-strategy_2026-09-29_v1.md (diagnosis, R1–R7, measurement)
- _reports/competitor-events_2026-09-29_v1.md (7 competitors, URLs)
- _reports/start-season-event_2026-09-29_v1.html + _reports/blc-data_2026-09-29_2002_v1.md (daily table, part 1)
- _reports/_template/report-base.html (new report base style)
- .agent/capsules/blc-db-schema.md (events tables mapped) · tasks/lessons.md (+1)

## Open (owner / client)
- Is the flags=128 account's 10M-coin grant + $6.0k skins intended? What is XP source 6? Leaderboard ranking basis + >$500 tiers?
- Stale "NO NAME RESORT" MainTitleToken in the live event config (dev/ops fix).
