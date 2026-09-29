# BLC: deposit bonus on deposits 2+ vs payment-system margin (live DB, 2026-09-25)
Source: DB `bloody` via postgres MCP, `public.deposits`, paid (`paid_at IS NOT NULL`, `_ab_cdc_deleted_at IS NULL`,
amount > 0), paid in the last 90 days. Ordinal = rank among the client's paid deposits over all time.
Fee = `amount - profit_amount` (`profit_amount` = amount x (1 - `commission_multiplier`)). Bonus = `bonus_amount`
at FACE value (upper bound of its cost — bonus balance is played through the cases' house edge).
Bots/bloggers NOT excluded.

## Actual bonus rule (reverse-engineered from the data, not from config)
| deposit # | < $19 | $19–48.99 | $49–98.99 | $99–198.99 | $199+ |
|---|---|---|---|---|---|
| 2nd | 7 % | 7 % | 7 % | 8 % | (n/a, 2 deps) |
| 3rd+ | **0 %** | 6 % | 7 % | 8 % | 10 % |

Same % on every payment system. Cliff: a $5 2nd deposit gets 7 %, a $5 3rd deposit gets 0 %.

## Volume, deposits 2+ (90 d)
| deposit # | deps | clients | GMV | avg dep | % with bonus | bonus $ | bonus % GMV | fee % |
|---|---|---|---|---|---|---|---|---|
| 2 | 1 129 | 1 129 | $14 479 | $12.82 | 100 | $1 031 | 7.12 | 8.25 |
| 3 | 656 | 656 | $9 210 | $14.04 | 30.2 | $387 | 4.21 | 8.02 |
| 4–5 | 866 | 560 | $14 661 | $16.93 | 37.0 | $701 | 4.78 | 7.71 |
| 6–10 | 1 180 | 459 | $23 349 | $19.79 | 38.0 | $1 181 | 5.06 | 7.26 |
| 11+ | 7 234 | 692 | $242 400 | $33.51 | 59.7 | $17 263 | 7.12 | 7.57 |
| **total** | 11 065 | — | **$304 099** | — | — | **$20 563** | **6.76** | ~7.6 |

11+ (692 clients) = 80 % of 2+ GMV and 84 % of the 2+ bonus.

## Fee + bonus by payment system x amount band (deposits 2+, 90 d, % of GMV)
| PS | fee (DB) | < $19 | $19–49 | $49–99 | $99–199 | $199+ | GMV |
|---|---|---|---|---|---|---|---|
| 82 | 7.2–10.9 % (regressive) | 11.8 | 14.3 | 14.5 | 15.3 | **17.2** | $279k |
| 5 | 5 % flat | 6.7 | 11.2 | 12.0 | 13.0 | 15.0 | $10.7k |
| 83 | 0 % | 2.8 | 6.1 | 7.0 | 8.0 | 4.7 | $7.0k |
| 94 | 0 % | 1.0 | 6.1 | 7.0 | 8.0 | 10.0 | $6.7k |
| 97 | 8 % | 11.5 | 14.9 | — | — | — | $0.4k |

PS 82's fee falls with ticket size (10.9 % -> 7.2 %) while the bonus rises (0 -> 10 %), so its biggest tickets are
the least profitable per $ (17.2 % off the top). PS 83/94 show fee 0 in the DB — UNVERIFIED whether that is real
or just not recorded. PS 94 had ~5 % payment success in Aug–Sep (_reports/blc-aug-sep-yoy_2026-09-18_v1.md).

## Return behaviour (paid 30–90 days ago, share with a next paid deposit)
| deposit # | band | deps | next ≤7 d | next ≤30 d |
|---|---|---|---|---|
| 2 | < $19 | 559 | 36.5 % | 46.9 % |
| 2 | $19–49 | 153 | 49.7 % | 52.3 % |
| 3–10 | < $19 (0 % bonus) | 1 157 | 54.5 % | 67.2 % |
| 3–10 | $19–49 (6 %) | 550 | 62.7 % | 72.7 % |
| 11+ | < $19 | 1 940 | 75.5 % | 87.0 % |
| 11+ | $199+ (10 %) | 268 (32 clients) | 94.4 % | 96.3 % |

Correlation only: bigger tickets are also more engaged players. The 2 -> 3 step is the leak (~half never return);
the $199+ tier pays 10 % to 32 regulars who return within a week 94 % of the time anyway.

## Presets dominate amounts
Most common 3+ amounts: $19.99 (1 368), $25 (1 355), $5 (1 123), $5.99 (1 098), $9.99, $10, $49.99, $200 (306),
$99, $199. Tiers sit just below presets ($19 / $49 / $99 / $199), so the ladder rewards preset clicks rather than
pushing anyone up a step. Real threshold elasticity is unknown — needs an A/B test.

## Options (90-day effect at static behaviour, face value)
| # | change | $ / 90 d | risk |
|---|---|---|---|
| A | $199+ tier 10 % -> 8 % | +$1.6k margin | 32 whales notice; possible churn in the top tier |
| B | fee-aware bonus: +2–3 pp on zero-fee methods | per migrated $: −2–3 pp bonus, +7–11 pp fee saved | only if the 0 % fee is real and that method converts (PS 94 does not) |
| C | bridge to #3: 5 % on < $19 for deposits 3–5 (or "3rd within 7 d") | −~$0.65k | cheap; target = 2->3 return 47–52 % |
| D | ladder that upsells: $25 5 % · $50 8 % · $100 10 % (cap) | unknown — test | changes preset behaviour; A/B only |
| E | 2nd deposit: tie the 7 % to the ticket (0 % under $10, 7 % from $10) | +~$0.3k | hits the weakest cohort; pair with C |

Recommended test: A+C together (fund the 2->3 bridge from the top-tier cut), primary metric = 30-day return
after deposit #2/#3, guardrail = 11+ GMV per client.

## SQL (core)
```sql
WITH d AS (
  SELECT client_id, amount, coalesce(bonus_amount,0) bonus, coalesce(profit_amount,amount) profit,
         payment_system_id ps, paid_at,
         row_number() OVER (PARTITION BY client_id ORDER BY paid_at, id) n,
         lead(paid_at) OVER (PARTITION BY client_id ORDER BY paid_at, id) nxt
  FROM public.deposits WHERE paid_at IS NOT NULL AND _ab_cdc_deleted_at IS NULL AND amount>0)
SELECT ... FROM d WHERE n>=2 AND paid_at >= now() - interval '90 days' GROUP BY ...;
-- bands: <1900 / <4900 / <9900 / <19900 / else (cents); fee = sum(amount)-sum(profit)
```
