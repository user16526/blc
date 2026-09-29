# Competitor events vs BLC "Start Season 2026": what ties an event to deposits
2026-09-29 · gaming-ux-strategist · web research (WebFetch/WebSearch/curl) + BLC live SSR config. Every competitor
claim carries a URL; "unverified" = seen only in a search snippet, or source page not reachable.

## TL;DR
- **We already pay for every deposit, and that is why it adds nothing.** Every top-up of $5-500 earns XP and coins
  automatically (8 bands on the event page). It rewards deposits players would make anyway: payers flat (+1%),
  GMV -18% (`_reports/start-season-event_2026-09-29_v1.html`).
- **Value sits at the very end.** 80% of level-skin value ($318 of $399) is in levels 22-25. Reaching them takes about
  $1.2k-2.2k of deposits at the best XP rate. A typical $20 payer reaches level 2-3 and gets skins worth $0.24-1.12.
  A $5 minimum deposit (800 XP) does not even finish level 1 (1,000 XP).
- **Competitors earn deposits with things that make players commit money or lose status.** Key-Drop sells a $5
  Premium Event Pass. Hellcase and Farmskins sell monthly subscriptions ($5-25 and $10-100). DatDrop's free-case
  level is set by deposits and drops $5 a day. CaseBattle's daily case scales with the last 7 days of wagering.
- **Top payers get their own races elsewhere, and not here.** CaseBattle runs $1k daily and $20k monthly wager
  leaderboards. Skin.club gates giveaway tiers by points. Our top-10 payers' GMV fell 31%, and nothing in the event
  is aimed at them in a way a player can see.
- **What to test next event:** (1) a paid premium track (~$5 from balance); (2) cumulative-deposit milestones within
  the event instead of flat XP per deposit; (3) a whale leaderboard with a published prize pool; (4) a mid-pass value
  step at levels 5-12. A hold-out group is needed so the effect on deposits can be measured.

## Our current event, as observed (live `bloodycase.com/ua/events`, SSR `events_get_current_events`, 2026-09-29)
- **Window:** 2026-09-08 20:00 to 2026-10-06 (StartAt/EndAt epoch 1788897600 to 1791331199). One free track with 25
  levels and 475,000 XP in total. Tabs: Main · Battle pass · Auctions · Event store · Leaderboard.
- **How XP and coins are earned** (config `Sources`). Opening a case gives 20 XP and 9-13 coins. The 18 event cases
  (ids 618-635) give 80 XP and 35-53 coins. Three more source types give 20, 50 and 500 XP. The page lists earning
  paths as "Cases, Dragon cases, Case battles, Giveaway, Deposit", but which type maps to which path is unverified.
- **Deposit reward ("refill quest"), shown very visibly** as 8 cards with "Top up" buttons: *"Every top-up brings
  you coins and XP"*. Bands (cents converted to $) and XP per band:
  $5-9.99 → 800 · $10-19.99 → 1,650 · $20-49.99 → 3,500 · $50-99.99 → 9,000 · $100-149.99 → 19,000 ·
  $150-199.99 → 30,000 · $200-249 → 42,000 · $250-500 → 55,000. Coins per band are about 0.4-0.6× the XP.
  That is 160-220 XP per $ at the bottom of each band and 70-150 XP per $ at the top. The config has no band above
  $500; what a larger deposit earns is unverified.
- **Level rewards:** one skin per level plus coins or an unidentified reward type ("Type 3"). Levels 1-15 give skins
  of $0.24-5.12. Level 16 gives $18.65. Levels 22-25 give a Glock Shinobu $28, Moto Gloves $82, a Falchion $93 and a
  Kukri $116. Total skin value is $398.63.
- **Deposit-only path:** one $150 deposit reaches level 10. Level 23 needs about $1,480 at the best rate. Level 25
  needs about $2,160.
- **Store, auctions and leaderboard** are rendered client-side, so their contents are unverified. The config lists 10
  leaderboard prize item ids, but the ranking basis is unverified.
- **Hygiene bug:** the Start Season config still carries `MainTitleToken: "NO NAME RESORT"`, which is the previous
  event's title. It shows up as the title image's alt text, so crawlers and screen readers read the old name.
