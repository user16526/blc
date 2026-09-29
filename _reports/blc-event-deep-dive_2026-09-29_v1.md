# Event deep-dive — Start Season 2026 + why events don't drive deposits
Source: live replica `bloody` via postgres MCP, queried 2026-09-29. Days UTC (assumed). Money = USD (cents/100).
Current event `ae9a967d…` (startseasonevent2026) 2026-09-08 20:00 → 2026-10-06. Previous `ddcce517…` (nonameresort2026).
Companion: `_reports/blc-data_2026-09-29_2002_v1.md` (daily table + 20-day windows).

## TL;DR
1. **The event is the same template every time.** The last 11 events (since 2025-07-29) have IDENTICAL XP rules
   (md5 of `events.rewards` equal) and the same 25-level / 475,000-XP curve. They run back to back with no gap. Only the
   theme and the reward skins change → for the player, "new event" = reskin of a permanent feature.
2. **93% of participants never reach level 1.** 12,993 of 14,024 have < 1,000 XP. L1 needs 1,000 XP; a $5 deposit gives
   800 XP; a case open gives 20 XP (80 on event cases). 1,031 players reached L1+, and ≈94% of those (974) are depositors.
3. **The pass is money-gated and long.** 58% of all XP comes from deposits (source 7). Full pass = 475k XP ≈ $2,300 of
   deposits (deposit XP is ~160–220 XP per $). Level 10 (26k XP) ≈ $140 in deposits, or 1,300 regular case opens.
   Deposits > $500 have no tier (table ends at $500; likely 0 XP, unverified) → the biggest deposits are ignored.
4. **Launches don't move payers.** Across 12 launches (Jun 2025 → Sep 2026), payers in the 14 days after vs before:
   −22% … +6%, typical ≈ +1%. GMV swings −24% … +23% and follows whales, not the event.
5. **This launch: GMV fell almost entirely in big deposits (−$12.4k of −$13.4k).** 20 days after vs 20 days before: $50+ deposits $35.0k → $22.6k (−35%),
   deposit count 285 → 177. Deposits < $50 flat ($37.9k → $36.9k). Total GMV −18%.
6. **Cost of the event (20 days): ≈ $8k in skins to real players ≈ 13% of GMV.** Level rewards $5.1k (995 players) +
   coin shop ≈ $2.8k to real players. A further **$6.0k of $500 skins went to one account** (`flags=128`, $0 deposits,
   10,000,000 coins granted manually, source 13) — internal/promo account; needs owner confirmation that this is intended.
7. **Macro trend is the bigger problem.** Payers per month: 3,418 (Mar 2025 peak) → 2,124 (Sep 2025) → ~1,800 (Sep 2026, 30-day
   equiv.). Registrations are UP YoY (+54% per day, Sep vs Sep), but reg → first-deposit fell 7.6% → 4.1%. Sep 2026 GMV/day
   $2.9k is the lowest month since Jan 2025.

## Event mechanics (from `stats.events`)
XP sources (`rewards` jsonb, identical since Jul 2025):
| source | what (inferred) | XP | coins |
|---|---|---|---|
| 1 | case open | 20 (80 on event cases 618–635) | 9–13 (35–53) |
| 2 | other game action (upgrade/battle?, unmapped) | 20 | 9–13 |
| 3 | game action (unmapped) | 50 | 22–32 |
| 7 | deposit $5–9.99 / 10–19.99 / 20–49.99 / 50–99.99 / 100–149.99 / 150–199.99 / 200–249.99 / 250–500 | 800 / 1,650 / 3,500 / 9,000 / 19,000 / 30,000 / 42,000 / 55,000 | ≈ 0.6 × XP |
| 8 | (unmapped, 66 players) | 500 | 50–100 |
| 6 | not in config; 132 players small amounts, 3 finishers ~835k each (unmapped) | — | — |

Level curve: L1 1,000 · L5 cum 7,400 · L10 26,000 · L15 72,000 · L20 186,500 · L25 475,000. Each level = 1 skin
(+ coins / reward_type 3 on some). Coin shop: 1,000 coins = $1 skin (flat rate across all price points, $0.51 → $501);
reward_type 3/4 items also sold (unmapped — likely free cases / bonus).

## XP by source (current event, to date)
| source | players | share of XP |
|---|---|---|
| 7 deposit | 1,311 | 58.2% |
| 1 case open | 10,235 | 14.8% |
| 2 | 5,125 | 12.7% |
| 6 | 134 | 11.9% |
| 3 | 1,267 | 2.0% |
| 8 | 66 | 0.3% |

## Progress funnel (current event, to date)
| level reached | players | of them depositors | XP from deposits |
|---|---|---|---|
| < L1 | 12,993 (92.6%) | 337 | 11% |
| L1–4 | 809 | 756 | 67% |
| L5–9 | 154 | 153 | 74% |
| L10–14 | 52 | 51 | 80% |
| L15–19 | 13 | 12 | 76% |
| L25 | 3 | 2 | 56% |

## Deposit mix, 20 days before vs after launch
| deposit size | before: deps / $ | event: deps / $ |
|---|---|---|
| $5–9 | 1,555 / 10,061 | 1,580 / 10,041 |
| $10–19 | 593 / 9,723 | 531 / 8,447 |
| $20–49 | 582 / 18,085 | 623 / 18,425 |
| $50–99 | 134 / 9,709 | 93 / 6,025 |
| $100–500 | 151 / 25,334 | 81 / 13,583 |
| > $500 (no tier) | 0 / 0 | 3 / 2,998 |

