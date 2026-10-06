---
name: case-battle-tournament
description: Pick prize skins for a BloodyCase leaderboard — the case-battle board (top 10 + tiers 11–20, 21–50, 51–100) or an event tournament (top 10) — against a price grid built from the owner's step, with no skin repeated from the last 5 case battles or the last 5 events. Use when the owner says "case-battle tournament", "csbattle", "CB tournament", "кейсбатл турнир", "кейс батл турнір", "event prizes", "призи івенту", "призи турніру", or asks for leaderboard prizes.
---

# Leaderboard prizes — case battle or event, against a step grid

Data recipes (DB tables, reason-range index trick, item page SSR lookup, history URL):
`.agent/capsules/blc-db-schema.md` → "Items, prices, case-battle leaderboard". Don't re-derive them.
- Case battle: `stats.tournament` type 3, prizes in `stats.tournament_awards` (place, award_reference = item_id).
- Event: prizes = `stats.events.extra->>'Leaderboard'` → `{"ItemsIds":[…]}`, places 1–10 in array order.
- SQL when the postgres MCP is down: tunnel up (`scripts/pg-tunnel-ensure.ps1`), then
  `uv run --no-project --with "psycopg[binary]" python db_query.py <file.sql>` (read-only session).

## 0. Ask FIRST (blocking — one message, before any research)
1. **Which board** — case battle or event; how many places and which tiers (owner gives them).
2. **The grid** — a target per place (owner list), or #1 price + step (% or $). Per tier if tiers differ.
3. **The tolerance** — how far a pick may sit from its target. Default (owner 2026-10-06):
   **−3% / +15%** — never more than 1–3% below, up to +10–15% above is fine. Owner may set another.
   A per-place range from the owner overrides it (e.g. #1 $1,000–1,100, #2 $500–650).
Grid from a step: `target(n) = target(n−1) × (1 − step%)` or `target(n−1) − step$`. Show the
grid back in the first deliverable table. No step/grid, no pool.

## 1. Rules every pick must pass
| Rule | Limit |
|---|---|
| Freshness | **no skin from the last 5 case-battle boards OR the last 5 events** (running ones included) — any overlap rejects, **any wear** of the same skin counts. Set = `exclusions.sql`; checked by `site_item.py --exclude` (REPEAT flag) |
| Price vs grid | our price within the **owner's tolerance** of the slot target (default −3% / +15%); prefer at or just above target, never more than 3% below |
| Step | prices strictly descending; with a step-built grid, realised gap to the place above within step ±3 pp |
| Price source | our price = bloodycase.com item Price = `client_items.buyout_price`. Buff is the market reference only, never the price |
| Stock | #1–3 any; #4–6 >100; #7–10 >200–300; repeating tiers: the cheaper, the bigger (>300) |
| Rust | count per Composition (≥1, ≤2); stock ≥10 on Steam/Skinport (Buff has no Rust) |
| Market | listed on the market; price stable (7/30-day vs 90-day drift small) |
| Demand | prefer strongest Buff buy orders + 90-day sales; our keep rate (withdrawn share of drops) where drops ≥30 |
| Style | classic, recognisable skins. **No StatTrak™** (owner 2026-10-06; v4 #1 Talon Fade 34556 and #5 M4A1-S Hyper Beast 31878 were StatTrak unflagged); no Souvenir (our default) |
| Wear outlier | skip a skin whose picked wear costs **≥5× its dearest other wear** (e.g. AK-47 Aphrodite FN $304 vs MW $35) — `site_item.py` last column `WEAR-OUTLIER` |
| Rust pick | iconic themed wearables — **facemasks** (e.g. Stainless Facemask), Alien Red, themed sets — over plain recolours (e.g. Plate Carrier – Black was rejected) |

**Composition (top 10, hard rules — owner 2026-10-06; backups must keep them true when swapped in, or the report names the required second swap):**
- **#1 or #2 is a knife or gloves** — that is the top.
- **Knives + gloves together ≤5, at most 3 of one type** (3 gloves + 2 knives, or 3 knives + 2 gloves).
  Never two knives or two gloves adjacent; knife–gloves–knife / gloves–knife–gloves is fine.
- **Each weapon model ≤2** (AK-47, AWP, M4A1-S, M4A4, Desert Eagle, USP-S, …; M4A1-S ≠ M4A4).
- **Each finish / series once** (owner 2026-10-06: two Printstreams, or Hyper Beast on AWP + M4A1-S,
  were mistakes) — across weapons, knives and gloves alike.
- **Rust: ≥1, ≤2.**
- **Neighbours differ (owner 2026-10-06):** two adjacent places never share a class — rifle
  (AK-47, M4A1-S, M4A4, FAMAS, Galil AR, AUG, SG 553) · sniper (AWP, SSG 08, SCAR-20, G3SG1) ·
  SMG · pistol · shotgun/MG · knife · gloves · Rust.
  **No two long guns (rifle or sniper) adjacent** (owner chose this strict form). No pistol/SMG
  fresh at a slot's price → a 2nd Rust there breaks the run.
- **Reference (owner's final top 10, event 2026-10-07):** Butterfly Autotronic MW · Deagle Sunset Storm FN ·
  Sport Gloves Scarlet Shamagh MW · Bayonet Lore FT · (rifle) · Alien Red · Hand Wraps Overprint FT ·
  Stainless Facemask · AWP Hyper Beast MW · USP-S Printstream FT = knife · pistol · gloves · knife · rifle ·
  Rust · gloves · Rust · sniper · pistol. Lesson: spend high slots on knives/gloves (desirable, 4 of 10),
  a flat-priced pistol is fine at #2, every finish unique.
- Then pick by stock → demand → variety. Show a composition check line under the table
  (knives n + gloves n /5 · models · finishes all unique · Rust n · class sequence).
- Our price vs Buff ask (`ours/buff`) is shown per row: a high ratio means the real market value
  is far below the displayed prize value — prefer the lower ratio when demand is similar.

## 2. Steps
1. Build the exclusion set: `db_query.py exclusions.sql > <scratch>/excl.tsv` (show the per-source counts).
2. Screen candidates per slot inside the tolerance band → step check → freshness → stock → stability → demand.
3. Every pick + backup: `python site_item.py --exclude <scratch>/excl.tsv <bloodycase item URLs…>` → ID, live price,
   `fresh`/`REPEAT`, wear ratio (`WEAR-OUTLIER`), `STATTRAK`, `2-VARIANTS`. `--wears` lists every wear's normal + ST ID/price.
   The page's wear map can hold the StatTrak item — the script picks the normal one; never take an ID by hand.
   A list the owner hands over gets the same run: the ID must be the URL's wear (2026-10-06: Hand Wraps
   35178 is FT, the URL said MW) and every row `fresh` (M4A1-S Cyrex was case-battle #63).
4. 1 pick + 1 backup per slot, all `fresh`.
5. Re-run step 3 on the final list right before delivering — prices move daily.

## 3. Deliverable
HTML in `_reports/<case-battle|event>-prizes_<date>_vN.html`, two tables:
1. **Proposal** — Place | **ID** | Skin (link) | Our price | Grid target | Δ vs grid % |
   Step vs place above | Fresh (last 5 CB + 5 events) | Buff ask | Buff stock | Buff buy orders |
   Sales 90 d | Kept by our players | Price drift | Stock rule. Totals vs grid.
2. **History** — the excluded boards/events by source (IDs; names where the page gives them).
Every number carries its label (e.g. "Buff stock 250", never a bare "(250)").
Links: `/item/<slug>#<wear>` (CS2), `/rust/item/<slug>#unknown` (Rust).

## Done
Every row inside the owner's tolerance or per-place range (and step rule), no WEAR-OUTLIER/STATTRAK, composition +
neighbour rules true (also for each single backup swap, or the second swap it needs is named), every row `fresh`, all IDs + prices
re-checked live (script output shown), page screenshot renders.
