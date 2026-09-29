# EGAMERSWORLD — monthly margin, last 12 months, and a fixed-fee ceiling (2026-09-25)

Source: live replica `bloody` via postgres MCP, queried 2026-09-25. Money in USD (all deposits single currency).

## TL;DR
- Promo stopped in **June 2026**: new code referrals fell from ~190–600/mo (Dec 25–May 26) to 31 → 10 → 7 → 3.
- 12-mo net to us (GGR − revshare accrued) = **~$7.6k**, but **~$4.2k of it is 2 whales** from the May 2026 cohort.
- Without whales, a typical month of active promo produced a new cohort worth **~$200 net** to date (~$250 GGR − ~$50 revshare).
- **Fixed-fee ceiling: ~$200/mo** if the 5% revshare stays; **~$250/mo** if the fixed fee replaces it. Up to ~$550/mo only if you bank on one whale a year.
- ⚠ Partner account 250572 holds **$1,722.61 unpaid revshare**; last crypto payout was **2025-08-21**. That alone may explain why they stopped promoting.

## Method
- Codes: `EGAMERSWORLD` (client_referral_systems 227635, 11,155 refs all-time), `EGW24` (411697, 17), `EGWNEWS` (458429, 72). Referred = `client_referrals_histories`.
- Deposits: `public.deposits`, `paid_at IS NOT NULL`.
- Withdrawals: `client_items.status = 3` at `steam_price`, dated by `sold_at`. Mapping inferred: status-3 sum $42.5k / 681 clients vs `clients.total_withdrawal_amount` $36.2k / 696 clients for the same cohort — close match, not app-code confirmed.
- GGR = deposits − withdrawals. Revshare = `balances.reference_type = 6` accruals to the 3 partner accounts (~5% of referred deposits).
- NOT included: payment-provider fees, skin acquisition cost vs Steam price, bonus balance still unplayed. Real margin is lower than GGR.

## Monthly — whole referred base (legacy + new)
| Month | Deposits | Withdrawals | GGR | Revshare | Net to us | New refs |
|---|---:|---:|---:|---:|---:|---:|
| 2025-10 | 2,090 | 1,723 | 367 | 106 | 261 | 142 |
| 2025-11 | 1,805 | 924 | 881 | 57 | 824 | 192 |
| 2025-12 | 2,090 | 1,661 | 429 | 78 | 351 | 368 |
| 2026-01 | 1,765 | 1,305 | 460 | 87 | 373 | 605 |
| 2026-02 | 1,450 | 880 | 570 | 71 | 499 | 346 |
| 2026-03 | 2,699 | 2,239 | 460 | 79 | 381 | 258 |
| 2026-04 | 3,097 | 2,639 | 457 | 97 | 360 | 190 |
| 2026-05 | 3,295 | 3,152 | 142 | 148 | −6 | 194 |
| 2026-06 | 8,320 | 5,814 | 2,506 | 496 | 2,010 | 31 |
| 2026-07 | 4,619 | 1,715 | 2,904 | 276 | 2,628 | 10 |
| 2026-08 | 738 | 901 | −163 | 37 | −200 | 7 |
| 2026-09* | 347 | 187 | 159 | 21 | 138 | 3 |
| **12 mo** | **32,314** | **23,140** | **9,173** | **1,555** | **7,618** | |

### Funnel view (v2, added 2026-09-25 on owner request)
Regs = new code referrals in the month. FTD = a referred client's first-ever paid deposit, made in that month; repeat = every later paid deposit. Margin = deposits − withdrawals; profit = margin − revshare.

