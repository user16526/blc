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
3. **The tolerance** — how far a pick may sit from its target (owner-set; default ±5%, e.g. ±10%).
Grid from a step: `target(n) = target(n−1) × (1 − step%)` or `target(n−1) − step$`. Show the
grid back in the first deliverable table. No step/grid, no pool.

## 1. Rules every pick must pass
| Rule | Limit |
|---|---|
| Freshness | **no skin from the last 5 case-battle boards OR the last 5 events** (running ones included) — any overlap rejects, **any wear** of the same skin counts. Set = `exclusions.sql`; checked by `site_item.py --exclude` (REPEAT flag) |
| Price vs grid | our price within the **owner's tolerance** of the slot target (default ±5%), aim for the middle |
| Step | prices strictly descending; with a step-built grid, realised gap to the place above within step ±3 pp |
| Price source | our price = bloodycase.com item Price = `client_items.buyout_price`. Buff is the market reference only, never the price |
| Stock | #1–3 any; #4–6 >100; #7–10 >200–300; repeating tiers: the cheaper, the bigger (>300) |
| Rust | ≥1 skin near the bottom of the top 10 (max 2 if one is in the middle); stock ≥10 on Steam/Skinport (Buff has no Rust) |
| Market | listed on the market; price stable (7/30-day vs 90-day drift small) |
| Demand | prefer strongest Buff buy orders + 90-day sales; our keep rate (withdrawn share of drops) where drops ≥30 |
| Style | classic, recognisable skins |

## 2. Steps
1. Build the exclusion set: `db_query.py exclusions.sql > <scratch>/excl.tsv` (show the per-source counts).
2. Screen candidates per slot inside the tolerance band → step check → freshness → stock → stability → demand.
3. Every pick + backup: `python site_item.py --exclude <scratch>/excl.tsv <bloodycase item URLs…>` → ID, live price, `fresh`/`REPEAT`.
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
Every row inside the owner's tolerance (and step rule), every row `fresh`, all IDs + prices
re-checked live (script output shown), page screenshot renders.
