# GA4 + GTM audit — BloodyCase, 2026-09-18
Source: GA4 Data API, property `282943360` ("bloodycase.com - GA4"), and GTM container
`GTM-K8LT52N` ("Bloodycase", account 6001579926), read live via the `vsc-ai-bot@…`
service account. Access granted by the owner on 2026-09-18; before that both returned 403/empty.

## Verdict
Three things, in order of how much they cost:

1. **~66% of September's "new users" are bot traffic from Singapore.** 115,734 of 176,296
   new users, Sep 3–10, ~10 seconds per session, zero key events. Every top-line growth
   number for September is inflated by it.
2. **Registration is not measured at all.** Both GTM registration tags are dead:
   `FinReg Tag` is PAUSED, `StartReg Tag` is a Universal Analytics tag (UA stopped
   processing data in July 2023). There is no `sign_up` event in GA4.
3. **GA4 independently confirms the payment failure found on 2026-09-17** — same size,
   different data source.

## 1. The Singapore wave
Daily new users (GA4): a flat ~2,000/day through Aug 16 → a step to ~3,200–4,200/day
from **Aug 17** → a spike to 11,723–25,961/day over **Sep 3–10** → back to ~3,200/day
from Sep 11.

Sep 1–17 2026, by country (new users / sessions):
| country | new users | sessions | pv/session | avg session | key events |
|---|---|---|---|---|---|
| **Singapore** | **115,734** | 115,423 | **1.05** | **10.1 s** | **0** |
| United States | 7,191 | 9,309 | 3.2 | 94 s | 114 |
| Ukraine | 5,941 | 26,514 | 9.5 | 347 s | 871 |
| Brazil | 3,926 | 25,547 | 1.9 | 94 s | 51 |
| Russia | 2,736 | 6,469 | — | — | — |

Singapore did not appear in the 2025 top-8 at all. One session per user, one page, ten
seconds, no conversions — datacenter traffic, not people. It is also what drags the
site-wide averages: pv/session 10.6 → 4.9 and avg session 387 s → 163 s year over year.

**Consequence:** September traffic "growth" is not real. Sessions 91,843 → 237,985 (+159%)
and new users 35,750 → 176,296 (+393%) both collapse to roughly flat once Singapore is
removed. Do not report September acquisition without excluding it.

⚠ Unverified but worth checking: the **smaller step on Aug 17** is the same date the PS 82
payment success rate fell (`_reports/blc-data_2026-09-17_1300_v2.md`). A fraud/bot wave and
a provider tightening its decline rules on the same day is a plausible single cause for both.
This is a hypothesis, not a finding — it needs the provider's decline reasons to confirm.

## 2. Registration is untracked
GTM container `GTM-K8LT52N`, Default Workspace (id 54), 14 tags:

| tag | type | state |
|---|---|---|
| StartReg Tag | `ua` (Universal Analytics) | active — **but UA is dead since Jul 2023, it sends nowhere** |
| FinReg Tag | `ua` | **PAUSED** |
| Pay-success-goal Tag | `ua` | paused |
| Enhanced Ecommerce Tag | `ua` | paused |
| Universal Analytics Classic | `ua` | paused |
| UA G4 Tag | `googtag` | active (this is the GA4 config tag) |
| GA4 Add Payment info Tag | `gaawe` | active |
| GA4 Purchase Tag | `gaawe` | active |
| FB Pixel Tag / Fb purchase Tag | `html` | active |
| MS Clarity Tag / Smartlook Tag | `html` | active |
| OneSignal Push Tag | `html` | active |
| Conversion linker Tag | `gclidw` | active |

GA4 therefore has exactly two funnel events: `add_payment_info` and `purchase`. Registration,
case opening, deposit-start — none are measured. **Registration counts can only come from the
database** (`public.clients.created`), which is what the pending research needs.

Fix (dev-team ticket, not ours to build): replace `StartReg`/`FinReg` with GA4 event tags
(`sign_up_start` / `sign_up`), and add a `begin_checkout`-equivalent so the deposit funnel has
a step before `add_payment_info`.

## 3. GA4 confirms the payment failure
Sep 1–17, both years, site-wide:
| event | 2025 | 2026 | Δ |
|---|---|---|---|
| `add_payment_info` | 5,682 | 5,529 | −2.7% |
| `purchase` | 3,004 | 2,443 | **−18.7%** |
| payment-step conversion | **52.9%** | **44.2%** | **−8.7 pp** |

Same number of people reach the payment step; far fewer complete. That is an independent
replication of the DB finding (PS 82 paid rate 57% → 48%) from a different system, and it
rules out "fewer people wanted to deposit" as the explanation.

## 4. Channel mix, Sep 1–17 (sessions)
| channel | 2025 | 2026 |
|---|---|---|
| Direct | 41,926 | 180,463 (≈115k of this is the Singapore bot wave) |
| Organic Search | 23,486 | 48,927 |
| **Paid Search** | **13,123** | **7** |
| Email | 5,871 | 1,207 |
| Paid/Organic Social, Video, Referral | ~7,000 | ~5,000 |

**Paid Search is switched off** (13,123 → 7 sessions) and **Email is down 79%**. Neither is a
tracking artifact — those channels simply stopped. In 2025 Paid Search brought 3,006 new users
in this window. Whether that was a deliberate budget decision is an owner question; if it was
not, it is a second, separate cause of the September revenue gap.

## Caveats
- GA4 `purchase` counts deposits as ecommerce purchases; it is close to, but not identical
  with, `deposits.paid_at` in the DB (2,443 vs 2,327 for a slightly different window).
- Country is GA4's IP geo. "Singapore" means the traffic egressed there, not that the users live there.
- Key events = GA4 `keyEvents`; the property's key-event set was not audited.
- `(not set)` holds 241 purchases — unattributed geo, not investigated.
