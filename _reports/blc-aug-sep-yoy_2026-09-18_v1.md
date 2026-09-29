# Aug 1 – Sep 17: 2026 vs 2025 — registrations, payments, payment failures
Status: **COMPLETE** (GA4 + live DB, both halves).
Source: GA4 property 282943360, read 2026-09-18. **Singapore excluded from every GA4 number**
(115k-session bot wave, `_reports/blc-ga4-gtm-audit_2026-09-18_v1.md`).

## Verdict
Traffic grew, intent to pay held exactly flat, completed payments fell 10%. The whole gap is
the payment step, and it opens in **week 34 (Aug 17–23)** — the same week the DB showed the
PS 82 decline. 2025 is the control: it shows no such break in the same weeks.

## Aug 1 – Sep 17 totals (Singapore excluded)
| metric | 2025 | 2026 | Δ |
|---|---|---|---|
| sessions | 272,450 | 315,284 | +15.7% |
| new visitors (`first_visit`) | 96,572 | 148,825 | **+54%** |
| reached payment (`add_payment_info`) | 15,299 | 15,236 | **−0.4%** |
| completed (`purchase`) | 8,366 | 7,495 | **−10.4%** |
| payment-step conversion | **54.7%** | **49.2%** | **−5.5 pp** |

Two independent failures are visible in this table:
- **Top of funnel got worse.** +54% new visitors produced −0.4% payment attempts. More people
  arrive; the same absolute number ever try to pay.
- **Payment step broke.** Of those who do try, fewer succeed.

Holding 2025's payment-step conversion on 2026's attempts would have given ≈8,331 purchases
instead of 7,495 — **≈836 lost deposits** in this window from the payment step alone.

## Weekly payment-step conversion — where the break is
| ISO week | dates (approx) | 2025 | 2026 |
|---|---|---|---|
| 32 | Aug 4–10 | 57.7% | 56.4% |
| 33 | Aug 11–17 | 56.9% | 55.9% |
| **34** | **Aug 18–24** | 54.8% | **50.6%** |
| 35 | Aug 25–31 | 55.0% | 48.9% |
| 36 | Sep 1–7 | 54.4% | **43.7%** |
| 37 | Sep 8–14 | 50.2% | 45.3% |
| 38 | Sep 15–17 (partial) | 54.6% | 41.6% |

2026 tracks 2025 within ~1 pp through week 33, then separates and never returns. 2025 holds
50–55% throughout, so this is not a seasonal pattern. Attempts per week are stable in both
years (≈2,100–2,400), which rules out a mix shift in who is trying.

## What GA4 cannot tell us
GA4 has no failure event — only `add_payment_info` and `purchase` (both reg tags in GTM are
dead: `FinReg` paused, `StartReg` is a Universal Analytics tag). "Payment failures" by
provider, decline reason or country exist only in `public.deposits`. Registrations exist only
in `public.clients`.

## DB half — registrations, payments, failures (live `bloody`, 2026-09-18)
Excludes test/do-not-count accounts (`clients.flags & 65 = 0`, and for registrations also
`deleted_at IS NULL`). Windows on `created`, [Aug 1, Sep 18).

### Headline
| Aug 1 – Sep 17 | 2025 | 2026 | Δ |
|---|---|---|---|
| **registrations** | 28,952 | **41,534** | **+43.5%** |
| deposit attempts | 18,074 | 18,171 | +0.5% |
| **paid** | 9,321 | **7,535** | **−19.2%** |
| **failed / unpaid** | 8,753 | **10,636** | **+21.5%** |
| paid rate | **51.6%** | **41.5%** | **−10.1 pp** |
| depositors | 3,190 | 2,693 | −15.6% |
| GMV | 181,061 | 163,707 | −9.6% |
| avg paid ticket | 19.42 | 21.73 | +11.9% |

43% more registrations, the same number of deposit attempts, a fifth fewer payments.
GMV fell less than payment count because the average successful ticket rose 12% — the
remaining payers are paying more, which masks part of the damage.

### Failures by payment system
| PS | attempts 2025 | rate 2025 | attempts 2026 | rate 2026 |
|---|---|---|---|---|
| **82** (≈70% of attempts) | 13,970 | **58.7%** | 12,896 | **52.0%** |
| **94** | 1,926 | 6.2% | **3,903** | **4.8%** |
| 97 (new) | 37 | 0.0% | 445 | 19.8% |
| 5 (internal/balance) | 597 | 100% | 397 | 100% |
| 83 | 282 | 39.0% | 381 | 38.6% |
| 96 | 411 | 46.7% | 40 | **0.0%** |
| 95 | 265 | 16.2% | 31 | 6.5% |

Two different problems:
- **PS 82 lost 6.7 pp of success on the system that carries most of the money.** At 2025's
  rate its 2026 attempts would have produced ≈864 more paid deposits.
- **PS 94 produced nearly the entire increase in failed transactions.** Its attempts doubled
  (1,926 → 3,903) at a ~5% success rate: failures there rose ≈1,807 → ≈3,716, i.e. ≈+1,909
  against a total failure increase of +1,883. ⚠ Whether 5% is "broken" depends on the method
  type — an invoice/crypto/bank-transfer flow that users simply abandon would look identical
  in this data. **Ask the dev team what PS 94 and PS 97 are before acting.** Either way,
  3,903 attempts routed to a method that completes 1 time in 20 is worth questioning.
- PS 96 went from 411 attempts at 46.7% to 40 attempts at 0% — small, but it looks dead.

### PS 82 weekly paid rate — 2025 is the control
| ISO week | 2025 | 2026 |
|---|---|---|
| 31 | 57.4% | 53.1% |
| 32 | 59.5% | 57.9% |
| 33 | 63.0% | 57.4% |
| **34** | 58.5% | **50.9%** |
| 35 | 59.8% | 50.7% |
| 36 | 57.8% | 49.6% |
| 37 | 54.2% | 47.0% |
| 38 (partial) | 59.3% | 47.7% |

2025 never leaves the 54–63% band. 2026 sits in the same band through week 33, steps down in
**week 34 (from Aug 17)** and stays 7–11 pp below its own prior year every week since.

### Matched cohorts: registration → first deposit within 7 days
Cohorts Aug 1 – Sep 10 only, so every registrant has a full 7 days (no right-censoring).
| cohort | registrations | tried to deposit ≤7d | paid ≤7d | reg→try | try→paid | reg→paid |
|---|---|---|---|---|---|---|
| 2025 Aug 1 – Sep 10 | 25,030 | 2,704 | 1,366 | 10.80% | **50.5%** | **5.46%** |
| 2026 Aug 1 – Sep 10 | 35,184 | 3,111 | 1,128 | 8.84% | **36.3%** | **3.21%** |

Both steps are worse, and they are independent failures:
- **reg → tries to deposit: 10.80% → 8.84%** (−18% relative). A registration is worth less
  than it was; this is the year-long acquisition-quality decline, not the August event.
- **tries → succeeds: 50.5% → 36.3%** (−28% relative). This is the August payment break.

Net: +40.6% registrations produced **−17.4% new depositors** (1,366 → 1,128).

## Caveats
- GA4 `purchase` ≈ but ≠ `deposits.paid_at`; it counts the client-side success event.
- ISO week 34 of 2026 starts Aug 17; the DB onset was dated Aug 17–18. Consistent, not identical.
- Weeks 31 and 38 are partial and are shown only for completeness.
