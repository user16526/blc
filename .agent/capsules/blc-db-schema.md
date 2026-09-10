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
- Not yet mapped: `stats.event_transactions`, `stats.event_exchange_transactions`,
  `stats.event_clients`, `stats.client_achievements`.

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
