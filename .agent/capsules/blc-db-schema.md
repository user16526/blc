# Capsule: BLC DB schema map (DB `bloody`, host bloodyanalytics02, via /mcpb)
Last updated: 2026-09-02. Structural facts only; numbers decay — re-query.

## Layout
- Schemas: `public` (Airbyte CDC replica of app tables), `stats` (event tables), `analytics` (derived),
  `airbyte_internal` (raw streams, ignore). CDC columns everywhere: `_ab_cdc_deleted_at` (filter IS NULL),
  `_repl_ts`.
- Timestamps in `public.deposits` are `timestamp without time zone` (assumed UTC, unverified);
  `deposit_promotions` uses timestamptz.

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
- Not yet mapped: `public.clients` (36 cols), `public.balances`, `public.client_items`, `stats.event_transactions`, `stats.event_exchange_transactions`,
  `stats.event_clients`, `stats.client_achievements`.

## Query rules learned (MCP validator, restricted mode)
- REJECTED: `AT TIME ZONE`, `percentile_cont(...) WITHIN GROUP`, `stddev_samp`, `sqrt` (compute sd offline from sum/sumsq). Accepted: `now() - interval`, min/max/avg,
  `date_trunc`, `to_char`, window functions, CTEs, HAVING.
- Always filter `_ab_cdc_deleted_at IS NULL` and `paid_at IS NOT NULL` for real deposits.
