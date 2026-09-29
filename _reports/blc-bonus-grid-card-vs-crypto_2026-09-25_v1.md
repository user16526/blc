# BLC: proposed bonus grid from deposit #2 — cards vs crypto (2026-09-25)
Builds on `_reports/blc-bonus-2plus_2026-09-25_v1.md`. Live DB, paid deposits #2+, last 90 days.
Method mapping (from `external_pay_way` / gateway): **card** = PS 82 `PCL_CARD` + `PCL_APPLEPAY` + `PCL_GOOGLEPAY`;
**crypto** = gateway 12 (PS 83–91, all `USDT`); local = PS 82 BLIK/PIX/Multibanco; steam = PS 94; kinguin = PS 5 codes.

## Fee facts (DB `commission_multiplier`)
- Card fee behaves like **~7 % + $0.30**: 11.5 % under $10, 9.6 % at $10–19, 8.3 % at $19–49, 7.2 % at $199+.
  BLIK/PIX carry the same schedule.
- Crypto (USDT) fee = 0 in the DB; owner states crypto has no chargebacks. Chargeback rate on cards: not in this
  analysis (owner to supply).
- Crypto 2+ GMV = $7.2k / 90 d vs cards $258.8k — crypto is ~2.5 %.

## Proposed grid (one grid from deposit #2; removes the 2nd = flat 7 % / 3rd = 0 % cliff)
| amount | card bonus | card fee+bonus | crypto bonus | crypto fee+bonus |
|---|---|---|---|---|
| $5–9.99 | 0 % | ~11.5 % | 5 % | 5 % |
| $10–18.99 | 3 % | ~12.6 % | 8 % | 8 % |
| $19–48.99 | 5 % | ~13.3 % | 10 % | 10 % |
| $49–98.99 | 6 % | ~13.6 % | 12 % | 12 % |
| $99–198.99 | 7 % | ~14.3 % | 13 % | 13 % |
| $199+ | 8 % | ~15.2 % | 15 % | 15 % |
| cap per deposit | $50 | | $100 | |

Rule: crypto total cost ≤ card total cost in every band, and the crypto bonus is visibly higher (+5–7 pp) so the
modal itself steers to USDT. BLIK/PIX/Steam/Kinguin use the card column.

## Static 90-day impact (no behaviour change, bonus at face value)
| | bonus now | bonus new | delta |
|---|---|---|---|
| cards (2+) | ~$17.98k | ~$14.94k | **−$3.0k** (~−$12k/yr) |
| crypto (2+) | ~$0.41k | ~$0.89k | +$0.47k |

Migration: each $ moving card -> crypto at $19–49 gains ~+3.3 pp margin (86.7 % -> 90 %) plus zero chargeback;
at $199+ it is margin-neutral (84.8 % vs 85 %) but chargeback-free.

## Update: card max $200, crypto unlimited (owner, 2026-09-25; DB 180 d confirms)
- Cards: largest deposit in 180 d = $200 (836 deps at $199–200, 70 clients). Card grid tops out at 8 % x $200 = $16,
  so the card cap line is moot.
- **An existing bonus cap of $35 per deposit** (max `bonus_amount` = $35.00 on every method): a $999 and a $1,000
  USDT deposit got $35 = 3.5 %. That cap is why crypto $199+ averaged 4.73 %, and it removes any reason to deposit
  big in crypto. Crypto > $200 in 180 d: 9 deposits, 5 clients, $5.3k.
- Crypto tiers above $200 (replace the $199+ row and the $100 cap):

| crypto amount | bonus | max bonus |
|---|---|---|
| $199–499 | 15 % | $75 |
| $500–999 | 16 % | $160 |
| $1 000–1 999 | 18 % | $360 |
| $2 000+ | 20 % | **$500 cap** |

Above $500 this deliberately pays 1–5 pp more than the card top tier (15.2 %) — justified only by zero fee, zero
chargeback and whale acquisition. Static cost ≈ $0 (volume is ~9 deposits / 180 d); the real risk is bonus abuse,
so these tiers need a wager requirement on bonus balance before withdrawal (dev/owner to confirm what exists).

## Open
- 2nd deposit under $10 on card loses its 7 % (559 of 1 129 2nd deposits are < $19; 30-day return only 47 %).
  Option: floor "2nd deposit ≥ 5 % on any amount" — cost ~+$0.4k / 90 d.
- Crypto $199+ averaged 4.73 %, not 8–10 %: a per-deposit bonus cap may already exist — confirm with dev.
- Whether bonus balance has a wagering / withdraw restriction — sets the real cost of the bonus (face value here).
- Validate with an A/B (grid vs current), primary = 2+ GMV net of fee+bonus per client, guardrail = 30-day return.

## Review of the "Andrey" grid (owner-pasted, 2026-09-25; rows $199+ only)
Volume at $199+, last 90 d (live DB): FIRST deposits 9 (8 card/other, 1 crypto) of 3 255 = 0.3 %;
NEXT deposits 377 card/other ($75.5k GMV, 312 of them at $200+) + 4 crypto.
- Andrey first (32–38 %, cap $200): ~+$0.3k / 90 d at static behaviour — cheap, but a fraud magnet on CARD first
  deposits (stolen card -> $200 + $70 bonus -> skins out -> chargeback). Crypto-only with wager: acceptable.
- Andrey next (12–13 % at $200+, cap $70): on cards ~+$1.25k / 90 d paid to ~32 regulars who return 94 % within
  7 days anyway; card cost at $200 becomes 7.15 % fee + 12 % = 19.15 %. Opposite of the fee-aware direction.
- Cliffs: $199 -> $200 jumps 32 % -> 35 % (first) and 10 % -> 12 % (next); both are presets.
- Above the cap the effective % collapses (first: 40 % at $500 -> 6.7 % at $3 000), breaking "pay more, get more".
- Same grid for card and crypto — ignores fee and chargeback difference.
- J (crypto) at $199–233 FIRST deposit pays less than today ($29.85 vs $35) — must be max(first-deposit rule, J).
- Neither grid touches the levers found in the cohort work: 1st deposit $19.99, 2nd deposit $25 (99 % of deposits
  sit below $199).
