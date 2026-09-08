# Happy Hour A/B test — design options after the owner's new idea (2026-09-02)
Status: PROPOSAL for owner approval (brainstorm output + sheriff review). Not yet the ТЗ.
Sources: `.agent/capsules/happy-hour-ab-test.md`, `_reports/blc-data_2026-09-02_0030_v1.md`,
`docs/happy-hour-backend_remote-copy_2026-09-02_v1.md`, dev comments by eugene_s (2026-08-27, 2026-09-01),
owner's ТЗ draft (pasted 2026-09-02).

## Goal of the test (acceptance criteria for any design)
G1. Answer, with attributable evidence, whether Happy Hour lifts depositor rate and deposits per
    logged-in client over the FULL day (primary, see P1), with capped net incremental revenue
    (Δ deposits − prize cost) as the guardrail; for whom = new vs returning, post-hoc cut.
G2. Produce a decision on the two levers we control: window (02–05 vs 18–21 UTC) and prize type
    (Deposit Bonus vs a case-type prize).
G3. Every prize in the pool must be a real prize for the client who gets it (winner-take-max vs the
    standing 20 % / 25 % first-deposit bonus, 6–10 % on later deposits).
G4. Implementable with what exists: planners with per-planner prize pools; the dev's logged-in
    split (33/33/33: control / 02 UTC / 18 UTC); no A/B-group concept in the backend planner.
G5. Bounded: a usable answer within ~3 weeks of the first prod day; the whole program ≤ 6 weeks.

## Hard facts that constrain every design
F1. Prizes are configured PER PLANNER. A planner fires at its cron time for everyone allowed to see it.
    The frontend gate decides which group sees which planner. So "different prize per WINDOW" costs
    nothing; "different prize per GROUP inside the same window" needs the frontend to route
    group → happy_hour_id (two planners at the same cron) — a small change, to be confirmed by dev.
F2. Winner-take-max: a Deposit Bonus ≤ 25 % is a no-op on first deposits; ≤ 10 % is a no-op on
    most repeat deposits. The owner's draft range "5–25 %" would be a null prize for new clients
    and nearly null for returning ones. Any Deposit Bonus slot must be ≥ 30 %.
F3. The backend has no expiry on BonusDeposit (no field in the doc); "valid 15 minutes" from the
    owner's draft is not implementable as written — it is a question for dev, not a spec line.
F4. `client_happy_hours.prize_won` stores the nominal roll only; there is no prize-cost column.
    prize_cost must be derived at deposit time (applied % − standing %) × amount, or logged by a
    new event. Without it G1 is unmeasurable.
F5. Case-type prizes available: `FreeTicket` = case BATTLE ticket (CaseID + Amount);
    `PromoCode` = real free case (7-day code), exists in the backend but was NOT in the admin
    prize list on 2026-08-27. `deposit_promotions` already gives a free case (776) for deposits
    ≥ $25 until 2026-09-09 — overlap if the test starts earlier.
F6. Reach: 02–05 UTC has 3.5–5× fewer deposits/hour than 18–21 UTC. Weekly deposits ~1050–1260 →
    ~55–60 deposits/day per third. Over 21 days ≈ 1200 deposits per arm on the full-day metric.
    ROUGH ORDER OF MAGNITUDE ONLY (Poisson on deposit counts): a 10 % lift on counts ≈ 2.4σ per arm-pair,
    and halving cell size drops that below 2σ. The real outcome is client-level net revenue (repeat
    deposits, heavy-tailed amounts, prize cost), so the true MDE is worse. PRE-START STEP P1: compute
    MDE on historical client-level full-day net revenue (90 d, per-client clustering) via /mcpb before
    fixing the run length; 3 weeks is the plan, not a proven number.
F7. `Weight` is ignored (uniform pick per slot); spin-once-per-day check is disabled for tests;
    planners have no end date (manual `is_active=false`).

## Option 1 — Manager's plan as agreed (timing test, identical pool)
H0 nothing / H1 02–05 UTC / H2 18–21 UTC; identical pool in both windows; 3 weeks.
Pool corrected for F2: Deposit Bonus 30 / 40 / 50 % (+ optionally 1 Free Ticket slot).
+ zero dev work beyond events; already built; clean answer on the WINDOW question
− answers nothing about prize type; morning arm is small-reach by construction (F6)

## Option 2 — Owner's idea: window × prize crossover (bonus in the morning, case in the evening, then swap)
Period 1 (3 wk): H1 02–05 UTC + Deposit Bonus; H2 18–21 UTC + case prize. Period 2 (3 wk): same
windows, prizes swapped. H0 nothing throughout.
+ zero dev work (F1: prizes are per planner); both levers in one program; the owner's intuition
  ("case fits the evening, near the battle peak") gets tested directly
− after Period 1 alone NOTHING is attributable — window and prize are fully confounded; the swap
  is mandatory, so the first usable answer arrives at week 6, not week 3 (fails G5)
− main effects only hold if there is no window×prize interaction — and the owner's own hypothesis
  IS an interaction ("case works in the evening"), which the crossover cannot estimate
− carryover: a group that learned "morning = bonus" for 3 weeks reacts differently in weeks 4–6;
  novelty decay across periods hits both arms but not symmetrically
− the case prize in Period 1 overlaps `deposit_promotions` (case 776) unless the start is after 09-09

