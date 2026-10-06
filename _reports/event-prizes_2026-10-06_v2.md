# Event leaderboard prizes, 2026-10-06 v2 (source for event-prizes_2026-10-06_v2.html)

Grid (owner): 1000/500/300/250/200/150/100/80/60/50, tolerance ±10%. Prices = bloodycase.com live 2026-10-06 (`site_item.py`, all 20 `fresh`).

| Place | ID | Skin | Our price | Target | Δ | Step | Buff ask | Buff bid | Skinport stock | Skinport sales 90 d | Kept | Drift 7d/90d |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 100871 | ★ Butterfly Knife \| Lore (minimal-wear) | $964.66 | $1000 | -3.5% | — | $893.23 | $844.38 | 5 | 75 | too few drops (7) | -1.0% |
| 2 | 113290 | ★ Specialist Gloves \| Cloud Chaser (field-tested) | $467.45 | $500 | -6.5% | -51.5% | $397.02 | $361.88 | 22 | 201 | too few drops (0) | -7.8% |
| 3 | 32892 | AK-47 \| Bloodsport (minimal-wear) | $310.88 | $300 | +3.6% | -33.5% | $119.88 | $115.86 | 27 | 421 | too few drops (0) | -2.1% |
| 4 | 33369 | AWP \| Asiimov (field-tested) | $252.86 | $250 | +1.1% | -18.7% | $96.65 | $93.82 | 38 | 446 | too few drops (0) | -5.7% |
| 5 | 31878 | M4A1-S \| Hyper Beast (minimal-wear) | $182.13 | $200 | -8.9% | -28.0% | $121.37 | $112.44 | 13 | 165 | too few drops (0) | -6.2% |
| 6 | 32911 | M4A4 \| The Emperor (minimal-wear) | $145.55 | $150 | -3.0% | -20.1% | $59.20 | $55.25 | 22 | 321 | too few drops (0) | -3.4% |
| 7 | 33880 | Desert Eagle \| Printstream (minimal-wear) | $93.85 | $100 | -6.2% | -35.5% | $43.48 | $40.95 | 76 | 995 | too few drops (0) | +2.9% |
| 8 | 59303 | Plate Carrier - Black (unknown) | $80.88 | $80 | +1.1% | -13.8% | — | — | 27 | 457 | too few drops (16) | n/a (Rust) |
| 9 | 31556 | AK-47 \| Neon Rider (field-tested) | $56.87 | $60 | -5.2% | -29.7% | $39.46 | $37.83 | 29 | 516 | too few drops (3) | -4.0% |
| 10 | 55017 | USP-S \| Printstream (field-tested) | $48.65 | $50 | -2.7% | -14.5% | $35.37 | $33.81 | 70 | 1320 | 3.0% (2 of 66 drops) | +2.2% |

Backups:

- #1: 34556 ★ Talon Knife | Fade (factory-new) $1,040.47 (+4.0%), Skinport stock 12, sales 90 d 112, kept too few drops (0)
- #2: 34335 ★ Talon Knife | Tiger Tooth (factory-new) $467.92 (-6.4%), Skinport stock 25, sales 90 d 325, kept too few drops (0)
- #3: 55178 USP-S | Printstream (factory-new) $286.22 (-4.6%), Skinport stock 8, sales 90 d 124, kept too few drops (0)
- #4: 32711 SSG 08 | Blood in the Water (minimal-wear) $239.55 (-4.2%), Skinport stock 10, sales 90 d 125, kept too few drops (0)
- #5: 100371 M4A4 | Temukau (factory-new) $183.49 (-8.3%), Skinport stock 11, sales 90 d 152, kept too few drops (0)
- #6: 33202 AWP | Wildfire (minimal-wear) $152.19 (+1.5%), Skinport stock 26, sales 90 d 330, kept too few drops (0)
- #7: 45785 MP9 | Starlight Protector (minimal-wear) $97.06 (-2.9%), Skinport stock 17, sales 90 d 259, kept too few drops (0)
- #8: 57284 Forest Raiders Roadsign Pants (unknown) $75.13 (-6.1%), Skinport stock 42, sales 90 d 826, kept too few drops (0)
- #9: 106905 FAMAS | Bad Trip (field-tested) $63.66 (+6.1%), Skinport stock 23, sales 90 d 258, kept too few drops (0)
- #10: 31504 AWP | Neo-Noir (field-tested) $52.14 (+4.3%), Skinport stock 22, sales 90 d 265, kept 0.4% (1 of 258 drops)

Top 10 total $2,603.78 vs grid $2,690 (-3.2%).

## SQL

Exclusion set: `.claude/skills/case-battle-tournament/exclusions.sql` (115 IDs).

Kept by our players:
```sql
select item_id, count(*) drops, count(*) filter (where status=3) withdrawn, count(*) filter (where status in (4,11)) sold_back
from public.client_items where reason >= 'main case win' and reason < 'main case wio' and created > now() - interval '90 days'
and item_id in (113290,32892,55178,33369,32711,31878,100371,32911,33202,33880,45785,31556,106905,55017,31504,100871,34556,59303,57284)
group by 1 order by 1
```

Result (drops / withdrawn / sold back): 31504 258/1/195 · 31556 3/0/2 · 55017 66/2/16 · 59303 16/0/16 · 100871 7/0/3; all others 0 drops. Sheriff: 2 decision calls (CANNOT-JUDGE: freshness evidence missing → evidence added → AGREE), tokens 3,919 + 5,636.

Market sources (2026-10-06): prices.csgotrader.app/latest/buff163.json + steam.json; api.skinport.com/v1/items and /v1/sales/history (apps 730, 252490).