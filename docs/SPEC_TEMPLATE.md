# Spec — <title>
<!-- A spec for `/run-spec`. Copy to specs/NNN-slug/spec.md and fill every <…>.
     Each step must be executable WITHOUT asking: an exact deliverable, the proof that
     closes it, and its row. plan-compiler copies Deliverable / Row / DoD verbatim into
     board lines, so what you write here is exactly what the queue is held to.
     Budget = the number of steps below; the queue never takes an item added later. -->

- **Spec id:** NNN-slug
- **Spec format:** 2  <!-- format 2 = every step carries `Kind:` and the gate lints it; a
  spec without this line predates v8.3.28 and is not linted -->
- **Goal:** <one sentence — the outcome, not the activity>
- **Done when:** <the one observable result that means the whole spec is done>
- **Source of truth:** <where the right answer lives: brief / live site / repo path>

## Open questions
Only what could not be settled from the repo and the brief: two readings with different
outcomes, a fact only the owner has. One line each, with the recommended answer — never an
invented one. Answered before the plan is approved, written back into the steps, then this
section is deleted. `/write-spec` fills it; an empty section means none were found.
- <…>

## Steps
One step = one board line = one gate cycle. Order is execution order. Keep each step
small enough to reach GREEN in one gate cycle — a step that needs iterating is two steps.
Context taken from a log or a recording is quoted VERBATIM (the real line, its real
shape) — a paraphrase or a synthetic example gets a fix for a case that never occurs.
<!-- Kind, per step:
     fix    = expected behaviour is known; cites the log/test. NEVER researched.
     build  = one obvious implementation. Not researched.
     choice = researched (`/write-spec` step 2a). A step is `choice` when drafting it hits ANY
              of these checkable triggers — not a judgement call:
              1. it introduces a numeric constant, limit, cap, threshold or timeout that is
                 not derived from the input or from a measurement in this repo;
              2. >=2 viable implementations differ in something costly to revert: stored data
                 format, public interface, new dependency, algorithm, external service;
              3. the owner's paragraph contains "best way", "how should", "which", or names
                 >=2 options.
     Budget: max 2 `choice` steps per spec. A third means "split: design spec first". -->

### S01 — <short name>
- **Kind:** fix | build | choice
- **Research:** — | specs/NNN-slug/research/Sxx.md  <!-- required when Kind is choice; never on fix -->
- **Deliverable:** <exact files / artefacts created or changed — paths, not topics>
- **DoD:** <the proof: a command and its expected output, a named test, a screenshot of X>
- **Row:** LOW | NORMAL | HIGH   <!-- never DESTRUCTIVE: that is a stop, not a step -->
- **Touches:** <risks: functional / visual / security / data / infra / content> — by grep:
  `<the grep that found the callers / consumers of each Deliverable path>` → <hits>
- **Persist before act:** — | <REQUIRED on any step that deletes or overwrites: what is
  copied or committed where, and the check that proves the copy is complete, BEFORE the
  delete/overwrite runs; a failed copy stops the step>
- **Depends on:** — | S0x

### S02 — <short name>
- **Kind:**
- **Research:**
- **Deliverable:**
- **DoD:**
- **Row:**
- **Touches:**
- **Persist before act:**
- **Depends on:**

## Non-goals
What this spec deliberately does NOT do. A step that drifts into one of these is scope
drift, and the run stops.
- <…>

## Stop conditions
This spec's own, ADDED to the stop list in `.claude/rules/automode-queue.md`. Concrete
and checkable, never a judgement call. Typical:
- A file outside every step's Deliverable would have to change — except the files every
  run writes anyway: `tasks/board.md`, `tasks/lessons.md`, `_reports/runs/` (incl.
  `latest.json`) and `.agent/state/`. Those are never scope drift.
- An external call, a paid service, or any new cost appears.
- A test outside this spec's scope turns RED.
- <…>

## Verification of the whole spec
<how the owner checks the end result once every step is [done] — one command or one
short walkthrough>