## Option 3 — Sequential: prize test first (single window), then the timing test with the winner
Run 1 (3 wk): ONE window, 18–21 UTC (max reach, F6). H0 nothing / H1 Deposit Bonus 30/40/50 % /
H2 case prize (PromoCode if it reaches the admin panel, else FreeTicket). Two planners at `0 18 * * *`,
the frontend routes group → planner (F1: small dev change; the existing gate already maps
group → window, so this is a mapping change, not a new layer).
Run 2 (3 wk): the winning prize from Run 1, H0 / 02 UTC / 18 UTC — exactly what the dev has built —
with a FRESH randomization (new experiment id / hash salt) so Run 1 treatment does not carry into the
window arms; plus a 1-week washout with Happy Hour off between the runs. Without re-randomization Run 2
would inherit the same carryover confound the proposal rejects in Option 2.
+ each run asks ONE question and is attributable on its own; usable answer at week 3 (G5)
+ prize test runs at maximum reach, so it has the best power of the three designs
+ Run 2 reuses the built split unchanged
− Run 1 needs the small routing change (dev confirms); if the dev refuses, see Recommendation (owner
  relaxes G5 or G2 explicitly)
− the morning window is untested until week 5–7 (3 + 1 washout + 3); whole program 7 weeks, so G5's
  "≤ 6 weeks" is missed by one week — the owner accepts or drops the washout (then carryover is a
  stated caveat on Run 2, not a hidden one)

## Recommendation
Option 3. Reason: the prize question is now the bigger uncertainty (F2 turned the agreed prize into
a partial no-op), and Option 2 cannot answer either question before week 6 while carrying an
interaction it cannot estimate. Option 3 gives a decision at week 3 with the best statistical power,
and the timing test then runs on a prize we already know works.
If the dev cannot route group → planner: NO no-routing design meets G2 and G5 together. The owner then
chooses explicitly which criterion to relax — relax G5 (accept a week-6 answer: Option 2 with the swap
fixed in advance, never Period 1 alone) or relax G2 (Option 1: window only, prize question deferred).
This is an owner decision, not a silent fallback.

## P1 result (live DB 2026-09-02, _reports/blc-data_2026-09-02_1830_v1.md)
3 weeks × 1/3 split: MDE on net revenue ≈ 130 % raw / ≈ 45 % whale-capped — unusable. MDE on depositor rate
(logged-in → ≥ 1 deposit, 5.0 % baseline) ≈ 19 % relative; 6 weeks ≈ 13 %. Therefore the PRIMARY metric
becomes depositor rate + deposits per logged-in client (full day); capped net revenue is a guardrail.
G1 is rewritten accordingly. New-client share is 24 % in both windows; 32 % of evening deposits are ≥ $25
(case-776 promo overlap → C6 stands). Free Ticket cost is not in the replica → Q6.

## Corrections to the owner's ТЗ draft (apply whichever option wins)
C1. Prize "Deposit Bonus 5–25 %" → "30 / 40 / 50 %" (F2). Below 30 % the prize is invisible to
    new clients; below 10 % to nearly everyone.
C2. "Valid 15 minutes" → remove; ask dev whether BonusDeposit can carry an expiry at all (F3).
    If not, the window itself (180 min) is the only time pressure.
C3. `is_new_client` is fixed ONCE per client at a PRE-TREATMENT index event: the client's first
    `happy_hour_gate_shown` in the run (fires at group resolution for ALL groups, control included —
    dev to confirm, Q4). Value = "no PAID deposit before that timestamp". Never re-derived later, never
    from `happy_hour_shown` (treatment-dependent). A client who registers on day 5 is new too.
C4. Cost logging per prize type, or G1 is unmeasurable for the case arm:
    - Deposit Bonus: `happy_hour_prize_won` (nominal) + `happy_hour_prize_applied` (deposit_id,
      nominal_pct, applied_pct, prize_cost = (applied − standing) % × amount, cents).
    - FreeTicket: issuance event (ticket amount, case_id) + redemption event (battle joined);
      prize_cost = ticket face value at REDEMPTION, 0 if unredeemed by test end.
    - PromoCode: issuance + redemption (case opened via code); prize_cost = the case's cost basis
      (its listed price unless finance gives a cost-of-goods figure) at redemption, 0 if unredeemed.
    - All: confirm `group` persisted in DB and joinable to `deposits` by client_id (F4).
C5. Stop rule: manual `is_active=false` on both planners on day 22; end-date field = a later ticket (F7).
C6. Start date: after 2026-09-09 whenever a case-type prize is in the pool (F5).
C7. Participation "min deposit $5–10" → pick ONE value; recommend $5 (median first deposit is $5.99;
    $10 excludes most new clients).

## Open questions for eugene_s (whichever option)
Q1. Can the frontend route group → happy_hour_id with two planners at the same cron? Effort?
Q2. Is PromoCode (free case) available as a planner prize now, or only FreeTicket (battle ticket)?
Q3. Does BonusDeposit have any expiry/TTL? (owner wants 15 min; doc shows none)
Q4. Is `group` persisted in DB per client_id, and does `happy_hour_gate_shown` fire once per session
    or once per user?
Q5. Anti-farm "Not Participated 24h": is it per planner or per client across all planners?
    (matters for Option 3 Run 1 with two planners at the same cron)
Q6. Where are FreeTicket / PromoCode redemptions logged (table or event), so prize_cost can be
    computed at redemption? Can the split be re-randomized (new experiment id) for Run 2?

## Cross-review
cross_review: closed 2026-09-02 — SHERIFF (Codex) 5 findings: [1] Run 2 carryover → ✅ re-randomize +
washout; [2] is_new_client treatment-dependent → ✅ pre-treatment index event; [3] no cost model for
case prizes → ✅ C4 per-type issuance/redemption cost; [4] power claim optimistic → ✅ downgraded to
order-of-magnitude, MDE on client-level data owed (P1); [5] fallback violated G2/G5 → ✅ explicit owner
relaxation decision. 0 ❌. Findings file: temp/sheriff/hh-design-findings.txt
