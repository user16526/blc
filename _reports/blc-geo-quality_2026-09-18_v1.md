# Leak 1 diagnosed — geography and registration quality, Aug–Sep 2026 vs 2025
Source: live DB `bloody` via /mcpb, 2026-09-18. Cohorts Aug 1 – Sep 10 (full 7-day maturity),
`clients.region`, real accounts only (`flags & 1 = 0`, `flags & 64 = 0`, `deleted_at IS NULL`).
Companion to `_reports/blc-aug-sep-yoy_2026-09-18_v1.md`, which found Leak 1 but not its cause.

## Verdict
Leak 1 is two things at once, and neither is a payment problem:

1. **The audience moved to countries that cannot pay.** Russia collapsed (−80%) and the volume
   was replaced by Belarus, Uzbekistan, Iran and the Netherlands — 4,265 registrations that
   produced **26 paying customers between them**.
2. **Intent fell inside the good markets.** Ukraine doubled its registrations while the share
   who even try to deposit **halved** (21.3% → 10.3%). Germany doubled its registrations while
   intent fell by two thirds (17.0% → 6.3%).

Growth was bought in the wrong places, and the places that already worked got worse traffic.

## Registrations by country, Aug 1 – Sep 17
| country | 2025 | 2026 | Δ |
|---|---|---|---|
| **RU** | 3,757 | 734 | **−80%** |
| UA | 4,072 | 7,200 | +77% |
| PL | 2,399 | 3,640 | +52% |
| TR | 2,434 | 2,579 | +6% |
| DE | 1,119 | 2,190 | +96% |
| **BY** | 497 | 1,672 | **+236%** |
| BR | 2,284 | 1,662 | −27% |
| US | 958 | 1,438 | +50% |
| **UZ** | 413 | 1,301 | **+215%** |
| AR | 519 | 1,237 | +138% |
| RO | 583 | 1,125 | +93% |
| **NL** | 326 | 1,056 | **+224%** |
| KZ | 382 | 1,009 | +164% |
| **IR** | 225 | 907 | **+303%** |
| ES | 927 | 903 | −3% |

## The two steps, by country (cohorts Aug 1 – Sep 10)
`tried` = registered and made at least one deposit attempt. `try→paid` = of those, how many succeeded.

| country | regs 2025 → 2026 | tried 2025 | tried 2026 | try→paid 2025 | try→paid 2026 |
|---|---|---|---|---|---|
| **UA** | 3,362 → 6,078 | **21.3%** | **10.3%** | 71.0% | 53.1% |
| **DE** | 955 → 1,879 | **17.0%** | **6.3%** | 58.0% | 36.1% |
| **PL** | 2,068 → 3,040 | 8.5% | 12.9% | **62.3%** | **33.8%** |
| TR | 2,134 → 2,163 | 8.4% | 10.9% | 46.9% | 45.8% |
| BR | 2,001 → 1,444 | 13.5% | 17.7% | 37.8% | 30.2% |
| US | 797 → 1,242 | 10.2% | 11.6% | 40.7% | 41.0% |
| RO | 525 → 955 | 5.9% | 7.3% | 48.4% | 50.0% |
| RU | 3,269 → (gone) | 6.9% | — | 37.6% | — |

Read it country by country — the story is different in each:
- **Ukraine is the biggest loss.** It is the largest market and the best converter. Registrations
  grew 81%, but intent halved. In absolute terms: 717 people tried to deposit in 2025, 623 in
  2026 — from nearly twice the registrations. Payment is NOT the cause here (PS 82 succeeds
  67.8% in UA, barely changed).
- **Germany looks like bought or referred junk.** Registrations doubled, intent fell by two thirds.
- **Poland is the opposite case** — intent actually rose, but payment success collapsed
  62.3% → 33.8%. Poland is a payment problem, not a traffic problem.
- **Turkey, Brazil, the US and Romania are stable or improving on intent.** Their losses are at
  the payment step, which is Leak 2.

