---
description: Independently verify the current change without building anything new.
---
Use the orchestration skill: map the risks of the current change, run the matching
reviewers in parallel and independently (they don't see each other's verdicts), then
the verifier consolidates → GREEN or send-back with findings. Write/update the run
report + latest.json. Finish with ./scripts/quality-gate.sh and show GREEN/BLOCKED.
