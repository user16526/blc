# SHERIFF mechanism — canonical export for the template (proposed v8.3.3)

Exported from field project A @ `05160f469d8f`, branch `feat/cg-4.2.4-unknown-keys`, 2026-08-30.
Every file below is **byte-identical** to the working, proven copy in that project
(copied and hash-verified, not retyped).

## Why this copy is the canonical one
This mechanism was reviewed three times BY ITSELF, cross-vendor, and each pass found
real defects that the previous one had missed. That is the entire evidence base:

| round | what it reviewed | findings |
|---|---|---|
| 1 | the command file as prose | 1 — no isolated work root, so the reviewer auto-loaded the repo's own `AGENTS.md` (verified: it quoted the file) |
| 2 | the full install diff | 3 — reviewer vendor hardcoded (same-vendor review of Codex-authored work); `-o` path unconstrained; manual fallback silently dropped the acceptance criteria |
| 3 | the hardened wrapper, run THROUGH itself | 4 — protected root taken from the caller's cwd; symlink final component bypassing containment; vendor denylist letting `ChatGPT`/`o3` through; isolation assertions that only ran when a real CLI was installed |

8 findings, 0 disputes, arbiter never needed. The load-bearing lesson: **a guarantee
that must hold 100% cannot live only in prose.** Rounds 1 and 2 found holes in prose;
round 3 found holes in code that tests then locked shut. Only the third kind stays fixed.

## The exit-code contract (stable — callers branch on it)
| code | meaning |
|---|---|
| 0 | review ran; findings path printed on the last line |
| 1 | the CLI invocation itself failed |
| 3 | REFUSED — a package/findings path resolves inside the repo root |
| 4 | REFUSED — same-vendor, or unrecognised, author identity |
| 5 | REFUSED — the CLI lacks a required isolation flag → manual package emitted |
| 6 | REFUSED — no CLI on PATH → manual package emitted |

5 and 6 gate the AUTOMATION only. Both print a complete manual review package, so the
review still happens. Never make them silent, and never make them exit 0.

## Files
- `scripts/sheriff-review.sh`
  → `scripts/sheriff-review.sh` · sha256 `64e2c827783d7ceb` · 15431 bytes
- `scripts/integration/sheriff-isolation-live.sh`
  → `scripts/integration/sheriff-isolation-live.sh` · sha256 `ec0adc0a5f7e9363` · 4524 bytes
- `scripts/test-hooks.sh`
  → `reference/test-hooks.sh.full` · sha256 `57d32d819efa8372` · 22773 bytes
- `.claude/skills/cross-review/SKILL.md`
  → `.claude/skills/cross-review/SKILL.md` · sha256 `a3170f5e6b81a372` · 5878 bytes
- `.claude/skills/cross-review/prompts/sheriff-review.md`
  → `.claude/skills/cross-review/prompts/sheriff-review.md` · sha256 `f7005990a7b5d1ff` · 1079 bytes
- `.claude/skills/cross-review/prompts/arbiter.md`
  → `.claude/skills/cross-review/prompts/arbiter.md` · sha256 `0e52619732ead3f5` · 779 bytes
- `.claude/commands/sheriff.md`
  → `.claude/commands/sheriff.md` · sha256 `e2e1fdc218182db8` · 2947 bytes
- `scripts/test-hooks.sh (section 8 only)`
  → `scripts/test-hooks.section8.sh` · sha256 `bc942276d7a8500a` · 11345 bytes

## Folding this into the template
1. `scripts/sheriff-review.sh` and `scripts/integration/sheriff-isolation-live.sh` drop
   in as-is. Keep the execute bit (`setup.sh` restores it; the repo stores 100644).
2. `scripts/test-hooks.section8.sh` is a splice-ready fragment — insert it before the
   final `cd "$ROOT" || true` in the template's own `test-hooks.sh`. It assumes the
   harness's `ok`/`no` helpers and `$SANDBOX`, and nothing else.
   `reference/test-hooks.sh.full` is this project's whole file, for context only.
3. The skill and command files drop in as-is.
4. The template must also carry, in its own words: the HIGH/DESTRUCTIVE row wiring in
   CLAUDE.md CORE, the SHERIFF alias line, the AGENTS.md SHERIFF-mode section, a dated
   role→model mapping line, and the UPGRADE.md section that keeps all of it from being
   dropped by a later upgrade.

## Three things not to "clean up"
- **The closed set of author identities.** It looks like it wants to be a regex. It was
  a regex; `ChatGPT` and `o3` walked through it while naming the sheriff's own vendor.
  Unrecognised input must fail CLOSED.
- **The probe's caveat text.** `--probe` proves a flag EXISTS, never that it BEHAVES.
  The live canary is the only thing that proves behaviour, which is why it is a separate
  manual script and why it must NOT be folded into the gate.
- **Path containment normalising both sides through `cd … && pwd -P`.** Comparing a
  `D:/…` string against a `/d/…` string silently never matches, and the check becomes
  decorative on Windows.

## Known limit carried over
The symlink branch of `refuse_if_in_repo` is unproven by EXECUTION on Windows (symlink
creation needs privilege there). It is proven by reading and by a reviewer re-check
only. On a Linux CI it is directly testable and should get a real assertion.

## Verification state at export
- `bash scripts/test-hooks.sh` → 68 assertions, 0 failures (section 8 contributes 26).
- `bash scripts/integration/sheriff-isolation-live.sh` → 3/0 GREEN on codex-cli
  0.147.0-alpha.6.6; the reviewer answered `NO PROJECT FILE`, the exact inverse of
  round 1's leak.
- `bash scripts/sheriff-review.sh --probe` → OK, automation available.
- `./scripts/quality-gate.sh` → GREEN.
