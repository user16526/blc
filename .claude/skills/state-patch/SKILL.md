---
name: state-patch
description: Maintain the authoritative execution state continuously during work via deterministic patches (LLM proposes, script merges). Use at every semantic event — completed unit of work, material discovery, failed hypothesis, decision, phase transition, finding resolved — NOT after every shell command.
---

# State patch — continuous authoritative execution state

The hybrid runtime (arXiv:2608.26263 adapted for Claude Code): a short WARM
transcript for in-context synthesis + an AUTHORITATIVE structured state that is
kept current throughout the task — so the transcript can be dropped at ANY
moment (/clear, compaction, crash) without losing the task. The handoff and
Context Guard remain the safety net, no longer the primary mechanism.

## When to emit a patch (semantic events — mandatory; per-command — never)
- a unit of work COMPLETED (block done, test suite run, gate passed)
- a MATERIAL discovery about the system or task
- a FAILED hypothesis / rejected approach  → `append: failed_rejected`
- a DECISION taken (1-liner here; full reasoning → decisions.md via memory-router)
- a PHASE transition (research → spec → build → verify → deploy)
- a reviewer FINDING resolved — only AFTER the gate confirms (open → resolved)
The ceremony tax of per-command patches is real; the anti-repeat value of
`failed_rejected` is also real. Batch small steps, never skip failures.

## How
Propose a patch; the SCRIPT validates and merges — never edit current.json or
current.md by hand:

    python3 scripts/state-patch.py --patch '{
      "set":    {"verified.test_hooks": "146/0 GREEN",
                 "next": "run quality-gate.sh"},
      "append": {"failed_rejected": "brace-expansion cp in bash_tool"},
      "delete": ["open_loops"]}'

Enforced invariants (rejection = state untouched, fix the patch):
I1 schema-listed keys only · I2 `next` = exactly one action, one line ·
I3 `failed_rejected` never shrinks without --allow-forget · I4 types ·
I5 no whole-state replacement. `--show` prints state; `--self-test` proves the
merge engine.
A hand-maintained `current.md` (no `RENDERED VIEW` marker) is never rendered over:
the patch still merges, and the view goes to `.agent/state/state-view.md` beside it.

## Division of labor with the rest of the template
- current.json/current.md = Σ (what's true NOW). Compact. Not a ledger.
- decisions.md / risks.md / lessons.md / _reports = cold ledger, on-demand only.
- handoff (skill `handoff`) = an INJECTION SNAPSHOT built FROM this state at
  rotation points; it no longer carries unique facts.
- Reviewer package (cross-review) = task + THIS state + diff + evidence —
  no transcript, so the reviewer never inherits stale hypotheses.
- Live-system facts inside `verified` DECAY like everywhere else: they are
  pointers, re-pull before acting (verify-external-state.md).
