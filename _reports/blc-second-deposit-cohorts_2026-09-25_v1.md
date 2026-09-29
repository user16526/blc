# BLC: 2nd-deposit dynamics by cohort (live DB, 2026-09-25)
Source: `public.deposits`, paid, `_ab_cdc_deleted_at IS NULL`, amount > 0; ordinal over all time. Bots/bloggers
NOT excluded. Method: card = PCL_CARD/APPLEPAY/GOOGLEPAY, crypto = gateway 12 (USDT), other = BLIK/PIX/Steam/Kinguin.

## By month of FIRST deposit (last 13 months; 2026-09 is partial, 2026-08 partly)
| cohort | 1st deps | avg 1st | -> 2nd (ever) | -> 2nd ≤7 d | avg 2nd | 2nd < $10 | 2nd ≥ $19 |
|---|---|---|---|---|---|---|---|
| 2025-09 | 1 326 | $11.43 | 35.8 % | 25.4 % | $15.98 | 48.6 % | 35.2 % |
| 2025-10 | 1 677 | $11.26 | 32.0 % | 22.1 % | $16.13 | 53.2 % | 31.5 % |
| 2025-11 | 1 402 | $10.04 | 32.5 % | 22.0 % | $14.27 | 57.7 % | 26.8 % |
| 2025-12 | 1 121 | $12.28 | 33.4 % | 24.9 % | $13.36 | 58.3 % | 23.3 % |
| 2026-01 | 1 214 | $10.74 | 32.6 % | 22.2 % | $14.90 | 54.5 % | 27.0 % |
| 2026-02 | 1 364 | $10.34 | 33.1 % | 24.6 % | $13.19 | 61.6 % | 23.3 % |
| 2026-03 | 1 582 | $10.89 | 33.9 % | 23.9 % | $13.54 | 61.1 % | 23.6 % |
| 2026-04 | 1 331 | $10.54 | 31.6 % | 23.9 % | $14.57 | 59.5 % | 26.0 % |
| 2026-05 | 1 406 | $11.67 | 32.6 % | 24.6 % | $15.65 | 57.3 % | 28.5 % |
| 2026-06 | 1 023 | $10.23 | 29.3 % | 21.9 % | $13.20 | 55.7 % | 25.7 % |
| 2026-07 | 1 075 | $11.25 | 31.6 % | 24.3 % | $12.92 | 62.6 % | 23.2 % |
| 2026-08 | 1 146 | $10.85 | 29.8 % | 23.7 % | $13.25 | 65.5 % | 25.7 % |
| 2026-09 | 925 | $11.67 | 22.2 % | 20.2 % | $12.08 | 64.4 % | 29.3 % |

- Avg 2nd deposit drifted **$16 -> $13** (autumn 2025 -> summer 2026); share of 2nd deposits under $10 rose 49 % -> 65 %.
- 7-day conversion to a 2nd deposit is flat at 22–25 % for the whole year. The standing bonus (2nd deposit = 7 %,
  live since ~May 2026) shows **no visible step** in May–Aug. Pre/post only, confounded (1st-deposit bonus started
  at the same time) — not proof of zero effect, but no sign of one.

## By first-deposit size x method (first deposit 12 m – 30 d ago; LTV90 partial for the newest 60 days)
| method | 1st dep | clients | -> 2nd ≤30 d | avg 2nd | 2nd / 1st | GMV 90 d | deps 90 d |
|---|---|---|---|---|---|---|---|
| card | < $10 | 7 662 | 27.5 % | $8.31 | 1.41 | $20.98 | 2.30 |
| card | $10–19 | 840 | 36.3 % | $12.53 | 1.15 | $55.13 | 3.27 |
| card | $19–49 | 1 592 | 41.1 % | $21.24 | 1.00 | $96.71 | 3.73 |
| card | $49+ | 290 | 43.4 % | $59.76 | 0.84 | $289.21 | 4.37 |
| crypto | < $10 | 147 | 20.4 % | $13.14 | 1.57 | $21.95 | 1.56 |
| crypto | $10–19 | 66 | 16.7 % | $26.99 | 2.47 | $32.19 | 1.94 |
| crypto | $19–49 | 95 | 26.3 % | $21.78 | 0.98 | $85.50 | 3.54 |
| crypto | $49+ | 43 | 25.6 % | $142.63 | 1.14 | $309.65 | 2.91 |
| other | < $10 | 2 699 | 18.8 % | $9.35 | 1.73 | $15.80 | 1.81 |
| other | $10–19 | 421 | 36.6 % | $14.54 | 1.42 | $45.98 | 2.87 |
| other | $19–49 | 410 | 35.4 % | $20.52 | 0.97 | $65.94 | 3.20 |
| other | $49+ | 123 | 50.4 % | $65.61 | 0.81 | $305.90 | 4.41 |

