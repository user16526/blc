# Event leaderboard prizes, 2026-10-06 v1 (source for event-prizes_2026-10-06_v1.html)

Grid (owner): 1000/500/300/250/200/150/100/80/60/50, tolerance ±10%. Prices = bloodycase.com live 2026-10-06 (`site_item.py`, all 20 `fresh`).

| Place | ID | Skin | Our price | Target | Δ | Step | Buff ask | Buff bid | Skinport stock | Skinport sales 90 d | Kept | Drift 7d/90d |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 100871 | ★ Butterfly Knife \| Lore (minimal-wear) | $964.66 | $1000 | -3.5% | — | $893.23 | $844.38 | 5 | 75 | too few drops (7) | -1.0% |
| 2 | 34335 | ★ Talon Knife \| Tiger Tooth (factory-new) | $503.75 | $500 | +0.8% | -47.8% | $428.89 | $419.96 | 25 | 325 | too few drops (0) | -0.6% |
| 3 | 107394 | ★ Nomad Knife \| Marble Fade (factory-new) | $275.79 | $300 | -8.1% | -45.3% | $209.08 | $199.55 | 15 | 202 | too few drops (0) | +1.4% |
| 4 | 46348 | ★ Huntsman Knife \| Gamma Doppler (factory-new) | $241.79 | $250 | -3.3% | -12.3% | $190.32 | $183.17 | 11 | 110 | too few drops (0) | -2.6% |
| 5 | 35224 | ★ Sport Gloves \| Omega (field-tested) | $188.58 | $200 | -5.7% | -22.0% | $167.24 | $156.37 | 27 | 452 | too few drops (2) | -7.0% |
| 6 | 33947 | ★ Ursus Knife \| Tiger Tooth (factory-new) | $148.33 | $150 | -1.1% | -21.3% | $121.64 | $116.31 | 17 | 197 | too few drops (0) | -4.9% |
| 7 | 103544 | ★ Kukri Knife \| Crimson Web (field-tested) | $100.26 | $100 | +0.3% | -32.4% | $74.01 | $69.99 | 16 | 177 | too few drops (0) | -4.4% |
| 8 | 59303 | Plate Carrier - Black (unknown) | $80.88 | $80 | +1.1% | -19.3% | — | — | 27 | 457 | too few drops (16) | n/a (Rust) |
| 9 | 35142 | ★ Hand Wraps \| Duct Tape (field-tested) | $61.91 | $60 | +3.2% | -23.5% | $40.21 | $38.87 | 32 | 573 | too few drops (8) | -4.9% |
| 10 | 55017 | USP-S \| Printstream (field-tested) | $48.65 | $50 | -2.7% | -21.4% | $35.37 | $33.81 | 70 | 1320 | 3.0% (2 of 66 drops) | +2.2% |

Backups:

- #1: 34556 ★ Talon Knife | Fade (factory-new) $1,040.47 (+4.0%), Skinport stock 12, sales 90 d 112, kept too few drops (0)
- #2: 113290 ★ Specialist Gloves | Cloud Chaser (field-tested) $467.45 (-6.5%), Skinport stock 22, sales 90 d 201, kept too few drops (0)
- #3: 34174 ★ Bayonet | Tiger Tooth (factory-new) $288.73 (-3.8%), Skinport stock 17, sales 90 d 273, kept too few drops (0)
- #4: 34324 ★ Bayonet | Lore (field-tested) $264.79 (+5.9%), Skinport stock 9, sales 90 d 116, kept too few drops (0)
- #5: 107311 ★ Nomad Knife | Tiger Tooth (factory-new) $195.99 (-2.0%), Skinport stock 17, sales 90 d 268, kept too few drops (0)
- #6: 33744 ★ Bowie Knife | Marble Fade (factory-new) $149.67 (-0.2%), Skinport stock 8, sales 90 d 216, kept too few drops (0)
- #7: 105029 M4A1-S | Vaporwave (field-tested) $100.48 (+0.5%), Skinport stock 61, sales 90 d 568, kept too few drops (0)
- #8: 57284 Forest Raiders Roadsign Pants (unknown) $75.13 (-6.1%), Skinport stock 42, sales 90 d 826, kept too few drops (0)
- #9: 34971 ★ Specialist Gloves | Buckshot (field-tested) $58.91 (-1.8%), Skinport stock 15, sales 90 d 346, kept too few drops (7)
- #10: 31504 AWP | Neo-Noir (field-tested) $52.14 (+4.3%), Skinport stock 22, sales 90 d 265, kept 0.4% (1 of 258 drops)

Top 10 total $2,614.60 vs grid $2,690 (-2.8%).

## SQL

Exclusion set: `.claude/skills/case-battle-tournament/exclusions.sql` (115 IDs).

Kept by our players:
```sql
select item_id, count(*) drops, count(*) filter (where status=3) withdrawn, count(*) filter (where status in (4,11)) sold_back
from public.client_items where reason >= 'main case win' and reason < 'main case wio' and created > now() - interval '90 days'
and item_id in (100871,34556,34335,113290,107394,34174,46348,34324,35224,107311,33947,33744,103544,105029,59303,57284,35142,34971,55017,31504)
group by 1 order by 1
```

Result (drops / withdrawn / sold back): 31504 258/1/195 · 34971 7/0/2 · 35142 8/0/5 · 35224 2/0/2 · 55017 66/2/16 · 59303 16/0/16 · 100871 7/0/3; all others 0 drops.

Market sources (2026-10-06): prices.csgotrader.app/latest/buff163.json + steam.json; api.skinport.com/v1/items and /v1/sales/history (apps 730, 252490).