## The countries that cannot pay at all
Cohort Aug 1 – Sep 10, 2026:
| country | registrations | paid | rate |
|---|---|---|---|
| BY | 1,401 | **4** | 0.29% |
| UZ | 1,158 | **7** | 0.60% |
| IR | 793 | **6** | 0.76% |
| NL | 913 | **9** | 0.99% |
| **total** | **4,265** | **26** | **0.61%** |

Against a house average of ~3.2%, these four contributed 12% of all registrations and
0.8% of new depositors. Three of them (BY, UZ, IR) are markets where card acquiring effectively
does not work; NL at 1% with this growth pattern looks like VPN exit traffic rather than Dutch
players. Whatever acquisition brought them, it is producing registrations and nothing else.

## What this means for the numbers in the main report
The headline "+43% registrations, −17% depositors" is now explained:
- roughly 3,000 net-new registrations came from the four dead geographies,
- and the two best markets (UA, DE) grew in volume while losing most of their intent.

Fixing the payment provider will not recover this half. It needs an acquisition answer.

## Caveats
- `clients.region` is the registration-time region; its source (IP or profile) is unverified.
- The 2025 → 2026 comparison uses the same calendar window and the same 7-day maturity rule.
- "tried" counts any deposit row, paid or not. A user who never opened the cashier is not counted.
- RU's collapse is stated as fact; the reason for it is not in this data.
- Per-country payment success for the same window is in `_reports/blc-aug-sep-yoy_2026-09-18_v1.md`.

## Owner input already recorded (2026-09-18)
- **Paid Search** (13,123 → 7 sessions) was **deliberately paused** — small volume, no measurable
  effect, unprofitable. A contractor is being sought; it will be resumed later. Not a cause.
- **Email** (−79%) is periodic retention broadcasts, so the channel is spiky by nature. Not a cause.

---

# Addendum — where the new Ukrainian traffic came from (GA4, 2026-09-18)
Aug 1 – Sep 17, country = Ukraine, both years.

| channel | 2025 sessions / new users / avg session | 2026 sessions / new users / avg session |
|---|---|---|
| Organic Search | 16,345 / 2,794 / 469 s | **32,415 / 9,308 / 464 s** |
| Direct | 31,565 / 5,535 / 310 s | 32,322 / 6,280 / 295 s |
| **Paid Search** | **17,524 / 2,945 / 548 s** | **gone (0)** |
| **Organic Social** | 690 / 32 / 436 s | **3,429 / 2,036 / 137 s** |
| Email | 1,887 / 151 / 393 s | 852 / 42 / 292 s |

By source/medium, the swap is explicit:
- `google / cpc` **17,524 → 0** — the paused Paid Search. It had the **longest sessions of any UA
  channel (548 s)**.
- `google / organic` 13,605 → **30,795** sessions, new users 2,263 → **8,979**. Quality per session
  is unchanged (462 s → 464 s) — this is real growth, just much more of it.
- **New in 2026:** `l.facebook.com / referral` 2,760 sessions / 1,683 new users at **126 s**, and
  `m.facebook.com / referral` 284 sessions / 278 new users at **27 s**. Roughly 1,960 new users
  arriving from Facebook links and leaving in about two minutes or less.

**Reading:** Ukraine's registration growth is organic search plus a new stream of Facebook
referral traffic that barely stays on the site. At the same time the channel with the highest
engagement (`google / cpc`) went to zero. Volume went up, average intent went down — which is
exactly the halving of "tried to deposit" seen in the DB.

⚠ We cannot measure per-channel deposit conversion: GA4 has no registration event and every
client in the DB carries `partner_id = 1`, so channel cannot be joined to deposits. The link
between "Facebook referral" and "did not deposit" is inference, not proof.

**Germany 2026** shows the same shape more crudely: Direct 6,368 sessions carrying 3,686 new
users at 180 s and an engagement rate of 0.44 — far below the site norm. Direct traffic that is
overwhelmingly new users with weak engagement is not typical bookmark/type-in behaviour.
