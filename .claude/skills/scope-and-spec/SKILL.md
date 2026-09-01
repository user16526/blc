---
name: scope-and-spec
description: Classify a task's scope before doing it, and write a spec sized to that scope. Use at the start of any non-trivial task, before implementing.
---

# Scope & Spec first (R3)
<!-- Adapted from the SE guide's hard rule R3. Don't jump straight into "small" tasks. -->

Before acting, classify the scope and write a spec sized to it. Bigger scope =
more upfront thinking, so the result is reproducible and the AI doesn't hallucinate.

| Scope | What to write first | Must include |
|---|---|---|
| **Trivial** (rename, change one config value, remove dead import) | nothing — just do it | — |
| **Small fix / bug** (≤1 file, ≤~50 lines) | a short spec | Context, how to reproduce, root cause, fix scope, acceptance criteria, a regression test, rollback |
| **New feature** (in an existing project) | a full feature spec | Goal, out-of-scope, states to handle (empty/loading/error), acceptance criteria, success metric, test plan |
| **New project** (from scratch) | a project spec | Vision, users, phases, tech-stack rationale, architecture, roles, risks, success metrics |

Rules:
- **Interview before feature+ specs.** If scope is New feature or bigger, OR the
  request is vague: before writing, ask the human the 3–7 questions that most
  change the design. The curse of knowledge lives on the human side — unstated
  assumptions are the main spec killer. Then write.
- Don't "do it by hand now and write the spec later" — you won't. Write it first.
- HIGH/DESTRUCTIVE-row specs live in `specs/NNN-slug/spec.md` (NNN = next number; put
  `plan.md` / `tasks.md` beside it when the task warrants them). This folder is
  the browsable feature history — it answers "why is it built this way" later.
  Timestamped names (artifact-versioning rule) remain for drafts and one-off docs.
- A spec must say how the result will be **verified**, not only what to build.
- If it's a repeated action, consider turning it into a skill instead of redoing it.

This pairs with plan mode in CLAUDE.md: classify scope → write the sized spec →
plan → implement → verify. Scope also picks the RISK MATRIX row (CLAUDE.md):
trivial → LOW (one proof, no run-report); client/infra/prod/irreversible →
HIGH or DESTRUCTIVE with full gates.
