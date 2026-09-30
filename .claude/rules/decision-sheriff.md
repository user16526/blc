# Decision-sheriff — a choice is checked by a second vendor before it reaches the owner (always on)

**Active only when `PROJECT → SHERIFF cross-review: on`.** Off or empty: dormant — ask
the owner exactly as before. It is the same switch as the `cross-review` skill; there is
nothing else to turn on.

## What it covers
An ENGINEERING choice inside the scope the owner already granted — which of two sound
implementations, which tool, which order — that you would otherwise put to the owner in
the MY RULES decision format. Before asking, send the decision packet to the sheriff. The
owner sees the question only when the sheriff disagrees or cannot judge.

MY RULES says HOW to ask when you have a real choice; this rule decides WHETHER a
non-matrix choice reaches the owner at all while the sheriff is on. A choice the sheriff
agrees with is taken, logged, and stays vetoable (below).

## Never through the sheriff — straight to the owner
- Every approval the RISK MATRIX requires: a HIGH plan, anything DESTRUCTIVE / money /
  prod / secrets, a deploy go-ahead, a CORE change, anything that spends.
- Every stop: the automode stop list, the kernel's every-row stops (RED, BLOCKED gate,
  anything irreversible), an escalation table from `orchestration`. The owner decides the
  stop — but the packet that goes with it is reviewed first (next section).
- A request for INFORMATION only the owner has — a path, an account, a preference, a
  priority. The sheriff can judge a decision; it cannot supply a fact.
- An ambiguity about WHAT THE OWNER ASKED FOR. Their intent is an owner-only fact.
- A scope change — anything beyond the request or the approved plan. An approval never
  covers a wider scope (`go-ahead-scope.md`), and a sheriff's AGREE is not an approval.
- Anything that would put a secret or client data into the packet.

## A stop's packet is reviewed; the stop is never decided by the sheriff
A BLOCKED gate, a RED, any every-row stop goes to the owner — always. But the packet you
would send with it (question, facts, options, recommendation) goes through the sheriff
FIRST, same wrapper, same `--mode decision`, and the verdict is shown beside your
recommendation: `sheriff: AGREE` / `DISAGREE: …` / `CANNOT-JUDGE: …` / `n/a (<exit>)`.
AGREE takes no stop decision; the owner does. A wrong recommendation on a stop ("push
anyway, docs only" on a BLOCKED gate) is exactly what a second reader catches. Counted
like every other call.

## The packet (the wrapper's stdin, about 40 lines at most)
1. **Question** — one sentence.
2. **Facts** — only what the decision turns on. No transcript, no AGENTS.md/CLAUDE.md. Each cites
   its evidence (a log line, a test, or a command + its output) or says `unverified`.
3. **Options** — each with its real pros and cons: the recommendation and the one real
   alternative, not five.
4. **Recommendation + why**, and whether it is reversible.
5. **What would change this recommendation** — one concrete check or fact, never "new
   information".

```
printf '%s' "$PACKET" | bash scripts/sheriff-review.sh --author claude --mode decision
```

The wrapper owns every isolation boundary, exactly as for a diff review (`cross-review`
skill). Never build the CLI call by hand.

## Reading the verdict — first line of the findings file
- `AGREE` → take the recommendation. Append one line to `.agent/state/decisions.md`
  (date · question · choice · `sheriff: AGREE` · findings path) and tell the owner in one
  line: `Decided (sheriff agreed): <choice> — <why>. Veto any time.`
- `DISAGREE: …` or `CANNOT-JUDGE: …` → ask the owner in the MY RULES format, with the
  sheriff's position shown beside yours.
- Any non-zero exit — no CLI, a missing isolation flag, a failed call, a same-vendor
  refusal → ask the owner as before. Do not hand over the manual package instead: a
  decision that goes manual is an owner question anyway.

## Count every call
Each call is billable. The run report records
`decision_sheriff: <calls> calls, <tokens> tokens` — calls = wrapper runs with
`--mode decision`; tokens = the sum of the `tokens used` figure the CLI prints on stderr
at the end of each run (`n/a` if it printed none). Without a run report, the same line goes into the
`decisions.md` entry.