## Launches vs payers (14 days after vs 14 before)
| launch | event | GMV chg | payers chg |
|---|---|---|---|
| 2025-06-10 | (pre-template) | +23% | +1% |
| 2025-07-29 | (template starts) | +22% | +1% |
| 2025-09-03 | backtogame | +1% | +4% |
| 2025-10-03 | candybattle | −3% | −1% |
| 2025-11-04 | bfridaycmoney | −24% | −22% |
| 2025-12-03 | xmasloot | −17% | +2% |
| 2026-01-06 | gravityblast | +16% | +6% |
| 2026-02-17 | rabbithunt | +15% | +6% |
| 2026-04-14 | majorbattleofcologne | −8% | 0% |
| 2026-06-22 | worldcasecup | +4% | −1% |
| 2026-07-22 | nonameresort | +15% | −3% |
| 2026-09-08 | startseason | −7% | +5% |

## Monthly trend (paid deposits; Sep 2026 = 28 days)
| month | GMV $ | payers | ARPPU $ | avg deposit $ | FTD | registrations |
|---|---|---|---|---|---|---|
| 2025-03 | 139,348 | 3,418 | 40.8 | 15.4 | 2,431 | 39,364 |
| 2025-09 | 116,641 | 2,124 | 54.9 | 20.1 | 1,327 | 17,496 |
| 2026-03 | 146,640 | 2,557 | 57.3 | 20.9 | 1,583 | 29,885 |
| 2026-06 | 138,511 | 1,814 | 76.4 | 26.9 | 1,020 | 28,460 |
| 2026-07 | 139,801 | 1,787 | 78.2 | 26.8 | 1,074 | 44,126 |
| 2026-08 | 113,855 | 1,859 | 61.2 | 22.4 | 1,148 | 25,869 |
| 2026-09 | 82,401 | 1,681 | 49.0 | 20.8 | 1,033 | 25,094 |
Full series (payers / GMV $), all months, used for the HTML chart:
2025-01 2,562 / 88,981 · 02 3,011 / 103,878 · 03 3,418 / 139,348 · 04 2,728 / 123,686 · 05 2,677 / 132,770 ·
06 2,394 / 144,280 · 07 2,234 / 128,286 · 08 2,222 / 113,364 · 09 2,124 / 116,641 · 10 2,647 / 144,098 ·
11 2,279 / 134,746 · 12 1,894 / 110,348 · 2026-01 1,968 / 129,151 · 02 2,197 / 108,838 · 03 2,557 / 146,640 ·
04 2,237 / 161,072 · 05 2,279 / 135,604 · 06 1,814 / 138,511 · 07 1,787 / 139,801 · 08 1,859 / 113,855 · 09 (1–28) 1,681 / 82,401.
SQL: `select date_trunc('month',paid_at), count(distinct client_id), sum(amount)/100.0 from public.deposits
where paid_at >= '2025-01-01' and paid_at < '2026-09-29' and _ab_cdc_deleted_at is null group by 1 order by 1;`
(plus analytics.first_deposit and public.clients real-user predicate for FTD / registrations per month).
Pattern: the payer base shrinks while ARPPU rose to mid-2026 → revenue became whale-dependent; when whales cool (Aug–Sep),
GMV drops and nothing underneath replaces it.

## Caveats
- Source/reward_type enums are inferred from config + data, not app code (sources 2, 3, 6, 8; reward_type 3/4).
- Deposits/FTD include the unflagged internal accounts (see 2026-09-09 report); the `flags=128` account is excluded from
  the "real players" shop figure only.
- Launch comparisons are before/after, not controlled; seasonality and traffic mix are not separated.

## SQL (key queries)
```sql
-- XP rules identical across events
select start_at, md5(rewards::text) = (select md5(rewards::text) from stats.events where id='ae9a967d-a97c-4996-8e8c-60eef48c57e7') same,
  (select sum((v->>'xp_to_complete')::int) from jsonb_array_elements(levels) v) total_xp
from stats.events where deleted_at is null order by start_at desc limit 15;
-- progress funnel
with x as (select client_id, sum(amount) xp, sum(amount) filter (where source=7) dep_xp from stats.event_transactions
  where event_id='ae9a967d-a97c-4996-8e8c-60eef48c57e7' and type=1 and _ab_cdc_deleted_at is null group by 1)
select case when xp<1000 then '<L1' when xp<7400 then 'L1-4' when xp<26000 then 'L5-9' when xp<72000 then 'L10-14'
  when xp<186500 then 'L15-19' when xp<475000 then 'L20-24' else 'L25' end b, count(*), count(*) filter (where dep_xp>0)
from x group by 1;
-- reward payout ($, buyout) — level vs exchange
select case when reason>='event level' and reason<'event lever' then 'level' else 'exchange' end, count(*), count(distinct client_id), sum(buyout_price)/100.0
from public.client_items where ((reason>='event level' and reason<'event lever') or (reason>='event exchange' and reason<'event exchangf'))
  and reason like '%ae9a967d%' and _ab_cdc_deleted_at is null group by 1;
-- launches vs payers: 14d windows around each stats.events.start_at over public.deposits (paid_at), see report text.
```
