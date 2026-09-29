# Run: BLC bonus grid (1st + 2+ deposits) — SHERIFF on demand, 2026-09-26
Deliverables: `_reports/bonus-grid-variants_2026-09-26_v2.html` (tables), `_reports/bonus-ladder_2026-09-25_v1.html` (schematic, A/B switch).
Owner inputs 2026-09-25: per-method bonus cap is configurable; NO wager on bonus balance.
Proof: headless-Chrome screenshots at 1280px — temp/bonus-ladder_A.png, temp/bonus-ladder_B.png, temp/bonus-variants_v2.png, temp/bonus-variants_v2_top.png.
Sheriff: Codex via scripts/sheriff-review.sh --author claude, exit 0, findings /tmp/tmp.cLkDuLqH2x/sheriff-findings.txt.
- [1] P1 no-wager crypto tiers abusable -> ✅ fixed: 15%+ only for accounts with 2+ deps and age >= 7 d; $300 bonus / account / 7 d; 1st-deposit bonus one per device/Steam ID/card.
- [2] P1 1st-deposit proposal raised cost (owner's concern too) -> ✅ fixed: 1st dep card 10/15/25% cap $35, crypto 15/20/30% cap $60; A −$1.4k/90 d on 1st dep; B adds 50/50 split bonus (up to −$3.6k).
- [3] P2 caps broke "pay more, get more" -> ✅ fixed: caps aligned to top tier (crypto 2+ A $180 = 18% x $1000, B $200 = 20% x $1000); buttons show $ bonus.
- [4] P2 +$3.7k upside overstated -> ✅ fixed: ~76 players x $41 ≈ +$3k.
Totals (static, 90 d): A −$3.2k, B −$7.3k.
cross_review: closed — 4 findings, 4 fixed, 0 disputed.