| Month | Regs | FTD # | FTD avg $ | FTD total $ | Repeat # | Repeat unique | Repeat avg $ | Repeat total $ | Deposits $ | Depositors unique | $/depositor | Margin $ | Profit $ |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2025-10 | 142 | 21 | 17.90 | 375.90 | 84 | 23 | 20.41 | 1,714.38 | 2,090 | 38 | 55.01 | 367 | 261 |
| 2025-11 | 192 | 38 | 10.81 | 410.63 | 88 | 29 | 15.85 | 1,394.57 | 1,805 | 59 | 30.60 | 881 | 824 |
| 2025-12 | 368 | 45 | 7.41 | 333.46 | 118 | 36 | 14.89 | 1,756.91 | 2,090 | 69 | 30.30 | 429 | 351 |
| 2026-01 | 605 | 31 | 12.01 | 372.43 | 106 | 33 | 13.14 | 1,392.49 | 1,765 | 54 | 32.68 | 460 | 373 |
| 2026-02 | 346 | 46 | 9.08 | 417.53 | 103 | 31 | 10.03 | 1,032.70 | 1,450 | 65 | 22.31 | 570 | 499 |
| 2026-03 | 258 | 27 | 7.97 | 215.16 | 118 | 38 | 21.05 | 2,483.43 | 2,699 | 54 | 49.97 | 460 | 381 |
| 2026-04 | 190 | 24 | 11.62 | 278.92 | 122 | 29 | 23.10 | 2,817.90 | 3,097 | 42 | 73.73 | 457 | 360 |
| 2026-05 | 193 | 29 | 8.44 | 244.88 | 135 | 33 | 22.59 | 3,049.92 | 3,295 | 50 | 65.90 | 142 | −6 |
| 2026-06 | 31 | 14 | 17.51 | 245.09 | 125 | 25 | 64.60 | 8,074.51 | 8,320 | 35 | 237.70 | 2,506 | 2,010 |
| 2026-07 | 10 | 2 | 60.50 | 121.00 | 74 | 21 | 60.78 | 4,497.61 | 4,619 | 22 | 209.94 | 2,904 | 2,628 |
| 2026-08 | 7 | 2 | 8.00 | 15.99 | 62 | 14 | 11.64 | 721.92 | 738 | 15 | 49.19 | −163 | −200 |
| 2026-09* | 3 | 4 | 11.24 | 44.97 | 24 | 11 | 12.57 | 301.57 | 347 | 15 | 23.10 | 159 | 138 |
| **12 mo** | **2,345** | **283** | | **3,075.96** | **1,159** | **161** | | **29,237.91** | **32,314** | **334** | **96.75** | **9,173** | **7,618** |

12-mo unique columns are distinct players over the whole window, not the sum of months. A player can be an FTD and a repeat depositor in the same month.

**Decision metric = cohort view below, not this table.** This monthly table mixes legacy players (referred 2023–25, they keep depositing without any promo) with new ones. A fixed fee buys only NEW registrations, so price it on value per registration from the cohort table: ~$1 margin / ~$0.80 profit per reg (non-whale), ~9% reg→depositor.

*Sep to the 25th. Jun–Jul spike = 2 whales referred in May 2026 ($14.4k deposits, $4.9k GGR between them). Aug–Sep is the post-promo run-rate: ~$0–150/mo.

## Cohort value — what one month of active promo is worth (lifetime to date)
| Ref cohort | Refs | Payers | Deposits | GGR |
|---|---:|---:|---:|---:|
| 2025-07 | 108 | 20 | 2,332 | 756 |
| 2025-08 | 161 | 23 | 1,716 | 422 |
| 2025-09 | 145 | 10 | 501 | 170 |
| 2025-10 | 142 | 14 | 579 | 134 |
| 2025-11 | 192 | 18 | 620 | 163 |
| 2025-12 | 368 | 41 | 1,501 | 408 |
| 2026-01 | 605 | 36 | 1,206 | 524 |
| 2026-02 | 346 | 28 | 839 | 97 |
| 2026-03 | 258 | 27 | 692 | −260 |
| 2026-04 | 190 | 16 | 718 | 122 |
| 2026-05 | 193 | 23 | 13,005 | 4,771 (2 whales) |

- 10 non-whale cohorts: $10.7k deposits, $2.54k GGR → **~$254 GGR/cohort**, ~$200 after 5% revshare. ~9% ref→payer, ~$1.1 GGR per referral.
- Incl. the whale cohort: ~$664 GGR/cohort, ~$556 after revshare. One whale per ~11 months; not plannable.

## Recommendation
- Offer **$150–200/mo fixed** (revshare kept) with a KPI floor: **≥200 code registrations/mo**, 2-month trial, renew on data.
- Settle the **$1,722.61 unpaid revshare** first — cheaper than any fixed fee and removes the most likely reason they stopped.
- Above ~$250/mo fixed we pay for traffic that historically returned less, unless another whale lands.
