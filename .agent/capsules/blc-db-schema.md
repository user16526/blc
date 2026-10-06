# Capsule: BLC DB schema map (DB `bloody`, host bloodyanalytics02, via /mcpb)
Last updated: 2026-09-09. Structural facts only; numbers decay — re-query.

## Layout
- Schemas: `public` (Airbyte CDC replica of app tables), `stats` (event tables), `analytics` (derived),
  `airbyte_internal` (raw streams, ignore). CDC columns everywhere: `_ab_cdc_deleted_at` (filter IS NULL),
  `_repl_ts`.
- Timestamps in `public.deposits` are `timestamp without time zone` (assumed UTC, unverified);
  `deposit_promotions` uses timestamptz.
- Money is CENTS everywhere unless noted.

## Tables that matter
- `public.deposits` (30 cols): `client_id`, `amount` bigint CENTS, `bonus_amount` int CENTS (standing deposit
  bonus actually applied; populated since ~2026-05), `paid_at` (NULL = not paid), `status`, `type` (0/1),
  `partner_id`, `referral_system_id`, `payment_system_id`, `country`, `currency`. PII columns present
  (card_*, ip, user_agent, finger_print) — never select them.
- `public.deposit_promotions`: "deposit ≥ `deposit_amount` (cents) → awards [{case_id}]" campaigns with
  `start_at` / `end_at`. Not a bonus-% config.
- `analytics.first_deposit`: `client_id`, `deposit_id`, `created_at` — precomputed first deposit per client.
- `public.client_login_records`: `client_id`, `logged_at` (timestamp w/o tz), `device`, `country`, `partner_id`,
  `ga_cid`; PII: ip, city. Index (client_id, logged_at). ~25k distinct clients / 21 d (2026-09-02).
- NOT in the replica (re-verified live 2026-09-03, all 3 schemas): tickets, case battles, promo/ticket codes, happy-hour tables. `stats` has
  auctions, events/event_clients/event_transactions/exchanges, tournaments, achievements only.
- Not yet mapped: `stats.event_exchange_transactions`, `stats.client_achievements`.

## Events / battle-pass (mapped 2026-09-29)
- `stats.events`: `id` uuid, `start_at`/`end_at` (w/o tz), `levels` jsonb (25), `extra` jsonb (slug in CDN image paths,
  e.g. `startseasonevent2026`, `nonameresort2026`). No name column — identify by slug in `extra`.
- `stats.event_clients`: one row per client per event (`event_id` TEXT, `created_at` = join time, `current_level`,
  `total_currency`). New registrations auto-join the running event (daily joins ≈ daily regs).
- `stats.event_transactions`: `event_id` uuid, `client_id`, `type` (1 = XP, 2 = coins; inferred), `source` int
  (enum unmapped; source 7 ≈ deposit: its client count ≈ payers), `amount`, `created_at`. PK index only.
  Every depositor earns event XP automatically → deposits can't be attributed to the event.
- XP rules (`events.rewards`) identical across all events since 2025-07-29; curve always 475k XP / 25 levels.
- `stats.event_exchanges`: coin shop (`currency_price`, `reward_type` 2 = skin, 3/4 unmapped); buys in
  `stats.event_exchange_transactions`. Shop rate ≈ 1,000 coins = $1. Event txn source 13 = manual coin grant.
- The live event config is also public: bloodycase.com/ua/events SSR state `events_get_current_events` (amounts in cents).
- Reports: `_reports/blc-data_2026-09-29_2002_v1.md`, `_reports/blc-event-deep-dive_2026-09-29_v1.md`.

## `public.clients` (36 cols) — TEST-ACCOUNT FLAGS LIVE HERE (mapped 2026-09-09)
- Identity/PII (never select): `email`, `steam_id`, `last_known_ip`, `display_name`, `trade_url`,
  `crypto_wallet_address`, `discord_uid`/`google_uid`/`facebook_uid`/`twitch_uid`, `avatar`.