- **The data is consistent with this design.** Every payer earns event XP automatically, so the event cannot be
  credited with any deposit (`.agent/capsules/blc-db-schema.md`).

## Competitors
| Site | Format | Progress earned by | Deposit hook | Rewards | Source |
|---|---|---|---|---|---|
| **Key-Drop** | Themed "Special Event" with an Event Pass (levels); free track plus Premium | Opening cases gives points "alongside the usual drop"; a top-up "gives you guaranteed EP" (unverified: search snippet, page now 404) | **Paid Premium Pass, $5**, "Double your rewards… extra rewards at every level"; run in 2024 and again in 2025 | Free skins per level; better on Premium; event points buy "gift exchange" skins (post title only) | [X 2024](https://x.com/keydropcom/status/1792556137721528518) · [X 2025](https://x.com/keydropcom/status/1892245182407487655) · [event-pass page (snippet)](https://key-drop.com/en/calm-strike/event-pass) · [FB](https://www.facebook.com/keydropcom/posts/-gift-exchange-use-event-points-to-claim-a-free-skin-join-now-httpskeydropcomhom/1000944112079133/) |
| **Hellcase** | Themed events (e.g. "Golden Goal", "The Great Eight") with tokens; a Battle Pass "now and then" | **Refills** earn tokens ("Event Rewards… for refilling their balance for a certain amount"); also daily missions | Refill-threshold rewards; **Token Vault** (the more tokens you deposit into it, the better the skin at event end); Premium subscription; Hellsquad VIP for $300+ refilled per rolling month | Event store (event cases; per snippet also bonus balance, premium time, games), wheel, skin generator; leaderboard of top token collectors | [bitdegree, Aug 2026](https://www.bitdegree.org/crypto/deals/hellcase-promo-code) · [FAQ (snippet; 403)](https://hellcase.com/faq) · [X Token Vault](https://twitter.com/hellcasecom/status/1594364955897176064) · [psxextreme](https://psxextreme.com/gen/hellcase-promo-code-how-to-get-free-money-cases-2026/) |
| **Skin.club** | "Back the Makers", 2026-09-22 to 10-22 (30 days); currency "Palette Points"; 5 giveaways plus a leaderboard | **Wagering only**: case open ×1, battle ×1, upgrade ×0.5 XP (live config); about 1 XP per 5¢ wagered | Giveaway entry tiers cost **12 / 100 / 220 / 900 points**; a separate giveaway for Premium level 50+; points reset at event end | 16 skin types × 15 copies (about $5-6.50 each) in giveaways; points store; weekly top-20 leaderboard "up to $850" (unverified) | [skin.club/en/event (Nuxt state)](https://skin.club/en/event) · [giveaway](https://skin.club/en/event/giveaway) · [bestcs2cases](https://bestcs2cases.com/case-opening/skinclub-full-review/) |
| **DatDrop** | No season pass; always-on currency plus races | 5 DatPoints per $1 spent | **Free-case level set by cumulative deposits ($3 to $100 for levels 1-5), decays $5 per day**, so players must keep depositing to keep it; Royale Race leaderboard | Premium cases only openable with DatPoints; daily case tiers | [csgamble, Sep 2026](https://csgamble.com/review/datdrop/) |
| **CaseBattle** | Always-on races plus Challenges plus Rewards | Wagering ("Start Climbing By Wagering") | **$1k daily and $20k monthly wager leaderboards**; daily case "scales with your last 7 days of wagering"; daily, weekly and monthly rakeback | Leaderboard cash, level cases (levels 10-100), money rain | [casebattle.com/rewards](https://casebattle.com/rewards) · [skincasereviewer, May 2026](https://skincasereviewer.com/irl/reviews/casebattle) |
| **Farmskins** | Seasonal events (Halloween, Black Friday, Christmas) with free cosmetic rewards; tournaments tied to esports events (queued: `pgl-singapore-major-2026`, `krakow-2027`) | Unverified. "Bullets"-style tokens from case drops appear only in a search summary | **Premium subscription: $10, $50 or $100 per month** (3- and 6-month plans 10-15% off), with extra cashback and exclusive cases | Profile hoods, borders and backgrounds; leaderboards (details unverified) | [farmskins.com SSR config](https://farmskins.com/) · [cs2-gambling.gg](https://cs2-gambling.gg/reviews/farmskins/) |
| G4Skins | Page titled "Buy Battle Pass & Claim Rewards" (a paid pass) | Unverified | Paid pass (price unverified) | Unverified | [g4skins.com/chicken-pass](https://g4skins.com/chicken-pass) |

Not documented: ggdrop, Forcedrop and CSGOCases event pages are JS shells, and no write-ups describe their events.

## Patterns that plausibly drive deposits (ranked)
1. **Make players pay before they progress: a paid premium track** (Key-Drop $5 pass; Hellcase and Farmskins
   subscriptions). Paying turns the free track into a purchase, and the paid track then pulls later deposits so the
   player doesn't waste it. For BLC: a $5-10 premium track bought from balance, which pairs every reward with a
   second, better one.
   *Metric:* attach rate among payers, and deposit count per premium buyer vs a matched free group.
2. **Status that decays unless the player deposits again** (DatDrop: level set by deposits, minus $5 a day;
   CaseBattle: daily case based on the last 7 days). This increases how often players deposit, where our flat
   XP-per-deposit does not.
   *Metric:* deposits per payer per week and the share of payers with 2+ deposits during the event.
3. **Deposit rewards that are extra, not automatic: thresholds reached cumulatively during the event**
   (Hellcase Event Rewards unlocked at a cumulative refill amount; Key-Drop's guaranteed EP from top-ups).
   For BLC: replace per-deposit XP with event-long cumulative milestones ($25, $75, $200, $500) that each unlock a
   chest. Show a "you are $X from the next chest" progress bar on the deposit screen.
   *Metric:* the share of payers moving from one deposit band to the next vs the previous event.
4. **Races for top payers with a published prize pool** (CaseBattle $1k daily / $20k monthly; Skin.club weekly
   top 20). This goes straight at our -31% GMV from the top 10 payers.
   *Metric:* GMV of the top-50 payers per week during the event vs before it.
5. **Giveaway entry tiers bought with points** (Skin.club 12/100/220/900). These create clear spend targets at
   low, medium and high levels, and cost only the prize.
6. **Places to spend the currency, with a cut-off at the end** (Hellcase Token Vault; Skin.club points that
   don't carry over). A known "use it or lose it" date gives a reason to spend and top up in the final week.
   *Metric:* GMV in the last 7 days vs the event average.
7. **VIP access gated by a monthly deposit amount** (Hellcase Hellsquad: $300 in a rolling month unlocks VIP
   cases). This works outside events and also sets the tier target for pattern 3.

## Anti-patterns (ours, and what to avoid copying)
- **Automatic, flat-rate deposit XP.** It pays for deposits players would make anyway, gives no reason to add
  more, and makes it impossible to credit the event with anything. This is the root cause of what we observed.
- **A dead first deposit.** The $5 minimum earns 800 XP, below level 1's 1,000, so the first deposit gets no
  reward moment. The first milestone should fall exactly at the minimum deposit.
- **Value only at the end.** Levels 1-15 give $0.24-5 skins; the value starts at level 22. Mid-size payers
  ($20-150), who are most of our GMV, have no reward in reach that is worth depositing for.
- **XP per $ that drops within a band.** $9.99 earns 80 XP per $ against 165 at $10. That only helps us if the UI
  says "add $0.01 → double XP", and whether it does is unverified (it needs a logged-in check).
- **XP for activity alone** (20 XP per case) raises activity without raising spend: +20% active participants,
  payers flat. That is fine for retention, but it should not be the main way to progress.
- **Stale branding** ("NO NAME RESORT" still in the Start Season config), which looks careless in an event that
  asks for money.
- **Don't copy blindly:** wager-only races (CaseBattle, Skin.club) mostly reward players who churn their balance
  quickly and hunt bonuses. Build our race on net deposits, or on wagering with a limit on bonus balance. Paid
  passes and decaying status also draw loot-box and responsible-gambling scrutiny in regulated GEOs, so publish the
  odds and value per tier.
