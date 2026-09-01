# /mcpb — query live BloodyCase data (read-only Postgres MCP)

Usage: `/mcpb <question in plain words>` — e.g. `/mcpb deposits per day last 14 days`,
`/mcpb which cases are opened most this week`, `/mcpb schema` (just refresh the map).
No argument = preflight only + "ready".

Data path: `scripts/pg-tunnel.ps1` (SSH port-forward) → localhost:5432 → MCP server
`postgres` (Postgres MCP Pro, restricted = read-only). Runbook: `docs/pg-tunnel.md`.

## 1. Preflight (every call, cheap)
1. Run `.\scripts\pg-tunnel-ensure.ps1`. It prints `UP` or starts the tunnel in a
   minimized window. If it prints `FAILED`, stop and show the message — don't guess.
2. Check the MCP tools `mcp__postgres__*` are callable (ToolSearch `+postgres` if
   deferred). If the server shows failed/not connected: tell the user to run `/mcp`
   → reconnect `postgres` (it connects at launch; a tunnel started later needs a
   reconnect). Never fabricate data while the MCP is down.

## 2. Schema memory (don't rediscover every time)
- Read `.agent/capsules/blc-db-schema.md` first if it exists and is < 30 days old.
- If missing/stale, or the user says `schema`: use `list_schemas`, `list_objects`,
  `get_object_details` on the tables that matter for the product metrics
  (users, deposits/payments, case opens, items/skins, withdrawals, promo) and
  write/refresh the capsule: table → purpose, key columns, money unit (cents?
  which currency), timestamp column + timezone, status enums, how "first deposit",
  "case open", "GMV" map to columns. Keep it ≤ 150 lines, facts only.

## 3. Answer the question
- Translate the question into ONE SQL statement (CTEs fine) via `execute_sql`.
  Aggregates over raw rows; always `LIMIT` (≤ 50); explicit date range and timezone
  in the SQL; never `SELECT *` on user/payment tables.
- Slow (> 30 s) or huge → stop, narrow the range/add a filter, re-run once.
- PII never leaves the DB: no emails, IPs, Steam IDs, names, wallet/transaction ids
  in the output. Aggregate or hash-count instead.
- Read-only is enforced by the server (restricted mode); still, never attempt writes.
  Credentials are never printed.

## 4. Output (decision first)
```text
<headline number / finding in one line>

| metric | value |   (≤ 10 rows)

SQL used:
```sql
...
```
Caveats: date range, timezone, what's excluded, anything unverified.
```
If the result is a deliverable (analysis someone else will read), also save it to
`_reports/blc-data_<YYYY-MM-DD>_<HHMM>_v1.md` (artifact-versioning rule) with the
SQL inside, and cite it. Chat-only answers need no report.

## Don'ts
- No fixes, no "we could also" — answer the question asked.
- Don't cache numbers as design tokens or facts in `current.md`; live values decay.
  Durable structural facts (schema, units) → the capsule only.
