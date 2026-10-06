# Run: prize skill — owner's final-list corrections, 2026-10-06
Row: NORMAL (skill + helper script edit; no BloodyCase code). Builder: orchestrator. Team: verifier (2 passes).
Sheriff: n/a — owner rulings, no engineering choice put to the owner.

## Inputs
- Owner (2026-10-06), after v4: mistakes = 2× Printstream, Hyper Beast on AWP + M4A1-S, Plate Carrier – Black
  (facemask better), StatTrak; knives+gloves may be 3+2 with no same type adjacent; price −1–3% / +10–15%;
  avoid a skin whose one wear is extra expensive (AK-47 Aphrodite FN); learn from the owner's final top 10.
- Live bloodycase.com item pages (`site_item.py`), `excl.tsv` from `exclusions.sql` (last 5 CB + 5 events).

## Verdict: GREEN
verifier pass 1 RED (1 critical: STATTRAK flag could never fire; 2 non-critical) → all fixed → pass 2 GREEN
(3 non-critical: stale docstring, run-report sections, literal tabs — fixed).

## Findings (all closed)
- `site_item.py` trusted the page's `Exteriors` map, which can hold the StatTrak item → v4 #1 Talon Fade 34556
  and #5 M4A1-S Hyper Beast 31878 were StatTrak, unflagged (the owner's "mistake 4"). Now reads `ExteriorList`
  (Id vs IdStattrack/IsStattrack), prefers the displayed normal item, REPEAT checks normal + ST Ids.
- "No Souvenir" was attributed to the owner → marked "our default".
- Redundant adjacent-finish clause dropped (covered by "finish once").

## Key result
- `SKILL.md`: tolerance −3% / +15%; finish/series once; knives+gloves ≤5 (max 3 per type, never same type
  adjacent); no StatTrak; wear outlier ≥5× dearest other wear; Rust prefers facemasks/themed over plain
  recolours; the owner's list also passes `site_item.py`; owner's final top 10 recorded as the reference.
- `site_item.py`: last column `wear xN.N` over normal prices (+`WEAR-OUTLIER`, `STATTRAK` for ST-only wear,
  `2-VARIANTS`); `--wears` dumps normal | ST IDs/prices.
- Live evidence: Aphrodite FN 113065 $304.49 `wear x8.8 WEAR-OUTLIER` (+ `REPEAT: case-battle #99`);
  Redline FT → normal 30953 $36.73 (old: ST 31662 $73.87); Deagle Sunset Storm FN 32243 $524.93
  `2-VARIANTS 32206/32243`.
- Owner's final list (live): M4A1-S Cyrex FN 30726 `REPEAT: case-battle #63`; Hand Wraps Overprint 35178 =
  Field-Tested $105.10 (URL said MW); Bayonet Lore FT 34164 $239.23 OK; Alien Red 55207 $143.75 (−4.2%).
  In-band fresh #5 swap: MP9 Hot Rod FN 31053 $208.88 (Glock Dragon Tattoo FN $236.21 = +18%,
  M4A4 Temukau FN $183.49 = −8%).

## Artifacts
- `.claude/skills/case-battle-tournament/SKILL.md`, `site_item.py`
- `tasks/lessons.md` (2026-10-06 [prizes]), `.agent/state/decisions.md`, memory `case-battle-prize-rules`

## Open
- Owner: replace #5 M4A1-S Cyrex (repeat) — recommend MP9 Hot Rod FN 31053.