- Safe: `id`, `created`, `last_logged_at`, `deleted_at`, `partner_id`, `currency`, `region`,
  `language`, `kyc_approved`, `total_withdrawal_amount`, `total_withdrawal_limit`, `flags`, `is_real`.
- **Countable-real-user predicate** (from the app's own partial index `idx_clients_created`):
  `(flags & 1) = 0 AND (flags & 64) = 0 AND deleted_at IS NULL`. **`flags & 64` = "do not count".**
  Also `idx_clients_is_real` / `idx_clients_not_real` partial indexes on `is_real`.
- ⚠ The flag is NOT reliably set: 275 accounts receiving admin balance grants are
  `is_real=true, flags=0` (incl. the QA account 6052). See
  `_reports/blc-data_2026-09-09_0041_v1.md` for the exclusion list.

## `public.balances` (mapped 2026-09-09) — money LEDGER, not a balance table
- One row per movement: `client_id`, `amount` (signed delta, cents), `old_balance`, `new_balance`,
  `created`, `reference_type` int, `info` text, `reference_id`, `wallet_id`, `partner_id`.
- Current balance = `new_balance` of the latest row (`ORDER BY id DESC LIMIT 1`).
- ⚠ **Only a PK index** — no index on `client_id` or `created`. Any client filter = full seq scan.
  Fine for one account; never fan out per-account.
- `reference_type` (no documented enum; inferred from `info` patterns, bidirectional):
  1 = case open (debit) · 2 = deposit / wallet code · 4 = **manual admin adjustment**
  (`info`: `test`, `qa`, `cd test`, or blank) · 7 = balance code · 8 = leave battle / error refund ·
  9 = case battle bet + cashback · 10 = sell item back · 15 = sniper battle bet + cashback.

## `public.client_items` (mapped 2026-09-09) — inventory + drop history
- `client_id`, `item_id`, `status` int, `created`, `sold_at`, `reason` text (free-form provenance),
  `case_id`, `battle_id`, `bet_id`, `giveaway_id`, `market_id`, `is_virtual_nft_item`.
- Prices (cents): `steam_price`, `buyout_price`, `bet_price`, `market_price_with_commission`.
  ⚠ **`market_price` is NULL in practice** — use `steam_price` (reference) or `buyout_price` (sell-back).
  Buyout can exceed Steam (premium, not a commission haircut).
- `status` (inferred from data, not app code): `sold_at` populated on 4 and 11 = disposed;
  1 / 8 / 9 = still held; 8 and 9 look pending/locked (the site excludes them from "Sell all").
- **"Sell all skins" total** = `SUM(buyout_price) WHERE status = 1 AND sold_at IS NULL
  AND is_virtual_nft_item = false AND _ab_cdc_deleted_at IS NULL` (reproduced to the cent, 2026-09-09).
- `reason` provenance vocabulary: `''` = plain case open · `battle id [N] winner` ·
  `sniper battle id [uuid] winner` · `free nft` · `event exchange. event=… exchange_id=…` ·
  `daily free win. history id: N` · `event level progression. leven=N event=…` ·
  `Tournament …` (also misspelled `Touenament` — match case-insensitively on both).

## Query rules learned (MCP validator, restricted mode)
- REJECTED: `AT TIME ZONE`, `percentile_cont(...) WITHIN GROUP`, `stddev_samp`, `sqrt` (compute sd offline
  from sum/sumsq), bare `SELECT func()` with no FROM. Accepted: `now() - interval`, min/max/avg,
  `date_trunc`, `to_char`, `regexp_replace`, `count(*) FILTER (WHERE …)`, window functions, CTEs, HAVING.
- Always filter `_ab_cdc_deleted_at IS NULL`, and `paid_at IS NOT NULL` for real deposits.
- Exclude internal accounts: `(flags & 64) = 0` PLUS the unflagged list in the report above.

## Payment methods + payment success (mapped 2026-09-29)
- Method names: `public_fwd.payment_systems` (`id`, `name`, `payment_gateway_id`, `status`, `category`, `min_deposit_amount`, `countries`)
  + `public_fwd.payment_gateways` (`id`, `name`). E.g. 82 = `zen_multicurrency` (Zen, card, the main method), 94 = skinsback,
  83 = whitepay_usdt, 5 = wallet_code. Rows carry updated_at 2023 — use for names, not live config.
- `deposits.status`: 2 = paid (`paid_at` set), 3 = not paid (decline / abandon — indistinguishable here), 1 = pending (rare). Inferred from data.
  Attempts = rows by `created`; success = paid / attempts, or clients with ≥1 paid / clients who created one.
- `payment_system_response` is provider text — may hold transaction ids; never select raw, only aggregate.
- Report: `_reports/blc-data_2026-09-29_2114_v1.md` (Zen TR success 69% → 42%, Sep 2026).
- No decline reasons in the replica: `payment_system_response` is empty for all Sep 2026 TR Zen attempts (22 of ~4k in Jun–Aug).
  Status 1 (pending) rows stop after Jun 2026 → status-3 counts are not comparable across that line; paid/attempts is.
- GA4 `purchase` for Türkiye is ~0 for weeks 2026-05-25 → 06-15 (tracking gap, DB normal; other countries not checked). Turkey deep-dive: `_reports/blc-data_2026-09-29_2135_v1.md`.

## Referral / partner codes (mapped 2026-09-25)
- `public.client_referral_systems`: one row per code — `id`, `client_id` (partner's own account), `referral_code`, `level`, `flags`.
  `public.client_referrals_histories`: `client_id` (referred) → `client_referral_system_id`, `created_at`.
- Revshare accrues to the partner's balance as `balances.reference_type = 6` (~5% of referred deposits);
  payouts are manual `reference_type = 4` with info `pay reff bonus by crypto`.
- `client_items.status = 3` ≈ withdrawn to Steam (dated by `sold_at`): matches `clients.total_withdrawal_amount`
  within ~15% on the EGW cohort. Inferred, not app-code confirmed. Report: `_reports/blc-egamersworld-margin_2026-09-25_v1.md`.

## Items, prices, case-battle leaderboard (mapped 2026-09-26)
- No items/name table in the replica. Name -> item_id: bloodycase.com item page SSR JSON `<script id="server_app-state">`,
  key `item_details_*` -> `Exteriors[<wear>].Id` / `.Price` (cents). That Price = `client_items.buyout_price` at drop time.
- `client_items.reason` vocabulary CHANGED: case opens are now `main case win: case id [N]` (no longer `''`), plus
  `successful upgrade`, `battle id [N] winner`, `bot_stat_increment` (bots), `free nft`. No index on `item_id`:
  filter through `ix_client_items_reason_created` with reason RANGES (`reason >= 'main case win' and reason < 'main case wio'`).
- Case-battle leaderboard = `stats.tournament` type 3; prizes in `stats.tournament_awards` (place, award_reference = item_id).
  Grid: places 1-10 unique, 11-20 / 21-50 / 51-100 one item each. Past boards: bloodycase.com/leaderboard/case-battle/history/<id>.

## Multi-open (x1..x10) detection + MCP timeout patterns (mapped 2026-10-01)
- No "open batch" id in the replica. One go = same client + same case `reason`, consecutive drops < 1 s apart
  (drops inside a batch land 0.2-0.7 s apart; next spin >= 1 s, mostly 3-60 s). Sizes cluster at 1-5 and 10 = the UI options.
- 90 d of `main case win` drops ≈ 3M rows (all users); the lag/running-sum window over all of it fits in 30 s ALONE.
- TIMEOUT TRAPS (planner underestimates the reason-range scan ~10x → nested loops):
  `c.id in (select … from <cte>)` and joining `clients` + `exists(deposits)` to fine-grained (client × case) rows.
  Fix: aggregate to ONE row per client first (array_agg per-case stats if needed), join `clients`/`deposits` there, then `unnest`.
- Parallel MCP queries contend on this host — run heavy ones sequentially.
- Report: `_reports/blc-data_2026-10-01_2108_v1.md`.