- **First-deposit size is the strongest predictor**: card <$10 -> $21 GMV in 90 d, $19–49 -> $97 (x4.6), $49+ -> $289.
  74 % of card first depositors start under $10.
- The 2nd deposit mirrors the 1st (ratio ~1.0 from $19 up); small starters climb only to ~$8.
- **Crypto players return less** (17–26 % vs 27–43 % on card) but put more per deposit ($143 avg 2nd from $49+).

## Minimum "comfortable" amount (first/second deposit 12 m – 90 d ago, all methods)
First deposit -> behaviour over the next 90 days:
| 1st dep | clients | 2nd ≤30 d | deps 90 d | GMV 90 d |
|---|---|---|---|---|
| $5–5.99 | 7 686 | 24.0 % | 2.10 | $17.50 |
| $6–9.99 | 1 209 | 30.8 % | 2.81 | $38.12 |
| $10–14.99 | 1 066 | 34.8 % | 2.90 | $44.55 |
| $15–19.98 | 133 | 39.8 % | 3.80 | $70.83 |
| $19.99–24.99 | 1 492 | 39.2 % | 3.59 | $87.08 |
| $25–29.99 | 151 | 42.4 % | 5.68 | $162.34 |
| $30–49.99 | 224 | 42.0 % | 3.06 | $122.04 |
| $50–99 | 194 | 42.3 % | 4.14 | $249.02 |
| $100+ | 89 | 47.2 % | 5.66 | $616.44 |
Return rises $5 -> $15–20, then **plateaus at ~40–42 %**. Minimum first deposit worth pushing = **$19.99 preset**.

Second deposit -> 3rd within 30 d (split by starting point):
| 2nd dep | start < $10: n / 3rd ≤30 d / GMV after 90 d | start $10+: n / 3rd ≤30 d / GMV after 90 d |
|---|---|---|
| $5–5.99 | 1 689 / 46.5 % / $25.53 | 197 / 48.7 % / $86.55 |
| $6–9.99 | 495 / 51.7 % / $39.50 | 139 / 50.4 % / $80.22 |
| $10–14.99 | 361 / 48.5 % / $45.58 | 281 / 56.2 % / $61.45 |
| $15–19.98 | 43 / 58.1 % / $110.05 | 55 / 50.9 % / $76.50 |
| $19.99–24.99 | 203 / 46.8 % / $86.09 | 496 / 55.0 % / $118.68 |
| $25–49.99 | 53 / 58.5 % / $252.10 | 228 / **67.1 %** / $225.67 |
| $50+ | — | 155 / 63.2 % / $483.51 |
Return to a 3rd is flat (~47–56 %) up to $24.99; the step is at **$25** (63–67 % for $10+ starters; 58 % for < $10
starters on n = 53). Minimum second deposit worth pushing = **$25**.

**Correlation, not causation**: players who choose bigger tickets are richer/more committed. Pushing a $5 player to
$19.99 will not buy the full $17.50 -> $87 difference; the true uplift needs an A/B.

## Implications for the bonus grid (`blc-bonus-grid-card-vs-crypto_2026-09-25_v1.md`)
1. Drop the "2nd deposit ≥ 5 % on any amount" floor proposed earlier: the flat 7 % on the 2nd shows no conversion lift.
2. The lever is ticket SIZE, not the fact of a 2nd deposit: make the $19 step on the 2nd deposit visibly worth it
   (e.g. 2nd deposit $19+ card 8–10 %, < $10 0 %) to move the $5 -> $19.99 preset. Validate by A/B.
3. Crypto bonus = acquisition of big tickets, not retention; pair it with a retention hook, not a bigger %.
