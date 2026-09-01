# Template Changelog

## v8.3.19 — release gate: verify from the artifact, never the tree (2026-09-01)
Owner decision after two same-day escapes (D4 stray .env, rotted START-HERE
literal) that passed working-tree checks. ADD scripts/release-check.sh — builds
via build-release.py, unpacks the RESULT, and inside it checks: no stray or
runtime files, no Context Guard release-file leak, no rot-able version literals
outside CHANGELOG/TEMPLATE-DELTA, CHANGELOG top entry == TEMPLATE_VERSION,
setup.sh restores exec bits, test-hooks 146/0, state-patch self-test under
utf-8 AND cp1252 (D3 regression), sha256 companion; optional --wrapper asserts
an all-in-one folder == artifact. Exit 0 ship / 1 do not ship / 2 not the
canonical tree. Lesson recorded in tasks/lessons.md [release]; UPGRADE.md and
build-release.py docstring point at it. Zero network.

## v8.3.18 — START-HERE version literal de-rotted (2026-09-01)
Found on the release re-check: START-HERE.md still pointed new projects at
`v8_3_15.zip` — a hard-coded version literal that had silently rotted through
two releases (the exact class the suffix retirement in v8.3.15 was about).
The line now refers to TEMPLATE_VERSION instead of naming a version, so it
cannot rot again. Docs-only; no code changed. Suite: PASS 146 / FAIL 0.

## v8.3.17 — BLC upgrade-run findings D3/D4 closed at the source (2026-09-01)
Reported by BLC on its v8.3.13 -> v8.3.16 upgrade (second defect report from
the field that came back as a fix — the pipeline working as designed).
- D3: scripts/state-patch.py --self-test died with UnicodeEncodeError printing
  its check marks under a cp1252 console. Fixed at source with the same
  stdout/stderr utf-8 reconfigure build-release.py already carries; verified
  here under PYTHONIOENCODING=cp1252: 9/9, no crash.
- D4: the v8.3.16 ALL-IN-ONE wrapper shipped a stray .env (byte-identical to
  .env.example, seeded by a setup.sh run in the working tree) and an empty
  .claude/handoffs/ — runtime artifacts of verification, cp -r'd into the
  release folder. The canonical zip was clean (its exclude list caught .env);
  the wrapper folder was not. CLASS fix in the release flow: the wrapper's
  template folder is now unpacked FROM the canonical artifact, and packaging
  asserts folder == artifact content (empty diff) before zipping. Lesson:
  never cp a worked-in tree into a release; verify from the artifact.
No template code changed beyond state-patch.py. Suite: PASS 146 / FAIL 0.

## v8.3.16 — hybrid execution state: continuous, deterministic patches (2026-09-01)
SKILL.state (arXiv:2608.26263) adapted, NOT copied: warm short transcript for
in-context synthesis + AUTHORITATIVE structured state maintained during work,
so the transcript is droppable at any moment. Handoff becomes a snapshot built
FROM state; Context Guard demotes to last safety net. LLM proposes patches,
a deterministic script validates and merges — never the reverse.
ADD: scripts/state-patch.py (validator+merge+atomic write+render, --self-test
GREEN, invariants I1-I5 incl. failed_rejected never shrinks silently);
.agent/state/state-schema.json (one schema per project, unknown keys rejected);
.claude/skills/state-patch/SKILL.md (semantic-event cadence — never per-command).
MODIFY: context-hygiene.md (+hybrid runtime), handoff SKILL (+built-from-state),
cross-review SKILL (+reviewer package = task+state+diff+evidence, NO transcript;
finding open->resolved only after gate), state-freshness.sh (+section 4: patch
older than HEAD => loud reminder), context-index.md (current.json authoritative).
DELETE: nothing. Suite re-run at release: PASS 146 / FAIL 0.

## v8.3.15 — versioning simplified: number only, suffix retired (2026-09-01)
Owner decision. Artifact name = TEMPLATE_VERSION, nothing else (`v8_3_15.zip`);
each release bumps the last number by 1. The runtime-derived -cgN suffix is
retired: in practice it produced two artifacts of the SAME version with
different names (v8_3_14-cg4 vs v8_3_14-cg5) — a fork, the exact failure the
pipeline exists to prevent. CG runtime pairing now lives only where it is
enforced: `.claude/context-guard/config.json` min_runtime (still 4.2.0 — no
CG 5.x source has been verified into the canon), the `runtime_version` line
`build-release.py` prints, and the release's CHANGELOG entry. Content is
otherwise identical to v8.3.14 plus the hermipro-staged additions:
`.claude/rules/communication.md` (final-first / advise-only-when-needed) with
the CLAUDE.md MY RULES bullet pointing at it, and `START-HERE.md`.
Full suite re-run at release: PASS 146 / FAIL 0.

