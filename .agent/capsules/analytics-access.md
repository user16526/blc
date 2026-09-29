# Analytics access — what the agent can actually reach (verified 2026-09-18)

Credentials live in `.env` (gitignored): `GOOGLE_SERVICE_ACCOUNT_JSON` (service account
`vsc-ai-bot@project-2076d028-0b33-4388-8dc.iam.gserviceaccount.com`) + GA4/GTM ids.
There is **no** analytics MCP server — access is direct REST with a service-account token
(`google.oauth2.service_account` + `requests`, both installed; no new dependency needed).
Scopes that work: `analytics.readonly`, `webmasters.readonly`, `tagmanager.readonly`.

## Verified live 2026-09-18 (probe: token refresh + one list call per API)
| API | Result for BloodyCase |
|---|---|
| Search Console (`searchconsole.googleapis.com/webmasters/v3`) | **WORKS** — `https://bloodycase.com/`, permission `siteFullUser` (also cabina.ai, scienceofchocolate.com) |
| GA4 Data API (`analyticsdata.googleapis.com/v1beta/properties/282943360:runReport`) | **WORKS** since the owner granted it on 2026-09-18 (was 403 earlier the same day) |
| GA4 Admin `accountSummaries` | 200 — account `24760760` "FIVE" → `282943360` **bloodycase.com - GA4** + `447679233` Cabina |
| GTM (`tagmanager.googleapis.com/v2/accounts`) | 200 — account 6001579926 "FIVE" → container `46033204` / **GTM-K8LT52N** "Bloodycase" (web), Default Workspace id 54 |

All three are granted. A 403/empty here is a GRANT problem, not a code bug — re-probe
(`.claude/rules/verify-external-state.md`) rather than debugging the script.

## What GA4 can and cannot answer (audited 2026-09-18 — see `_reports/blc-ga4-gtm-audit_2026-09-18_v1.md`)
- Only TWO funnel events exist: `add_payment_info` and `purchase`. **No `sign_up`.**
  GTM's `FinReg Tag` is paused and `StartReg Tag` is a Universal Analytics tag (dead since
  Jul 2023) — so registration is not measured anywhere in GA4. Registrations come from
  `public.clients.created` in the DB, full stop.
- Retention reaches back past Sep 2025, so year-over-year queries work.
- **Sep 3–10 2026 carries a ~115k-session Singapore bot wave** (10 s sessions, 0 key events).
  Never quote September traffic/new-user numbers without excluding country = Singapore.

## Registrations / deposits are NOT in these
Client counts come from the live replica via the postgres MCP (`/mcpb`). Local `psql`/
`psycopg` probes are denied by the auto-mode classifier — the MCP tool is the only path,
and it only connects if the SSH tunnel is already UP at session start
(`scripts/pg-tunnel-ensure.ps1`, then start the session).

## Secret hygiene
`GOOGLE_SERVICE_ACCOUNT_JSON` is a single-line inline JSON — a `grep` of `.env` prints the
private key. Never grep `.env` unmasked; select keys by name and mask values.
Key `d4a16539…` was exposed to a transcript on 2026-09-18 and should be rotated.
