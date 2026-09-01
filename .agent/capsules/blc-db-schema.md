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
- Not yet mapped: `public.clients` (36 cols), `public.balances`, `public.client_items`,
  `public.client_login_records`, `stats.event_transactions`, `stats.event_exchange_transactions`,
  `stats.event_clients`, `stats.client_achievements`.

## Query rules learned (MCP validator, restricted mode)
- REJECTED: `AT TIME ZONE`, `percentile_cont(...) WITHIN GROUP`. Accepted: `now() - interval`, min/max/avg,
  `date_trunc`, `to_char`, window functions, CTEs, HAVING.
- Always filter `_ab_cdc_deleted_at IS NULL` and `paid_at IS NOT NULL` for real deposits.