## v8.3.14 — BLC findings D1/D2 fixed at the source, CODE release (2026-09-01)
Artifact suffix at the time: derived -cgN. Retired in v8.3.15 (see above); the
"CG runtime 5.x on the fleet" wording that briefly appeared here was never
verified by mechanism and is struck.
`build-release.py` derives the suffix from `.claude/context-guard/config.json`
min_runtime instead of a literal; the stale "-cg4" literal was itself a D-class
bug of the kind BLC just reported. NOTE for the owner: `min_runtime` in that
config still says 4.2.0 — bump it to the CG5 floor you actually require, per
project, when CG5 is verified there (compatibility is your call, not mine).
Reported by BLC with write-up docs/template-defects-owed-upstream_2026-09-01_v1.md;
fixed at the canonical tree, every project upgrades (D1 blocked every NEW v8
project's first commit).

- **D1 (blocking)**: the pre-commit secret scan now excludes exactly ONE path,
  `scripts/test-hooks.sh` — the suite legitimately carries synthetic secrets as
  negative controls, so scanning it blocked the first commit of any project
  that stages the suite. Narrowness is itself asserted: a synthetic secret in
  any OTHER file must still block (new suite control).
- **D2**: the gate's verdict extraction reads the "## Verdict" header line AND
  the next line, so a report written exactly to the shipped
  RUN_REPORT_TEMPLATE.md parses; the template's example now also shows the
  same-line form. Both styles are valid; the contract is stated in both files.
- Three new suite assertions (146/0 here): first-commit-with-suite allowed;
  D1 exclusion narrow; template-style verdict parses.
- For BLC on upgrade: its local D1 workaround and D2 report-format workaround
  are SUPERSEDED — the 3-way merge should take the template versions, and risk
  R1 (a mechanical merge reverting the workaround) dissolves with them.
- Canonicity, recorded: releases are payload builds of the maintainer's
  canonical working tree; the shared releases folder is the single
  distribution point. `build-release.py` remains the reproducible path for
  machines holding the full source tree with `context-guard/`.

## v8.3.13 — sheriff round 10: the fd8 control rebuilt, CODE release (2026-09-01)
One file changed: test-hooks §8 (91 → 102 assertions; suite here: 143/0).
Wrapper and live canary are UNCHANGED and were not re-shipped — the round-10
verdict is that the v8.3.12b "fd 8 LEAKED" flake was THE CONTROL, not the
wrapper: every refusal path (exit 2/3/5/6) left the stub log empty, empty ≠
CLOSED, so a refusal printed a security finding that never happened — with rc
and stderr discarded, which is why a single failure was undiagnosable. Its
neighbour was the mirror fail-open (passed when nothing ran).

- New `fd8_verdict()`: separates "did the CLI run" (decided by the argv log
  ALONE) from "what did it report" — RAN-CLOSED / RAN-LEAK / RAN-LEAK-PRESENT /
  NO-RUN. Keying run-ness off the exit code was the round's CRITICAL finding:
  a reviewer can inherit fd 8, write through it, then make the wrapper exit
  non-zero — a control forces exactly that and proves the leak still reports.
- Existence probed with `: >&8` (no bytes): CLOSED no longer conflates "closed"
  with "write failed"; present-but-unwritable is its own verdict.
- Two vacuous-pass traps closed in the controls: the no-CLI control used to
  prepend an empty dir to PATH and so INVOKED THE REAL CODEX — a billable model
  call from the hook suite, passing for the wrong reason; PATH is now filtered
  of every codex dir with the removal proven first, bash resolved absolute
  before filtering, and NO-RUN alone is never a pass (exit 6 + message
  asserted). Standing rule earned: gate controls must be provably offline.
- Honest limit, stated: the original 1-in-8 trigger was not reproduced (200
  isolated + 10 full-suite runs); leading hypothesis is a transient
  `exec --help` probe failure → correct exit-5 → old control cried leak, and a
  forced control now covers that shape. The next occurrence prints rc + refusal
  reason and settles itself.
- Every project upgrades: the shipped v8.3.12 gates carry both the false-LEAK
  generator and the fail-open assertion. Running total: 10 rounds, 31 findings,
  0 disputes, arbiter never needed.

## v8.3.12b — temp/ hygiene in the devops audit, docs/skills only (2026-08-31)
DECLARED FLAKE (pre-exists in v8.3.12, observed while cutting this release, on
Linux): §8's "fd 8 LEAKED into the reviewer" assertion failed once in ~8 suite
runs, unreproduced in consecutive reruns. Per the mtime lesson: stability loops
prove little — this needs a root cause or a forced-worst-case control,
field-first (queued). Until then a single red on THAT assertion warrants a
rerun + a report, not a shrug and not a merge.
No executable changes; the cadence rule reads this gap as not-behind. New step
in the devops skill's audit checklist: temp/ entries older than 14 days are
listed for a sweep each audit — scratch is deleted freely, but
sheriff-export*/provenance trees are evidence and get zipped into docs/ first
(the template's provenance doc points at those bytes). Deletions still go
through the owner manually per the guard. Origin: hermipro accumulated ~90
scratch files in a week; the fix is a standing rule, not an episode.

## v8.3.12a — two upgrade-procedure rules from the fan-out, docs only (2026-08-31)
No code changes; projects already on v8.3.12 need nothing.
- **CR-agnostic classification** (hivoice): step 2 file comparison must be
  CR-stripped — `* text=auto` gives Windows worktrees CRLF `.md` while release
  zips are LF, so raw hashes invent divergences and manufacture hand-merges
  that do not exist. Line-ending-only difference == identical.
- **Survival-task waiver** (hermipro): when an upgrade changes zero executable
  bytes in the project, the survival task may be waived with the owner's
  explicit OK, recorded in the run report — a rule to cite instead of a
  precedent to argue.

## v8.3.12 — sheriff rounds 8–9 folded in: CODE release (2026-08-31)
hermipro's field-first close of the round-7 findings, plus what its own loop
caught in the fixes. Suite here: 132/0 (section 8 alone: 91 assertions). Every
project upgrades to this one via update-new — first code release since v8.3.9.

- **Wrapper** (`scripts/sheriff-review.sh`, verbatim, round-8 hash): [1] and
  the `--out` TOCTOU closed — a private 0700 mktemp dir is canonical for both
  package and findings; `--package`/`--out` are copy-OUT destinations written
  through O_EXCL descriptors held until the copy; no caller pathname is ever
  reopened and the CLI never opens one. The round-8 sheriff then caught the fix
  itself introducing a WORSE hole — the held fd inherited by the reviewer
  (`/dev/fd/8` reaches the inode past every pathname rule and past read-only) —
  closed by closing both fds for the child on every CLI invocation, with a
  behavioural test and a negative control.
- **Live canary** (verbatim, round-9): new `git_manifest()` closes round-7 [3]
  — walks the gitdir (hooks incl. out-of-tree core.hooksPath via --path,
  config, refs, reflogs, MERGE_HEAD, rerere; index via `ls-files --stage -v`;
  excludes objects/ as inert and *.lock as transient). Root cause of the 127/2
  "flake": manifests hashed `ls -ldn` mtime at minute resolution — a control
  defect, not flakiness; fixed with `--time-style=+`, forced-worst-case
  assertion instead of stability-loop faith. Round 9: that flag is GNU-only and
  a rejecting ls left an empty stream hashing to a valid "nothing" → GREEN;
  both manifests now stage the stream and refuse when empty, the canary refuses
  an empty baseline (empty==empty fails open). Stated limit: GNU coreutils
  required — the failure is now "exit 2, named reason", never silent GREEN.
- **test-hooks §8** — 91 assertions incl. six new (three are controls: an
  mtime-only touch must move nothing; the pre-fix function must still trip; a
  flag no ls accepts must produce nothing).
- Also: round-6's canary had shipped as BINARY to git (a literal NUL in `tr`);
  now plain text.

## v8.3.11a — cadence rule: docs-only gaps are not "behind" (2026-08-31)
Docs only. hivoice caught the class: the freshness check compared bare versions,
so every docs-only release would generate a false "behind" in every project
forever (it had to leave a project-local standing note to suppress one). The
UPDATE POLICY cadence rule now says: a version gap counts as "behind" only if
the gap contains a CODE release (docs-only entries are marked "No code changes"
and are skippable by design). Projects need no local notes for this anymore.

## v8.3.11 — round-7 record corrections, docs only (2026-08-31)
No code changes. hermipro's round 7 (3 findings, none blocking, everything
still tighter than v8.3.8) lands three corrections to the round-6 record:
- The v8.3.9 claim "one rule closing hard links, symlinks and pre-planted
  files" OVERSTATES: `reserve_target` closes the package path (held descriptor),
  but for `--out` a TOCTOU window remains — the CLI reopens the findings path
  by name (the wrapper already states this at its lines ~296-300; the changelog
  didn't).
- Declared open limit [1]: the held package descriptor is later reopened by
  name; narrow (default package sits in a 0700 mktemp dir; needs --package
  aimed at a shared dir).
- Declared open limit [3], the one that matters: `repo_manifest()` in the live
  canary is built from `git ls-files` and cannot see `.git/` — a planted
  `.git/hooks/*` (code-execution persistence), config, refs or index mutation
  scores GREEN. Until fixed, the canary's stated limits are: submodules not
  walked AND `.git/` internals not walked.
Fixes go the field-first route (hermipro's AGENT queue owns [3]); the template
folds the proven result as the next code release. Fan-out on v8.3.10/11 remains
correct: nothing here relaxes anything relative to v8.3.8.

## v8.3.10 — record correction, docs only (2026-08-31)
No code changes. The v8.3.9 entry recorded finding 9 (the CRLF worktree
condition) as "still open upstream — fix it there per the recipe". That was
already false at release time: hivoice closed it at c38a55e on 2026-08-31
(core.autocrlf false + forced re-checkout through .gitattributes, decision in
its decisions.md). The recipe is superseded — upgrades must NOT re-issue it.
The 2 stray CR bytes the v8.3.9 fold saw predated that close. Lesson, same
class as everything else here: a changelog entry is an instruction, and a stale
instruction re-executes — correct the record the moment the fact changes.

## v8.3.9 — sheriff round 6 folded in (2026-08-31)
hivoice's round 6: my three upstream findings fixed field-first, plus four more
the process caught in the fixes themselves (including `exec 9> "$PKG"
2>/dev/null` permanently muting every later refusal — found by an assertion,
not by any reviewer). Running total: 6 rounds, 18 findings, 0 disputes.

- **`scripts/sheriff-review.sh`** — round-6 field copy, verbatim:
  `--ephemeral` promoted to REQUIRED (the persisted session IS the review
  package; exit 5 still emits the manual package, so requiring it costs
  nothing); `precheck_target`/`reserve_target` — a pre-existing
  package/findings target is refused (exit 3), one rule closing hard links,
  symlinks and pre-planted files; package written through the held descriptor
  (`set -C; exec 9>`), never reopened; `--package` == `--out` refused. Exit
  contract unchanged: 0/1/3/4/5/6.
- **`scripts/integration/sheriff-isolation-live.sh`** — canary now diffs a repo
  MANIFEST (name set + modes + symlink targets + content, tracked and
  untracked-not-ignored) instead of `git status` text, and mutates the repo
  mid-run to prove the assertion can fail. Stated limit: submodules not walked.
- **`test-hooks.sh` §8** — round-6 fragment (44 assertions; suite here: 92/0),
  incl. behavioural `repo_manifest` tests against a throwaway repo.
- **Template-side fix IN the fragment** (owed back upstream as a note): the
  `--ephemeral`-probe assertion ran after `$STUBDIR` was deleted, so it
  silently tested whatever real codex was on PATH — the round-3 class
  ("assertions that only run when a real CLI is installed") reproduced in a
  test; on a CLI-free machine it failed. The good stub is now rebuilt first.
- Normalization: the wrapper arrived with 2 stray CR bytes despite the
  blob-built export (finding 9, the CRLF worktree condition, is still open
  upstream — fix it there per the repo-local recipe already given).

## v8.3.8 — build-release default name unhardcoded (2026-08-30)
hivoice's post-upgrade sheriff pass, finding [1] of 4: `build-release.py
--template-name` defaulted to the literal `v8_2_0-cg4.zip`, so on any newer
source tree the documented default invocation would `os.replace` new content
onto an OLD archived artifact. Default is now derived: `TEMPLATE_VERSION`
(fallback: the source dir name); the flag still overrides. Findings [2]–[4]
(hard-link containment, canary comparing git status not content hashes,
`--ephemeral` classified hardening-not-required) touch the canonical sheriff
mechanism and go the field-first route: fixed under the pilot's sheriff + live
canary, then folded back — per the round-5 lesson, the maintainer does not
hot-patch the mechanism blind.

## v8.3.7 — fork merge: the final-first architecture rule (2026-08-30)
A parallel chat (2026-08-28) had already added the owner's global rules to a
v8.3.0 of its own; the sheriff line was built from a zip WITHOUT them — two
v8.3.0 forks. Merged here; Kernel Change Rationale: adopt the owner's standing
final-first rule into CORE.

- **CLAUDE.md CORE, HOW YOU WORK #3 → final-first**: go straight to the
  strongest practical solution — never plan a `v1 → improve → v2` chain;
  iterate ONLY on a new fact or a real test disproving the solution (the old
  "STOP and re-plan" survives as exactly that branch). CORE re-baselined.
- **CLAUDE.md MY RULES**: "Recommend only when something must change. If it's
  OK, say `OK` in one line and stop."
- **README_UA.md** title still said v8.1.9 — now version-agnostic v8.3.x.
- Projects that already pasted the fork's `old-projects-add-rules.md` keep
  their MY RULES lines untouched (MY RULES is preserved verbatim on upgrade);
  final-first reaches their CORE via this entry's rationale + re-baseline.

## v8.3.6 — line-ending policy (2026-08-30)
Closes the class the v8.3.5 fold hit for real: an export from a Windows machine
carried CRLF and all 25 sheriff assertions failed rc=2 on a Linux shell —
working code, red gate. **NEW `.gitattributes`**: `*.sh`, `*.py` and
`scripts/pre-commit` are `text eol=lf`; everything else `text=auto`. Existing
projects get it via the standard upgrade; after the merge run
`git add --renormalize .` once so already-committed files convert.

## v8.3.5 — sheriff round 5 folded in (2026-08-30)
The pilot's self-review clause fired on the v8.3.4 upgrade itself and found the
template's own regression: delta 2 (`--version </dev/null`) swapped ONE
hard-coded `codex` for `$SHERIFF_TOOL` and left seven invocation sites literal —
so the probe could validate a different executable than the review runs, the
exact failure the probe exists to prevent, reintroduced by the fix. Running
total: 5 rounds, 10 findings, 0 disputes, arbiter never needed.

- **`scripts/sheriff-review.sh`** — post-round-5 field copy: every site that
  INVOKES the CLI goes through `$SHERIFF_TOOL`; the closed author-identity line
  stays literal on purpose (vendor token, not executable — folding it in would
  couple the identity set to the CLI's name).
- **`test-hooks.sh` §8** — round-5 fragment, 29 assertions: adds the
  single-spelling check (greps non-comment invoking lines; negative control on
  a doctored copy reports the exact reinstated lines). Suite here: 70/0.
- **UPGRADE.md → UPDATE POLICY** — rule adopted verbatim from the pilot's
  decisions.md: **"An additive upstream delta is still a diff, and still owes a
  sheriff pass."** "Additive, relaxes nothing" is a merge rule, never a review
  waiver.
- Normalization, not a delta: the export arrived with CRLF endings (every
  sheriff assertion failed rc=2 on a Linux shell until stripped); both touched
  files normalized to LF.
- The §8 fragment's corrected splice CONTRACT (its header) is kept in-file:
  ok/no helpers, $SANDBOX, cwd==$SANDBOX at entry, scripts/ copied in.

## v8.3.4 — canonical sheriff wrapper folded in (2026-08-30)
The template converges on the field-proven sheriff mechanism exported from the
first install (4 cross-vendor review rounds over itself, 9 real findings,
0 disputes, arbiter never needed). Every mechanism file is the byte-verified
working copy, with exactly two declared template deltas. Provenance, the
evidence table, and the "do not clean up" list: `docs/sheriff-provenance_2026-08-30_v1.md`.

- **`scripts/sheriff-review.sh`** — replaced verbatim. New API: package
  (acceptance criteria + diff) on stdin, `--author <identity>` required,
  `--out/--package/--scratch/--dry-run/--probe`. **Exit contract (stable,
  callers branch on it): 0 ran / 1 CLI failed / 3 path inside repo / 4
  same-or-unknown vendor / 5 missing isolation flag → manual package / 6 no
  CLI → manual package.** Supersedes v8.3.1's 3/4 semantics. Guarantees now in
  code: root from the script's own git toplevel (deterministic fallback, never
  cwd); case-normalized containment on both sides; symlink-aware abspath;
  closed identity set failing closed on unknowns; whole-token flag matching
  (`--cd-root` does not satisfy `--cd`); empty work root handed to the
  reviewer; manual package always carries the full contract + criteria + diff.
- **`scripts/integration/sheriff-isolation-live.sh`** — canonical live canary,
  now under `scripts/integration/` (moved from `scripts/`); asserts behavior:
  reviewer sees no project file, repo state byte-identical after the run.
  `setup.sh` chmods the new subdir.
- **`test-hooks.sh` section 8** — replaced by the export's splice-ready
  fragment: 26 assertions incl. ordering guarantee (vendor check before any FS/
  CLI work), argv-recording stubs on every machine, renamed-flag refusal,
  manual-package completeness, `--probe` contract + its exists≠behaves caveat.
  Suite here: 69/0.
- **Skill + command files** — canonical versions; the command now covers both
  author directions (Claude-authored → codex sheriff; Codex-authored → fresh
  zero-context Claude session, a cold subagent is NOT enough).
- **Declared deltas (the only two):** (1) the skill re-gains the template's
  "Pluggable — PROJECT toggle" section — the export came from a project where
  the sheriff is unconditionally on; (2) the wrapper's `--version` probe reads
  with stdin closed (`</dev/null`) — the gate hung on an interactive stdin
  here; relaxes nothing, but per the mechanism's own rule it owes an upstream
  sheriff round, recorded in decisions.md.
- Prompts were already byte-identical; unchanged.

## v8.3.3 — update policy made standing (2026-08-30)
Upgrades stop being ad-hoc events and become policy. No behavior change to any
project until it upgrades; CORE untouched.

- **NEW `TEMPLATE_VERSION`** (repo root) — the installed template version as a
  file, not a memory. Standup ships it; UPGRADE step 5 rewrites it; FROM in
  step 1 now reads it (changelog-top remains the fallback for older projects).
- **UPGRADE.md → "UPDATE POLICY"** section: releases are build products kept in
  ONE shared folder (recommended `D:\claude\template-releases\`); semantics —
  patch = mechanical merge, minor = new capabilities OFF by default (the
  sheriff is the model case), major = transplant route; rollback is the step-0
  checkpoint branch, stated before starting; a release lands in ONE project and
  survives its gate before fanning out.
- **devops skill, section A** — template freshness rides the existing 35-day
  audit cadence: compare `TEMPLATE_VERSION` vs the newest release in the shared
  folder, propose "upgrade template" when behind; security-relevant releases
  are proposed immediately.
- Old projects need no history: unzip the new template into
  `temp/template-new/` and say "upgrade template" — the procedure reads the
  changelog intent itself. Projects predating UPGRADE.md: paste this file's
  content as a message first (built-in fallback).

## v8.3.2 — third sheriff pass ported to the template (2026-08-30)
The hardened project's own sheriff pass found 4 more real bugs in the hardening;
three classes existed in the template wrapper too and are closed BEFORE fan-out.
CORE untouched.

- **[1] Protected root from the caller's cwd** — invoking the wrapper by
  absolute path from outside the repo protected the wrong tree. `REPO_ROOT` now
  derives from `BASH_SOURCE[0]`, never `git rev-parse`/cwd. Test: wrapper run
  from a foreign cwd still refuses a scratch dir inside its OWN tree.
- **[2] Symlink final component** — a package/findings path outside the repo
  can be a symlink pointing inside it. Symlink package/findings paths are now
  refused outright (exit 3). Tested by execution here (Linux CI can create
  symlinks); on Windows workers the test self-skips with a stated known limit.
- **[3] Vendor patterns → closed set** — `codex*|gpt*` was a similarity rule;
  the CG 4.2.4 lesson applies: EXACT membership only (`codex`/`claude`/`gemini`),
  anything else is unknown → manual-only (exit 4). Test: an unlisted identity
  never auto-runs.
- **[4] Flags asserted nowhere without a real CLI** — the happy-path stub now
  records the argv actually passed and the suite asserts `--sandbox`,
  `read-only`, `--cd` are present on EVERY machine; deleting a flag from the
  invocation line turns the gate red. Suite: 51/0.
- Test fixtures renamed to the exact `codex` name in two PATH dirs — the closed
  set (correctly) rejected the old `codexgood`/`codexbad` names as unknown.
- Note: the field project's wrapper uses finer exit codes (5 missing flag, 6 no
  CLI); the template keeps 3/4 semantics. At fan-out pick ONE canonical wrapper
  — prefer the battle-tested project one if they diverge (3-way diff, UPGRADE
  step 2/3).

## v8.3.1 — sheriff isolation made executable (2026-08-30)
Field feedback from the first real install: two independent sheriff passes on
the same mechanism found two DIFFERENT missed isolation flags. Root cause class,
not instances: the isolation guarantees lived as prose an LLM must remember to
type. Per the template's own lesson — enumeration never closes an open-ended
class — the guarantees are now a script plus tests. Architecture stays simple:
author → `sheriff-review.sh` → SHERIFF ≤5 findings → fix/test → done.

- **NEW `scripts/sheriff-review.sh`** — the ONLY sanctioned sheriff invocation;
  the command file calls it and never constructs the reviewer CLI call. Owns:
  scratch dirs OUTSIDE the repo (hard exit 3 if a package/findings path resolves
  inside), the full flag set, the cross-vendor policy (author vendor == sheriff
  vendor → hard exit 3), and a **capability probe** (no version pin — probes
  that the required isolation flags exist via `--help`; `--probe` mode for
  install-time checks). **Fail-closed scope is automation only:** probe/CLI
  failure → exit 4 with the manual copy-paste package already built — the
  review itself is never skipped. The probe proves a flag EXISTS, not that it
  BEHAVES; behavioral proof is the live canary below.
- **NEW `scripts/sheriff-isolation-live.sh`** — manual behavioral canary
  (reviewer is asked whether it can see AGENTS.md/CLAUDE.md; must answer
  NO-CONTEXT, leak markers fail). Deliberately NOT in the gate: live call,
  tokens, nondeterminism. Run after any change to the sheriff mechanism.
- **`scripts/test-hooks.sh`** — new section 8 (6 effect-based tests): scratch
  inside repo refused; same-vendor refused; probe failure → manual package
  outside repo; happy path through a fake CLI; `--probe` both ways. Plus
  sheriff-review.sh added to the executable-bit check and a syntax check for
  the live canary. Suite: 47/0.
- **`cross-review` skill** — trigger 3 added, self-review: any diff touching
  `.claude/skills/cross-review/**`, `.claude/commands/sheriff.md`, or
  `scripts/sheriff-review.sh` is automatically HIGH row → sheriff pass (both
  real-world findings came from the mechanism auditing itself). Plus the
  wrapper-only invocation rule. `.claude/commands/sheriff.md` step 2 now calls
  the wrapper and dispatches on its exit codes (0 / 4 manual / 3 stop).
- **`tasks/lessons.md`** — shipped lesson: "a guarantee that must hold 100%
  cannot live only in prose — encode it in executable policy and test it."
  NOTE for upgrades: lessons.md is project-owned (bucket 3) — append this line
  manually in existing projects; the merge must not overwrite their lessons.
- Install note: run `scripts/sheriff-review.sh --probe` against the real
  reviewer CLI; if it fails, adjust `REQUIRED_CAPS` (and, if needed, the single
  invocation line) to that machine's actual isolation flags — then re-run
  test-hooks.sh and one live canary. CORE untouched — no re-baseline needed.

## v8.3.0 — SHERIFF cross-review, pluggable (2026-08-30)
Adds an OPTIONAL external cross-vendor review layer. Rationale: all internal
reviewers run on the same base model (correlated blind spots — see the
orchestration skill's "honest limit of independence"); SHERIFF is one pass by a
different vendor's model on high-risk diffs, plus a single arbiter for deadlocks.
Three agents, the third almost never fires. Off by default.

- **NEW** `.claude/skills/cross-review/SKILL.md` + `prompts/sheriff-review.md`
  + `prompts/arbiter.md` — the protocol: SHERIFF ≤5 findings (critical/high
  only, no style) → author answers `✅ fixed / 🧪 test / ❌ disagree (≤2, falsifiable)`
  → tests settle everything testable → remaining ❌ go to the ARBITER in one
  anonymous batch, verdict final among models; owner veto rare and silent.
  Roles are permanent; the role→model mapping is a dated entry in
  `.agent/state/decisions.md` (staleness protection per model-selection.md) —
  shipped mapping: SHERIFF = Codex CLI, ARBITER = Claude Fable 5.
- **NEW** `.claude/commands/sheriff.md` — on-demand check of the current step:
  auto via `codex exec` in a read-only sandbox when the CLI is available,
  manual copy-paste fallback otherwise. Always available, toggle or not.
- **CLAUDE.md** (CORE re-baselined with this rationale): HIGH row gains
  "SHERIFF on (PROJECT): external cross-review after GREEN"; DESTRUCTIVE row
  gains "SHERIFF on: cross-review mandatory". Non-CORE: PROJECT gains the
  `SHERIFF cross-review: on | off` toggle (default off, asked at onboarding —
  FIRST RUN updated); MY RULES gains the sheriff aliases line
  (sheriff / шериф / шер / шері / шері-мен → run `/sheriff`).
- **AGENTS.md** — "SHERIFF mode": as reviewer, Codex reads ONLY the prompt +
  diff (no CLAUDE.md/skills/state — independence needs less context, not more);
  when Codex authors, roles swap and the sheriff must be another vendor.
- **docs/ROLES.md** — SHERIFF listed under "External (not subagents)"; the
  internal `verifier` keeps its name and job — do not merge or rename them.
- Upgrade for existing projects: standard UPGRADE.md procedure; the four new
  files are template-owned bucket-1, the CLAUDE.md/AGENTS.md lines merge per
  step 3 (CORE line needs Kernel Change Rationale + re-baseline). Enable per
  project by setting the PROJECT toggle to `on` — no other edits.

## Context Guard 4.2.4 — unknown policy keys (2026-08-28)
Runtime `4.2.4`, schema **`1` — unchanged**. Scope is exactly one class: a
*misspelled* Context Guard policy key. Nothing else was pulled in.

- **CLOSEOUT (owner decision, 2026-08-28): structural identifiers are an EXACT,
  FINITE schema. The confusability rule is removed, not perfected.** Six review
  rounds each found one more name that a similarity rule accepted as harmless
  metadata while the runtime never read it — `_1M`, `_1m_old`, `_m1`, `_1n`, the
  fullwidth `_１ｍ`, and finally `_1rn`, where the edit distance was absolute but
  its *bound* `max(1, len/4)` still scaled with the name being matched. Every one
  silently ran the built-in default ladder at `--compat` exit 0. A rule about
  similarity has to be right for the whole of Unicode; a rule about membership
  does not have to reason about similarity at all. So the invariant is now:
  **only exact canonical structural identifiers can affect Context Guard
  policy.** A profile name is `1m` or `default`. A field name is one of the
  documented fields, or the single documented metadata field `_comment`
  (accepted at the root and inside a profile entry, never interpreted). Any
  other name at any of those levels is CONFIG INVALID — loud, fail-open, no
  ladder guessed — regardless of how much it resembles a real one.
  `_foldname`, `_dist` and `_confusable` are deleted; `difflib` survives only in
  the *"did you mean …?"* hint, which takes no part in acceptance. **Stated
  cost:** free-form metadata names (`_todo`, `_owner`, `_note`, a `_parked`
  profile, a `_comment` used as a profile *name*) are no longer valid; prose
  goes in `_comment`. The three shipped configs use only `_comment` at the root
  and migrate nothing. The earlier 4.2.4 bullets below that describe the
  confusability rule (rounds two to five) are the history of how this decision
  was reached; the behaviour they describe is superseded by this one.
- **FIX (sixth review round, V2): a lone UTF-16 surrogate in a config name
  reached a THIRD state.** `"p\ud800q"` is valid JSON and a valid `str` but not
  encodable as UTF-8, so `log_error`'s `errors.log` write raised
  `UnicodeEncodeError` — which its `except OSError` did not catch — out of every
  hook: `--compat` exit 1, the gate hook exit 1 with a raw traceback, and the
  statusline showing **no banner at all**, so the project rendered as if it had
  never opted in. Neither VALID nor CONFIG INVALID. `log_error` now writes with
  `errors="backslashreplace"` and can never raise; stdio uses the same policy so
  the banner keeps the operator's evidence instead of a `?`. Measured after the
  fix: `--compat` 4, banner on stderr and statusline, the literal `\ud800` in
  the message.
- **FIX (sixth review round, V2): two diagnostic paths interpolated the raw
  name.** `_check_name` already rendered names through `_showkey`, but the
  "profiles.X is not an object" and the cross-level messages did not, so an ANSI
  escape in a profile name reached stderr and `errors.log` raw. Both paths now
  go through `_showkey`, and the suite sweeps every hook entry point over
  surrogate, ANSI and control-character fixtures asserting no raw `ESC` and no
  traceback anywhere (§22).
- **FIX (closeout review, V2): a schema-VALID document could still reach the
  third state.** A 20000-deep nested array under `_comment` (never interpreted,
  so nothing in the schema objects to it) makes `json.load` raise
  `RecursionError`, which is not a `ValueError`, so `read_config` let it escape:
  `--compat` exit 1, gate/tooluse exit 1 with a traceback, statusline with no
  banner. `RecursionError` is now caught with the other parse failures →
  ordinary CONFIG INVALID. Same review: `compat_check` interpolated
  `min_runtime` raw into the INCOMPATIBLE banner, so an ESC smuggled in a
  fourth dotted chunk (`"9.0.0.\u001b]0;…"`, schema-valid because only three
  chunks are checked) reached the terminal — now `_showkey`'d. Both in §22.
- **FIX (closeout review, V2, respin B → C): the third state is now
  structurally impossible, not merely un-enumerated.** A `min_runtime` chunk of
  5000 digits passed `_numeric_floor`, then `int()` raised `ValueError` (the
  3.11+ str→int digit limit) inside `compat_check`: exit 1, tracebacks, no
  banner, postcompact printing the wrong banner. Three review rounds each found
  one more exception class escaping (UnicodeEncodeError, RecursionError,
  ValueError); the invariant must not depend on that list being complete. So:
  `_numeric_floor` bounds a chunk to 9 digits and `_ver` cannot raise; and
  **every entry point is total** — `read_config` catches any exception from the
  reader or validator as CONFIG INVALID with a bounded, escape-rendered
  *internal error* reason; `guard_enabled`, `load_thresholds` (→ `ConfigInvalid`),
  the CLI `--compat` path and the statusline's embedded Python each have a
  last-resort `except Exception`; the gate and tooluse hooks catch a
  `ConfigInvalid` from the ladder read and shout instead of tracing. The
  INCOMPATIBLE `schema_version` message is bounded through `_showkey`. Proven by
  **injection**: a ninth mutant whose validator raises `RuntimeError` on every
  document must still render CONFIG INVALID through `--compat` (4), gate (0,
  loud), tooluse at 610k (0), statusline (banner) and postcompact, with no
  traceback and no raw ESC anywhere.
- **FIX (workstation gate): `quality-gate.sh` read `latest.json` in the platform
  codepage.** A bare `open()` on Windows is charmap, so one non-ASCII byte in a
  valid UTF-8 file reported "unreadable" and "not valid JSON" — a false RED. Both
  reads are now explicit `encoding="utf-8"` (template and hermipro-vps copies).
- **Suite:** the length-dependence mutant (M8) is removed with the rule it
  tested; the M6 mutant now restores the underscore *metadata namespace* and
  must reproduce `_sof_limit`, `_1M`, `_1rn` and `_parked` all passing on it;
  the neighbourhood sweep is kept only as a generator of non-canonical names,
  every one of which must be rejected; and §22 states the exact set as a
  property (every canonical name VALID, 25 hostile names INVALID at every
  level). Runtime suite 1154 → **1313** assertions.

- **FIX (M5, release blocker): an UNRECOGNISED key inside a policy-bearing
  object is now CONFIG INVALID, not a silent substitution.** 4.2.3 typed every
  *declared* field and left an *undeclared* one untouched — "unknown keys are
  still ignored" was written into that release on purpose. But a misspelled
  policy key reaches the **same destination** as a wrongly-typed one: the field
  the project meant to set is absent, so the hard-coded default takes its place,
  mixed per key with whatever the project spelled correctly. Reproduced on the
  4.2.3 runtime, every row with `--compat` exit **0** and no banner anywhere:
  - `"sof_limit": 200000` → the ladder actually used was soft **90000** +
    checkpoint 300000 + high 400000 — the exact mixed-ladder shape M4 closed,
    reached by a typo instead of a type error;
  - `"checkpont_limit"` → checkpoint **120000** + the project's 200000/400000;
  - `"higH_limit"` → high **150000** + the project's 200000/300000;
  - `"runway_limit": 800000` → runaway stayed at the default **600000**, a
    backstop nobody set;
  - `"runaway_enable": false` → runaway stayed **ENABLED** after the operator
    disabled it — the one key whose silent default re-arms a *blocking* backstop;
  - `"schema": 999` → read as a pre-J config, buying a free compatibility pass.
  `validate_config()` now also rejects a key it does not recognise, in the two
  objects that **define policy**: the document root and each `profiles.<name>`.
  The allowlist is derived from the fields the runtime actually reads, nothing
  invented — root: `schema_version`, `min_runtime`, `profiles`, `soft_limit`,
  `checkpoint_limit`, `high_limit`, `auto_compact_window`, `runaway_limit`,
  `state_stale_seconds`, `runaway_enabled`, and the v2/v3 aliases
  `handoff_limit`/`hard_limit`; a profile: the thresholds and flags only, since
  that is exactly what `load_thresholds()` applies from a profile. Handling is
  identical to M1/M4 CONFIG INVALID: `--compat` exits **4**, no ladder is
  returned (`load_thresholds` raises `ConfigInvalid`), the gate advises nothing,
  the RUNAWAY backstop is disabled, the statusline shows
  `⚠ CONTEXT GUARD CONFIG INVALID` and writes no state, PostCompact says CONFIG
  INVALID, and `verify-install.py` reports a clean `✗` with no traceback.
  **No name that would select or set Context Guard policy is silently ignored.**
- **FIX (second review round): three more routes to the same destination.** Both
  reviewers falsified the sentence above on the first fixed candidate, and all
  three are closed here rather than filed as residue.
  - **Metadata may not be CONFUSABLE with policy, not merely identical to it.**
    The shadow test was exact (`bare in allowed`), so one added underscore on top
    of an ordinary typo bought the whole defect back: `"_1M"` as a profile name
    ran the ENTIRE default ladder 90000/120000/150000 at `--compat` exit 0,
    `"_sof_limit"` reproduced the owner's own signature, and `"_runaway_enable"`
    left the BLOCKING backstop armed after the operator had written the disable.
    A near miss of a policy name is now rejected too. The cost is deliberate and
    stated: a documentation key may not be *named after* the field it documents
    (`_soft_limit_rationale` is rejected); prose belongs in `_comment`, which
    every shipped config already uses.
  - **An alias and its modern name are ONE setting.** `load_thresholds` folds
    `handoff_limit`/`hard_limit` in a single pass, so declaring both let whichever
    was written LAST win in silence: `{"checkpoint_limit":300000,
    "handoff_limit":111111}` ran 111111, and flipping the two lines flipped the
    answer. Declaring both is now CONFIG INVALID; an alias used **alone** stays
    the documented v2/v3 spelling.
  - **A duplicate JSON name is rejected at parse time.** `json.load` keeps only
    the last value for a repeated name and discards the earlier one before any
    validator can see it - `{"soft_limit":200000,...,"soft_limit":90000}` ran
    90000 at exit 0, the exact mixed ladder this release line exists to
    eliminate. Both spellings are correct, so no allowlist could catch it; an
    `object_pairs_hook` does.
  - **The banner is bounded in LENGTH, not only in count.** One 5000-character
    key produced a 5041-byte banner and a non-ASCII one about 30KB - printed on
    every prompt and every tool call and appended to `errors.log`. `_showkey` now
    truncates the rendered name (and still says how long it really was) and
    `_why` caps the joined string absolutely.
  - **Metadata inside `profiles` really is accepted now.** `_comment` as a string
    there was rejected by the shape check with a message naming the wrong
    problem; the docs claimed otherwise, and the code now matches the docs.
- **FIX (third review round): the confusability rule was length-dependent.**
  `difflib`'s ratio scales with the length of the name being matched, and the two
  profile buckets are 2 and 7 characters, so the SAME operator gesture split on
  string length: `_default_old` was rejected while `_1m_old` was accepted and ran
  the ENTIRE default ladder, and a transposed `_m1` did the same. Confusability is
  now decided on a normalised form by three tests — one name contains the other,
  the same characters in another order, or a near miss — so parking a bucket by
  renaming it is rejected on both buckets or on neither. None of the metadata
  names any shipped config or test fixture uses (`_comment`, `_note`, `_todo`,
  `_owner`, `_reviewed`, `_parked`, `_docs`) trips any of the three.
- **FIX (fourth review round): the third test was still a ratio, so it was still
  length-dependent.** Keeping `difflib` for the near-miss test kept the defect
  for the shape the round-three property loop happened not to enumerate. Its
  seven shapes were all containment or permutation; not one was a
  **substitution**, and a one-character substitution scores `0.5` on a
  2-character bucket against `0.86` on a 7-character one. Measured on that
  reader: **70 of the 178** strings one edit away from `"1m"` were accepted as
  metadata and ran the ENTIRE default ladder at `--compat` exit 0 — `_1n`
  (keyboard-adjacent), `_lm` (the 1/l homoglyph), `_om` — while **all 533**
  neighbours of `"default"` were rejected. The near-miss test is now an absolute
  edit **distance** of `max(1, len/4)`, which cannot split on length. The suite
  no longer enumerates shapes either: it sweeps the entire distance-1
  neighbourhood — substitution, insertion and deletion over `[a-z0-9_]` — of both
  bucket names and of every root policy field, **12708 names, 0 accepted**, and
  an eighth mutant restores the ratio and must reproduce the 70/0 split itself.
- **FIX (fourth review round): `min_runtime` had to *start with* a version, not
  merely contain a digit.** `_ver` keeps the digits of each dotted chunk and
  zeroes the rest, so `"latest-1"` parses to `(1, 0, 0)` — a floor no runtime can
  ever fail — while reading to a human as "one before latest". The round-three
  check tested for *a digit anywhere* and passed it. The first dotted chunk must
  now be a number, which is the test `_ver` actually applies. Every documented
  and shipped spelling is bare-numeric, so nothing on disk changes.
- **FIX (fourth review round, latent): `_norm` was defined twice.** The name
  folder added in the second round shadowed the **path** normaliser that
  `_state_dir()` — and therefore the W3 equivalence with `state-dir.sh` — depends
  on. It was harmless purely by accident of import order: `STATE_DIR` is computed
  before the redefinition is reached, and nothing called `_state_dir()` again. Any
  later caller or a reordering would have got a folded, unusable path and every
  hook would have failed open. Renamed to `_foldname`, and the suite now asserts
  the invariant directly (`_state_dir() == STATE_DIR` on a second call), which
  fails on the shadowed source.
- **FIX (third review round): a setting declared at the root AND inside a profile.**
  `load_thresholds` applies the root last, so the root wins and the profile value
  is never read. For the three LADDER keys that is the documented flat override —
  the shipped `_comment` says so and this suite has asserted it since 4.2.0 — and
  it stays valid. For every other setting there is no documented precedence at
  all, and one of them is not a hint: a profile's `runaway_enabled: false` under a
  root `true` left the BLOCKING backstop armed and blocked a real tool call at
  610k, after the operator had written the disable. An overlap on those keys is
  now CONFIG INVALID.
- **FIX (third review round): a `min_runtime` with no version number.** `_ver`
  folds a string with no digits to `(0, 0, 0)`, so `"next"` or `"latest"` declared
  a compatibility floor that could never fail — a policy the operator wrote and
  the runtime silently read as "none".
- **FIX (fifth review round, both reviewers independently): a homoglyph walked
  past the confusability rule.** `_foldname` dropped case and punctuation but not
  Unicode compatibility forms, so the fullwidth `_１ｍ` — visually identical to
  `_1m` in most terminals — folded to two characters differing from `1m` in both
  positions, scored distance 2, and ran the built-in default ladder
  90000/120000/150000 at `--compat` exit 0 with a healthy-looking statusline. The
  Cyrillic `_1м` was already caught at distance 1; that one spelling was caught
  and the other was not is the same split this release exists to remove.
  `_foldname` now NFKC-normalises first.
- **FIX (fifth review round): a config that was neither VALID nor CONFIG INVALID.**
  `"⁴".isdigit()` is `True` but `int("⁴")` raises, so `min_runtime: "⁴.2.0"` passed
  validation and then made `_ver` raise out of `compat_check` into the hooks —
  exit 1 with a raw traceback and **no statusline banner at all**, so the project
  rendered as if it had never opted in and the blocking backstop was silently
  disarmed. Fail-open survived; "loud" did not. `_ver` now reads ASCII digits only
  and can no longer raise.
- **FIX (fifth review round): `min_runtime` was still patched to the example.**
  Round three rejected `"next"`, round four required the FIRST chunk to be
  numeric — and left `"4.next"` and `"4.x"` resolving to `(4, 0, 0)` at exit 0, a
  floor weaker than the one written, while the code comment claimed the
  first-chunk test "matches what `_ver` does". It did not. Every chunk `_ver`
  reads must now be a plain number, and the suite asserts the property over all
  216 chunk spellings rather than the example. Stated cost: this also rejects a
  prerelease spelling like `"4.2.0-rc1"`; no shipped or documented config uses
  one, and the rejection is loud and fail-open.
- **FIX (fifth review round): the BLOCKING backstop could be revoked by an
  omission.** A `profiles` block naming only one bucket is a valid document (see
  below), and `runaway_limit`/`runaway_enabled` were accepted inside a profile —
  so `profiles.default.runaway_enabled = false` on a 1M window selected the
  *undeclared* `"1m"` bucket, fell back to the built-in default, and **re-armed
  the backstop the operator had just disabled: a real tool call blocked at 610k**,
  `--compat` 0, no banner. For the ladder tiers such an omission costs only a
  missed hint; for the one setting that can block, it does not. The backstop is
  documented at the root only, and that is now its only home, so no omission can
  revoke it. The diagnostic says where to declare it rather than offering a
  misleading `did you mean high_limit?`.
- **Known and accepted, not a defect:** a `profiles` block that declares only one
  of the two buckets leaves the other window size on the built-in defaults -
  measured, `profiles:{"default":{200000/300000/400000}}` runs 90000/120000/150000
  on a 1M window at exit 0. This is the documented meaning of a bucket (`"1m"`
  applies at 600000 and above, `"default"` below), and it is symmetric with the
  `1m`-only shape the suite has always treated as valid, so rejecting it would
  narrow a legitimate document. `"default"` is a bucket name, not a catch-all.
  **The fifth review round narrowed what this deferral covers.** It was defended
  as fail-open and merely surprising; that was true only of the ladder tiers,
  which are hints. Its fail-CLOSED twin was measured — the same omission applied
  to `runaway_enabled` re-armed a blocking backstop and stopped a real tool call —
  and that half is now fixed above, not deferred. What remains deferred is
  exactly what the sentence says: an undeclared bucket runs the built-in ladder,
  costing at most a hint at the wrong threshold.
- **FIX (found by review before this shipped): the profile NAME.** The allowlist
  typed the keys *inside* each `profiles.<name>` and never the name itself, while
  `load_thresholds()` asks for exactly two literal buckets — `"1m"` above a 600k
  window, `"default"` below — through `.get(bucket, {})`. A miss returns `{}`
  silently, so `profiles: {"1M": {…}}` — a **case** typo, on a Windows-first tool —
  substituted the **entire** default ladder: 90000/120000/150000 in place of the
  project's 200000/300000/400000, `--compat` exit 0. That is strictly *worse* than
  the misspelled key that triggered this release, which replaced one field and
  kept the other two. The accepted set is as derivable as the field allowlist —
  it is the two literals in the `bucket` expression — and an unrecognised profile
  name is now CONFIG INVALID.
- **FIX (found by review before this shipped): metadata may not shadow a policy
  field.** `"_soft_limit": 200000` was accepted as metadata and ignored, so the
  hard-coded default took the field's place — the same substitution, reached
  through the escape hatch. Worse, `"_runaway_enabled": false` left the
  **blocking** backstop armed: measured, a tool call at 610k still exited 2 after
  the operator had written the disable. Underscore-prefixing a name that *is* a
  policy field or profile is now rejected, and the diagnostic says so.
- **Forward compatibility: metadata keeps its own namespace.** A key whose name
  starts with `_` and is *not* a policy name is metadata — accepted at *every*
  level, never interpreted. That is the existing convention (`_comment`, which
  every shipped config carries), so documentation, future extension fields and a
  deliberately parked `_profile` stay valid without buying silence for a
  misspelled threshold. This is deliberately **not** a general "reject every
  unknown JSON key" policy and **not** a config language.
- **Diagnostics name the fix, not just the fault.** The reason travels with the
  state as before, and now suggests the field the key most likely was:
  `profiles.1m.sof_limit is not a Context Guard field (did you mean soft_limit?)`.
  The `difflib` cutoff is 0.6 rather than 0.7 so that `schema` →
  `schema_version` is caught, and an unmatched key is retried case-folded so
  `1M` → `1m` is suggested; a wrong guess costs nothing, since the key is
  rejected either way. Two further properties, because this message is the
  operator's only path out of a fail-open outage:
  - a name that is not plain printable ASCII is rendered as a **literal**.
    Otherwise `"soft_limit "` (trailing space), `"soft_limit́"` (combining
    mark) and `"sоft_limit"` (Cyrillic homoglyph) all *print* as the field
    they impersonate, and the message reads "soft_limit is not a Context Guard
    field (did you mean soft_limit?)" — a tautology nobody can act on. It also
    stops an ANSI escape embedded in a config key from reaching the operator's
    terminal raw.
  - the joined reason is **bounded** to the first 10 findings plus a count.
    Every hook prints it on every prompt and every tool call and appends it to
    `errors.log`; a config with 200 unknown keys previously produced ~7.8KB each
    time, now 405 bytes.
- **Schema stays 1, deliberately.** `schema_version` is compared for *equality*,
  so a bump would turn every existing project config INCOMPATIBLE until each one
  is migrated — for a change that migrates **no document**. Every config on this
  machine (template, `hermipro-vps`, `hivoice`) validates unchanged, and the
  suite asserts it. What narrows is not the documented format but the set of
  documents that were *silently mis-read*; as in 4.2.3, catching a misspelled key
  is validation, not a document-format change. `min_runtime: 4.2.0` (a floor)
  keeps accepting this runtime.
- **Tests.** `scripts/test-context-guard.sh` §21 adds 18 INVALID rows (each
  proving the same 13 properties as the §20 matrix: `--compat` 4, no `OK`, no
  ladder returned, gate silent at 250k, backstop disabled at 610k, statusline
  CONFIG INVALID with no ladder icon and no state file, PostCompact CONFIG
  INVALID and not INCOMPATIBLE), 3 VALID metadata rows, the three real on-disk
  configs, and 13 diagnostic assertions. `verify-install.py` gains 11
  compatibility-matrix rows (9 invalid, 2 metadata) and a §5d end-to-end pass on
  the `sof_limit` case and a second on the profile-name case. **Non-vacuity:** a
  fifth mutant restores the 4.2.3 reader — `_check_name`'s body neutered in
  place, which reverts all three routes at once while leaving M4's type
  validation intact — and must reproduce all **thirteen** measured defects,
  *and* still accept all seven VALID rows, proving the fix narrows typos and not
  valid documents. The M1 and M4 mutant anchors were repaired in the same pass:
  refactoring `read_config` broke both, the suite caught it as `0/2` and `0/8`
  rather than passing quietly, and that is the harness working as 4.2.3 intended.
- **Out of scope, unchanged (owner instruction):** Cygwin `/tmp` mapping,
  symlink/junction resolution, the wide `git ` RUNAWAY exemption, schema typo
  aliases, stale-runtime diagnostics, telemetry filtering, `verify-install`
  return codes, POSIX `_fold` coverage, the `1-claude-templates` git migration,
  credentials, Codex integration, and fan-out.

## Context Guard 4.2.3 — config validation (2026-08-28)
Runtime `4.2.3`, schema **`1` — unchanged**. Stricter validation of fields the
schema already declared is not a change to the accepted document format, so no
config migrates and `min_runtime: 4.2.0` (a floor) keeps accepting this runtime:
the `hermipro-vps` and `hivoice` configs are untouched by design. Scope is one
blocker (M4) plus the two cleanups adjacent to it. Nothing else was pulled in.

- **FIX (M4, release blocker): a declared field with the wrong TYPE is now
  CONFIG INVALID, not a silent substitution.** 4.2.2 closed only the half of the
  class where `json.load()` itself failed. A config that *parsed* but declared a
  field with the wrong type still slipped through, because the only type check
  lived in the consumer: `load_thresholds` tested `isinstance(v, int)` and
  silently **dropped** anything else, letting the hard-coded default take that
  key's place — mixed, per key, with whatever the project got right. Reproduced
  on the 4.2.2 runtime, all with `--compat` exit **0** and no banner anywhere:
  - `"soft_limit": "200000"` (also `200000.0`, `null`, `[…]`, `{…}`) → the ladder
    actually used was soft **90000** + checkpoint 300000 + high 400000: an
    incoherent mix of the project's policy and the default one;
  - `"soft_limit": true` → JSON `true` **is** a Python `int`, so the threshold
    became `1`; bash then failed `[ "$USED" -ge True ]` and the **guard segment
    vanished from the statusline entirely**;
  - `"profiles": "1m"` / `"profiles": []` → ignored whole, so a 1M-window session
    ran the full 90k/120k/150k default ladder;
  - `"profiles": {"1m": [1,2]}` → `AttributeError`, the PreToolUse hook died with
    exit 1.
  The type check moved out of the consumer into `validate_config()`, which runs
  once at load. Threshold fields are integers only (`bool` explicitly excluded,
  `>= 0` as before), `runaway_enabled` is a boolean, `profiles` is an object,
  every profile entry is an object, `schema_version` is an integer and
  `min_runtime` a string. A violation makes the whole document CONFIG INVALID —
  identical handling to a syntax error: `--compat` exits **4**, no ladder is
  returned (`load_thresholds` raises `ConfigInvalid`), the gate advises nothing,
  the RUNAWAY backstop is disabled, the statusline shows
  `⚠ CONTEXT GUARD CONFIG INVALID` and writes no state, and `verify-install.py`
  reports a clean `✗`. Unknown keys are still ignored exactly as before — this
  closes the silent-substitution class, it does not add an unknown-key policy.
  *(Superseded by 4.2.4: an unrecognised key in a policy-bearing object is now
  CONFIG INVALID too — that exemption was the last route into the same class.)*
- **FIX (LOW, adjacent): `context-guard-postcompact.sh` no longer blames the
  runtime for a broken project config.** It branched on "`--compat` non-zero" and
  printed `CONTEXT GUARD INCOMPATIBLE` for every cause, telling the operator to
  upgrade a runtime that was fine. It now reads the exit code: **4** →
  `CONTEXT GUARD CONFIG INVALID` naming the config, **3** → `INCOMPATIBLE`. Every
  entry point (CLI, gate, PreToolUse, statusline, PostCompact, verify-install)
  now distinguishes OK / CONFIG INVALID / RUNTIME-SCHEMA INCOMPATIBLE / not
  opted in.
- **FIX (LOW, adjacent): a UTF-8 BOM no longer invalidates a valid config.** This
  is a Windows-first tool and Notepad/PowerShell write a BOM by default, which
  `json.load()` rejects as a syntax error — so a *correct* config reported itself
  CONFIG INVALID. `read_config` reads with `utf-8-sig`, which strips a leading
  BOM and is byte-identical to `utf-8` otherwise: plain UTF-8 stays valid, BOM +
  valid JSON is valid, BOM + malformed JSON stays invalid. Not general encoding
  autodetection.
- **Diagnostics.** The reason travels with the state, so every surface names the
  offending field: `profiles.1m.soft_limit is string, integers only`.
- **Tests.** `scripts/test-context-guard.sh` §20 is a table-driven matrix — 6
  VALID rows (canonical, flat legacy aliases, pre-J, UTF-8, and two BOM rows) and
  24 INVALID rows, each proving all of: `--compat` 4, no `OK`, no ladder
  returned, gate silent at 250k (where a substituted default ladder *would* fire
  a final-handoff tier), backstop disabled at 610k, statusline CONFIG INVALID
  with no ladder icon and no state file, PostCompact CONFIG INVALID and not
  INCOMPATIBLE. Plus per-path `verify-install` runs, and a non-vacuity mutant
  that restores the 4.2.2 reader in place and must reproduce all 8 measured
  defects. The M1 and M4 mutants both mutate **in place**: `cg_common`'s
  `__main__` block runs before a trailing definition is reached, so an appended
  override leaves `--compat` un-mutated and the mutant scores itself passing —
  which is exactly how the M1 mutant silently went vacuous during this release.

## Context Guard 4.2.2 — bounded hardening (2026-08-28)
Runtime `4.2.2`, schema `1` (unchanged — no config migration; `min_runtime: 4.2.0`
is a floor and accepts 4.2.2, so the `hermipro-vps` and `hivoice` configs are
untouched by design). Scope is exactly three items — M1 correctness, M3 path
classification, M2 acceptance harness — all three raised by the independent
reviewer against 4.2.1. No unrelated backlog was pulled in.

- **FIX (M1, release blocker): a config that exists but cannot be parsed is no
  longer treated as a legacy config.** 4.2.1's `load_config` caught the parse
  failure and returned `{}` — and `{}` is exactly what a pre-J config looks like,
  so the project stayed enabled, `compat_check` passed, `cg_common.py --compat`
  exited **0**, and `load_thresholds` silently handed back the **default** ladder.
  Reproduced on the 4.2.1 runtime with a truncated `config.json`: on a 1M window
  the FINAL HANDOFF tier fired at **250k** (default `high_limit` 150000) against
  the 400000 the project's own profile declares, and the statusline showed 🔴
  where it should have shown 🟡. A project could therefore run its whole life on
  a policy nobody wrote, while every health path said OK.
  `load_config` now returns three distinct states — absent `({}, "")`, valid
  `(dict, path)`, unparseable `(None, path)` — and a non-object document (array,
  string, number) counts as unparseable too. On CONFIG INVALID:
  - guard automation is disabled and **fails open**: `PreToolUse` never blocks,
    the RUNAWAY backstop is off, the gate advises nothing;
  - `load_thresholds` raises `ConfigInvalid` instead of substituting defaults —
    there is no code path left that guesses a ladder;
  - the statusline shows a loud `⚠ CONTEXT GUARD CONFIG INVALID` and writes no
    state, so every hook stays fail-open rather than pretending to be armed;
  - `cg_common.py --compat` exits **4**, a dedicated code distinct from 3
    (schema/runtime incompatibility);
  - `verify-install.py` reports a clean `✗ project config.json parses as JSON`
    finding. 4.2.1 read that file bare and died with a `JSONDecodeError`
    traceback instead of reporting the one thing it exists to report.
  The principle this preserves: **Context Guard may disable itself when it is
  broken; it may not silently operate under the wrong project policy.**
  Covered by suite section 18 (missing / legacy / canonical / malformed /
  truncated / non-object array / non-object string), proven non-vacuous by a
  mutant that restores the `except -> {}` behaviour and reverts both assertions
  (`--compat` back to 0, `high_limit` back to 150000).

- **FIX (M3): the RUNAWAY exemption is now classified, not substring-matched.**
  The backstop lets two directories through at any context size because its own
  message orders the agent to write them. 4.2.1 decided that with an unanchored
  `".claude/handoffs/" in path`. Reproduced against 4.2.1, six defects at once —
  three false negatives that block work the guard demands, three false positives
  that exempt paths outside the guarded directories:
  - `.Claude/Handoffs/current.md` (the case variant Windows opens as the same
    directory) — **blocked**;
  - a relative `.agent/state/current.md`, forward or backslash — **blocked**;
  - `C:/elsewhere/.claude/handoffs/x.md`, outside the project — **exempt**;
  - `<proj>/.claude/handoffs/../../../evil.py`, walking back out — **exempt**;
  - `<proj>/vendor/.claude/handoffs/x.py` and `<proj>/src/.agent/state/x.py`,
    nested lookalikes — **exempt**.
  Replaced by `cg.exempt_dir()`, a bounded lexical classifier: separators are
  equivalent, comparison is case-folded per platform (`os.path.normcase`, so it
  is case-insensitive exactly where the filesystem is), `..` is resolved
  lexically, relative paths resolve against the project root, and the result must
  land **inside** `<project>/.claude/handoffs/` or `<project>/.agent/state/` —
  both exemptions using identical anchoring. `_drive_align` additionally
  reconciles the cygwin `/d/proj` spelling with a drive-lettered `D:/proj` root,
  and fires only when the root is drive-lettered, so it is inert on POSIX.
  Deliberately **not** a filesystem security layer: no `stat()`, no `realpath`,
  no symlink resolution. It answers one question — does this path land inside one
  of this project's two exempt directories. A cygwin *mount* path (`/tmp/...`)
  against a drive-lettered root resolves to "outside", i.e. blocked, which is the
  safe direction. The **tool sets are unchanged** from 4.2.1 (Write/Edit/Read for
  handoffs, Write/Edit for `.agent/state`): this release fixes which paths
  qualify, not which tools may touch them. Covered by suite section 19 (18 path
  shapes plus the handoff-telemetry round-trip) and proven non-vacuous by a
  mutant that restores the substring test and reproduces all 6 defects. Section
  16's W5 mutant was retargeted onto the new classifier and still fails 2/2.

- **FIX (M2): the acceptance harness no longer false-fails.** `cg-acceptance.sh`
  Stage B grepped `claude -p --debug` for hook filenames, which Claude Code
  2.1.247 no longer emits — so the shipped Stage B returned **RED on a correct
  install**: three assertions false-failed and the fourth ("no INCOMPATIBLE
  banner") passed vacuously on an empty log. A debug-log format is not a
  contract. Stage B is now effect-based: it seeds observable state for a fixed
  `--session-id` in an isolated state dir, runs a real session, and reads the
  effects back out of the telemetry the hooks themselves wrote — the gate's tier
  counter (UserPromptSubmit), the block counter (PreToolUse), and the flushed
  session record's very existence (SessionEnd), with the seeded `model` and
  `context_window` round-tripping as a discriminator that the record is ours. A
  second probe seeded between this project's `soft` and `checkpoint` but above
  the default ladder's `high` turns the M1 failure into an assertion: a session
  running the wrong ladder fires a tier counter that a correct one does not.
  SessionStart/restore, PostCompact and the statusline stay in the **manual**
  checklist rather than being faked — print mode never runs the statusline, and
  the other two need a real compaction. Stage B tags the two records it leaves in
  `telemetry.jsonl` with `"acceptance":"cg-stage-b"`.

Not in scope, deliberately deferred: general unknown-key policy, migrating the
template source into git, telemetry redesign, Context Cost Governor.

## Context Guard 4.2.1 — release reconciliation (2026-08-27)
Runtime `4.2.1`, schema `1` (unchanged — no config migration; `min_runtime: 4.2.0`
is a floor and accepts 4.2.1, so existing project configs are untouched by design).
Two release blockers found by independent review, both fixed here.

- **FIX (W5): Windows handoff-path normalization.** 4.2.0 normalized the
  `.agent/state/` check and not the two `.claude/handoffs/` checks, so on Windows —
  where the hook receives `D:\proj\.claude\handoffs\current.md` — neither matched.
  Measured on the 4.2.0 runtime: a backslash handoff Write at 610k exited **2
  (blocked)** with `last_handoff_used` absent, against exit 0 / 610000 for the same
  path with forward slashes. So the RUNAWAY backstop blocked the very handoff write
  its own message orders the agent to perform — a Windows deadlock, not merely a
  telemetry gap. Fixed by normalizing `file_path` **once**, at the top of the hook,
  and comparing the normalized form everywhere below. Covered by suite section 16
  (forward slash / backslash / read / `.agent/state` / negative control) and proven
  non-vacuous by a mutant that strips the normalization out and fails 2/2.
- **FIX: the release contradicted its own architecture.** The installer said "one
  runtime, not N copies" while the same release's template payload shipped a full
  executable runtime under `.claude/context-guard/` and registered project-local
  Context Guard hooks and a statusLine. A project stood up from it therefore OWNED a
  runtime — and `project_enabled()` stands the shared runtime down when it sees one,
  so Context Guard would have been **silently INACTIVE** in every project onboarded
  that way. Reconciled:
  - the runtime moved to `context-guard/` — RELEASE SOURCE, not project payload, and
    deliberately outside `.claude/`, where a copy triggers stand-down;
  - `.claude/context-guard/` now holds `config.json` and nothing else — the whole
    project payload, and the only Context Guard file a project ever owns;
  - `.claude/settings.json` no longer registers any Context Guard hook or statusLine;
    the canonical user-level wiring is the only source of execution;
  - `scripts/build-release.py` builds **two** artifacts from the one tree — the
    project template (no runtime, no CG wiring) and `context-guard-<version>.zip`
    (runtime + installer + suites) — and refuses to ship a template that carries
    release files.
- **NEW: legacy vendored-runtime detection.** `install-context-guard.py` fails
  **before writing anything** when a project carries its own runtime, naming the
  files and the `git rm` that fixes it, instead of producing a silently INACTIVE
  install; `--migrate-vendored` backs the files up and removes them (never touching
  git). `verify-install.py` gained section 3b: 0 project-local runtime files,
  `.claude/context-guard/` holds `config.json` only, 0 project-local CG hook
  registrations, 0 project-local CG statusLine, shared runtime not INACTIVE.
- **NEW: `scripts/test-onboarding.sh`** — the release-process regression test. It
  builds both artifacts, stands a scratch git project up from the template artifact,
  onboards it through the installer, and asserts the **onboarded result** (not source
  strings): 0 runtime files, 0 CG hooks, 0 CG statusLine, shared runtime OK,
  `verify-install` GREEN, then re-runs the installer for idempotence. A re-vendoring
  mutant trips all five assertions, so the test cannot pass vacuously. Wired into
  `cg-acceptance.sh` as Stage A2.

## v8.2.0 (Context Guard v4)
Theme: the context window, the shared usage quota, and disk state each get ONE
owner. Built from a real project's telemetry (a 5-min /loop in a ~772k session
burned 54.8M tokens), external review, and current Claude Code docs.

- **NEW: Context Guard v4** (`.claude/context-guard/`) — window-aware, advisory,
  non-blocking context ladder. 1M profile: 200k "work compactly" -> 300k
  agent-written task handoff (`.claude/handoffs/current.md`, `handoff` skill) ->
  400k final handoff refresh -> ~450k auto-compaction
  (`CLAUDE_CODE_AUTO_COMPACT_WINDOW=450000` in settings env) -> automatic resume
  with the handoff injected. 200k-model profile stays 90/120/150. NOTHING in the
  ladder blocks; the only block is a RUNAWAY backstop (PreToolUse, ~600k,
  `runaway_enabled` flag) for the one case where auto-compaction physically
  failed — observed in the wild as the 772k session. Thresholds are a starting
  operating point, NOT correctness bounds; telemetry decides the final numbers.
- **NEW: telemetry + analyzer** — hooks auto-record peak context, compactions
  (auto/manual via PostCompact trigger), pre/post-compact context, handoff age
  at compaction, runaway blocks; `/session-log` records outcome judgments
  (rework-after-compact, human-noticed drift; verifier auto-derived from
  `_reports/runs/latest.json` when present). `analyze-telemetry.py` reports
  success/rework/drift by peak-context band (<200/200-300/300-400/400-450/>450k).
  Revisit thresholds only after ~10-20 long tasks.
- **NEW: `/continue-work` discipline** — after auto-compaction the task resumes
  automatically; after `/clear` (or on startup) an ACTIVE handoff is only
  ANNOUNCED and resumes solely via explicit `/continue-work` (a `/clear` may mean
  "different task"); on `resume` a one-line announce only. Restore skill logic
  lives in `handoff` Mode 2; `.claude/skills/handoff` deliberately avoids the
  word "checkpoint" in its triggers — `checkpoint` remains the git-restore-point
  skill, and the two must not route into each other.
- **NEW: loops & watchers policy** (`.claude/rules/loops-and-watchers.md` +
  `scripts/watch-transition.sh`) — /loop and cron tasks are session-scoped and
  re-pay the whole context every fire; completion-waiting NEVER goes into a
  polling loop. Tiering: Monitor for in-session live streams, Channels for
  push events, the transition watcher for cross-session external state (wakes a
  fresh bounded `claude -p` ONLY on RUNNING->SUCCESS/FAILED/ATTENTION, never on
  progress; idempotent, cooldown, daily wake budget, max-quiet timeout, and no
  `acceptEdits` unattended — RISK MATRIX applies to machines too).
- **Single-owner compact inject** — `state-freshness.sh` no longer dumps the
  disk snapshot when a fresh ACTIVE Context Guard handoff exists (the CG
  SessionStart hook owns that injection); the full dump remains the FALLBACK for
  sessions that blew up before a handoff was written. `precompact-snapshot.sh`
  now embeds a copy of the CG handoff so Codex/cross-agent resume sees it
  (AGENTS.md pt 8 updated).
- **Memory map updated** — memory-router gains the "in-flight task state" row
  (`.claude/handoffs/current.md`, ephemeral, gitignored — never the only home of
  anything durable); CLAUDE.md MEMORY (non-CORE) now names Context Guard as the
  compaction path with the snapshot as fallback; `.claude/handoffs/` gitignored.
- **Verification** — `scripts/test-context-guard.sh` (profile selection,
  advisory one-shots, runaway block + whitelist, restore branches, postcompact
  trigger, flush, analyzer, env-vs-config window consistency, broken payloads).
  `test-hooks.sh` unchanged and still owns the template hooks. CORE untouched —
  no re-baseline needed.
- **Review pass (pre-release)** — fresh-eyes audit of the built package with
  both suites executed GREEN and the setup file verified byte-identical to the
  template. Fix 1: flat-key override order in `load_thresholds` (cg_common +
  the statusline resolver) — top-level flat keys now override profile values,
  as the config contract documents (regression: test 1b, hooks + statusline
  paths). Fix 2: UPGRADE.md step 5 now runs `test-context-guard.sh` alongside
  `test-hooks.sh`, so a future template upgrade can't silently break the guard.
  `runaway_enabled` stays `true` deliberately: the backstop sits ABOVE
  auto-compaction and fires only when the env physically failed to apply.

## v8.1.9-p1-lean-final (FREEZE)
Theme: 3 fixes + 3 cleanups from external review, then freeze. No new rules,
agents, or safety layers — the next iteration input is a REAL project, not
another review round.

- **FIX 1 — Codex hooks schema** — `.codex/hooks.json` now uses the top-level
  `hooks` wrapper required by the current Codex schema, and registers native
  `PreCompact` → `precompact-snapshot.sh` (mirrors `.claude/settings.json`).
  The comment now states the honest limits instead of hedging: project-local
  hooks load only for TRUSTED projects and each hook is trusted per-hash (new/
  changed → skipped until reviewed); some builds need `[features] codex_hooks =
  true`; several Codex versions fire Pre/PostToolUse for **Bash only**, so
  Write|Edit matchers may never run there. Consequence made explicit: Codex
  hooks are best-effort guardrails — the guaranteed, agent-agnostic enforcement
  is the git `pre-commit` hook.
- **FIX 2 — AGENTS.md de-contradicted** — removed "No SessionStart hook here"
  (one IS registered in `.codex/hooks.json`) and "No compaction event on Codex"
  (false: Codex fires `PreCompact` and `SessionStart source="compact"`). The
  native chain PreCompact → snapshot → compaction → SessionStart → freshness is
  now the primary path; manual `precompact-snapshot.sh` demoted to a fallback
  for untrusted/non-firing hooks. Pt 5 documents the new gate flow (commit
  first, latest.json after).
- **FIX 3 — Quality Gate dirty-tree loophole closed** — reproduced scenario:
  verified code + GREEN report + latest.json bound to HEAD, THEN an unstaged
  edit → gate still went GREEN, because dirty tree was only a note. Now a dirty
  working tree **BLOCKS** the gate; sole exemption `_reports/runs/latest.json`.
  That file is now **gitignored** by design: it is written AFTER the commit it
  points to (`head_sha` = that commit), so it can never be tracked + committed +
  current at once (self-referential cycle). `_reports/runs/*.md` stay tracked
  as the human-readable proof. Canonical flow: BUILD → VERIFY → write report →
  commit code+report → write latest.json(head_sha=HEAD) → gate (tree clean
  except latest.json) → GREEN. `test-hooks.sh` gains adversarial case 7d: valid
  proof + post-verification edit must BLOCK; 7b rewritten to the canonical flow.
- **CLEAN — packaging** — single top-level directory (was a triple-nested
  matryoshka), duplicate UPGRADE.md copy and empty marker file dropped.
- **CLEAN — version names** — README_UA.md, CHANGELOG and archive all say
  `v8.1.9-p1-lean-final` (was `-draft` vs `-p1-lean` mismatch).
- **CLEAN — no shipped `.env`** — removed from the archive (it was a 1:1 copy of
  `.env.example`, no secrets); `setup.sh` already creates `.env` from the
  example. A repo template should not normalize ".env exists in the archive".

## v8.1.9-p1-lean
Theme: one owner per question. Model thinks, starter sets bounds, scripts prove
facts. (All 9 decisions human-approved individually; CORE re-baselined once.)

- **NEW: RISK MATRIX & AUTOMODE [CORE]** — the single owner of "how much process /
  who approves / how many agents": LOW / NORMAL / HIGH / DESTRUCTIVE, row picked by
  the highest touched risk. Session toggle "automode on/off" shifts NORMAL→LOW;
  the DESTRUCTIVE row never shifts. Replaces FOUR conflicting policies: AUTONOMY
  A/B/C, EXECUTION LANES (skill deleted), the GOLDEN RULE, and the plan-everything
  reflex. Onboarding now asks "default automode" instead of A/B/C.
- **Disagreement is signal, not noise** — "agents must agree" deleted. Reviewers
  never reconcile verdicts; `verifier` is the human's FILTER: rework loop first,
  and only a surviving material disagreement escalates — as a structured table
  (orchestration skill), never raw verdicts. Automode never applies to escalations.
- **Agents per matrix row** — verifier-reflex removed from CORE; LOW: no agents;
  NORMAL: verifier + specialist only for a touched risk; HIGH: reviewer per risk;
  best-of-N planning demoted to a DESTRUCTIVE/ambiguous-spec escalation.
- **Verification-first replaces blanket TDD** — pipeline Phase 3 now carries a
  proof table (work type → canonical proof, defined BEFORE building); TDD where
  the test has durable value.
- **Codex parity, hard layer** — NEW `.codex/hooks.json` registers the SAME policy
  scripts (Codex project-local hooks share Claude Code's event names + stdin JSON);
  AGENTS.md de-falsified ("hooks are Claude-Code-specific" removed, native
  subagents acknowledged). Shared skill discovery → v8.2 backlog (symlinks are
  Windows-hostile; needs a real design).
- **Checkpoint hard rule** — stage ONLY this task's files; `git add -A` only on a
  pre-clean tree; unrelated dirty files are listed, never staged, never stashed.
- **project-map tells the truth** — Active team (from CLAUDE.md) vs available
  catalog vs archive; "Default automode" parsed from its real home; empty team →
  "⚑ КОМАНДА НЕ СФОРМОВАНА — прожени FIRST RUN" instead of showing the catalog as
  the team. New rule in the script: unparsable field → "не заповнено", never guess.
- **/init guidance future-proofed** — reworded from capability claims ("/init skips
  onboarding") to ownership facts: this CLAUDE.md exists, CORE is hash-protected,
  FIRST RUN is canonical; idempotent if /init already ran.
- **CLAUDE.md 227 → 198 lines** (hard cap stays 250): AUTONOMY + LANES + GOLDEN
  RULE collapsed into the matrix, MEMORY compressed to pointers, F6 emphasis trim.
  MY RULES stay in the committed file on purpose — CLAUDE.local.md is gitignored
  and would silently drop the human's rules on every VPS workspace clone.
- **Audit loop closed** — model-audit.md now logs the RESOLUTION of the 2026-07-28
  findings (F1-F4, F6, F7 applied; F5 open) + new rule: YELLOW/RED audits must end
  in an apply/veto decision, never only a doc.

## v8.1.9-p0-hardening
Theme: the controls themselves were breakable — adversarial review found 4 P0s,
all reproduced experimentally, all fixed, all now covered by tests (37 total).

- **FIX (critical): GREEN-on-RED gate.** `quality-gate.sh` checked that the WORD
  "Verdict" and a latest.json FILE existed — a `Verdict: RED` report plus an empty
  `{}` passed GREEN. Now the gate parses the verdict VALUE (report + json must both
  be GREEN), validates latest.json schema (run_id, timestamp, report path exists),
  and binds proof to the commit: `head_sha` must match current HEAD (stale proof →
  BLOCKED). Non-trivial runs with NO lint/test/build detected are BLOCKED unless
  `QG_ALLOW_NO_CHECKS=1` (genuinely non-code projects). Template updated with `report`.
- **FIX (critical): fail-open hooks.** The archive ships without the Unix execute
  bit; `./scripts/guard.sh` in settings.json meant every safety hook silently
  no-op'd until `setup.sh`. Hooks are now invoked as
  `bash "${CLAUDE_PROJECT_DIR}/scripts/…"` — the execute bit is no longer a
  security prerequisite (setup.sh stays for pre-commit install + UX).
- **FIX (critical): PreCompact was async.** An async snapshot can race the
  compaction it exists to survive. Now synchronous.
- **FIX (critical): secret guard missed modern credential families.**
  `sk-proj-`, `sk-ant-`, `ghp_/gho_/ghu_/ghs_/ghr_`, `github_pat_`, `xox[baprs]-`,
  `glpat-`, `AIza`, any PEM block — all previously rc=0. Patterns now live in ONE
  place (`scripts/secret-patterns.sh`), sourced by guard.sh, pre-commit, and the
  gate, with a fail-safe inline fallback. Honest reframe: this is a guardrail
  layer, not a security wall — pair with a real scanner in CI.
- **NEW: adversarial tests** in `test-hooks.sh` (28 → 37): every modern secret
  family, prose false-positive check, GREEN-on-RED replay, stale-HEAD proof,
  legitimate-GREEN pass.
- Onboarding: FIRST RUN now asks "is this project on our VPS?" → read
  `D:\claude\core-vps\CLAUDE.md` + `PROJECT_TEMPLATE.md`, create `<short-name>-vps`
  workspace from the template, append to `REGISTRY.md`; new PROJECT field
  "VPS workspace". README version header fixed (said v8.1.8).
- CORE hash unchanged (all fixes are scripts/settings — outside the kernel).
- Known P1 debt (deliberate, needs owner decisions — see review notes): one
  autonomy/risk matrix (F3), drop "agents must agree" (F4), lane-conditional
  reviewer counts (F1/F2), verification-first instead of blanket TDD, real Codex
  parity via `.codex/hooks.json` + shared scripts, checkpoint `git add -A` scope,
  project-map active-team vs available-roles, /init guidance refresh, CLAUDE.md
  toward ~150 lines with personal prefs in CLAUDE.local.md.

## v8.1.9-draft
Theme: the config itself decays — audit it on a clock, not on a hope.
(Prompted by the "you updated the model, not the files it reads" revision
checklist + the Opus 5 / GPT-5.2 vendor prompting guides.)

- **NEW: `devops` skill** (`.claude/skills/devops/`). Config-as-infrastructure
  maintenance loop: live lineup check → instruction triage against the CURRENT
  vendor guides (never from memory) → human veto → survival test → record.
  Plus harness health (`test-hooks.sh`, gate smoke, never-fired-skill pruning)
  and a pointer to the archived infra roles for LIVE ops (kept separate).
- **NEW: audit cadence, enforced deterministically.** `state-freshness.sh` §3
  reads `Last audited:` / `Cadence days:` (default 35) from
  `.agent/state/model-audit.md` (new) and prints ⚑ ATTENTION at SessionStart
  when stale or missing. Zero network in the hook; the audit itself is the skill.
- **NEW: `/devops-audit`** command; AGENTS.md tells Codex to check the audit age
  manually (no SessionStart there); 2-line pointer in CLAUDE.md MEMORY (non-CORE,
  v8.1.7 pattern — file now 222 lines, soft-note range, cuts proposed below).
- **Audit findings vs Opus 5 / GPT-5.2** (proposed, NOT applied):
  `docs/model-audit-recommendations_2026-07-28_1500_v1.md` — F1 verifier-reflex →
  lane-conditional [CORE], F2 conditional subagent offloading [CORE], F3 GOLDEN
  RULE vs CORE#2/no-confirmation contradiction, F4 add verbosity+scope lines /
  cut the "agents agree" filler, F5 opus/sonnet cost table superseded by the
  effort knob + reviewer-count lever, F6 emphasis-density trim, F7 line budget.
- **NEW: `UPGRADE.md`** (root). One-page migration procedure for EXISTING
  projects: checkpoint → FROM→TO via changelogs (intent, not just diffs) →
  three file buckets (replace / 3-way-merge with veto / never-touch) →
  CLAUDE.md+settings merged never replaced (CORE = rationale + re-baseline) →
  devops audit as the adapt step → verify, record in decisions.md, clean temp/.
  Major gap (v7 and older) or missing v8 markers → section T: transplant path —
  new skeleton stands up clean, project KNOWLEDGE pours in via memory-router,
  every transplanted rule passes the devops audit before entering the kernel,
  inventory report guarantees nothing is dropped silently. Old projects
  without this file: paste its content as a message — same effect.
- CORE hash unchanged; F1/F2 require Kernel Change Rationale + re-baseline.

## v8.1.8
Theme: see the project like a child would, pick models like an adult would,
and take from SDD only what we lacked.

- **NEW: project map** — `scripts/project-map.py` (stdlib-only) + `/map` command.
  Writes `docs/project-map.html` + `docs/project-map.txt`: rooms = top-level
  folders (tagline from each folder's on-demand CLAUDE.md), ▶ = active board
  tasks matched to rooms, chips = agent roster, service row (tasks/.agent/
  _reports/scripts/docs/specs). Honest by design: big timestamp + "snapshot of
  recorded state, not live telemetry"; stale board → stale map, the /map command
  says so and suggests a board cleanup.
- **NEW: `.claude/rules/model-selection.md`** (always-on). The model lineup decays
  like any external state: check it live first, then ASK the human in the standard
  decision format; record role→model in `decisions.md` with a date. Match the model
  to the PHASE: strongest for brainstorm/spec/plan/review, cheaper in a fresh
  context for executing an approved task list (pairs with context-hygiene).
- **SDD adoptions in `scope-and-spec`** (from the Spec Kit review; the routing idea
  itself — "decide fix vs spec vs brainstorm first" — was already our
  scope-and-spec + execution-lanes, so no new mechanism): (1) interview-before-spec
  for feature+ or vague requests — 3–7 design-changing questions first;
  (2) canonical home for full-lane specs: `specs/NNN-slug/spec.md` (+plan/tasks
  beside it) as browsable feature history; timestamped names stay for drafts.
  Spec Kit itself is NOT bundled — two frameworks would duplicate ceremony.
- `CLAUDE.md` untouched (at the 220-line soft limit; rules and commands auto-load).
  CORE hash unchanged, harness still GREEN.

## v8.1.7
Theme: repeated procedures should become skills — but noticing is a duty and
creation is a proposal, never a silent self-modification.

- **NEW: `.claude/rules/skill-extraction.md`** (always-on rule; auto-loaded).
  Rule of three: doing the same multi-step procedure for the ~3rd time → the agent
  must STOP and PROPOSE extracting it into `.claude/skills/<name>/` (name +
  one-line trigger + steps). Human approves; the HOW then lives in the existing
  `skill-authoring` skill — deliberately not duplicated here. Includes the
  boundaries (fact → memory, must-hold-100% → hook, one-off → context) and a prune
  clause: a skill that never fires is a deletion candidate (skills cost tokens on
  every load). Explicitly NOT auto-creation: a self-authored skill is self-modifying
  configuration, which contradicts the template's integrity model (CORE hash,
  evidence-gated done, graded autonomy).
- One-line pointer in `CLAUDE.md` MEMORY (non-CORE; file now 220 lines, still under
  the 220-soft/250-hard limits). CORE untouched — hash unchanged, no re-baseline.

## v8.1.6
Theme: make the "works out of the box" guarantee verifiable, and make context-loss
on auto-compaction a deterministic save instead of a hope.

- **NEW: hook test harness** (`scripts/test-hooks.sh`, run `bash scripts/test-hooks.sh`).
  Hermetic — builds a throwaway `mktemp` sandbox and exercises each hook's LOGIC there,
  so it never touches your real `CLAUDE.md` / `.claude/core.sha` / git repo. Covers:
  every script present AND executable (direct guard against the v8.1.3 exec-bit defect);
  `guard.sh` (blocks secrets + `rm -rf`, allows benign writes, and crucially does NOT
  false-block a doc that merely mentions `rm -rf` — the old over-broad-guard bug);
  `check-claude-md-size.sh` (>250 → exit 2); `check-core.sh` + `core-baseline.sh`
  (tampered CORE → STOP, non-CORE edits don't trip it); `precompact-snapshot.sh`;
  `state-freshness.sh` resume-surfacing; `pre-commit` (.env/secret block, clean commit
  passes); `quality-gate.sh` smoke. Wired into `setup.sh` as a verify step.
- **NEW: PreCompact handoff (deterministic context save).** `scripts/precompact-snapshot.sh`
  is wired to `PreCompact` (matcher `auto`, `async`) and persists a working-state handoff
  to `.agent/state/handoff.md` just before an auto-compaction. `state-freshness.sh`
  (SessionStart) resurfaces it when `source=compact|resume`. This pairing is required
  because Claude Code's PreCompact stdout is NOT injected post-compaction, whereas
  SessionStart stdout IS — so the snapshot goes to disk on the way down and is re-read
  on the way back up. `auto` only: a manual `/compact` is intentional and is already
  covered by `context-hygiene` ("route durable state to memory first").
  **Honest limit, stated in the script:** a shell hook can only snapshot what's on disk
  plus the transcript path; it cannot capture the in-context design↔code synthesis — so
  this is a safety net that complements `context-hygiene`, not a replacement.
- **Codex parity** (`AGENTS.md`): no compaction event on Codex → snapshot working state
  manually before summarizing/restarting; verify hooks with `bash scripts/test-hooks.sh`.
- **Docs:** non-CORE pointer in `CLAUDE.md` → MEMORY, `.agent/state/handoff.md` added to
  the `context-index` map and gitignored (machine-local, rewritten each compaction).

Note: the CORE block in CLAUDE.md is byte-identical to v8.1.3 — every v8.1.6 addition is
non-CORE machinery, so the CORE hash (`.claude/core.sha`) is unchanged.

## v8.1.5
- **NEW: context-hygiene rule** (`.claude/rules/context-hygiene.md`, always-on, no
  `paths:` frontmatter → loads every session and survives `/compact`). Codifies when
  to `/clear` vs keep context warm: clear on topic change / phase boundary, keep warm
  within one coherent task (don't destroy the in-context design↔code synthesis), route
  durable state to memory FIRST so a clear loses nothing, prefer `/compact` over
  `/clear` mid-task. 2-line pointer added to CLAUDE.md MEMORY (non-CORE; CORE hash
  unchanged).

## v8.1.4
Acts on an external review. Theme: ship-correctly out of the box, make velocity a
first-class choice (not just governance), and state the honest limits.

- **FIX (critical): scripts shipped without the execute bit.** The archive came from
  a filesystem that doesn't carry Unix permissions, so every hook
  (`guard.sh`, `state-freshness.sh`, `check-core.sh`, `check-claude-md-size.sh`) and
  `quality-gate.sh` silently failed to run after extraction. Added `setup.sh` (run
  `bash setup.sh` once) that chmods everything and installs the git hook; README now
  makes it Step 0.
- **FIX: packaging.** Removed duplicate top-level copies of `check-core.sh` /
  `memory-router.md` and the double-nested `v8.1.x/v81.x/` folder — the template now
  has a single clean root. Removed leftover LLM editing scaffolding and the stale
  "v7" anchor text from the README.
- **NEW: two execution lanes** (`.claude/skills/execution-lanes/` + a non-CORE
  pointer in CLAUDE.md). Fast lane (trivial/solo/disposable): one pass, one proof,
  no run-report. Full lane (client/infra/prod/irreversible): the full pipeline +
  gates. Stops both over-ceremony on throwaway work and reckless shortcuts on real
  work. SAFETY + spend guard apply in both.
- **NEW: research-before-plan.** `/research` command + a Research phase in the
  pipeline — research the CURRENT state before committing to an approach, consistent
  with `verify-external-state` (don't plan on stale training knowledge).
- **NEW: resume-after-context-reset flow.** Made explicit in CLAUDE.md MEMORY +
  pipeline: artifacts are the checkpoint; new session → read current.md + latest.json
  + spec → continue. Never restart from chat memory.
- **NEW: `skill-authoring` skill** — write a new skill by copying the shape of a
  working one; prefer a hook for 100%-rules and memory-router for facts.
- **HONESTY: reviewer independence.** orchestration + AGENTS.md now state that all
  reviewers share one base model (correlated blind spots); fresh context reduces but
  doesn't remove rubber-stamping, and Codex "sequential passes" are weaker still —
  for high-stakes work the human is the real independent check.
- **CEO lens + sustainable pace** added to `executive-review`: an explicit demand
  check ("who actually wants this?") and a quiet stop-condition for driving a project
  hard with no users at the cost of everything else.
- **`forbidden-sites.md`** (referenced by CORE) shipped empty; now carries
  explanatory template content (default-allow; add per-project denials).
- **FIX: missing `.env.example`.** The template referenced `.env.example` in 4 places
  (CLAUDE.md SAFETY, guard.sh, .gitignore, verify-external-state) but never shipped it,
  so the "real .env stays gitignored, commit .env.example" convention had no seed file.
  Added a tailored `.env.example` (app / AI keys / DB / external APIs / auth / deploy,
  placeholders only); `setup.sh` now copies it to a local gitignored `.env`; onboarding
  tailors it to the project's real variables. (A real `.env` is still never shipped or
  committed — verified: gitignored + blocked by the pre-commit hook.)
- **Model cost: unchanged default, now documented.** Reviewers stay on `opus` by
  design (time > tokens); orchestration + team-proposal explain how to downgrade
  non-high-risk roles to `sonnet` per project if token budget matters.

Note: the CORE block in CLAUDE.md is byte-identical to v8.1.3 — every addition lives
OUTSIDE the CORE markers, so `.claude/core.sha` is unchanged and `check-core.sh`
passes out of the box.

## v8.1.3
Fixes for issues that recurred in seeded projects: loops ("fixed N times, still broken"),
version conflicts, stale-note-as-truth, and a guard that blocked legitimate docs.

- **FIX (critical): `.claude/settings.json` was invalid JSON** — two concatenated top-level
  objects, so Claude Code could not parse it (hooks/permissions silently failed to load).
  Merged into one valid object; `WebFetch`/`WebSearch` folded into `permissions.allow`.
- **FIX: `scripts/guard.sh` was over-broad.** It scanned file CONTENT (Write/Edit) for
  destructive command words, so it blocked docs/analysis that merely mention `rm -rf`,
  `git reset --hard`, etc. (and a `YYYY-MM-DD ` date matched the `dd ` disk-wipe pattern) —
  training people to reword around the safety guard. Now it detects `tool_name`: secrets are
  checked for every tool, but the destructive-command + `.env`-staging checks run **only for
  Bash** (file content is not executed). Real protection intact, false-positives gone.
- **NEW: live-state-as-truth discipline** (root cause of loops + version conflicts):
  - `.claude/rules/verify-external-state.md` — live system is the source of truth; published
    versions are the #1 stale fact; validate breadth not one example; anti-loop ("don't
    re-fix on a stale basis"); gate irreversible actions on a live check.
  - `.claude/settings.json` `SessionStart` hook → `scripts/state-freshness.sh` — zero-network
    banner each session: current.md holds NOTES that decay; verify live first.
  - `scripts/check_live_state.py` — read-only stub; each project implements live checks for its
    external systems (deploy version, published config, external API/DB).
  - `.agent/state/current.md` — freshness banner + `[verified <date> via <tool>]` provenance
    convention.
  - CLAUDE.md MEMORY section — one line: notes are not live truth (non-CORE, no rebaseline).
- **FIX: 250-line limit wording** — `settings.json` comment said "200"; CLAUDE.md said "~220".
  Now consistently 250 (the hard limit `check-claude-md-size.sh` already enforces).

- **FIX: stale CORE baseline.** The shipped `.claude/core.sha` did not match the template's own
  CORE block, so `check-core.sh` fired a spurious "CORE changed — STOP" on the first edit in
  every seeded project (the v8.1.2 template failed its own check too). CORE content is unchanged;
  the baseline was re-generated so `check-core.sh` passes out of the box.

Note: CORE block content itself is unchanged from v8.1.2 (verified — identical CORE hash); the
verify-live additions all live OUTSIDE the CORE markers, so no real kernel change occurred.

## v8.2.1 — Context Guard v4.2.0
Theme: v4 was correct on Linux and a **silent no-op on Windows**, and its own
smoke test said GREEN either way. This release makes the package work on the
machine it is actually used on, makes it say so when it cannot, and makes the
archive a build product of a canonical source tree instead of the only copy.

- **Windows/MSYS2 correctness.** Four defects, each proven by direct
  instrumentation rather than inspection:
  - `json.load(open(p))` with no `encoding=` — `config.json` carries a Ukrainian
    comment, so on a cp1252 default the read raised, the exception was swallowed,
    and a **1M model silently ran the 200k ladder**.
  - cp1252 stdout — every hook message is Ukrainian, so `UnicodeEncodeError`
    killed the ladder, the runaway message and the post-compaction handoff
    injection.
  - **state-directory disagreement** — with `TMPDIR` unset, git-bash resolved
    `/tmp` to `%TEMP%` and native-Windows python resolved it drive-relative to
    `D:\tmp`. The statusline wrote state the hooks could never read, so
    `load_state()` returned `ts=0` and **every hook failed open**. Root cause:
    MSYS2 rewrites path-shaped env vars when spawning a native Windows process,
    so an env-derived path agrees across the boundary and a *literal* fallback
    never can. Resolution now prefers a drive-lettered `TMPDIR`/`TEMP`/`TMP` on
    both sides (`.claude/context-guard/state-dir.sh` + `cg_common._state_dir()`).
  - `grep -q "🟠"` — git-bash grep 3.0 cannot match 4-byte UTF-8; the smoke test
    reported false failures. Now `LC_ALL=C grep -qF`.
- **The smoke test hid the worst of those.** It did `export TMPDIR="$(mktemp -d)"`,
  which is exactly the condition under which the state-dir bug cannot appear.
  State-dir agreement is now proven by writing a token from bash and reading it
  back from python — directory identity, not string equality.
- **NEW: compatibility guard (J).** `version.json` is the source of truth for
  `runtime_version` / `schema_version`; the module constants are its fallback and
  a test asserts they agree. A project config declares `schema_version` (exact)
  and `min_runtime` (floor — 4.9.9 satisfies 4.2.0; there is no exact-version
  equality). Every entry point calls `guard_enabled()` first. On mismatch the
  statusline reads **⚠ CONTEXT GUARD INCOMPATIBLE**, the banner goes to stderr
  for `--debug`, `cg_common.py --compat` exits 3 — and all automation switches
  off, **including the runaway backstop**. Context Guard never blocks work
  because Context Guard needs an upgrade. A config declaring neither field is a
  pre-J config and stays compatible.
- **NEW: atomic state.** Unique temp file in the same directory then
  `os.replace()` / `mv -f`, for state, telemetry and flags. Verified with a
  positive control: the atomic writer showed 0 partial reads in ~42k, a
  direct-write mutant under the identical probe showed 4 in 51.
- **NEW: user-level install, per-project opt-in**
  (`scripts/install-context-guard.py`). One runtime at `~/.claude/context-guard/`,
  registered once in `~/.claude/settings.json`. Because that runtime loads in
  every project, a project counts as opted in only if it owns
  `.claude/context-guard/config.json`; without one the runtime is silent, writes
  no state, shows no statusline segment and blocks nothing. Installing is not
  enabling. The installer is idempotent: it removes every hook entry pointing
  into a context-guard directory and re-adds the canonical set, so re-running
  repairs drift instead of duplicating hooks, and never touches hooks that are
  not ours.
- **NEW: `scripts/build-release.py`** — the zip is now a reproducible build
  product (sorted entries, pinned `SOURCE_DATE_EPOCH`), with the sha256 written
  next to it. Edit the tree, rebuild; never patch the archive.
- **NEW: `.claude/context-guard/verify-install.py`** — verifies what was actually
  installed, where: registration without duplicates, the real statusline command
  out of `settings.json`, the compatibility matrix, opted-out silence, and
  atomicity of the installed writers.
- **Vendored runtimes win.** A project that ships its own
  `.claude/context-guard/hooks/cg_common.py` owns it: the user-level runtime
  stands down there rather than double-firing every hook and putting two writers
  on one state file. Found in the wild — another project on the build machine had
  a per-project pre-J copy installed, which the user-level model would otherwise
  have silently taken over.
