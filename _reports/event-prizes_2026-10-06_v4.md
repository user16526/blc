# Event leaderboard prizes, 2026-10-06 v4 (source for event-prizes_2026-10-06_v4.html)

Grid (owner): 1000/500/300/250/200/150/100/80/60/50, tolerance ±10%; #1 $1,000–1,100, #2 $500–650. Prices = bloodycase.com live 2026-10-06 (`site_item.py`, all 20 `fresh`).

| Place | ID | Skin | Our price | Target | Δ | Step | Buff ask | Buff bid | Skinport stock | Skinport sales 90 d | Kept | Drift 7d/90d |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 34556 | ★ Talon Knife \| Fade (factory-new) | $1,019.34 | $1000 | +1.9% | — | $745.27 | $716.31 | 12 | 112 | too few drops (0) | +3.9% |
| 2 | 35176 | ★ Sport Gloves \| Nocts (well-worn) | $611.18 | $500 | +22.2% | -40.0% | $505.81 | $463.14 | 7 | 68 | too few drops (0) | +3.4% |
| 3 | 32892 | AK-47 \| Bloodsport (minimal-wear) | $310.88 | $300 | +3.6% | -49.1% | $119.88 | $115.86 | 27 | 421 | too few drops (0) | -2.1% |
| 4 | 31053 | MP9 \| Hot Rod (factory-new) | $227.85 | $250 | -8.9% | -26.7% | $192.85 | $175.73 | 6 | 71 | too few drops (4) | -4.8% |
| 5 | 31878 | M4A1-S \| Hyper Beast (minimal-wear) | $182.11 | $200 | -8.9% | -20.1% | $121.37 | $112.44 | 13 | 165 | too few drops (0) | -6.2% |
| 6 | 55207 | Alien Red (unknown) | $143.86 | $150 | -4.1% | -21.0% | — | — | 40 | 1300 | 0.0% (0 of 100 drops) | n/a (Rust) |
| 7 | 33880 | Desert Eagle \| Printstream (minimal-wear) | $93.85 | $100 | -6.2% | -34.8% | $43.48 | $40.95 | 76 | 995 | too few drops (0) | +2.9% |
| 8 | 59303 | Plate Carrier - Black (unknown) | $77.61 | $80 | -3.0% | -17.3% | — | — | 27 | 457 | too few drops (16) | n/a (Rust) |
| 9 | 31640 | AWP \| Hyper Beast (minimal-wear) | $64.63 | $60 | +7.7% | -16.7% | $46.17 | $43.63 | 13 | 213 | too few drops (14) | -5.0% |
| 10 | 55017 | USP-S \| Printstream (field-tested) | $48.69 | $50 | -2.6% | -24.7% | $35.37 | $33.81 | 70 | 1320 | 3.0% (2 of 66 drops) | +2.2% |

Composition check: knives + gloves 2/2 (#1 knife, #2 gloves) · every model ×1 · Printstream ×2 (#7, #10) · Hyper Beast ×2 (#5, #9) · Rust ×2 (#6, #8). Neighbours: knife → gloves → rifle → SMG → rifle → Rust → pistol → Rust → sniper → pistol (no shared class or finish, no two long guns adjacent).

Backup swaps: every single swap keeps all rules except two. #2 (Specialist Gloves | Fade MW) would sit next to #1 Talon Knife | Fade → also swap #1 to Butterfly Knife | Autotronic; it is also at the $500 floor ($500.30), re-check first. No other fresh gloves exist at $500–650. #3 (USP-S | Printstream FN) would make Printstream ×3 → also swap #10; no fresh rifle or sniper exists at $270–330 for a cleaner #3 backup.

Backups:

- #1: 46408 ★ Butterfly Knife | Autotronic (minimal-wear) $1,080.27 (+8.0%), Skinport stock 8, sales 90 d 51, kept too few drops (3)
- #2: 35277 ★ Specialist Gloves | Fade (minimal-wear) $500.30 (+0.1%), Skinport stock 9, sales 90 d 67, kept too few drops (0)
- #3: 55178 USP-S | Printstream (factory-new) $286.22 (-4.6%), Skinport stock 8, sales 90 d 124, kept too few drops (0)
- #4: 31874 Glock-18 | Dragon Tattoo (factory-new) $236.21 (-5.5%), Skinport stock 14, sales 90 d 114, kept too few drops (0)
- #5: 100371 M4A4 | Temukau (factory-new) $183.49 (-8.3%), Skinport stock 11, sales 90 d 152, kept too few drops (0)
- #6: 56251 Christmas Lights (unknown) $148.81 (-0.8%), Skinport stock 23, sales 90 d 810, kept too few drops (20)
- #7: 31896 USP-S | Neo-Noir (field-tested) $99.97 (-0.0%), Skinport stock 5, sales 90 d 120, kept too few drops (0)
- #8: 57284 Forest Raiders Roadsign Pants (unknown) $78.25 (-2.2%), Skinport stock 42, sales 90 d 826, kept too few drops (0)
- #9: 31556 AK-47 | Neon Rider (field-tested) $56.87 (-5.2%), Skinport stock 29, sales 90 d 516, kept too few drops (3)
- #10: 104866 Glock-18 | Gold Toof (minimal-wear) $47.48 (-5.0%), Skinport stock 9, sales 90 d 137, kept too few drops (0)

Top 10 total $2,780.00 vs grid $2,690 (+3.3%).

## SQL

Exclusion set: `.claude/skills/case-battle-tournament/exclusions.sql` (115 IDs).

Kept by our players:
```sql
select item_id, count(*) drops, count(*) filter (where status=3) withdrawn, count(*) filter (where status in (4,11)) sold_back
from public.client_items where reason >= 'main case win' and reason < 'main case wio' and created > now() - interval '90 days'
and item_id in (34556,35176,32892,31053,31878,55207,33880,59303,31640,55017,46408,35277,55178,31874,100371,56251,31896,57284,31556,104866)
group by 1 order by 1
```

Result (drops / withdrawn / sold back): 31053 4/0/1 · 31556 3/0/2 · 31640 14/2/5 · 46408 3/0/0 · 55017 66/2/16 · 55207 100/0/100 · 56251 20/0/18 · 59303 16/0/16; all others 0 drops. Option C chosen by the owner after the sheriff returned CANNOT-JUDGE on v3 (owner-intent question). Verifier: RED (backup-swap claim) → fixed.

Market sources (2026-10-06): prices.csgotrader.app/latest/buff163.json + steam.json; api.skinport.com/v1/items and /v1/sales/history (apps 730, 252490).