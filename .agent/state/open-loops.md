# Open Loops
<!-- Unresolved tasks / pending approvals. Close when done. -->
<!-- - [ ] waiting on my approval to deploy staging -->

- [x] Report the two template defects upstream — CLOSED 2026-09-01. Not by us:
      the maintainer fixed both at the canonical tree in **v8.3.14**, so the fixes
      arrived with this upgrade and both local workarounds were dropped.

- [ ] Owed upstream at the next template build (D3 + one hygiene item):
      D3 — `scripts/state-patch.py --self-test` crashes on a default Windows cp1252
      console (`UnicodeEncodeError` on the `✓`). Workaround: `PYTHONIOENCODING=utf-8`.
      Hygiene — the shipped `template-v8.3.16/` folder carries a stray `.env` (a copy
      of `.env.example` from a staging `setup.sh` run) that the canonical release zip
      does not. Detail: `_reports/runs/template-upgrade-v8.3.16_2026-09-01.md`.

- [ ] `devops` audit is overdue (35d cadence, flagged by the SessionStart hook).
      Deliberately NOT folded into this upgrade — it is a model/vendor-guide audit,
      not a file merge. State: `.agent/state/model-audit.md`.

- [ ] Confirm whether `mockups/main002/index4.html` matches what the client last saw
      before iterating on it — unrecorded anywhere.
