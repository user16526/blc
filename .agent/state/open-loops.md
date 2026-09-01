# Open Loops
<!-- Unresolved tasks / pending approvals. Close when done. -->
<!-- - [ ] waiting on my approval to deploy staging -->

- [x] Report the two template defects upstream — CLOSED 2026-09-01. Not by us:
      the maintainer fixed both at the canonical tree in **v8.3.14**, so the fixes
      arrived with this upgrade and both local workarounds were dropped.

- [x] D3 + D4 owed upstream — **CLOSED 2026-09-01: SHIPPED UPSTREAM in v8.3.17.**
      D3 (`state-patch.py --self-test` died under cp1252) fixed with a utf-8
      stdout/stderr reconfigure; proven at release both ways (default env and
      `PYTHONIOENCODING=cp1252`, 9/9 each). D4 (stray `.env` + empty
      `.claude/handoffs/` in the shipped wrapper folder) fixed as a CLASS: the
      wrapper is now unpacked FROM the canonical artifact and packaging asserts
      folder == artifact before zipping. Verified here against the artifact, not
      taken on trust: canonical `release/v8_3_17.zip` sha256 `415594db…` matches
      the owner's, and the wrapper folder now diffs EMPTY against it (108 == 108,
      no `.env`, no `handoffs/`).

- [ ] **Take template v8.3.17 on the normal cadence** (owner: no urgency — our
      v8.3.16 tree is functionally unaffected by both fixes). Merge is scoped and
      near-trivial, measured not guessed: the only template-owned deltas are
      `scripts/state-patch.py` (a 10-line utf-8 header), `CHANGELOG.md` and
      `TEMPLATE_VERSION`. Everything else that differs is our own keep-ours bucket.
      Artifact: `D:/claude/1-claude-templates/template-v8.3.17-all-in-one.zip`.
      NOTE until then: on THIS tree `--self-test` still needs `PYTHONIOENCODING=utf-8`
      — the fix ships in v8.3.17, which we have not taken yet.

- [ ] `devops` audit is overdue (35d cadence, flagged by the SessionStart hook).
      Deliberately NOT folded into this upgrade — it is a model/vendor-guide audit,
      not a file merge. State: `.agent/state/model-audit.md`.

- [ ] Confirm whether `mockups/main002/index4.html` matches what the client last saw
      before iterating on it — unrecorded anywhere.
