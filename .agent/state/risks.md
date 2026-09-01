# Active Risks
<!-- Update as they change; mark resolved, don't delete. -->
<!-- - [open] R1: ... — impact — mitigation — owner -->

- [open] R1: `scripts/pre-commit` diverges from the template by one line (D1 exclusion).
  Impact — a future upgrade's mechanical merge could silently revert it and re-block
  every commit, or widen it past `scripts/test-hooks.sh`. Mitigation — recorded in
  decisions.md as KEPT OURS + `docs/template-defects-owed-upstream_2026-09-01_v1.md`;
  re-run the negative control (plant a `sk-proj-…` in `temp/`, expect rc=1) after any
  upgrade that touches the hook. Owner — whoever runs the next template upgrade.
