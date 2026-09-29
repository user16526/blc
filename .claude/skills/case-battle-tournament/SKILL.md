---
name: case-battle-tournament
description: Build the prize pool for the next BloodyCase case-battle leaderboard (top 10 + tiers 11–20, 21–50, 51–100) against a price grid. Use when the owner says "case-battle tournament", "case battle tournament", "csbattle", "CB tournament", "кейсбатл турнир", "кейс батл турнір", or asks for case-battle leaderboard prizes.
---

# Case-battle tournament — prize pool against a grid

Data recipes (DB tables, reason-range index trick, `stats.tournament` type 3, item
page SSR lookup, history URL): `.agent/capsules/blc-db-schema.md` → "Items, prices,
case-battle leaderboard". Don't re-derive them.

## 0. Get the grid FIRST (blocking)
The grid = a target price for every slot: #1…#10, 11–20, 21–50, 51–100.
- The owner gave it → use it as is.
- Not given → ask ONE question before any research, with a recommended grid: the
  current board's prices (or the 6-board average) scaled by the owner's discount.
  No grid, no pool.

## 1. Rules every pick must pass
| Rule | Limit |
|---|---|
| Price vs grid | our price within **±5%** of the slot's grid target, aim ≤1–3% — so the gaps between places follow the grid |
| Price source | our price = bloodycase.com item Price = `client_items.buyout_price`. Buff is the market reference only, never the price |
| Stock | #1–3 any; #4–6 >100; #7–10 >200–300; repeating tiers: the cheaper, the bigger (>300) |
| Rust | ≥1 skin near the bottom of the top 10 (max 2 if one is in the middle); stock ≥10 on Steam/Skinport (Buff has no Rust) |
| Market | skin must be listed on the market; price stable (7/30-day vs 90-day drift small) |
| Demand | prefer strongest Buff buy orders + 90-day sales; our keep rate (withdrawn share of drops) where drops ≥30 |
| Freshness | no skin repeated from the last 6 boards; classic style |

## 2. Steps
1. Pull the last 6 type-3 boards from the DB (prices + items) for the history table.
2. Screen candidates per slot inside the ±5% band → stock → stability → demand.
3. Look up each pick's **ID + live price**: `python .claude/skills/case-battle-tournament/site_item.py <bloodycase item URLs…>`.
4. Pick 1 per slot + 1 backup per slot (same checks).
5. Re-run step 3 on the final list right before delivering — prices move daily.

## 3. Deliverable
HTML in `_reports/case-battle-prizes_<date>_vN.html`, two tables:
1. **Proposal** — columns: Place | **ID** | Skin (link to bloodycase.com) | Our price |
   Grid target | Δ vs grid % | Buff ask | Buff stock | Buff buy orders | Sales 90 d |
   Kept by our players | Price drift | Stock rule. Totals vs grid and vs current board.
2. **History** — the last 6 boards, same slots.
Every number carries its label (e.g. "Buff stock 250", never a bare "(250)").
Links: `/item/<slug>#<wear>` (CS2), `/rust/item/<slug>#unknown` (Rust).

## Done
Every row within ±5% of grid, all IDs + prices re-checked live (script output shown),
page screenshot renders.
